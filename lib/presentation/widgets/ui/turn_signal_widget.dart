import 'package:flutter/material.dart';

/// 방향 지시등 표시 위젯
/// 좌/우 방향등과 비상등 상태를 애니메이션과 함께 표시
class TurnSignalWidget extends StatelessWidget {
  /// 방향 지시등 상태 (0: 꺼짐, 1: 우측, 2: 좌측, 3: 비상)
  final int turnSignal;

  /// 깜빡임 애니메이션
  final Animation<double> animation;

  const TurnSignalWidget({
    super.key,
    required this.turnSignal,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // 깜빡임 효과를 위한 투명도 계산
        double opacity = 1.0;
        if (turnSignal != 0) {
          // 0.3 ~ 1.0 사이에서 깜빡임
          opacity = 0.3 + (animation.value * 0.7);
        }

        // 각 요소의 색상 초기화
        Color leftColor = Colors.grey.withOpacity(0.3);
        Color rightColor = Colors.grey.withOpacity(0.3);
        Color emergencyColor = Colors.grey.withOpacity(0.3);

        // 텍스트 라벨
        String leftText = '좌방향등';
        String rightText = '우방향등';
        Color leftTextColor = Colors.grey.withOpacity(0.5);
        Color rightTextColor = Colors.grey.withOpacity(0.5);

        // 상태에 따른 색상 설정
        if (turnSignal == 1) {
          // 우측 방향등
          rightColor = Colors.amber.withOpacity(opacity);
          rightTextColor = Colors.amber.withOpacity(opacity);
        } else if (turnSignal == 2) {
          // 좌측 방향등
          leftColor = Colors.amber.withOpacity(opacity);
          leftTextColor = Colors.amber.withOpacity(opacity);
        } else if (turnSignal == 3) {
          // 비상등 (중앙 경고등)
          emergencyColor = Colors.red.withOpacity(opacity);
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 좌측 방향등
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 36,
                    color: leftColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    leftText,
                    style: TextStyle(
                      fontSize: 13,
                      color: leftTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // 중앙 비상등
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: emergencyColor,
                shape: BoxShape.circle,
                // 비상등 활성화 시 빛나는 효과
                boxShadow: turnSignal == 3
                    ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(opacity * 0.5),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ]
                    : [],
              ),
              child: Icon(
                Icons.warning,
                size: 28,
                color: turnSignal == 3 ? Colors.white : Colors.grey[700],
              ),
            ),
            // 우측 방향등
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 36,
                    color: rightColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rightText,
                    style: TextStyle(
                      fontSize: 13,
                      color: rightTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}