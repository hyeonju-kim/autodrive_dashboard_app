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
      child: Column(
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
        ],
      ),
    );
  }
}