import 'package:flutter/material.dart';
import '../../../core/config/app_constants.dart';
import '../ui/status_button.dart';

/// 대시보드의 상태 표시 섹션
/// 자율주행, 브레이크, 브러시, 급가속/급정거 상태 표시
class StatusIndicatorsSection extends StatelessWidget {
  /// 자율주행 모드 상태
  final bool isAutoDrive;

  /// 브레이크 작동 상태
  final bool isBraking;

  /// 브러시 작동 상태
  final bool isBrushOn;

  /// 급가속/급정거 상태
  final int harshDriving;

  const StatusIndicatorsSection({
    super.key,
    required this.isAutoDrive,
    required this.isBraking,
    required this.isBrushOn,
    required this.harshDriving,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
      child: Row(
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
            onColor: Colors.grey[600]!,
          ),
          // 브러시 상태
          StatusButton(
            icon: Icons.cleaning_services,
            label: '브러쉬',
            isOn: isBrushOn,
            onColor: Colors.grey[600]!,
          ),
          // 급가속/급정거 상태
          HarshDrivingButton(
            harshDriving: harshDriving,
          ),
        ],
      ),
    );
  }
}