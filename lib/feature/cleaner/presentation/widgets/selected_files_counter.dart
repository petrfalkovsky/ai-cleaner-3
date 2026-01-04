import 'package:ai_cleaner_2/generated/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'dart:math' as math;
import '../bloc/media_cleaner_bloc.dart';

class SelectedFilesCounter extends StatefulWidget {
  const SelectedFilesCounter({super.key});

  @override
  State<SelectedFilesCounter> createState() => _SelectedFilesCounterState();
}

class _SelectedFilesCounterState extends State<SelectedFilesCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onCountChanged(int newCount) {
    if (newCount != _previousCount) {
      _scaleController.forward(from: 0);
      _previousCount = newCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
      builder: (context, state) {
        if (state is! MediaCleanerLoaded) {
          return const SizedBox.shrink();
        }

        final selectedCount = state.selectedFiles.length;

        if (selectedCount == 0) {
          return const SizedBox.shrink();
        }

        _onCountChanged(selectedCount);

        // Вычисляем размер текста для определения необходимости расширения
        final countText = selectedCount.toString();
        final needsExpansion = countText.length >= 2;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              LiquidGlass(
                    settings: LiquidGlassSettings(
                      blur: 5,
                      ambientStrength: 1.0,
                      lightAngle: 0.25 * math.pi,
                      glassColor: Colors.white.withOpacity(0.12),
                      thickness: 25,
                    ),
                    shape: const LiquidRoundedSuperellipse(borderRadius: Radius.circular(22)),
                    glassContainsChild: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            // Анимированный счетчик
                            AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  constraints: BoxConstraints(
                                    minWidth: needsExpansion ? 44 : 40,
                                    minHeight: 40,
                                  ),

                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: needsExpansion ? 12 : 0,
                                      vertical: 0,
                                    ),
                                    child: Center(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 200),
                                        transitionBuilder: (child, animation) {
                                          return ScaleTransition(scale: animation, child: child);
                                        },
                                        child: Text(
                                          countText,
                                          key: ValueKey(selectedCount),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .animate(
                                  onPlay: (controller) => controller.forward(),
                                  autoPlay: false,
                                )
                                .scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1.0, 1.0),
                                  duration: 200.ms,
                                  curve: Curves.elasticOut,
                                ),

                            const SizedBox(width: 12),

                            // Текст "Выбрано" с tap gesture для очистки выбора
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  context.read<MediaCleanerBloc>().add(UnselectAllFiles());
                                },
                                child: Text(
                                  Locales.current.cancel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ),

                            // Кнопка удаления с анимацией
                            GestureDetector(
                                  onTap: () {
                                    _showDeleteConfirmation(context);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          Locales.current.delete,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .animate()
                                .slideX(
                                  begin: 1.0,
                                  end: 0.0,
                                  duration: 300.ms,
                                  curve: Curves.easeOut,
                                )
                                .fadeIn(duration: 200.ms),
                          ],
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: 350.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 250.ms),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final selectedCount = context.read<MediaCleanerBloc>().state is MediaCleanerLoaded
        ? (context.read<MediaCleanerBloc>().state as MediaCleanerLoaded).selectedFiles.length
        : 0;

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(Locales.current.delete_files),
        content: Text(
          '${Locales.current.are_you_sure_delete} $selectedCount ${_getFileWord(selectedCount)}?\n\n${Locales.current.action_cannot_be_undone}',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(Locales.current.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<MediaCleanerBloc>().add(DeleteSelectedFiles());
            },
            child: Text(Locales.current.delete),
          ),
        ],
      ),
    );
  }

  String _getFileWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return Locales.current.file.toLowerCase();
    } else if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return Locales.current.a_file.toLowerCase();
    } else {
      return Locales.current.files.toLowerCase();
    }
  }
}
