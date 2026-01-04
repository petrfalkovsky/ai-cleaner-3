import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final List<CircleData> _circles = [];

  @override
  void initState() {
    super.initState();
    _initializeCircles();
  }

  void _initializeCircles() {
    _controllers = [];
    _animations = [];

    // Создаем 12 кругов с разными параметрами
    final circlesConfig = [
      CircleData(
        radius: 80.0,
        centerX: 0.1,
        centerY: 0.15,
        orbitRadius: 60.0,
        color: const Color(0xFF8B5CF6).withOpacity(0.15), // Purple
      ),
      CircleData(
        radius: 120.0,
        centerX: 0.85,
        centerY: 0.1,
        orbitRadius: 80.0,
        color: const Color(0xFFEC4899).withOpacity(0.12), // Pink
      ),
      CircleData(
        radius: 60.0,
        centerX: 0.3,
        centerY: 0.3,
        orbitRadius: 50.0,
        color: const Color(0xFFF59E0B).withOpacity(0.1), // Orange
      ),
      CircleData(
        radius: 100.0,
        centerX: 0.7,
        centerY: 0.4,
        orbitRadius: 70.0,
        color: const Color(0xFF8B5CF6).withOpacity(0.13), // Purple
      ),
      CircleData(
        radius: 90.0,
        centerX: 0.15,
        centerY: 0.6,
        orbitRadius: 65.0,
        color: const Color(0xFFEC4899).withOpacity(0.14), // Pink
      ),
      CircleData(
        radius: 70.0,
        centerX: 0.6,
        centerY: 0.7,
        orbitRadius: 55.0,
        color: const Color(0xFFEF4444).withOpacity(0.11), // Red
      ),
      CircleData(
        radius: 110.0,
        centerX: 0.9,
        centerY: 0.65,
        orbitRadius: 75.0,
        color: const Color(0xFF8B5CF6).withOpacity(0.12), // Purple
      ),
      CircleData(
        radius: 85.0,
        centerX: 0.4,
        centerY: 0.85,
        orbitRadius: 60.0,
        color: const Color(0xFFEC4899).withOpacity(0.13), // Pink
      ),
      CircleData(
        radius: 95.0,
        centerX: 0.2,
        centerY: 0.45,
        orbitRadius: 68.0,
        color: const Color(0xFFF97316).withOpacity(0.1), // Orange/Red
      ),
      CircleData(
        radius: 75.0,
        centerX: 0.75,
        centerY: 0.25,
        orbitRadius: 58.0,
        color: const Color(0xFFEC4899).withOpacity(0.11), // Pink
      ),
      CircleData(
        radius: 105.0,
        centerX: 0.5,
        centerY: 0.55,
        orbitRadius: 72.0,
        color: const Color(0xFF8B5CF6).withOpacity(0.14), // Purple
      ),
      CircleData(
        radius: 65.0,
        centerX: 0.12,
        centerY: 0.9,
        orbitRadius: 52.0,
        color: const Color(0xFFEF4444).withOpacity(0.12), // Red
      ),
    ];

    _circles.addAll(circlesConfig);

    for (int i = 0; i < _circles.length; i++) {
      final controller = AnimationController(
        duration: Duration(seconds: 8 + i * 4),
        vsync: this,
      );
      final animation = Tween<double>(
        begin: 0,
        end: 2 * math.pi,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.linear,
      ));
      _controllers.add(controller);
      _animations.add(animation);
      controller.repeat();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(_animations),
      builder: (context, child) {
        return CustomPaint(
          painter: AnimatedCirclesPainter(_animations, _circles),
          size: Size.infinite,
        );
      },
    );
  }
}

class CircleData {
  final double radius;
  final double centerX;
  final double centerY;
  final double orbitRadius;
  final Color color;

  CircleData({
    required this.radius,
    required this.centerX,
    required this.centerY,
    required this.orbitRadius,
    required this.color,
  });
}

class AnimatedCirclesPainter extends CustomPainter {
  final List<Animation<double>> animations;
  final List<CircleData> circles;

  AnimatedCirclesPainter(this.animations, this.circles);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < circles.length; i++) {
      final circle = circles[i];
      final animation = animations[i];

      final paint = Paint()
        ..color = circle.color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);

      final centerX = size.width * circle.centerX;
      final centerY = size.height * circle.centerY;
      final x = centerX + circle.orbitRadius * math.cos(animation.value);
      final y = centerY + circle.orbitRadius * math.sin(animation.value);

      canvas.drawCircle(Offset(x, y), circle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
