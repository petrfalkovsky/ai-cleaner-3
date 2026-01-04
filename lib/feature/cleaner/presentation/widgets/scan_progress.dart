import 'package:flutter/material.dart';
import '../../../../core/extensions/core_extensions.dart';

class ScanProgressIndicator extends StatelessWidget {
  final double progress;
  final String message;

  const ScanProgressIndicator({super.key, required this.progress, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Индикатор прогресса
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),

        const SizedBox(height: 16),

        // Сообщение о текущем этапе сканирования
        Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
        ),

        // Процент прогресса
        Text(
          '${(progress * 100).toInt()}%',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ).p(all: 24);
  }
}
