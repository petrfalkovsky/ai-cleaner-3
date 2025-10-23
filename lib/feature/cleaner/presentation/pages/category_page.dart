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

  Widget _buildBottomBar(BuildContext context, MediaCleanerReady state, List<MediaFile> categoryFiles) {
    final selectedCategoryCount = categoryFiles.where((f) => f.isSelected).length;
    final totalSelectedCount = state.selectedFiles.length;

    if (selectedCategoryCount == 0 && totalSelectedCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
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
                _showDeleteConfirmation(context, selectedCategoryCount > 0 ? selectedCategoryCount : totalSelectedCount);
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

  // Старый код AppBar actions
  Widget _oldActions(BuildContext context) {
    return BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
      builder: (context, state) {
        if (state is! MediaCleanerReady) return const SizedBox();

        final List<MediaFile> categoryFiles = _getCategoryFiles(state);
          // Выбрать все/Отменить
          BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
            builder: (context, state) {
              if (state is! MediaCleanerReady) return const SizedBox();

              final List<MediaFile> categoryFiles = _getCategoryFiles(state);

              // Пропускаем, если нет файлов в категории
              if (categoryFiles.isEmpty) {
                return const SizedBox();
              }

              // Получаем текущие выбранные файлы и их ID
              final selectedFiles = state.selectedFiles;
              final selectedIds = selectedFiles.map((file) => file.entity.id).toList();

              // Получаем ID всех файлов в категории
              final categoryIds = categoryFiles.map((file) => file.entity.id).toList();

              // Проверяем, сколько файлов из категории выбрано
              final selectedCount = categoryIds.where((id) => selectedIds.contains(id)).length;
              final allSelected = selectedCount == categoryIds.length && categoryIds.isNotEmpty;

              return TextButton.icon(
                onPressed: () {
                  if (allSelected) {
                    // Если все выбраны - снимаем выбор со всех файлов категории
                    for (final id in categoryIds) {
                      if (selectedIds.contains(id)) {
                        context.read<MediaCleanerBloc>().add(ToggleFileSelectionById(id));
                      }
                    }
                  } else {
                    // Иначе выбираем все невыбранные файлы в категории
                    for (final id in categoryIds) {
                      if (!selectedIds.contains(id)) {
                        context.read<MediaCleanerBloc>().add(ToggleFileSelectionById(id));
                      }
                    }
                  }
                },
                icon: Icon(
                  allSelected ? Icons.check_circle : Icons.check_circle_outline,
                  color: Colors.white,
                ),
                label: Text(
                  allSelected ? "Отменить выбор" : "Выбрать все",
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
        builder: (context, state) {
          if (state is! MediaCleanerReady) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<MediaFile> categoryFiles = _getCategoryFiles(state);

          if (categoryFiles.isEmpty) {
            return Center(child: Text('Нет файлов в категории $categoryName'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Найдено ${categoryFiles.length} ${categoryType == "photo" ? "фото" : "видео"}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),

              Expanded(child: _buildCategoryContent(context, state)),
            ],
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
        builder: (context, state) {
          if (state is! MediaCleanerReady) return SizedBox();

          // Получаем файлы категории и общее количество выбранных файлов
          final categoryFiles = _getCategoryFiles(state);
          final selectedCategoryCount = categoryFiles.where((f) => f.isSelected).length;
          final totalSelectedCount = state.selectedFiles.length;

          // Показываем либо оригинальную панель для категории, либо общий счетчик выбранных
          if (selectedCategoryCount > 0) {
            // Старая нижняя панель с акцентом на выбранные в этой категории
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Назад'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: selectedCategoryCount > 0
                            ? () => context.read<MediaCleanerBloc>().add(DeleteSelectedFiles())
                            : null,
                        icon: const Icon(Icons.delete_outline),
                        label: Text('Удалить ($selectedCategoryCount)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (totalSelectedCount > 0) {
            // Показываем счетчик всех выбранных файлов, если в этой категории ничего не выбрано
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Выбрано: $totalSelectedCount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<MediaCleanerBloc>().add(DeleteSelectedFiles());
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Удалить'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SizedBox(); // Не показываем нижнюю панель, если нет выбранных файлов
        },
      ),
    );
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
      // video
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

  // Строит содержимое категории в зависимости от типа (iOS/Telegram стиль)
  Widget _buildCategoryContent(BuildContext context, MediaCleanerReady state) {
    // Для категории размытых фотографий используем специальную сетку
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
              padding: EdgeInsets.zero, // Убираем отступы
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 1.0, // Минимальные отступы как в iOS/Telegram
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

    // Для категорий с группировкой (похожие и Серии снимков)
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
        return Center(child: Text('${categoryName} не найдены'));
      }

      return Column(
        children: [
          // Добавляем баннер сверху
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

    // Для остальных категорий - простая сетка в стиле iOS/Telegram
    final List<MediaFile> files = _getCategoryFiles(state);

    return Column(
      children: [
        // Добавляем баннер сверху
        SwipeModeBanner(
          mediaIds: files.map((file) => file.entity.id).toList(),
          title: categoryName,
        ),

        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero, // Убираем отступы как в iOS Photos
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 1.0, // Минимальные отступы
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

  // Показывает превью медиафайла
  void _showMediaPreview(BuildContext context, MediaFile file) {
    Navigator.of(context).push(
      MaterialPageRoute(fullscreenDialog: true, builder: (context) => MediaPreviewPage(file: file)),
    );
  }
}
