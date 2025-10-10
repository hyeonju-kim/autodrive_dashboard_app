import 'package:flutter/material.dart';
import '../../../core/config/app_constants.dart';
import '../ui/gauge_widget.dart';

/// 대시보드의 게이지 섹션
/// 속도와 배터리 게이지를 포함하는 컨테이너
class GaugeSection extends StatefulWidget {
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
  State<GaugeSection> createState() => _GaugeSectionState();
}

class _GaugeSectionState extends State<GaugeSection> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _toggleTooltip() {
    if (_overlayEntry != null) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _removeOverlay,
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: Stack(
              children: [
                CompositedTransformFollower(
                  link: _layerLink,
                  targetAnchor: Alignment.topRight,
                  followerAnchor: Alignment.topRight,
                  offset: const Offset(-40, 20),
                  child: GestureDetector(
                    onTap: () {}, // 툴팁 클릭 시 닫히지 않게
                    child: _buildInfoTooltip(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTooltip() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            '- 속도',
            'inVehicleData.speedXMps',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            '- 배터리',
            'inVehicleData.batteryGaugePercent',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String dataPath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          dataPath,
          style: TextStyle(
            color: Colors.white54,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
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
                  value: widget.speedKmh.toStringAsFixed(0),
                  unit: 'km/h',
                  percentage: (widget.speedKmh / AppConstants.speedMaxKmh).clamp(0.0, 1.0),
                  color: Colors.cyan,
                  icon: Icons.speed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GaugeWidget(
                  label: 'BATTERY',
                  value: widget.batteryPercent.toStringAsFixed(0),
                  unit: '%',
                  percentage: widget.batteryPercent / 100,
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
            child: CompositedTransformTarget(
              link: _layerLink,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque, // 투명 영역도 클릭 가능하게
                onTap: _toggleTooltip,
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