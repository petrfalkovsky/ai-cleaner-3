import 'dart:async';
import 'package:ai_cleaner_2/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'dart:math' as math;
import '../bloc/media_cleaner_bloc.dart';

class ScanButton extends StatefulWidget {
  const ScanButton({super.key});

  @override
  State<ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<ScanButton> with SingleTickerProviderStateMixin {
  bool _isStarting = false;
  double _startProgress = 0.0;
  Timer? _progressTimer;
  late AnimationController _dropController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _dropController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _dropController, curve: Curves.easeInBack));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _dropController, curve: const Interval(0.5, 1.0)));
  }

  void _startScan() {
    HapticFeedback.mediumImpact();

    setState(() {
      _isStarting = true;
      _startProgress = 0.0;
    });

    // Запускаем анимацию капли
    _dropController.forward();

    // Симулируем небольшую задержку с прогресс-баром
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        // Ускоряющийся прогресс-бар для имитации подготовки
        _startProgress += 0.05 * (1.0 - _startProgress);

        if (_startProgress >= 0.95) {
          _progressTimer?.cancel();
          _isStarting = false;
          // Запускаем реальное сканирование
          context.read<MediaCleanerBloc>().add(ScanForProblematicFiles());
        }
      });
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _dropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isStarting
        ? AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _startProgress > 0.5 ? 1.0 : 0.0,
            child: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _startProgress,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(CupertinoColors.activeBlue),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    Locales.current.preparing_for_scan,
                    style: TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                ],
              ),
            ),
          )
        : AnimatedBuilder(
                animation: _dropController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: GestureDetector(
                        onTap: _startScan,
                        child: LiquidGlass(
                          settings: LiquidGlassSettings(
                            blur: 5,
                            ambientStrength: 1.0,
                            lightAngle: 0.25 * math.pi,
                            glassColor: Colors.white.withOpacity(0.3),
                            thickness: 25,
                          ),
                          shape: LiquidRoundedSuperellipse(borderRadius: const Radius.circular(25)),
                          glassContainsChild: false,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              spacing: 4,
                              children: [
                                Icon(CupertinoIcons.sparkles, color: Colors.white, size: 24),
                                Text(
                                  Locales.current.start_scan,
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
              .animate()
              .fadeIn(duration: 350.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              );
  }
}
