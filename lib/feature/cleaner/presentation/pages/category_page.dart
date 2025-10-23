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
import '../bloc/media_cleaner_bloc.dart';

@RoutePage()
class CategoryPage extends StatelessWidget {
  final String categoryType; // 'photo' или 'video'
  final String categoryName;

  const CategoryPage({super.key, required this.categoryType, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(categoryName),
        trailing: BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
          builder: (context, state) {
            if (state is! MediaCleanerReady) return const SizedBox();

            final List<MediaFile> categoryFiles = _getCategoryFiles(state);
            if (categoryFiles.isEmpty) return const SizedBox();

            final selectedFiles = state.selectedFiles;
            final selectedIds = selectedFiles.map((file) => file.entity.id).toList();
            final categoryIds = categoryFiles.map((file) => file.entity.id).toList();
            final selectedCount = categoryIds.where((id) => selectedIds.contains(id)).length;
            final allSelected = selectedCount == categoryIds.length && categoryIds.isNotEmpty;

            return CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
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
              child: Text(
                allSelected ? 'Отменить' : 'Выбрать все',
                style: const TextStyle(fontSize: 16),
              ),
            );
          },
        ),
      ),
      child: SafeArea(
        child: BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
          builder: (context, state) {
            if (state is! MediaCleanerReady) {
              return const Center(child: CupertinoActivityIndicator());
            }

            final List<MediaFile> categoryFiles = _getCategoryFiles(state);

            if (categoryFiles.isEmpty) {
              return Center(
                child: Text(
                  'Нет файлов в категории $categoryName',
                  style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                ),
              );
            }

            return Column(
              children: [
                Expanded(child: _buildCategoryContent(context, state)),
                _buildBottomBar(context, state, categoryFiles),
              ],
            );
          },
        ),
      ),
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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        border: Border(
          top: BorderSide(color: CupertinoColors.separator.resolveFrom(context), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Выбрано: ${selectedCategoryCount > 0 ? selectedCategoryCount : totalSelectedCount}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: CupertinoColors.systemRed,
              borderRadius: BorderRadius.circular(12),
              onPressed: () {
                _showDeleteConfirmation(
                  context,
                  selectedCategoryCount > 0 ? selectedCategoryCount : totalSelectedCount,
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(CupertinoIcons.trash, size: 18),
                  SizedBox(width: 6),
                  Text('Удалить', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
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

      return Column(
        children: [
          SwipeModeBanner(
            mediaIds: blurryFiles.map((file) => file.entity.id).toList(),
            title: 'Размытые фото',
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
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
            ),
          ),
        ],
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

      return Column(
        children: [
          SwipeModeBanner(
            mediaIds: groups.expand((group) => group.files).map((file) => file.entity.id).toList(),
            title: categoryName,
          ),
          Expanded(
            child: ListView.builder(
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
            ),
          ),
        ],
      );
    }

    final List<MediaFile> files = _getCategoryFiles(state);

    return Column(
      children: [
        SwipeModeBanner(
          mediaIds: files.map((file) => file.entity.id).toList(),
          title: categoryName,
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
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
          ),
        ),
      ],
    );
  }

  void _showMediaPreview(BuildContext context, MediaFile file) {
    Navigator.of(context).push(
      MaterialPageRoute(fullscreenDialog: true, builder: (context) => MediaPreviewPage(file: file)),
    );
  }
}
