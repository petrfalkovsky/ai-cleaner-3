import 'package:ai_cleaner_2/feature/cleaner/domain/media_file_entity.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/pages/media_preview_page.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/blurry_media_grid_item.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/media_grid_item.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/similar_media_group.dart';
import 'package:ai_cleaner_2/feature/swipe/presentation/widgets/swipe_mode_banner.dart';
import 'package:auto_route/auto_route.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        actions: [
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

  // Строит содержимое категории в зависимости от типа
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
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
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

    // Для остальных категорий - простая сетка
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
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
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
