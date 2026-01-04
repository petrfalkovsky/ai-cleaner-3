import 'package:ai_cleaner_2/core/enums/media_category_enum.dart';
import 'package:ai_cleaner_2/feature/cleaner/domain/media_file_entity.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/pages/media_preview_page.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/animated_background.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/blurry_media_grid_item.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/media_grid_item.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/similar_media_group.dart';
import 'package:ai_cleaner_2/feature/swipe/presentation/widgets/swipe_mode_banner.dart';
import 'package:ai_cleaner_2/generated/l10n.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import '../bloc/media_cleaner_bloc.dart';
import '../../../../core/services/first_launch_tracker.dart';

@RoutePage()
class CategoryPage extends StatefulWidget {
  final String categoryType; // 'photo' или 'video'
  final String categoryName;

  const CategoryPage({super.key, required this.categoryType, required this.categoryName});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  bool _showFirstLaunchLoading = false;

  @override
  void initState() {
    super.initState();

    // Проверяем, нужно ли показать loading при первом запуске
    if (FirstLaunchTracker.instance.shouldShowFirstCategoryLoading()) {
      _showFirstLaunchLoading = true;

      // Через 1 секунду убираем loading и отмечаем что категория открылась
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _showFirstLaunchLoading = false;
          });
          FirstLaunchTracker.instance.markCategoryOpened();
        }
      });
    }
  }

  // Получить PhotoCategory из строки
  PhotoCategory? get photoCategory {
    if (widget.categoryType != 'photo') return null;
    try {
      return PhotoCategory.values.firstWhere((e) => e.name == widget.categoryName);
    } catch (e) {
      return null;
    }
  }

  // Получить VideoCategory из строки
  VideoCategory? get videoCategory {
    if (widget.categoryType != 'video') return null;
    try {
      return VideoCategory.values.firstWhere((e) => e.name == widget.categoryName);
    } catch (e) {
      return null;
    }
  }

  // Получить локализованное название категории
  String get localizedCategoryName {
    if (widget.categoryType == 'photo' && photoCategory != null) {
      return photoCategory!.title;
    } else if (widget.categoryType == 'video' && videoCategory != null) {
      return videoCategory!.title;
    }
    return widget.categoryName; // fallback
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(localizedCategoryName, style: const TextStyle(color: Colors.white)),
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
                padding: const EdgeInsets.only(right: 16),
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
                    shape: LiquidRoundedSuperellipse(borderRadius: const Radius.circular(25)),
                    glassContainsChild: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        allSelected ? Locales.current.cancel : Locales.current.select_all,
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
      body: Stack(
        children: [
          // Основной контент
          BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
            builder: (context, state) {
              if (state is! MediaCleanerReady) {
                return const Center(child: CupertinoActivityIndicator());
              }

              final List<MediaFile> categoryFiles = _getCategoryFiles(state);

              if (categoryFiles.isEmpty) {
                return Center(
                  child: Text(
                    Locales.current.no_files_in_category,
                    style: TextStyle(color: Colors.white60),
                  ),
                );
              }

              return Stack(
                children: [
                  // Градиентный фон для похожих фото
                  if ((photoCategory == PhotoCategory.similar || photoCategory == PhotoCategory.series))
                    const Positioned.fill(child: AnimatedBackground()),

                  // Полноэкранный grid
                  _buildCategoryContent(context, state),

                  // Floating banner сверху
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(bottom: false, child: _buildSwipeBanner(context, categoryFiles)),
                  ),

                  // Floating bottom bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(top: false, child: _buildBottomBar(context, state, categoryFiles)),
                  ),
                ],
              );
            },
          ),

          // First launch loading overlay с блюром
          if (_showFirstLaunchLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CupertinoActivityIndicator(
                      radius: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwipeBanner(BuildContext context, List<MediaFile> files) {
    return SwipeModeBanner(
      mediaIds: files.map((file) => file.entity.id).toList(),
      title: localizedCategoryName,
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
        shape: LiquidRoundedSuperellipse(borderRadius: const Radius.circular(28)),
        glassContainsChild: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              // Badge с числом
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                constraints: BoxConstraints(minWidth: needsExpansion ? 44 : 40, minHeight: 40),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: needsExpansion ? 12 : 0, vertical: 6),
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
                  child: Text(
                    Locales.current.cancel,
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Locales.current.delete,
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
        title: Text(Locales.current.delete_files),
        content: Text('${Locales.current.are_you_sure_delete} $count ${_getFileWord(count)}?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
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

  // Получает файлы для выбранной категории
  List<MediaFile> _getCategoryFiles(MediaCleanerReady state) {
    if (widget.categoryType == 'photo' && photoCategory != null) {
      switch (photoCategory!) {
        case PhotoCategory.similar:
          return state.similarGroups.expand((group) => group.files).toList();
        case PhotoCategory.series:
          return state.photoDuplicateGroups.expand((group) => group.files).toList();
        case PhotoCategory.screenshots:
          return state.screenshots;
        case PhotoCategory.blurry:
          return state.blurry;
        case PhotoCategory.livePhotos:
          return state.livePhotos;
      }
    } else if (widget.categoryType == 'video' && videoCategory != null) {
      switch (videoCategory!) {
        case VideoCategory.duplicates:
          return state.videoDuplicateGroups.expand((group) => group.files).toList();
        case VideoCategory.screenRecordings:
          return state.screenRecordings;
        case VideoCategory.shortVideos:
          return state.shortVideos;
        case VideoCategory.largeVideos:
          return state.largeVideos;
      }
    }
    return [];
  }

  Widget _buildCategoryContent(BuildContext context, MediaCleanerReady state) {
    if (photoCategory == PhotoCategory.blurry) {
      final blurryFiles = state.blurry;

      return GridView.builder(
        padding: const EdgeInsets.only(top: 180, bottom: 100), // Баннер (~90px) + 40px отступ
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          crossAxisSpacing: 1.0,
          mainAxisSpacing: 1.0,
        ),
        // Оптимизация производительности
        cacheExtent: 1000.0, // Предзагрузка ~3 экранов контента
        addAutomaticKeepAlives: true, // Сохранение состояния при прокрутке
        addRepaintBoundaries: true, // Изоляция перерисовки элементов
        itemCount: blurryFiles.length,
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: BlurryMediaGridItem(
              file: blurryFiles[index],
              onTap: () {
                context.read<MediaCleanerBloc>().add(
                  ToggleFileSelection(blurryFiles[index].entity.id),
                );
              },
              onPreview: () {
                _showMediaPreview(context, blurryFiles[index]);
              },
            ),
          );
        },
      );
    }

    if (photoCategory == PhotoCategory.similar ||
        photoCategory == PhotoCategory.series ||
        videoCategory == VideoCategory.duplicates) {
      final List<MediaGroup> groups;

      if (photoCategory == PhotoCategory.similar) {
        groups = state.similarGroups;
      } else if (photoCategory == PhotoCategory.series) {
        groups = state.photoDuplicateGroups;
      } else {
        groups = state.videoDuplicateGroups;
      }

      if (groups.isEmpty) {
        return Center(
          child: Text('$localizedCategoryName ${Locales.current.not_found.toLowerCase()}'),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.only(top: 180, bottom: 100), // Баннер (~90px) + 40px отступ
        // Оптимизация производительности
        cacheExtent: 1000.0, // Предзагрузка ~2-3 групп заранее
        addAutomaticKeepAlives: true, // Сохранение состояния при прокрутке
        addRepaintBoundaries: true, // Изоляция перерисовки элементов
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: SimilarMediaGroup(
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
            ),
          );
        },
      );
    }

    final List<MediaFile> files = _getCategoryFiles(state);

    return GridView.builder(
      padding: const EdgeInsets.only(top: 180, bottom: 100), // Баннер (~90px) + 40px отступ
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 1.0,
        mainAxisSpacing: 1.0,
      ),
      // Оптимизация производительности
      cacheExtent: 1000.0, // Предзагрузка ~3 экранов контента
      addAutomaticKeepAlives: true, // Сохранение состояния при прокрутке
      addRepaintBoundaries: true, // Изоляция перерисовки элементов
      itemCount: files.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: MediaGridItem(
            file: files[index],
            onTap: () {
              context.read<MediaCleanerBloc>().add(ToggleFileSelection(files[index].entity.id));
            },
            onPreview: () {
              _showMediaPreview(context, files[index]);
            },
          ),
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
