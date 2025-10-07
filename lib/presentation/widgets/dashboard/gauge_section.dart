import 'package:flutter/material.dart';
import '../../../core/config/app_constants.dart';
import '../ui/gauge_widget.dart';

/// 대시보드의 게이지 섹션
/// 속도와 배터리 게이지를 포함하는 컨테이너
class GaugeSection extends StatelessWidget {
  /// 현재 속도 (km/h)
  final double speedKmh;

  /// 배터리 잔량 (%)
  final double batteryPercent;

  const GaugeSection({
    super.key,
    required this.speedKmh,
    required this.batteryPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2), // 적절한 패딩
      decoration: BoxDecoration(
        color: AppConstants.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 속도 게이지
          GaugeWidget(
            label: 'SPEED',
            value: speedKmh.toStringAsFixed(0),
            unit: 'km/h',
            percentage: (speedKmh / AppConstants.speedMaxKmh).clamp(0.0, 1.0),
            color: Colors.cyan,
            icon: Icons.speed,
          ),
          // 배터리 게이지
          GaugeWidget(
            label: 'BATTERY',
            value: batteryPercent.toStringAsFixed(0),
            unit: '%',
            percentage: batteryPercent / 100,
            color: Colors.green,
            icon: Icons.battery_charging_full,
          ),
        ],
      ),
    );
  }
}