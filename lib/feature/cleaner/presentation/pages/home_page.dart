import 'package:ai_cleaner_2/core/enums/media_category_enum.dart';
import 'package:ai_cleaner_2/core/router/router.gr.dart';
import 'package:ai_cleaner_2/feature/cleaner/domain/media_file_entity.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/scan_button.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/scan_status_banner.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/selected_files_counter.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/animated_background.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'dart:math' as math;
import '../bloc/media_cleaner_bloc.dart';
import '../widgets/photo_category_card.dart';
import '../widgets/video_category_card.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  final int initialTabIndex;

  const HomePage({super.key, this.initialTabIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabController;

  // Для отслеживания категорий, которые уже отображались
  Set<PhotoCategory> _previousPhotoCategories = {};
  Set<VideoCategory> _previousVideoCategories = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      setState(() {}); // Обновляем UI при изменении таба
    });

    _fabController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);

    // При запуске проверяем наличие сохраненных данных или начинаем сканирование
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<MediaCleanerBloc>();
      bloc.add(LoadMediaFiles());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
      builder: (context, state) {
        // Показываем табы только если есть результаты сканирования
        final showTabs = state is MediaCleanerReady;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0E27), // Темный фон для контраста
          appBar: AppBar(
            title: const Text(
              'AI Cleaner',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: Stack(
              children: [
                // Анимированный фон с паттернами
                const Positioned.fill(child: AnimatedBackground()),
                Column(
                  children: [
                    // Custom Tab Bar в iOS стиле с liquid glass - показываем только после сканирования
                    if (showTabs)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: LiquidGlassLayer(
                          settings: LiquidGlassSettings(
                            blur: 3,
                            ambientStrength: 0.5,
                            lightAngle: 0.2 * math.pi,
                            glassColor: Colors.white12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: LiquidGlass.inLayer(
                                  shape: LiquidRoundedSuperellipse(
                                    borderRadius: const Radius.circular(12),
                                  ),
                                  glassContainsChild: false,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              _tabController.animateTo(0);
                                            },
                                            child: _tabController.index == 0
                                                ? LiquidGlass(
                                                    settings: LiquidGlassSettings(
                                                      blur: 8,
                                                      ambientStrength: 0.5,
                                                      lightAngle: 0.2 * math.pi,
                                                      glassColor: Colors.black26,
                                                      thickness: 10,
                                                    ),
                                                    shape: LiquidRoundedSuperellipse(
                                                      borderRadius: const Radius.circular(10),
                                                    ),
                                                    glassContainsChild: false,
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(vertical: 8),
                                                      child: Center(
                                                        child: Text(
                                                          'Фото',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : const Padding(
                                                    padding: EdgeInsets.symmetric(vertical: 8),
                                                    child: Center(
                                                      child: Text(
                                                        'Фото',
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              _tabController.animateTo(1);
                                            },
                                            child: _tabController.index == 1
                                                ? LiquidGlass(
                                                    settings: LiquidGlassSettings(
                                                      blur: 8,
                                                      ambientStrength: 0.5,
                                                      lightAngle: 0.2 * math.pi,
                                                      glassColor: Colors.black26,
                                                      thickness: 10,
                                                    ),
                                                    shape: LiquidRoundedSuperellipse(
                                                      borderRadius: const Radius.circular(10),
                                                    ),
                                                    glassContainsChild: false,
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(vertical: 8),
                                                      child: Center(
                                                        child: Text(
                                                          'Видео',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : const Padding(
                                                    padding: EdgeInsets.symmetric(vertical: 8),
                                                    child: Center(
                                                      child: Text(
                                                        'Видео',
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
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

                    // Баннер статуса сканирования
                    const ScanStatusBanner(),

                    // Основной контент
                    Expanded(
                      child: showTabs
                          ? TabBarView(
                              controller: _tabController,
                              children: [
                                KeepAliveWrapper(child: _buildPhotoTab()),
                                KeepAliveWrapper(child: _buildVideoTab()),
                              ],
                            )
                          : _buildPhotoTab(), // До завершения показываем только фото вкладку
                    ),
                  ],
                ),

                // Floating счетчик выбранных файлов (всегда поверх контента)
                Positioned(left: 0, right: 0, bottom: 0, child: const SelectedFilesCounter()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoTab() {
    return BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
      builder: (context, state) {
        // Обработка состояний
        if (state is MediaCleanerInitial || state is MediaCleanerLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CupertinoActivityIndicator(radius: 16),
                SizedBox(height: 16),
                Text(
                  'Загрузка...',
                  style: TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel),
                ),
              ],
            ),
          );
        }

        if (state is MediaCleanerError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_circle,
                  size: 64,
                  color: CupertinoColors.systemRed,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Произошла ошибка',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CupertinoColors.secondaryLabel),
                  ),
                ),
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  onPressed: () => context.read<MediaCleanerBloc>().add(LoadMediaFiles()),
                  child: const Text('Попробовать снова'),
                ),
              ],
            ),
          );
        }

        // Если есть результаты сканирования
        if (state is MediaCleanerReady) {
          return _buildPhotoTabContent(state);
        }

        // Если файлы загружены, но не просканированы
        if (state is MediaCleanerLoaded && !(state is MediaCleanerReady)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.photo,
                  size: 80,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Очистите свою галерею',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Найдите и удалите ненужные фотографии для освобождения места',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.5)),
                  ),
                ),
                const SizedBox(height: 32),
                const ScanButton(),
              ],
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPhotoTabContent(MediaCleanerReady state) {
    final bool isScanningInBackground = state.isScanningInBackground;
    final DateTime? lastScanTime = state.lastScanTime;

    final List<PhotoCategory> currentCategories = [];
    if (state.similarCount > 0) currentCategories.add(PhotoCategory.similar);
    if (state.photoDuplicatesCount > 0) currentCategories.add(PhotoCategory.series);
    if (state.screenshotsCount > 0) currentCategories.add(PhotoCategory.screenshots);
    if (state.blurryCount > 0) currentCategories.add(PhotoCategory.blurry);

    final Map<PhotoCategory, (int, int)> categoryCounts = {
      PhotoCategory.similar: (
        state.similarGroups.fold<int>(0, (sum, group) => sum + group.files.length),
        state.similarGroups.fold<int>(
          0,
          (sum, group) => sum + group.files.where((f) => f.isSelected).length,
        ),
      ),
      PhotoCategory.series: (
        state.photoDuplicateGroups.fold<int>(0, (sum, group) => sum + group.files.length),
        state.photoDuplicateGroups.fold<int>(
          0,
          (sum, group) => sum + group.files.where((f) => f.isSelected).length,
        ),
      ),
      PhotoCategory.screenshots: (
        state.screenshots.length,
        state.screenshots.where((f) => f.isSelected).length,
      ),
      PhotoCategory.blurry: (state.blurry.length, state.blurry.where((f) => f.isSelected).length),
    };

    final Set<PhotoCategory> newCategories = currentCategories.toSet().difference(
      _previousPhotoCategories,
    );
    _previousPhotoCategories = currentCategories.toSet();

    if (currentCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.checkmark_circle,
              size: 80,
              color: CupertinoColors.systemGreen.resolveFrom(context),
            ),
            const SizedBox(height: 16),
            const Text(
              'Проблем не найдено',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ваша галерея в отличном состоянии!',
              style: TextStyle(color: CupertinoColors.secondaryLabel),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).scale(),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Проблемные фото',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                if (lastScanTime != null && !isScanningInBackground)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Обновлено: ${DateFormat('dd.MM HH:mm').format(lastScanTime)}',
                      style: const TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final category = currentCategories[index];
              final (count, selectedCount) = categoryCounts[category]!;
              final isNew = newCategories.contains(category);

              return Padding(
                padding: EdgeInsets.only(bottom: index < currentCategories.length - 1 ? 12 : 0),
                child:
                    PhotoCategoryCard(
                          key: ValueKey('photo_${category.name}'),
                          category: category,
                          count: count,
                          selectedCount: selectedCount,
                          onTap: () => context.router.push(
                            CategoryRoute(categoryType: 'photo', categoryName: category.name),
                          ),
                        )
                        .animate(key: ValueKey('anim_${category.name}'))
                        .fadeIn(
                          duration: 300.ms,
                          delay: Duration(milliseconds: index * 50),
                        )
                        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
              );
            }, childCount: currentCategories.length),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CupertinoButton(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
              onPressed: isScanningInBackground
                  ? null
                  : () => context.read<MediaCleanerBloc>().add(ScanForProblematicFiles()),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.refresh,
                    color: CupertinoColors.activeBlue.resolveFrom(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Повторить сканирование',
                    style: TextStyle(color: CupertinoColors.activeBlue.resolveFrom(context)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoTab() {
    return BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
      builder: (context, state) {
        if (state is MediaCleanerReady) {
          return _buildVideoTabContent(state);
        }

        if (state is MediaCleanerLoaded && !(state is MediaCleanerReady)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.play_rectangle,
                  size: 80,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Очистите видео',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Найдите дубликаты и ненужные видео',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel),
                  ),
                ),
                const SizedBox(height: 32),
                const ScanButton(),
              ],
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
          );
        }

        return const Center(child: CupertinoActivityIndicator());
      },
    );
  }

  Widget _buildVideoTabContent(MediaCleanerReady state) {
    final bool isScanningInBackground = state.isScanningInBackground;
    final DateTime? lastScanTime = state.lastScanTime;

    final List<VideoCategory> currentCategories = [];
    if (state.videoDuplicatesCount > 0) currentCategories.add(VideoCategory.duplicates);
    if (state.screenRecordingsCount > 0) currentCategories.add(VideoCategory.screenRecordings);
    if (state.shortVideosCount > 0) currentCategories.add(VideoCategory.shortVideos);

    final Map<VideoCategory, (int, int)> categoryCounts = {
      VideoCategory.duplicates: (
        state.videoDuplicateGroups.fold<int>(0, (sum, group) => sum + group.files.length),
        state.videoDuplicateGroups.fold<int>(
          0,
          (sum, group) => sum + group.files.where((f) => f.isSelected).length,
        ),
      ),
      VideoCategory.screenRecordings: (
        state.screenRecordings.length,
        state.screenRecordings.where((f) => f.isSelected).length,
      ),
      VideoCategory.shortVideos: (
        state.shortVideos.length,
        state.shortVideos.where((f) => f.isSelected).length,
      ),
    };

    final Set<VideoCategory> newCategories = currentCategories.toSet().difference(
      _previousVideoCategories,
    );
    _previousVideoCategories = currentCategories.toSet();

    if (currentCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.checkmark_circle,
              size: 80,
              color: CupertinoColors.systemGreen.resolveFrom(context),
            ),
            const SizedBox(height: 16),
            const Text(
              'Проблем не найдено',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Все видео в порядке!',
              style: TextStyle(color: CupertinoColors.secondaryLabel),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).scale(),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Проблемные видео',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                if (lastScanTime != null && !isScanningInBackground)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Обновлено: ${DateFormat('dd.MM HH:mm').format(lastScanTime)}',
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final category = currentCategories[index];
              final (count, selectedCount) = categoryCounts[category]!;

              return Padding(
                padding: EdgeInsets.only(bottom: index < currentCategories.length - 1 ? 12 : 0),
                child:
                    VideoCategoryCard(
                          key: ValueKey('video_${category.name}'),
                          category: category,
                          count: count,
                          selectedCount: selectedCount,
                          onTap: () => context.router.push(
                            CategoryRoute(categoryType: 'video', categoryName: category.name),
                          ),
                        )
                        .animate(key: ValueKey('anim_${category.name}'))
                        .fadeIn(
                          duration: 300.ms,
                          delay: Duration(milliseconds: index * 50),
                        )
                        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
              );
            }, childCount: currentCategories.length),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CupertinoButton(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
              onPressed: isScanningInBackground
                  ? null
                  : () => context.read<MediaCleanerBloc>().add(ScanForProblematicFiles()),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.refresh,
                    color: CupertinoColors.activeBlue.resolveFrom(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Повторить сканирование',
                    style: TextStyle(color: CupertinoColors.activeBlue.resolveFrom(context)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Wrapper для сохранения состояния вкладок при переключении
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Обязательно вызываем super.build для AutomaticKeepAliveClientMixin
    return widget.child;
  }
}
