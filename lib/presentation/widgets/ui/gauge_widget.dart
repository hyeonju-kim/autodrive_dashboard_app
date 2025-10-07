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
      width: 120,  // 적절한 크기로 조정
      height: 120, // 적절한 크기로 조정
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 게이지 원형 그래프 그리기
          CustomPaint(
            size: const Size(110, 110), // 적절한 크기로 조정
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
                  fontSize: 32, // 36에서 약간 축소
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'monospace',
                ),
              ),
              // 단위 표시
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 13, // 14에서 약간 축소
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 2),
              // 라벨 표시
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10, // 11에서 약간 축소
                  color: Colors.white54,
                  letterSpacing: 1.0,
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

    // 게이지가 차지할 전체 각도 (거의 전체 원, 작은 갭 남김)
    const double totalAngle = math.pi * 2 * 0.85; // 전체 원의 85% (306도)
    // 시작 각도 (하단 약간 오른쪽)
    const double startAngle = math.pi * 0.575; // 약 103.5도

    // 배경 원 그리기 (회색 테두리)
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8; // 적절한 두께

    // 배경 호 그리기
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      startAngle,
      totalAngle,
      false,
      backgroundPaint,
    );

    // 눈금 그리기 (40개)
    const int tickCount = 40;
    for (int i = 0; i <= tickCount; i++) {
      final angle = startAngle + (totalAngle * i / tickCount);

      // 주요 눈금(5개마다)은 길게, 나머지는 짧게
      final isMainTick = i % 5 == 0;
      final tickLength = isMainTick ? 8.0 : 5.0;

      // 눈금 시작점과 끝점 계산
      final x1 = center.dx + (radius - 15) * math.cos(angle);
      final y1 = center.dy + (radius - 15) * math.sin(angle);
      final x2 = center.dx + (radius - 15 + tickLength) * math.cos(angle);
      final y2 = center.dy + (radius - 15 + tickLength) * math.sin(angle);

      final tickPaint = Paint()
        ..color = Colors.white.withOpacity(isMainTick ? 0.3 : 0.2)
        ..strokeWidth = isMainTick ? 1.5 : 1.0;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }

    // 진행률 표시 원호 그리기
    if (percentage > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      // 진행률에 따른 호의 각도 계산
      final sweepAngle = totalAngle * percentage;

      // 호 그리기
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 8),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );

      // 시작점에 원형 캡 추가
      final startX = center.dx + (radius - 8) * math.cos(startAngle);
      final startY = center.dy + (radius - 8) * math.sin(startAngle);
      canvas.drawCircle(
        Offset(startX, startY),
        4,
        Paint()..color = color,
      );

      // 끝점에 원형 캡 추가
      final endAngle = startAngle + sweepAngle;
      final endX = center.dx + (radius - 8) * math.cos(endAngle);
      final endY = center.dy + (radius - 8) * math.sin(endAngle);
      canvas.drawCircle(
        Offset(endX, endY),
        4,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(GaugePainter oldDelegate) {
    // percentage가 변경되면 다시 그리기
    return oldDelegate.percentage != percentage;
  }
}