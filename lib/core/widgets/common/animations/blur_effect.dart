import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
@immutable
class CustomBlurEffect extends Effect<Offset> {
  static const Offset neutralValue = Offset(neutralBlur, neutralBlur);
  static const Offset defaultValue = Offset(defaultBlur, defaultBlur);
  static const double neutralBlur = 0.0;
  static const double defaultBlur = 64.0;
  static const double minBlur = 0.01;
  const CustomBlurEffect({
    super.delay,
    super.duration,
    super.curve,
    Offset? begin,
    Offset? end,
  }) : super(
          begin: begin ?? neutralValue,
          end: end ?? (begin == null ? defaultValue : neutralValue),
        );
  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    Animation<Offset> animation = buildAnimation(controller, entry);
    return getOptimizedBuilder<Offset>(
      animation: animation,
      builder: (_, __) {
        final double sigmaX = _normalizeSigma(animation.value.dx);
        final double sigmaY = _normalizeSigma(animation.value.dy);
        bool enabled = sigmaX > minBlur || sigmaY > minBlur;
        return ImageFiltered(
          enabled: enabled,
          imageFilter: ImageFilter.blur(
            sigmaX: sigmaX,
            sigmaY: sigmaY,
            tileMode: TileMode.decal,
          ),
          child: child,
        );
      },
    );
  }
  double _normalizeSigma(double sigma) {
    return sigma < minBlur ? minBlur : sigma;
  }
}
extension CustomBlurEffectExtensions<T extends AnimateManager<T>> on T {
  T customBlur({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    Offset? begin,
    Offset? end,
  }) =>
      addEffect(CustomBlurEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: begin,
        end: end,
      ));
}