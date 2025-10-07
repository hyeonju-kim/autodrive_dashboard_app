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

  String? _currentTopic; // 현재 구독 중인 토픽

  Stream<VehicleData> get vehicleDataStream => _vehicleDataController.stream;

  /// MQTT 연결 상태를 방출하는 스트림
  Stream<bool> get connectionStream => _connectionController.stream;

  Future<void> connectToTopic(String topic) async {
    _currentTopic = topic;
    await connect();
  }

  Future<void> connect() async {
    try {
      // 고유한 클라이언트 ID 생성 (타임스탬프 사용)
      final clientId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
      Logger.log('🆔 MQTT Client ID: $clientId');

      // MQTT 클라이언트 생성 (WebSocket 사용)
      _client = MqttServerClient.withPort(
        'ws://${AppConstants.mqttHost}${AppConstants.mqttPath}',
        clientId,
        AppConstants.mqttPort,
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

    if (_currentTopic != null) {
      _client!.subscribe(_currentTopic!, MqttQos.atLeastOnce);
      Logger.log('✅ 토픽 구독 완료: $_currentTopic');
    }

    // 메시지 수신 리스너 설정
    _client!.updates!.listen((messages) {
      final message = messages[0];
      final recMess = message.payload as MqttPublishMessage;

      // 바이트 배열을 문자열로 변환
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      try {
        // JSON 파싱 및 VehicleData 객체 생성
        final data = jsonDecode(payload);
        final vehicleData = VehicleData.fromJson(data);

        // 스트림으로 데이터 방출
        _vehicleDataController.add(vehicleData);
      } catch (e) {
        Logger.log('❌ MQTT 메시지 파싱 오류: $e');
      }
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
    _client?.disconnect();
    _vehicleDataController.close();
    _connectionController.close();
  }
}