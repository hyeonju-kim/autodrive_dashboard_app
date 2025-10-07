import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 원형 게이지 위젯
/// 속도, 배터리 등의 수치를 시각적으로 표현
class GaugeWidget extends StatelessWidget {
  /// 게이지 상단에 표시될 라벨 (예: SPEED, BATTERY)
  final String label;

  /// 중앙에 표시될 현재 값
  final String value;

  /// 값의 단위 (예: KM/H, %)
  final String unit;

  /// 0.0 ~ 1.0 사이의 백분율 값
  final double percentage;

  /// 게이지의 주 색상
  final Color color;

  /// 중앙에 표시될 아이콘
  final IconData icon;

  const GaugeWidget({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.percentage,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 게이지 원형 그래프 그리기
          CustomPaint(
            size: const Size(140, 140),
            painter: GaugePainter(
              percentage: percentage,
              color: color,
            ),
          ),
          // 중앙 텍스트 영역
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 현재 값 표시
              Text(
                value,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'monospace', // 숫자가 일정한 너비를 갖도록
                ),
              ),
              // 단위 표시
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              // 라벨 표시
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                  letterSpacing: 1.2, // 글자 간격으로 가독성 향상
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 게이지의 원형 그래프를 그리는 CustomPainter
class GaugePainter extends CustomPainter {
  /// 진행률 (0.0 ~ 1.0)
  final double percentage;

  /// 게이지 색상
  final Color color;

  GaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // 중심점과 반지름 계산
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 배경 원 그리기 (회색 테두리)
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius - 10, backgroundPaint);

    // 눈금 그리기 (40개의 작은 선)
    for (int i = 0; i < 40; i++) {
      // 시작 각도: -135도 (좌하단)
      // 전체 각도: 270도 (3/4 원)
      final angle = (-math.pi * 0.75) + (math.pi * 1.5 * i / 40);

      // 눈금 시작점과 끝점 계산
      final x1 = center.dx + (radius - 20) * math.cos(angle);
      final y1 = center.dy + (radius - 20) * math.sin(angle);
      final x2 = center.dx + (radius - 12) * math.cos(angle);
      final y2 = center.dy + (radius - 12) * math.sin(angle);

      final tickPaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..strokeWidth = 1.5;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }

    // 진행률 표시 원호 그리기
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round; // 둥근 끝처리

    // 진행률에 따른 호의 각도 계산
    final sweepAngle = math.pi * 1.5 * percentage;

    // 호 그리기 (시작: -135도, 스윕: 진행률에 따라)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi * 0.75, // 시작 각도
      sweepAngle,      // 스윕 각도
      false,           // 중심과 연결하지 않음
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(GaugePainter oldDelegate) {
    // percentage가 변경되면 다시 그리기
    return oldDelegate.percentage != percentage;
  }
}