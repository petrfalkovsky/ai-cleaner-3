import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS-style loading overlay - круглый прогресс индикатор с полупрозрачным фоном
class IOSLoadingOverlay {
  static OverlayEntry? _currentOverlay;

  /// Показать loading overlay
  static void show(BuildContext context) {
    hide(); // Убираем предыдущий если есть

    _currentOverlay = OverlayEntry(
      builder: (context) => _LoadingOverlayWidget(),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  /// Скрыть loading overlay
  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// Показать loading на время выполнения Future
  static Future<T> during<T>(
    BuildContext context,
    Future<T> Function() future, {
    Duration minDuration = const Duration(milliseconds: 500),
  }) async {
    show(context);

    try {
      // Запускаем future и минимальную задержку параллельно
      final results = await Future.wait([
        future(),
        Future.delayed(minDuration),
      ]);

      return results[0] as T;
    } finally {
      hide();
    }
  }
}

class _LoadingOverlayWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CupertinoActivityIndicator(
              radius: 16,
              color: CupertinoColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
