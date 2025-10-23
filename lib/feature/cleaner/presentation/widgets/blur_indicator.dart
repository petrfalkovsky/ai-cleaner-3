import 'package:flutter/material.dart';

class BlurIndicator extends StatelessWidget {
  final double blurScore; // 0.0 - 1.0, где 1.0 - максимально размыто
  final double size;

  const BlurIndicator({Key? key, required this.blurScore, this.size = 24.0}) : super(key: key);

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
      width: size,
      height: size,
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle),
      child: Center(
        child: Icon(Icons.blur_on, color: color, size: size * 0.6),
      ),
    );
  }
}
