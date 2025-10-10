// lib/data/services/mqtt_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../../core/config/app_constants.dart';
import '../../core/utils/logger.dart';
import '../models/vehicle_data.dart';
import 'notification_service.dart';
import '../../data/services/background_service.dart';  // 추가


/// MQTT 통신을 관리하는 서비스 클래스
/// 차량의 실시간 데이터를 MQTT 브로커로부터 수신
class MqttService {
  // ===== 설정 가능한 상수들 =====
  /// 데이터 타임아웃 시간 (분)
  /// 이 시간 동안 데이터가 수신되지 않으면 연결 끊김으로 판단
  static const int _dataTimeoutMinutes = AppConstants.dataTimeoutMinutes;

  /// 재연결 알림 활성화 여부
  static const bool _enableReconnectionNotification = true; // 알림 끄고 싶으면 false로 수정

  /// 로그 메시지 템플릿
  static const String _logResetReceived = '🔄 리셋 신호 수신';
  static const String _logDataRecovery = '✅ 리셋 후 데이터 수신 - 정상 복귀 🌱🌱🌱🌱🌱🌱🌱';
  static const String _logDataReconnection = '✅ $_dataTimeoutMinutes분 이상 끊어진 후 데이터 재수신';
  static const String _logDataTimeout = '$_dataTimeoutMinutes분간 데이터 수신 없음 ❌ (상태 기록만)';
  static const String _logResetTimeout = '❌❌❌ 리셋 후 $_dataTimeoutMinutes분간(타임아웃시간) 데이터 수신 없음 ❌❌❌ (상태 기록만)';

  /// 알림 메시지 템플릿
  /// {location} - 지역명 (화성/제주)
  /// {vehicle} - 차량 정보 (차량번호 또는 ID)
  static const String _notificationTitleTemplate = '{location} - {vehicle}';
  static const String _notificationBodyTemplate = '차량 데이터 수신을 시작합니다.';

  // ===== 멤버 변수 =====
  MqttClient? _client;
  int? _currentPort;

  final _vehicleDataController = StreamController<VehicleData>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _resetController = StreamController<bool>.broadcast();

  String? _currentVehicleId;
  String? _currentDataTopic;
  String? _currentResetTopic;
  String? _currentVehicleNumber;

  Timer? _dataTimeoutTimer;
  bool _wasDisconnected = false;
  bool _isResetState = false;
  DateTime? _resetTime;  // 리셋 시간 추가

  Stream<VehicleData> get vehicleDataStream => _vehicleDataController.stream;

  /// MQTT 연결 상태를 방출하는 스트림
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<bool> get resetStream => _resetController.stream;

  Future<void> connectToVehicle(
      String vehicleId, {
        required int port,
        required String vehicleNumber,
      }) async {
    _currentVehicleId = vehicleId;
    _currentVehicleNumber = vehicleNumber;
    _currentDataTopic = AppConstants.mqttDataTopicTemplate.replaceAll('%s', vehicleId);
    _currentResetTopic = AppConstants.mqttResetTopicTemplate.replaceAll('%s', vehicleId);
    await connect(port: port);
  }

  Future<void> connect({required int port}) async {
    _currentPort = port; // 포트 저장

    try {
      // 고유한 클라이언트 ID 생성 (타임스탬프 사용)
      final clientId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
      Logger.log('🆔 MQTT Client ID: $clientId');

      // MQTT 클라이언트 생성 (WebSocket 사용)
      _client = MqttServerClient.withPort(
        'ws://${AppConstants.mqttHost}${AppConstants.mqttPath}',
        clientId,
        port,
      );

      final serverClient = _client as MqttServerClient;

      // WebSocket 프로토콜 설정
      serverClient.useWebSocket = true;
      serverClient.websocketProtocols = ['mqtt'];

      // 클라이언트 옵션 설정
      _client!.logging(on: false); // 상세 로깅 비활성화
      _client!.keepAlivePeriod = 60; // 60초마다 핑 전송
      _client!.autoReconnect = true; // 연결 끊김 시 자동 재연결
      _client!.setProtocolV311(); // MQTT 3.1.1 프로토콜 사용

      // 연결 이벤트 핸들러 등록
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;

      // 연결 메시지 구성
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(AppConstants.mqttUsername, AppConstants.mqttPassword)
          .startClean() // 세션 정보를 저장하지 않음
          .keepAliveFor(60); // Keep-alive 주기 설정

      _client!.connectionMessage = connMessage;

      Logger.log('🔄 MQTT 연결 시도 중...');
      await _client!.connect();
    } catch (e) {
      Logger.log('❌ MQTT 연결 실패: $e');
      _connectionController.add(false);
      rethrow;
    }
  }

  /// MQTT 연결 성공 시 호출되는 콜백
  /// 토픽을 구독하고 메시지 수신을 시작
  void _onConnected() {
    Logger.log('✅ MQTT 연결 성공');
    _connectionController.add(true);

    if (_currentDataTopic != null && _currentResetTopic != null) {
      _client!.subscribe(_currentDataTopic!, MqttQos.atLeastOnce);
      Logger.log('✅ 데이터 토픽 구독: $_currentDataTopic');

      _client!.subscribe(_currentResetTopic!, MqttQos.atLeastOnce);
      Logger.log('✅ 리셋 토픽 구독: $_currentResetTopic');
    }

    // 메시지 리스너
    _client!.updates!.listen(_onMessage);
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final pubMsg = message.payload as MqttPublishMessage;
      final jsonString = MqttPublishPayload.bytesToStringAsString(pubMsg.payload.message);

      try {
        final jsonData = json.decode(jsonString);

        /// ================= 리셋 메시지 처리 =================
        if (message.topic == _currentResetTopic) {
          if (jsonData['isReset'] == true) {
            Logger.log(_logResetReceived);
            _isResetState = true;
            _resetTime = DateTime.now();  // 리셋 시간 기록
            _resetController.add(true);
            _dataTimeoutTimer?.cancel();

            // 백그라운드 서비스에 리셋 상태 전달
            BackgroundService.updateLastDataTime(
              vehicleId: _currentVehicleId!,
              vehicleNumber: _currentVehicleNumber,
              port: _currentPort,
              isReset: true,  // 리셋 상태 true로 설정
              resetTime: _resetTime,  // 리셋 시간 전달
            );

            // 리셋 후 타이머 시작
            _startResetTimeoutTimer();
          }
        }
        ///  ================= 데이터 메시지 처리 (리셋이 아닌 일반 메시지) =================
        else if (message.topic == _currentDataTopic) {
          // Logger.log('📥 데이터 메시지 수신 - topic: ${message.topic}');

          // 리셋 상태에서 데이터가 들어온 경우
          if (_isResetState && _resetTime != null) {
            final timeDiff = DateTime.now().difference(_resetTime!);
            Logger.log('📊 리셋 후 데이터 수신 - 경과시간: ${timeDiff.inMinutes}분 ${timeDiff.inSeconds % 60}초');

            // 10분 이상 경과했으면 알림 발송
            if (timeDiff.inMinutes >= _dataTimeoutMinutes) {
              Logger.log(_logDataReconnection);
              if (_enableReconnectionNotification) {
                _sendReconnectionNotification();
              }
            } else {
              Logger.log('📊 리셋 후 ${timeDiff.inMinutes}분 ${timeDiff.inSeconds % 60}초 만에 데이터 수신 - 알림 발송하지 않음 ❌');
            }

            _isResetState = false;
            _resetTime = null;
          }

          // 일반 타임아웃 후 재연결된 경우
          else if (_wasDisconnected) {
            Logger.log(_logDataReconnection);
            _wasDisconnected = false;

            // 재연결 알림 발송
            if (_enableReconnectionNotification) {
              _sendReconnectionNotification();
            }
          }

          // 타이머 리셋
          _resetDataTimer();

          // 백그라운드 서비스에 데이터 수신 시간 업데이트
          BackgroundService.updateLastDataTime(
            vehicleId: _currentVehicleId!,
            vehicleNumber: _currentVehicleNumber,
            port: _currentPort,
            isReset: false,  // 데이터 수신시 리셋 상태 해제
          );
          final vehicleData = VehicleData.fromJson(jsonData);
          _vehicleDataController.add(vehicleData);
        }
      } catch (e) {
        Logger.log('❌ JSON 파싱 오류: $e');
      }
    }
  }

  /// 📢 일반 데이터 수신 타임아웃 타이머
  /// 데이터가 지정된 시간 동안 안 들어오면 상태만 기록
  void _resetDataTimer() {
    _dataTimeoutTimer?.cancel();
    _dataTimeoutTimer = Timer(const Duration(minutes: _dataTimeoutMinutes), () {
      Logger.log(_logDataTimeout);
      _wasDisconnected = true;
    });
  }

  /// ⏰ 리셋 후 데이터 수신 타임아웃 타이머
  /// 리셋 후 지정된 시간 이내에 데이터가 안 들어오면 상태만 기록
  void _startResetTimeoutTimer() {
    _dataTimeoutTimer?.cancel();
    _dataTimeoutTimer = Timer(const Duration(minutes: _dataTimeoutMinutes), () {
      if (_isResetState) {
        Logger.log(_logResetTimeout);
        _wasDisconnected = true;
      }
    });
  }

  /// 📢 재연결 알림 발송
  void _sendReconnectionNotification() {
    final location = _getLocationName();
    final vehicleInfo = _currentVehicleNumber ?? _currentVehicleId ?? '알 수 없음';

    final title = _notificationTitleTemplate
        .replaceAll('{location}', location)
        .replaceAll('{vehicle}', vehicleInfo);

    final body = _notificationBodyTemplate;

    NotificationService.showNotification(
      title: title,
      body: body,
    );
    Logger.log(_logDataRecovery);
  }

  /// 지역명 가져오기 (vehicleId 기반)
  String _getLocationName() {
    if (_currentVehicleId == AppConstants.marsVehicleId) {
      return '화성';
    } else if (_currentVehicleId == AppConstants.jejuVehicleId) {
      return '제주';
    }
    return '알 수 없음';
  }

  void _onDisconnected() {
    Logger.log('🔌 MQTT 연결 해제됨');
    _connectionController.add(false);
  }

  void dispose() {
    _dataTimeoutTimer?.cancel();
    _client?.disconnect();
    _vehicleDataController.close();
    _connectionController.close();
    _resetController.close();
  }
}