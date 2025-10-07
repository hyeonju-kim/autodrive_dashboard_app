class VehicleData {
  final double speedXMps;
  final double batteryGaugePercent;
  final int turnSignal;
  final bool brakePedal;
  final double accelerationXMps2;
  final bool operationModeAuto;
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

  factory VehicleData.fromJson(Map<String, dynamic> json) {
    final inVehicleData = json['inVehicleData'] ?? {};
    final operationStatusData = json['operationStatusData'] ?? {};
    final serviceModuleData = json['serviceModuleData'] ?? {};

    return VehicleData(
      speedXMps: (inVehicleData['speedXMps'] ?? 0.0).toDouble(),
      batteryGaugePercent: (inVehicleData['batteryGaugePercent'] ?? 0.0).toDouble(),
      turnSignal: (inVehicleData['turnSignal'] ?? 0) as int,
      brakePedal: inVehicleData['brakePedal'] ?? false,
      accelerationXMps2: (inVehicleData['accelerationXMps2'] ?? 0.0).toDouble(),
      operationModeAuto: operationStatusData['operationMode'] == 'DRIVE_AUTO',
      blowerRun: serviceModuleData['blowerRun'] ?? false,
    );
  }

  int get harshDriving {
    if (accelerationXMps2 > 0) return 1; // 급가속
    if (accelerationXMps2 < 0) return -1; // 급감속
    return 0; // 정상
  }
}