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
              Icon(Icons.info_outline, color: Colors.cyan, size: 24),
              const SizedBox(width: 8),
              const Text(
                '게이지 데이터 정보',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('속도', 'inVehicleData.speedXMps'),
              const SizedBox(height: 12),
              _buildInfoRow('배터리', 'inVehicleData.batteryGaugePercent'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '확인',
                style: TextStyle(color: Colors.cyan),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String dataPath) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            dataPath,
            style: TextStyle(
              color: Colors.white54,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: GaugeWidget(
                  label: 'SPEED',
                  value: speedKmh.toStringAsFixed(0),
                  unit: 'km/h',
                  percentage: (speedKmh / AppConstants.speedMaxKmh).clamp(0.0, 1.0),
                  color: Colors.cyan,
                  icon: Icons.speed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GaugeWidget(
                  label: 'BATTERY',
                  value: batteryPercent.toStringAsFixed(0),
                  unit: '%',
                  percentage: batteryPercent / 100,
                  color: Colors.green,
                  icon: Icons.battery_charging_full,
                ),
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