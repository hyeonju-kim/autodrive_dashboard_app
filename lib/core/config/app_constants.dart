import 'dart:ui';

class AppConstants {
  // ===== 차량 정보 =====
  /// 화성 차량 정보
  static const String marsVehicleNumber = '80허3342';
  static const String marsVehicleId = 'f4FwwkGR';

  /// 제주 차량 정보
  static const String jejuVehicleNumber = '00임4427';
  // static const String jejuVehicleId = 'VEHICLEID';
  static const String jejuVehicleId = 'f4FwwkGR';

  // Janus 서버 설정
  static const String janusServer = 'http://123.143.232.180:25800/janus';

  // MQTT 설정
  // static const String mqttHost = '192.168.2.51';
  static const String mqttHost = '123.143.232.180';
  static const String mqttPath = '/mqtt';
  static const int mqttPortMars = 38083; // 화성
  static const int mqttPortJeju = 28083; // 제주
  static const String mqttUsername = 'socket';
  static const String mqttPassword = 'thzpt!@#';

  // MQTT 토픽 템플릿
  static const String mqttDataTopicTemplate = '/topic/%s';
  static const String mqttResetTopicTemplate = '/topic/%s/route/reset';

  // 화성 토픽들
  static const String mqttTopicMars = '/topic/f4FwwkGR';
  static const String mqttResetTopicMars = '/topic/f4FwwkGR/route/reset';

  // 제주 토픽들
  static const String mqttTopicJeju = '/topic/f4FwwkGR';
  static const String mqttResetTopicJeju = '/topic/f4FwwkGR/route/reset';

  // ICE 서버 설정
  static const List<String> stunServers = [
    'stun:stun.l.google.com:19302',
    'stun:stun1.l.google.com:19302',
  ];

  static const String turnServer = 'turn:123.143.232.180:3478';
  static const String turnUsername = 'platform';
  static const String turnCredential = 'Abacus0131!';

  // ===== 스트림 식별자 =====
  /// 화성 - 첫 번째 카메라 스트림 ID
  static const int stream1Id = 11;

  /// 화성 - 두 번째 카메라 스트림 ID
  static const int stream2Id = 12;

  /// 제주 - 첫 번째 카메라 스트림 ID
  static const int jejuStream1Id = 13;

  /// 제주 - 두 번째 카메라 스트림 ID
  static const int jejuStream2Id = 14;

  // 타이머 설정
  static const Duration pollInterval = Duration(milliseconds: 500);
  static const Duration clockUpdateInterval = Duration(seconds: 1);

  // UI 설정
  static const int maxLogCount = 100;
  static const double speedMaxKmh = 50.0;

  // 색상
  static const backgroundPrimary = Color(0xFF1a2332);
  static const backgroundSecondary = Color(0xFF0d1419);
}