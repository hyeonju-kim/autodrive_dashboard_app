// lib/presentation/widgets/ui/gauge_widget.dart

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
      width: 90,
      height: 100, // 높이 축소
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 라벨 + 단위 (상단)
          Text(
            '$label ($unit)',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white54,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // 게이지와 값
          Stack(
            alignment: Alignment.center,
            children: [
              // 게이지 원형 그래프
              CustomPaint(
                size: const Size(80, 80),
                painter: GaugePainter(
                  percentage: percentage,
                  color: color,
                ),
              ),
              // 중앙 값만 크게 표시
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'monospace',
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
    const double totalAngle = math.pi * 2 * 0.98; // 전체 원의 98%
    // 시작 각도 (하단 약간 오른쪽)
    const double startAngle = math.pi * 0.525;

    // 배경 원 그리기 (회색 테두리)
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6; // 약간 얇게

    // 배경 호 그리기
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      startAngle,
      totalAngle,
      false,
      backgroundPaint,
    );

    // 눈금 그리기 (30개로 축소)
    const int tickCount = 30;
    for (int i = 0; i <= tickCount; i++) {
      final angle = startAngle + (totalAngle * i / tickCount);

      // 주요 눈금(5개마다)은 길게, 나머지는 짧게
      final isMainTick = i % 5 == 0;
      final tickLength = isMainTick ? 6.0 : 3.0;

      // 눈금 시작점과 끝점 계산
      final x1 = center.dx + (radius - 12) * math.cos(angle);
      final y1 = center.dy + (radius - 12) * math.sin(angle);
      final x2 = center.dx + (radius - 12 + tickLength) * math.cos(angle);
      final y2 = center.dy + (radius - 12 + tickLength) * math.sin(angle);

      final tickPaint = Paint()
        ..color = Colors.white.withOpacity(isMainTick ? 0.25 : 0.15)
        ..strokeWidth = isMainTick ? 1.2 : 0.8;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }

    // 진행률 표시 원호 그리기
    if (percentage > 0) {
      // 진행률에 따른 호의 각도 계산
      final sweepAngle = totalAngle * percentage;

      // 진행률 호 그리기 (그라데이션 제거, 단색으로)
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      // 호 그리기
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 6),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );

      // 끝점에 완전히 채워진 원형 캡 추가
      final endAngle = startAngle + sweepAngle;
      final endX = center.dx + (radius - 6) * math.cos(endAngle);
      final endY = center.dy + (radius - 6) * math.sin(endAngle);

      // 외곽선 없는 채워진 원
      final capPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(endX, endY),
        4,
        capPaint,
      );
    }
  }

  @override
  bool shouldRepaint(GaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}