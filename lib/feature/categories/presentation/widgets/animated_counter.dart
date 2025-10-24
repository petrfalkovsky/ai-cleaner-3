import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _displayValue = countersManager.getValue(
      widget.counterKey,
      defaultValue: widget.targetValue > 0 ? widget.targetValue ~/ 3 : 0,
    );
    _previousTargetValue = widget.targetValue;
    if (_displayValue != widget.targetValue) {
      _startAnimation();
    }
  }
  @override
  void didUpdateWidget(CategoryAnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    if (_displayValue == widget.targetValue) {
      return;
    }
    if (widget.targetValue < _displayValue) {
      setState(() {
        _displayValue = widget.targetValue;
        countersManager.setValue(widget.counterKey, _displayValue);
      });
      return;
    }
    final int difference = widget.targetValue - _displayValue;
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
      final int remainingDifference = widget.targetValue - _displayValue;
      final int maxPossibleIncrement = min(remainingDifference, widget.maxIncrement);
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
    super.build(context);
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