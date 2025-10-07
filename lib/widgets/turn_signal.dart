import 'package:flutter/material.dart';

class TurnSignalWidget extends StatelessWidget {
  final int turnSignal;
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
        double opacity = 1.0;

        if (turnSignal != 0) {
          opacity = 0.3 + (animation.value * 0.7);
        }

        Color leftColor = Colors.grey.withOpacity(0.3);
        Color rightColor = Colors.grey.withOpacity(0.3);
        Color emergencyColor = Colors.grey.withOpacity(0.3);

        String leftText = '좌방향등';
        String rightText = '우방향등';
        Color leftTextColor = Colors.grey.withOpacity(0.5);
        Color rightTextColor = Colors.grey.withOpacity(0.5);

        if (turnSignal == 1) {
          rightColor = Colors.amber.withOpacity(opacity);
          rightTextColor = Colors.amber.withOpacity(opacity);
        } else if (turnSignal == 2) {
          leftColor = Colors.amber.withOpacity(opacity);
          leftTextColor = Colors.amber.withOpacity(opacity);
        } else if (turnSignal == 3) {
          emergencyColor = Colors.red.withOpacity(opacity);
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0d1419),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
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
                        fontSize: 10,
                        color: leftTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: emergencyColor,
                  shape: BoxShape.circle,
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
                        fontSize: 10,
                        color: rightTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}