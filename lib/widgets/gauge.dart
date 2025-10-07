import 'package:flutter/material.dart';
import 'dart:math' as math;

class GaugeWidget extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double percentage;
  final Color color;
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
          CustomPaint(
            size: const Size(140, 140),
            painter: GaugePainter(
              percentage: percentage,
              color: color,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  GaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius - 10, backgroundPaint);

    for (int i = 0; i < 40; i++) {
      final angle = (-math.pi * 0.75) + (math.pi * 1.5 * i / 40);
      final x1 = center.dx + (radius - 20) * math.cos(angle);
      final y1 = center.dy + (radius - 20) * math.sin(angle);
      final x2 = center.dx + (radius - 12) * math.cos(angle);
      final y2 = center.dy + (radius - 12) * math.sin(angle);

      final tickPaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..strokeWidth = 1.5;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = math.pi * 1.5 * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi * 0.75,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(GaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}