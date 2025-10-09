// lib/presentation/widgets/dashboard/vehicle_status_section.dart

import 'package:flutter/material.dart';
import '../../../core/config/app_constants.dart';
import '../ui/turn_signal_widget.dart';
import '../ui/status_button.dart';

/// 차량 상태 통합 섹션
/// 방향 지시등과 각종 상태 표시를 하나의 섹션으로 통합
class VehicleStatusSection extends StatelessWidget {
  /// 방향 지시등 상태
  final int turnSignal;

  /// 깜빡임 애니메이션
  final Animation<double> blinkAnimation;

  /// 자율주행 모드 상태
  final bool isAutoDrive;

  /// 브레이크 작동 상태
  final bool isBraking;

  /// 브러시 작동 상태
  final bool isBrushOn;

  /// 급가속/급정거 상태
  final int harshDriving;

  const VehicleStatusSection({
    super.key,
    required this.turnSignal,
    required this.blinkAnimation,
    required this.isAutoDrive,
    required this.isBraking,
    required this.isBrushOn,
    required this.harshDriving,
  });

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.backgroundSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Text(
                '차량 상태 데이터 정보',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  '방향지시등',
                  'inVehicleData.turnSignal',
                  'Off: 0, Right: 1, Left: 2, 비상등: 3',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  '자율주행',
                  'operationStatusData.operationMode',
                  'DRIVE_AUTO일 때만 ON',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  '브레이크',
                  'inVehicleData.brakePedal',
                  '',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  '브러시',
                  'serviceModuleData.blowerRun',
                  '',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  '급가속/급정거',
                  'invehicleData.accelerationXMps2',
                  '양수: 급가속, 음수: 급정거',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '확인',
                style: TextStyle(color: Colors.amber),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String dataPath, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dataPath,
          style: TextStyle(
            color: Colors.white54,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // 방향 지시등 부분
              TurnSignalWidget(
                turnSignal: turnSignal,
                animation: blinkAnimation,
              ),

              const SizedBox(height: 16),

              // 구분선
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 상태 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 자율주행 상태
                  StatusButton(
                    icon: Icons.directions_car,
                    label: '자율주행',
                    isOn: isAutoDrive,
                    onColor: Colors.blue,
                  ),
                  // 브레이크 상태
                  StatusButton(
                    icon: Icons.local_parking,
                    label: '브레이크',
                    isOn: isBraking,
                    onColor: Colors.green[600]!,
                  ),
                  // 브러시 상태
                  StatusButton(
                    icon: Icons.cleaning_services,
                    label: '브러쉬',
                    isOn: isBrushOn,
                    onColor: Colors.pink[600]!,
                  ),
                  // 급가속/급정거 상태
                  HarshDrivingButton(
                    harshDriving: harshDriving,
                  ),
                ],
              ),
            ],
          ),
          // 정보 아이콘 (우측 상단)
          Positioned(
            top: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showInfoDialog(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white38,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}