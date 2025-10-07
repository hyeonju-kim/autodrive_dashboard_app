/// 차량의 실시간 데이터를 표현하는 모델 클래스
/// MQTT를 통해 수신되는 차량 상태 정보를 구조화
class VehicleData {
  /// 차량 속도 (m/s 단위)
  final double speedXMps;

  /// 배터리 잔량 (퍼센트)
  final double batteryGaugePercent;

  /// 방향 지시등 상태 (0: 꺼짐, 1: 우측, 2: 좌측, 3: 비상)
  final int turnSignal;

  /// 브레이크 페달 상태
  final bool brakePedal;

  /// X축 가속도 (m/s² 단위)
  /// 양수: 가속, 음수: 감속
  final double accelerationXMps2;

  /// 자율주행 모드 활성화 여부
  final bool operationModeAuto;

  /// 청소 브러시 작동 여부
  final bool blowerRun;

  VehicleData({
    required this.speedXMps,
    required this.batteryGaugePercent,
    required this.turnSignal,
    required this.brakePedal,
    required this.accelerationXMps2,
    required this.operationModeAuto,
    required this.blowerRun,
  });

  /// JSON 데이터로부터 VehicleData 객체 생성
  /// MQTT로 수신된 JSON 메시지를 파싱하여 객체로 변환
  factory VehicleData.fromJson(Map<String, dynamic> json) {
    // 차량 내부 데이터 추출
    final inVehicleData = json['inVehicleData'] ?? {};

    // 운행 상태 데이터 추출
    final operationStatusData = json['operationStatusData'] ?? {};

    // 서비스 모듈 데이터 추출
    final serviceModuleData = json['serviceModuleData'] ?? {};

    return VehicleData(
      // 기본값 0.0으로 null 안전성 보장
      speedXMps: (inVehicleData['speedXMps'] ?? 0.0).toDouble(),
      batteryGaugePercent: (inVehicleData['batteryGaugePercent'] ?? 0.0).toDouble(),
      turnSignal: (inVehicleData['turnSignal'] ?? 0) as int,
      brakePedal: inVehicleData['brakePedal'] ?? false,
      accelerationXMps2: (inVehicleData['accelerationXMps2'] ?? 0.0).toDouble(),

      // 운행 모드가 'DRIVE_AUTO'인 경우 자율주행 모드
      operationModeAuto: operationStatusData['operationMode'] == 'DRIVE_AUTO',

      // 블로워(브러시) 작동 상태
      blowerRun: serviceModuleData['blowerRun'] ?? false,
    );
  }

  /// 급가속/급감속 상태 계산
  /// 가속도 값에 따라 운전 패턴 판단
  int get harshDriving {
    if (accelerationXMps2 > 0) return 1;  // 급가속
    if (accelerationXMps2 < 0) return -1; // 급감속
    return 0; // 정상
  }

  /// 속도를 km/h 단위로 변환 (안함)
  double get speedKmh => speedXMps;
}

/// 방향 지시등 상태를 표현하는 열거형
enum TurnSignalState {
  off(0),     // 꺼짐
  right(1),   // 우측
  left(2),    // 좌측
  hazard(3);  // 비상

  final int value;
  const TurnSignalState(this.value);

  /// 정수 값으로부터 TurnSignalState 생성
  static TurnSignalState fromValue(int value) {
    return TurnSignalState.values.firstWhere(
          (e) => e.value == value,
      orElse: () => TurnSignalState.off,
    );
  }
}

/// 급가속/급감속 상태를 표현하는 열거형
enum HarshDrivingState {
  normal(0),         // 정상 운전
  acceleration(1),   // 급가속
  deceleration(-1);  // 급감속

  final int value;
  const HarshDrivingState(this.value);

  /// 정수 값으로부터 HarshDrivingState 생성
  static HarshDrivingState fromValue(int value) {
    if (value > 0) return HarshDrivingState.acceleration;
    if (value < 0) return HarshDrivingState.deceleration;
    return HarshDrivingState.normal;
  }
}