import 'package:flutter/material.dart';

class BlurIndicator extends StatelessWidget {
  final double blurScore; // 0.0 - 1.0, где 1.0 - максимально размыто
  final double size;

  const BlurIndicator({super.key, required this.blurScore, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    // Определяем цвет от зеленого (четкое) до красного (размытое)
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
