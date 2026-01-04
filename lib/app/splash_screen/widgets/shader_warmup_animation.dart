import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Прогревающая анимация для splash screen
/// Запускает сложные анимации и шейдеры чтобы подготовить GPU
class ShaderWarmupAnimation extends StatefulWidget {
  const ShaderWarmupAnimation({super.key});

  @override
  State<ShaderWarmupAnimation> createState() => _ShaderWarmupAnimationState();
}

class _ShaderWarmupAnimationState extends State<ShaderWarmupAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Основная анимация
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Вращение
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Пульсация
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _rotationController, _pulseController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _WarmupPainter(
            progress: _controller.value,
            rotation: _rotationController.value,
            pulse: _pulseController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _WarmupPainter extends CustomPainter {
  final double progress;
  final double rotation;
  final double pulse;

  _WarmupPainter({
    required this.progress,
    required this.rotation,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.3;

    // Фон с градиентом (как в основном дизайне)
    _drawBackgroundGradient(canvas, size);

    // Вращающиеся круги с градиентами
    _drawRotatingCircles(canvas, center, radius);

    // Пульсирующие частицы
    _drawPulsingParticles(canvas, center, radius);

    // Светящиеся линии
    _drawGlowingLines(canvas, center, radius);

    // Центральный светящийся круг
    _drawCenterGlow(canvas, center);
  }

  void _drawBackgroundGradient(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF0A0E27),
          const Color(0xFF161B39),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawRotatingCircles(Canvas canvas, Offset center, double radius) {
    const circleCount = 5;

    for (int i = 0; i < circleCount; i++) {
      final angle = (rotation * 2 * math.pi) + (i * 2 * math.pi / circleCount);
      final r = radius * (0.5 + i * 0.1);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(const Color(0xFF6366F1), const Color(0xFFFFD700), i / circleCount)!
                .withOpacity(0.4),
            Color.lerp(const Color(0xFF8B5CF6), const Color(0xFFFFA500), i / circleCount)!
                .withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 30))
        ..blendMode = BlendMode.screen;

      canvas.drawCircle(Offset(x, y), 30, paint);
    }
  }

  void _drawPulsingParticles(Canvas canvas, Offset center, double radius) {
    const particleCount = 12;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i * 2 * math.pi / particleCount) + (progress * 2 * math.pi * 0.2);
      final r = radius * (0.8 + pulse * 0.3);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFFFFD700),
          const Color(0xFF6366F1),
          (i / particleCount + progress) % 1.0,
        )!.withOpacity(0.6 + pulse * 0.4)
        ..blendMode = BlendMode.screen;

      canvas.drawCircle(Offset(x, y), 4 + pulse * 3, paint);
    }
  }

  void _drawGlowingLines(Canvas canvas, Offset center, double radius) {
    const lineCount = 8;

    for (int i = 0; i < lineCount; i++) {
      final angle = (rotation * 2 * math.pi * 0.5) + (i * 2 * math.pi / lineCount);

      final startX = center.dx + (radius * 0.3) * math.cos(angle);
      final startY = center.dy + (radius * 0.3) * math.sin(angle);
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.center,
          end: Alignment.topRight,
          colors: [
            const Color(0xFFFFD700).withOpacity(0.3),
            const Color(0xFF6366F1).withOpacity(0.0),
          ],
        ).createShader(Rect.fromPoints(
          Offset(startX, startY),
          Offset(endX, endY),
        ))
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.screen;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  void _drawCenterGlow(Canvas canvas, Offset center) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(const Color(0xFFFFD700), const Color(0xFF6366F1), pulse)!
              .withOpacity(0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: center,
        radius: 40 + pulse * 20,
      ))
      ..blendMode = BlendMode.screen;

    canvas.drawCircle(center, 40 + pulse * 20, paint);
  }

  @override
  bool shouldRepaint(_WarmupPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.rotation != rotation ||
        oldDelegate.pulse != pulse;
  }
}
