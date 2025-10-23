import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// Глобальный менеджер для хранения текущих значений счетчиков
class CountersManager {
  static final CountersManager _instance = CountersManager._internal();
  factory CountersManager() => _instance;
  CountersManager._internal();

  final Map<String, int> _counters = {};

  int getValue(String key, {int defaultValue = 0}) {
    return _counters[key] ?? defaultValue;
  }

  void setValue(String key, int value) {
    _counters[key] = value;
  }
}

final countersManager = CountersManager();

class CategoryAnimatedCounter extends StatefulWidget {
  final int targetValue;
  final String counterKey;
  final TextStyle? style;
  final Duration animationDuration;
  final Curve curve;
  final String suffix;
  final int minIncrement;
  final int maxIncrement;

  const CategoryAnimatedCounter({
    super.key,
    required this.targetValue,
    required this.counterKey,
    this.style,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeOutCubic,
    this.suffix = '',
    this.minIncrement = 1,
    this.maxIncrement = 5,
  });

  @override
  State<CategoryAnimatedCounter> createState() => _CategoryAnimatedCounterState();
}

class _CategoryAnimatedCounterState extends State<CategoryAnimatedCounter>
    with AutomaticKeepAliveClientMixin {
  late int _displayValue;
  late int _previousTargetValue;
  Timer? _timer;
  final Random _random = Random();

  @override
  bool get wantKeepAlive => true; // Сохраняем состояние виджета

  @override
  void initState() {
    super.initState();

    // Получаем сохраненное значение из менеджера
    _displayValue = countersManager.getValue(
      widget.counterKey,
      defaultValue: widget.targetValue > 0 ? widget.targetValue ~/ 3 : 0,
    );

    _previousTargetValue = widget.targetValue;

    // Запускаем анимацию, если текущее значение не равно целевому
    if (_displayValue != widget.targetValue) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(CategoryAnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Проверяем, изменилась ли целевая цифра
    if (widget.targetValue != _previousTargetValue) {
      _previousTargetValue = widget.targetValue;
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    _timer?.cancel();

    // Проверяем, нужна ли анимация
    if (_displayValue == widget.targetValue) {
      return;
    }

    // Если значение уменьшилось, просто устанавливаем новое значение без анимации
    if (widget.targetValue < _displayValue) {
      setState(() {
        _displayValue = widget.targetValue;
        countersManager.setValue(widget.counterKey, _displayValue);
      });
      return;
    }

    // Расчёт параметров анимации
    final int difference = widget.targetValue - _displayValue;

    // Ограничиваем количество шагов для более плавной анимации
    final int steps = difference > 100 ? 15 + (difference ~/ 100) : difference.clamp(5, 20);

    final tickDuration = Duration(
      milliseconds: (widget.animationDuration.inMilliseconds / steps).round(),
    );

    _timer = Timer.periodic(tickDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_displayValue >= widget.targetValue) {
        timer.cancel();
        setState(() {
          _displayValue = widget.targetValue;
          countersManager.setValue(widget.counterKey, _displayValue);
        });
        return;
      }

      // Вычисляем случайный прирост
      final int remainingDifference = widget.targetValue - _displayValue;
      final int maxPossibleIncrement = min(remainingDifference, widget.maxIncrement);

      // Для очень маленьких оставшихся значений используем минимальное приращение
      final int increment = remainingDifference <= widget.minIncrement
          ? remainingDifference
          : widget.minIncrement +
                _random.nextInt(max(1, maxPossibleIncrement - widget.minIncrement + 1));

      setState(() {
        _displayValue += increment;
        countersManager.setValue(widget.counterKey, _displayValue);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Необходимо для AutomaticKeepAliveClientMixin

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: _displayValue.toString(),
            style:
                widget.style ??
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          if (widget.suffix.isNotEmpty)
            TextSpan(
              text: widget.suffix,
              style:
                  widget.style?.copyWith(fontWeight: FontWeight.normal) ??
                  TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
            ),
        ],
      ),
    );
  }
}
