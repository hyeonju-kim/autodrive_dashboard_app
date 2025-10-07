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
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1a2332),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 아이콘 컨테이너
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              // 상태에 따른 색상 변경
              color: isOn ? onColor : Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          // 라벨 텍스트
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white70,
            ),
          ),
        ],
      ),
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
    String alertText;

    if (isAccel) {
      alertColor = Colors.orange;
      alertText = '급가속';
    } else if (isDecel) {
      alertColor = Colors.red;
      alertText = '급정거';
    } else {
      alertColor = Colors.grey[800]!;
      alertText = '';
    }

    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1a2332),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상태 표시 원
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: alertColor,
              shape: BoxShape.circle,
            ),
            child: alertText.isNotEmpty
                ? Center(
              // 급가속/급정거 텍스트 표시
              child: Text(
                alertText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
                : Icon(
              // 정상 상태일 때 체크 아이콘
              Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          // 라벨
          Text(
            '급가속/급정거',
            style: TextStyle(
              fontSize: 8,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}