import 'package:flutter/material.dart';
import '../ui/turn_signal_widget.dart';

/// 대시보드의 방향 지시등 섹션
/// 애니메이션과 함께 방향등 상태를 표시
class TurnSignalSection extends StatelessWidget {
  /// 방향 지시등 상태
  final int turnSignal;

  /// 깜빡임 애니메이션
  final Animation<double> blinkAnimation;

  const TurnSignalSection({
    super.key,
    required this.turnSignal,
    required this.blinkAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return TurnSignalWidget(
      turnSignal: turnSignal,
      animation: blinkAnimation,
    );
  }
}