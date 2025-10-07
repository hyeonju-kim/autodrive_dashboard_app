import 'dart:ui';

class AppConstants {
  // ===== 차량 정보 =====
  /// 화성 차량 정보
  static const String marsVehicleNumber = '80허3342';
  static const String marsVehicleId = 'f4FwwkGR';

  /// 제주 차량 정보
  static const String jejuVehicleNumber = '00임4427';
  static const String jejuVehicleId = 'VEHICLEID';

  // Janus 서버 설정
  static const String janusServer = 'http://123.143.232.180:25800/janus';

  // MQTT 설정
  static const String mqttHost = '192.168.2.51';
  static const String mqttPath = '/mqtt';
  static const int mqttPort = 8083;
  static const String mqttUsername = 'socket';
  static const String mqttPassword = 'thzpt!@#';
  static const String mqttTopic = '/topic/f4FwwkGR';
  /// 차량 데이터를 수신할 MQTT 토픽 (화성)
  static const String mqttTopicMars = '/topic/f4FwwkGR';
  /// 차량 데이터를 수신할 MQTT 토픽 (제주)
  static const String mqttTopicJeju = '/topic/VEHICLEID';

  // ICE 서버 설정
  static const List<String> stunServers = [
    'stun:stun.l.google.com:19302',
    'stun:stun1.l.google.com:19302',
  ];

  static const String turnServer = 'turn:123.143.232.180:3478';
  static const String turnUsername = 'platform';
  static const String turnCredential = 'Abacus0131!';

  // 스트림 ID
  static const int stream1Id = 11;
  static const int stream2Id = 12;
  static const int stream3Id = 13;
  static const int stream4Id = 14;

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