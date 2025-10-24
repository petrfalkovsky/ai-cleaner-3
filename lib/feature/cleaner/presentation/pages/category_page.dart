import 'package:ai_cleaner_2/feature/cleaner/domain/media_file_entity.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/pages/media_preview_page.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/blurry_media_grid_item.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/media_grid_item.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/similar_media_group.dart';
import 'package:ai_cleaner_2/feature/swipe/presentation/widgets/swipe_mode_banner.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'dart:math' as math;
import '../bloc/media_cleaner_bloc.dart';

@RoutePage()
class CategoryPage extends StatelessWidget {
  final String categoryType; // 'photo' или 'video'
  final String categoryName;

  const CategoryPage({super.key, required this.categoryType, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(categoryName, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
            builder: (context, state) {
              if (state is! MediaCleanerReady) return const SizedBox();

              final List<MediaFile> categoryFiles = _getCategoryFiles(state);
              if (categoryFiles.isEmpty) return const SizedBox();

              final selectedFiles = state.selectedFiles;
              final selectedIds = selectedFiles.map((file) => file.entity.id).toList();
              final categoryIds = categoryFiles.map((file) => file.entity.id).toList();
              final selectedCount = categoryIds.where((id) => selectedIds.contains(id)).length;
              final allSelected = selectedCount == categoryIds.length && categoryIds.isNotEmpty;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    if (allSelected) {
                      for (final id in categoryIds) {
                        if (selectedIds.contains(id)) {
                          context.read<MediaCleanerBloc>().add(ToggleFileSelectionById(id));
                        }
                      }
                    } else {
                      for (final id in categoryIds) {
                        if (!selectedIds.contains(id)) {
                          context.read<MediaCleanerBloc>().add(ToggleFileSelectionById(id));
                        }
                      }
                    }
                  },
                  child: LiquidGlass(
                    settings: LiquidGlassSettings(
                      blur: 3,
                      ambientStrength: 0.6,
                      lightAngle: 0.2 * math.pi,
                      glassColor: Colors.white.withOpacity(0.15),
                      thickness: 12,
                    ),
                    shape: LiquidRoundedSuperellipse(
                      borderRadius: const Radius.circular(12),
                    ),
                    glassContainsChild: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        allSelected ? 'Отменить' : 'Выбрать все',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
        builder: (context, state) {
          if (state is! MediaCleanerReady) {
            return const Center(child: CupertinoActivityIndicator());
          }

          final List<MediaFile> categoryFiles = _getCategoryFiles(state);

          if (categoryFiles.isEmpty) {
            return const Center(
              child: Text(
                'Нет файлов в категории',
                style: TextStyle(color: Colors.white60),
              ),
            );
          }

          return Stack(
            children: [
              // Полноэкранный grid
              _buildCategoryContent(context, state),

              // Floating banner сверху
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: _buildSwipeBanner(context, categoryFiles),
                ),
              ),

              // Floating bottom bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: _buildBottomBar(context, state, categoryFiles),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwipeBanner(BuildContext context, List<MediaFile> files) {
    return SwipeModeBanner(
      mediaIds: files.map((file) => file.entity.id).toList(),
      title: categoryName,
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    MediaCleanerReady state,
    List<MediaFile> categoryFiles,
  ) {
    // Правильная проверка: сравниваем ID файлов категории с ID выбранных файлов из state
    final categoryIds = categoryFiles.map((f) => f.entity.id).toSet();
    final selectedIds = state.selectedFiles.map((f) => f.entity.id).toSet();
    final selectedCategoryCount = categoryIds.intersection(selectedIds).length;
    final totalSelectedCount = state.selectedFiles.length;

    if (selectedCategoryCount == 0 && totalSelectedCount == 0) {
      return const SizedBox.shrink();
    }

    final displayCount = selectedCategoryCount > 0 ? selectedCategoryCount : totalSelectedCount;
    final countText = displayCount.toString();
    final needsExpansion = countText.length >= 2;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LiquidGlass(
        settings: LiquidGlassSettings(
          blur: 5,
          ambientStrength: 1.0,
          lightAngle: 0.25 * math.pi,
          glassColor: Colors.white.withOpacity(0.12),
          thickness: 25,
        ),
        shape: LiquidRoundedSuperellipse(
          borderRadius: const Radius.circular(20),
        ),
        glassContainsChild: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              // Badge с числом
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
                      child: Text(
                        countText,
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
              const SizedBox(width: 12),
              // Текст "Выбрано" с tap для очистки
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Очищаем только выбранные файлы из текущей категории
                    final categorySelectedIds = categoryIds.intersection(selectedIds).toList();
                    for (final id in categorySelectedIds) {
                      context.read<MediaCleanerBloc>().add(ToggleFileSelectionById(id));
                    }
                  },
                  child: const Text(
                    'Выбрано',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _showDeleteConfirmation(context, displayCount);
                },
                child: LiquidGlass(
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
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.trash, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Удалить',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int count) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Удалить файлы'),
        content: Text('Вы уверены, что хотите удалить $count ${_getFileWord(count)}?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
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

  // Получает файлы для выбранной категории
  List<MediaFile> _getCategoryFiles(MediaCleanerReady state) {
    if (categoryType == 'photo') {
      switch (categoryName) {
        case 'Похожие':
          return state.similarGroups.expand((group) => group.files).toList();
        case 'Серии снимков':
          return state.photoDuplicateGroups.expand((group) => group.files).toList();
        case 'Снимки экрана':
          return state.screenshots;
        case 'Размытые':
          return state.blurry;
        default:
          return [];
      }
    } else {
      switch (categoryName) {
        case 'Дубликаты':
          return state.videoDuplicateGroups.expand((group) => group.files).toList();
        case 'Записи экрана':
          return state.screenRecordings;
        case 'Короткие записи':
          return state.shortVideos;
        default:
          return [];
      }
    }
  }

  Widget _buildCategoryContent(BuildContext context, MediaCleanerReady state) {
    if (categoryName == 'Размытые') {
      final blurryFiles = state.blurry;

      return GridView.builder(
        padding: const EdgeInsets.only(top: 110, bottom: 100), // Баннер (~90px) + 20px отступ
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          crossAxisSpacing: 1.0,
          mainAxisSpacing: 1.0,
        ),
        itemCount: blurryFiles.length,
        itemBuilder: (context, index) {
          return BlurryMediaGridItem(
            file: blurryFiles[index],
            onTap: () {
              context.read<MediaCleanerBloc>().add(
                ToggleFileSelection(blurryFiles[index].entity.id),
              );
            },
            onPreview: () {
              _showMediaPreview(context, blurryFiles[index]);
            },
          );
        },
      );
    }

    if (categoryName == 'Похожие' || categoryName == 'Серии снимков') {
      final List<MediaGroup> groups;

      if (categoryName == 'Похожие') {
        groups = state.similarGroups;
      } else if (categoryType == 'photo') {
        groups = state.photoDuplicateGroups;
      } else {
        groups = state.videoDuplicateGroups;
      }

      if (groups.isEmpty) {
        return Center(child: Text('$categoryName не найдены'));
      }

      return ListView.builder(
        padding: const EdgeInsets.only(top: 110, bottom: 100), // Баннер (~90px) + 20px отступ
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return SimilarMediaGroup(
            group: groups[index],
            onFileSelected: (fileId) {
              context.read<MediaCleanerBloc>().add(ToggleFileSelection(fileId));
            },
            onPreviewFile: (file) {
              _showMediaPreview(context, file);
            },
            onSelectAllInGroup: (fileIds) {
              context.read<MediaCleanerBloc>().add(SelectAllInGroup(groups[index].id));
            },
          );
        },
      );
    }

    final List<MediaFile> files = _getCategoryFiles(state);

    return GridView.builder(
      padding: const EdgeInsets.only(top: 110, bottom: 100), // Баннер (~90px) + 20px отступ
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 1.0,
        mainAxisSpacing: 1.0,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        return MediaGridItem(
          file: files[index],
          onTap: () {
            context.read<MediaCleanerBloc>().add(ToggleFileSelection(files[index].entity.id));
          },
          onPreview: () {
            _showMediaPreview(context, files[index]);
          },
        );
      },
    );
  }

  void _showMediaPreview(BuildContext context, MediaFile file) {
    Navigator.of(context).push(
      MaterialPageRoute(fullscreenDialog: true, builder: (context) => MediaPreviewPage(file: file)),
    );
  }
}
