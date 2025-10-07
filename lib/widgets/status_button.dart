import 'package:flutter/material.dart';

class StatusButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isOn;
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
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
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

class HarshDrivingButton extends StatelessWidget {
  final int harshDriving;

  const HarshDrivingButton({
    super.key,
    required this.harshDriving,
  });

  @override
  Widget build(BuildContext context) {
    bool isAccel = harshDriving > 0;
    bool isDecel = harshDriving < 0;

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
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: alertColor,
              shape: BoxShape.circle,
            ),
            child: alertText.isNotEmpty
                ? Center(
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
              Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
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