import 'package:flutter/material.dart';
class BlurIndicator extends StatelessWidget {
  final double blurScore;
  final double size;
  const BlurIndicator({Key? key, required this.blurScore, this.size = 24.0}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    Color color;
    if (blurScore < 0.3) {
      color = Colors.green;
    } else if (blurScore < 0.6) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.blur_on, color: color, size: 12),
    );
  }
}