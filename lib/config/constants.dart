class AppConstants {
  // Janus 서버 설정
  static const String janusServer = 'http://123.143.232.180:25800/janus';

  // MQTT 설정
  static const String mqttHost = '192.168.2.51';
  static const String mqttPath = '/mqtt';
  static const int mqttPort = 8083;
  static const String mqttUsername = 'socket';
  static const String mqttPassword = 'thzpt!@#';
  static const String mqttTopic = '/topic/f4FwwkGR';

  // TURN 서버 설정
  static const String turnServer = 'turn:123.143.232.180:3478';
  static const String turnUsername = 'platform';
  static const String turnCredential = 'Abacus0131!';

  // 스트림 ID
  static const int stream1Id = 11;
  static const int stream2Id = 12;
}