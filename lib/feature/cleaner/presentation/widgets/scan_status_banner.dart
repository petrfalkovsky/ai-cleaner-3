import 'dart:async';
import 'package:ai_cleaner_2/generated/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/media_cleaner_bloc.dart';

class ScanStatusBanner extends StatefulWidget {
  const ScanStatusBanner({Key? key}) : super(key: key);

  @override
  State<ScanStatusBanner> createState() => _ScanStatusBannerState();
}

class _ScanStatusBannerState extends State<ScanStatusBanner> with TickerProviderStateMixin {
  bool _isExpanded = true;
  DateTime? _scanStartTime;
  Timer? _heatWarningTimer;
  bool _showHeatWarning = false;
  late AnimationController _pulseController;
  late AnimationController _warningController;
  bool _showCompletionMessage = false;
  Timer? _completionTimer;

  @override
  void initState() {
    super.initState();
    // Анимация пульсации кнопки паузы после 3 минут
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Анимация появления предупреждения
    _warningController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _heatWarningTimer?.cancel();
    _completionTimer?.cancel();
    _pulseController.dispose();
    _warningController.dispose();
    super.dispose();
  }

  void _startHeatWarningTimer() {
    _heatWarningTimer?.cancel();
    _scanStartTime = DateTime.now();

    // Через 3 минуты показываем предупреждение
    _heatWarningTimer = Timer(const Duration(minutes: 3), () {
      if (mounted) {
        setState(() {
          _showHeatWarning = true;
        });
        _warningController.forward();
      }
    });
  }

  void _stopHeatWarningTimer() {
    _heatWarningTimer?.cancel();
    _scanStartTime = null;
    setState(() {
      _showHeatWarning = false;
    });
    _warningController.reverse();
  }

  String _getElapsedTime() {
    if (_scanStartTime == null) return '';
    final elapsed = DateTime.now().difference(_scanStartTime!);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MediaCleanerBloc, MediaCleanerState>(
      listener: (context, state) {
        if (state is MediaCleanerScanning && !state.isPaused) {
          if (_scanStartTime == null) {
            _startHeatWarningTimer();
          }
          // Убираем сообщение о завершении если началось новое сканирование
          if (_showCompletionMessage) {
            setState(() {
              _showCompletionMessage = false;
            });
            _completionTimer?.cancel();
          }
        } else if (state is MediaCleanerReady && !state.isScanningInBackground) {
          // Сканирование завершено - показываем сообщение на 3 секунды
          _stopHeatWarningTimer();
          if (!_showCompletionMessage && _scanStartTime != null) {
            setState(() {
              _showCompletionMessage = true;
            });
            _completionTimer?.cancel();
            _completionTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _showCompletionMessage = false;
                });
              }
            });
          }
        } else {
          _stopHeatWarningTimer();
        }
      },
      builder: (context, state) {
        // Показываем баннер при сканировании или ошибке
        bool showBanner = false;
        String? message;
        double? progress;
        bool isError = false;
        bool isPaused = false;
        bool isCompleted = false;
        int? processedFiles;
        int? totalFiles;

        if (_showCompletionMessage) {
          // Показываем сообщение о завершении
          showBanner = true;
          message = Locales.current.scan_completed_exclamation;
          isCompleted = true;
        } else if (state is MediaCleanerScanning) {
          showBanner = true;
          message = state.scanMessage;
          progress = state.scanProgress;
          processedFiles = state.processedFiles;
          totalFiles = state.totalFiles;
          isPaused = state.isPaused;
        } else if (state is MediaCleanerLoaded && state.isScanningInBackground) {
          showBanner = true;
          message = "AI анализирует вашу медиатеку...";
        } else if (state is MediaCleanerLoaded && state.scanError != null) {
          showBanner = true;
          message = state.scanError;
          isError = true;
        } else if (state is MediaCleanerError) {
          showBanner = true;
          message = state.message;
          isError = true;
        }

        if (!showBanner) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CupertinoColors.systemGrey6.resolveFrom(context),
                CupertinoColors.systemGrey5.resolveFrom(context),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                // Основной заголовок - всегда видимый
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        // Иконка или индикатор
                        if (isCompleted)
                          const Icon(
                            Icons.check_circle,
                            color: CupertinoColors.systemGreen,
                            size: 24,
                          )
                        else if (isError)
                          const Icon(
                            Icons.error_outline,
                            color: CupertinoColors.systemRed,
                            size: 24,
                          )
                        else if (isPaused)
                          const Icon(
                            Icons.pause_circle_outline,
                            color: CupertinoColors.systemOrange,
                            size: 24,
                          )
                        else
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(CupertinoColors.activeBlue),
                            ),
                          ),
                        const SizedBox(width: 12),

                        // Сообщение
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message ?? Locales.current.scanning,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              if (progress != null && processedFiles != null)
                                Text(
                                  '$processedFiles ${Locales.current.from} $totalFiles • ${(progress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // // Кнопка паузы/возобновления
                        // if (!isError && state is MediaCleanerScanning)
                        //   _buildPauseButton(context, state),

                        // Стрелка разворачивания
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Развернутый контент с анимацией
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? Column(
                          children: [
                            // Прогресс-бар
                            if (progress != null) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    tween: Tween<double>(begin: 0.0, end: progress),
                                    builder: (context, value, child) {
                                      return LinearProgressIndicator(
                                        value: value,
                                        backgroundColor: CupertinoColors.systemGrey4.resolveFrom(
                                          context,
                                        ),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          progress! > 0.9
                                              ? CupertinoColors.systemGreen
                                              : CupertinoColors.activeBlue,
                                        ),
                                        minHeight: 8,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Дополнительная информация
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                Locales.current.ai_cleaner_description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            // Предупреждение о нагреве
                            if (_showHeatWarning)
                              FadeTransition(
                                opacity: _warningController,
                                child: SlideTransition(
                                  position:
                                      Tween<Offset>(
                                        begin: const Offset(0, -0.5),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _warningController,
                                          curve: Curves.easeOut,
                                        ),
                                      ),
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 12, left: 16, right: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          CupertinoColors.systemRed.withOpacity(0.1),
                                          CupertinoColors.systemOrange.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: CupertinoColors.systemOrange.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: CupertinoColors.systemOrange,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            Locales.current.scan_warning,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: CupertinoColors.label.resolveFrom(context),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPauseButton(BuildContext context, MediaCleanerScanning state) {
    final isPaused = state.isPaused;
    final elapsedMinutes = _scanStartTime != null
        ? DateTime.now().difference(_scanStartTime!).inMinutes
        : 0;
    final shouldPulse = elapsedMinutes >= 3 && !isPaused;

    Widget button = CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 36,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isPaused
              ? CupertinoColors.systemOrange.withOpacity(0.1)
              : shouldPulse
              ? CupertinoColors.systemRed.withOpacity(0.1)
              : CupertinoColors.systemGrey5.resolveFrom(context),
          shape: BoxShape.circle,
          border: Border.all(
            color: isPaused
                ? CupertinoColors.systemOrange
                : shouldPulse
                ? CupertinoColors.systemRed
                : CupertinoColors.systemGrey3.resolveFrom(context),
            width: 2,
          ),
        ),
        child: Icon(
          isPaused ? Icons.play_arrow : Icons.pause,
          size: 20,
          color: isPaused
              ? CupertinoColors.systemOrange
              : shouldPulse
              ? CupertinoColors.systemRed
              : CupertinoColors.label.resolveFrom(context),
        ),
      ),
      onPressed: () {
        if (isPaused) {
          context.read<MediaCleanerBloc>().add(ResumeScanningEvent());
        } else {
          context.read<MediaCleanerBloc>().add(PauseScanningEvent());
        }
      },
    );

    // Добавляем пульсацию после 3 минут
    if (shouldPulse) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.1),
            child: Opacity(opacity: 0.8 + (_pulseController.value * 0.2), child: child),
          );
        },
        child: button,
      );
    }

    return button;
  }
}
