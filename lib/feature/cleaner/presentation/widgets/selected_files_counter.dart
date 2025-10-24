import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'dart:math' as math;
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
        final countText = selectedCount.toString();
        final needsExpansion = countText.length >= 2;
        return LiquidGlass(
              settings: LiquidGlassSettings(
                blur: 5,
                ambientStrength: 1.0,
                lightAngle: 0.25 * math.pi,
                glassColor: Colors.white.withOpacity(0.12),
                thickness: 25,
              ),
              shape: const LiquidRoundedSuperellipse(borderRadius: Radius.circular(0)),
              glassContainsChild: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            constraints: BoxConstraints(
                              minWidth: needsExpansion ? 44 : 40,
                              minHeight: 40,
                            ),
                            child: LiquidGlass(
                              settings: LiquidGlassSettings(
                                blur: 3,
                                ambientStrength: 0.6,
                                lightAngle: 0.2 * math.pi,
                                glassColor: CupertinoColors.activeBlue.withOpacity(0.4),
                                thickness: 12,
                              ),
                              shape: LiquidRoundedSuperellipse(
                                borderRadius: Radius.circular(needsExpansion ? 20 : 100),
                              ),
                              glassContainsChild: false,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: needsExpansion ? 12 : 0,
                                  vertical: 6,
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
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .animate(onPlay: (controller) => controller.forward(), autoPlay: false)
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.0, 1.0),
                            duration: 200.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            context.read<MediaCleanerBloc>().add(UnselectAllFiles());
                          },
                          child: const Text(
                            'Отмена',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _showDeleteConfirmation(context);
                        },
                        child:
                            LiquidGlass(
                                  settings: LiquidGlassSettings(
                                    blur: 3,
                                    ambientStrength: 0.6,
                                    lightAngle: 0.2 * math.pi,
                                    glassColor: CupertinoColors.systemRed.withOpacity(0.4),
                                    thickness: 12,
                                  ),
                                  shape: LiquidRoundedSuperellipse(
                                    borderRadius: const Radius.circular(16),
                                  ),
                                  glassContainsChild: false,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Удалить',
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
                      ),
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
            .fadeIn(duration: 250.ms);
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
    } else if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return 'файла';
    } else {
      return 'файлов';
    }
  }
}