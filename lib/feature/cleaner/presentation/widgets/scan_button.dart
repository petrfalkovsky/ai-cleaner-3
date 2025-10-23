import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/media_cleaner_bloc.dart';
import '../../../../core/theme/button.dart';
import 'scan_progress.dart';

class ScanButton extends StatefulWidget {
  const ScanButton({Key? key}) : super(key: key);

  @override
  State<ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<ScanButton> {
  bool _isStarting = false;
  double _startProgress = 0.0;
  Timer? _progressTimer;

  void _startScan() {
    HapticFeedback.mediumImpact();

    setState(() {
      _isStarting = true;
      _startProgress = 0.0;
    });

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isStarting
        ? SizedBox(
            width: 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: _startProgress,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                const Text('Подготовка к сканированию...', style: TextStyle(fontSize: 14)),
              ],
            ),
          )
        : StyledButton.filled(
            title: "Начать сканирование",
            onPressed: _startScan,
            fullWidth: true,
            backgroundColor: Colors.blue,
            fontColor: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ).animate().fadeIn(duration: 350.ms);
  }
}
