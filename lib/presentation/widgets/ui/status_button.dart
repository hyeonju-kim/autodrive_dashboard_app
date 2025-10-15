// lib/presentation/widgets/ui/status_button.dart

import 'package:flutter/material.dart';

/// 상태 표시 버튼 위젯
/// 자율주행, 브레이크 등의 상태를 아이콘과 함께 표시
class StatusButton extends StatelessWidget {
  /// 표시할 아이콘
  final IconData icon;

  /// 버튼 하단에 표시될 라벨
  final String label;

  /// 활성화 상태
  final bool isOn;

  /// 활성화 시 색상
  final Color onColor;

  const StatusButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isOn,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 아이콘만 표시 (박스 제거)
        Icon(
          icon,
          color: isOn ? onColor : Colors.grey[600],
          size: 28,
        ),
        const SizedBox(height: 4),
        // 라벨 텍스트
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isOn ? Colors.white70 : Colors.white38,
          ),
        ),
      ],
    );
  }
}

/// 급가속/급정거 상태 표시 버튼
/// 특수한 동작으로 인해 별도 위젯으로 구현
class HarshDrivingButton extends StatelessWidget {
  /// 급가속/급정거 상태 (-1: 급정거, 0: 정상, 1: 급가속)
  final int harshDriving;

  const HarshDrivingButton({
    super.key,
    required this.harshDriving,
  });

  @override
  Widget build(BuildContext context) {
    // 상태 확인
    bool isAccel = harshDriving > 0;
    bool isDecel = harshDriving < 0;

    // 상태에 따른 색상과 텍스트 설정
    Color alertColor;
    String statusText;

    if (isAccel) {
      alertColor = Colors.orange;
      statusText = '급가속';
    } else if (isDecel) {
      alertColor = Colors.red;
      statusText = '급정거';
    } else {
      alertColor = Colors.grey[600]!;
      statusText = '';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 아이콘 대신 상태 텍스트를 배지 스타일로 표시
        Container(
          height: 28,
          child: Center(
            child: statusText.isNotEmpty
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: alertColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: alertColor.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: alertColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            )
                : Icon(
              Icons.speed,
              color: Colors.grey[600],
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // 라벨은 항상 "급가속/급정거"로 고정
        Text(
          '급가속/급정거',
          style: TextStyle(
            fontSize: 13,
            color: (isAccel || isDecel) ? Colors.white70 : Colors.white38,
          ),
        ),
      ],
    );
  }
}