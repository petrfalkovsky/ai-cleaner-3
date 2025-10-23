import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../bloc/media_cleaner_bloc.dart';

class SelectedFilesCounter extends StatefulWidget {
  const SelectedFilesCounter({Key? key}) : super(key: key);

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

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CupertinoColors.systemGrey6.resolveFrom(context),
                CupertinoColors.systemGrey5.resolveFrom(context),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Анимированный счетчик
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: needsExpansion ? 12 : 0,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        CupertinoColors.activeBlue,
                        CupertinoColors.systemBlue,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      needsExpansion ? 20 : 100,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.activeBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    minWidth: needsExpansion ? 44 : 40,
                    minHeight: 40,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: Text(
                        countText,
                        key: ValueKey(selectedCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                      'Выбрано',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label.resolveFrom(context),
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),

                // Кнопка удаления с анимацией
                AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    color: CupertinoColors.systemRed,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () {
                      _showDeleteConfirmation(context);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          CupertinoIcons.trash,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Удалить',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
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
                ),
              ],
            ),
          ),
        )
            .animate()
            .slideY(
              begin: 1.0,
              end: 0.0,
              duration: 400.ms,
              curve: Curves.easeOut,
            )
            .fadeIn(duration: 300.ms);
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final selectedCount =
        context.read<MediaCleanerBloc>().state is MediaCleanerLoaded
            ? (context.read<MediaCleanerBloc>().state as MediaCleanerLoaded)
                .selectedFiles
                .length
            : 0;

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Удалить файлы'),
        content: Text(
          'Вы уверены, что хотите удалить $selectedCount ${_getFileWord(selectedCount)}?\n\nЭто действие нельзя отменить.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<MediaCleanerBloc>().add(DeleteSelectedFiles());
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  String _getFileWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'файл';
    } else if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'файла';
    } else {
      return 'файлов';
    }
  }
}
