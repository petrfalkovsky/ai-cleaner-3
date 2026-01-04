import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

/// iOS-подобное уведомление с анимацией сверху
/// Использует spring анимацию и blur эффекты как в iOS
class IOSNotification {
  static OverlayEntry? _currentEntry;
  static bool _isShowing = false;

  /// Показать iOS-подобное уведомление
  ///
  /// [context] - контекст для отображения
  /// [title] - заголовок уведомления
  /// [message] - текст сообщения
  /// [icon] - иконка (опционально)
  /// [duration] - длительность показа (по умолчанию 3 секунды)
  /// [type] - тип уведомления (success, error, info)
  static void show(
    BuildContext context, {
    required String title,
    String? message,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    IOSNotificationType type = IOSNotificationType.info,
  }) {
    // Убираем предыдущее уведомление если есть
    if (_isShowing) {
      hide();
    }

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => _IOSNotificationWidget(
        title: title,
        message: message,
        icon: icon,
        type: type,
        onDismiss: hide,
      ),
    );

    _currentEntry = entry;
    _isShowing = true;
    overlay.insert(entry);

    // Автоматически скрываем через указанное время
    Future.delayed(duration, () {
      if (_isShowing && _currentEntry == entry) {
        hide();
      }
    });
  }

  /// Скрыть текущее уведомление
  static void hide() {
    if (_currentEntry != null && _isShowing) {
      _currentEntry!.remove();
      _currentEntry = null;
      _isShowing = false;
    }
  }

  /// Показать уведомление об успехе
  static void showSuccess(BuildContext context, {required String title, String? message}) {
    show(
      context,
      title: title,
      message: message,
      icon: CupertinoIcons.check_mark_circled_solid,
      type: IOSNotificationType.success,
    );
  }

  /// Показать уведомление об ошибке
  static void showError(BuildContext context, {required String title, String? message}) {
    show(
      context,
      title: title,
      message: message,
      icon: CupertinoIcons.xmark_circle_fill,
      type: IOSNotificationType.error,
    );
  }

  /// Показать информационное уведомление
  static void showInfo(BuildContext context, {required String title, String? message}) {
    show(
      context,
      title: title,
      message: message,
      icon: CupertinoIcons.info_circle_fill,
      type: IOSNotificationType.info,
    );
  }
}

enum IOSNotificationType { success, error, info }

class _IOSNotificationWidget extends StatefulWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final IOSNotificationType type;
  final VoidCallback onDismiss;

  const _IOSNotificationWidget({
    required this.title,
    this.message,
    this.icon,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_IOSNotificationWidget> createState() => _IOSNotificationWidgetState();
}

class _IOSNotificationWidgetState extends State<_IOSNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Контроллер анимации с spring эффектом
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    // Анимация сдвига с iOS spring эффектом
    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic, // iOS-подобная кривая
    );

    // Анимация прозрачности
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    // Запускаем появление
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case IOSNotificationType.success:
        return const Color(0xFF34C759).withOpacity(.5);
      case IOSNotificationType.error:
        return const Color(0xFFFF3B30).withOpacity(.5);
      case IOSNotificationType.info:
        return Colors.grey.withOpacity(.2);
    }
  }

  IconData _getIcon() {
    if (widget.icon != null) return widget.icon!;

    switch (widget.type) {
      case IOSNotificationType.success:
        return CupertinoIcons.check_mark_circled_solid;
      case IOSNotificationType.error:
        return CupertinoIcons.xmark_circle_fill;
      case IOSNotificationType.info:
        return CupertinoIcons.info_circle_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -100 * (1 - _slideAnimation.value)),
              child: Opacity(opacity: _opacityAnimation.value, child: child),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: _dismiss,
              onVerticalDragEnd: (details) {
                // Свайп вверх для закрытия
                if (details.primaryVelocity! < -500) {
                  _dismiss();
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getBackgroundColor().withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            // Иконка
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_getIcon(), color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),

                            // Текст
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (widget.message != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.message!,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: -0.1,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
