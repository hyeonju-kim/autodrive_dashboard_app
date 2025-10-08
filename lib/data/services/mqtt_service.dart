// lib/data/services/mqtt_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../../core/config/app_constants.dart';
import '../../core/utils/logger.dart';
import '../models/vehicle_data.dart';

/// MQTT 통신을 관리하는 서비스 클래스
/// 차량의 실시간 데이터를 MQTT 브로커로부터 수신
// lib/data/services/mqtt_service.dart

class MqttService {
  /// MQTT 클라이언트 인스턴스
  MqttClient? _client;

  /// 차량 데이터 스트림 컨트롤러
  /// UI 레이어에서 구독하여 실시간 업데이트 수신
  final _vehicleDataController = StreamController<VehicleData>.broadcast();

  /// MQTT 연결 상태 스트림 컨트롤러
  final _connectionController = StreamController<bool>.broadcast();
  final _resetController = StreamController<bool>.broadcast();

  String? _currentVehicleId;
  String? _currentDataTopic;
  String? _currentResetTopic;

  Timer? _dataTimeoutTimer;
  bool _wasDisconnected = false;

  Stream<VehicleData> get vehicleDataStream => _vehicleDataController.stream;

  /// MQTT 연결 상태를 방출하는 스트림
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<bool> get resetStream => _resetController.stream;

  Future<void> connectToVehicle(String vehicleId, {required int port}) async {
    _currentVehicleId = vehicleId;
    _currentDataTopic = AppConstants.mqttDataTopicTemplate.replaceAll('%s', vehicleId);
    _currentResetTopic = AppConstants.mqttResetTopicTemplate.replaceAll('%s', vehicleId);
    await connect(port: port);
  }

  Future<void> connect({required int port}) async {
    try {
      // 고유한 클라이언트 ID 생성 (타임스탬프 사용)
      final clientId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
      Logger.log('🆔 MQTT Client ID: $clientId');

      // MQTT 클라이언트 생성 (WebSocket 사용)
      _client = MqttServerClient.withPort(
        'ws://${AppConstants.mqttHost}${AppConstants.mqttPath}',
        clientId,
        port, // AppConstants.mqttPort 대신 매개변수 사용
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
      rethrow; // 호출자에게 에러 전파
    }
  }

  /// MQTT 연결 성공 시 호출되는 콜백
  /// 토픽을 구독하고 메시지 수신을 시작
  void _onConnected() {
    Logger.log('✅ MQTT 연결 성공');
    _connectionController.add(true);

    if (_currentDataTopic != null && _currentResetTopic != null) {
      // 데이터 토픽 구독
      _client!.subscribe(_currentDataTopic!, MqttQos.atLeastOnce);
      Logger.log('✅ 데이터 토픽 구독: $_currentDataTopic');

      // 리셋 토픽 구독
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

        // 리셋 메시지 처리
        if (message.topic == _currentResetTopic) {
          if (jsonData['isReset'] == true) {
            Logger.log('🔄 리셋 신호 수신');
            _resetController.add(true);
            _dataTimeoutTimer?.cancel();
          }
        }
        // 데이터 메시지 처리
        else if (message.topic == _currentDataTopic) {
          // Logger.log('📥 차량 데이터 수신');

          // 5분 이상 끊어졌다가 다시 연결된 경우
          if (_wasDisconnected) {
            _wasDisconnected = false;
            // NotificationService.showNotification(
            //   title: '차량 연결 복구',
            //   body: '${jsonData['vehicleNum']} 차량이 다시 연결되었습니다.',
            // );
          }

          // 타이머 리셋
          _resetDataTimer();

          final vehicleData = VehicleData.fromJson(jsonData);
          _vehicleDataController.add(vehicleData);
        }
      } catch (e) {
        Logger.log('❌ JSON 파싱 오류: $e');
      }
    }
  }

  void _resetDataTimer() {
    _dataTimeoutTimer?.cancel();
    _dataTimeoutTimer = Timer(const Duration(minutes: 5), () {
      Logger.log('⚠️ 5분간 데이터 수신 없음');
      _wasDisconnected = true;
    });
  }

  /// MQTT 연결이 끊어졌을 때 호출되는 콜백
  void _onDisconnected() {
    Logger.log('🔌 MQTT 연결 해제됨');
    _connectionController.add(false);
  }

  /// 리소스 정리
  /// 앱 종료 시 반드시 호출하여 메모리 누수 방지
  void dispose() {
    _dataTimeoutTimer?.cancel();
    _client?.disconnect();
    _vehicleDataController.close();
    _connectionController.close();
    _resetController.close();
  }
}