import 'dart:io';
import 'package:ai_cleaner_2/core/config/vision_config.dart';
import 'package:ai_cleaner_2/core/enums/media_category_enum.dart';
import 'package:ai_cleaner_2/core/router/router.gr.dart';
import 'package:ai_cleaner_2/core/theme/app_colors.dart';
import 'package:ai_cleaner_2/core/widgets/ios_notification.dart';
import 'package:ai_cleaner_2/core/widgets/native_segmented_control.dart';
import 'package:ai_cleaner_2/core/widgets/tab_view/native_tab_view.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/scan_button.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/scan_status_banner.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/selected_files_counter.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/ios_category_card.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/ios_storage_header.dart';
import 'package:ai_cleaner_2/feature/premium/domain/premium_service.dart';
import 'package:ai_cleaner_2/generated/l10n.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import '../bloc/media_cleaner_bloc.dart';
import '../widgets/video_category_card.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  final int initialTabIndex;

  const HomePage({super.key, this.initialTabIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _fabController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);

    // При запуске проверяем наличие сохраненных данных или начинаем сканирование
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<MediaCleanerBloc>();
      bloc.add(LoadMediaFiles());
    });
  }

  @override
  void dispose() {
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
          backgroundColor: context.iosBackground,
          appBar: AppBar(
            leading: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.iosSecondaryBackground.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: context.iosLabel.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => context.router.push(SettingsRoute()),
                  child: Icon(CupertinoIcons.settings, color: context.iosLabel, size: 20),
                ),
              ),
            ),
          ),
            title: Text(
              Locales.current.ai_cleaner,
              style: TextStyle(fontWeight: FontWeight.w600, color: context.iosLabel),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: StreamBuilder<bool>(
                  stream: PremiumService().premiumStatusStream,
                  initialData: PremiumService().isPremium,
                  builder: (context, snapshot) {
                    final isPremium = snapshot.data ?? false;

                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPremium
                              ? [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.2)]
                              : [const Color(0xFFFFD700), const Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isPremium
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minSize: 0,
                        // onPressed: () => context.router.push(PaywallRoute()),
                        onPressed: () => context.router.push(const PaywallThreePlansRoute()),

                        // onPressed: () => context.router.push(const PaywallWhiteThemeRoute()),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/vectors/crown.svg',
                              color: isPremium ? const Color(0xFFFFD700) : Colors.white,
                              width: 24,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              Locales.current.pro.toUpperCase(),
                              style: TextStyle(
                                color: isPremium ? const Color(0xFFFFD700) : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Анимированный переход между ScanStatusBanner и Storage Header
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.1),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: (state is MediaCleanerScanning || state is MediaCleanerInitial)
                          ? const ScanStatusBanner(key: ValueKey('scan_banner'))
                          : state is MediaCleanerReady
                              ? Padding(
                                  key: const ValueKey('storage_header'),
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: const IOSStorageHeader(),
                                )
                              : const SizedBox.shrink(key: ValueKey('empty')),
                    ),

                    // Основной контент - нативный iOS 26 TabView
                    Expanded(
                      child: showTabs
                          ? _buildNativeTabView(state as MediaCleanerReady)
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

  /// Подготовить данные категорий фото для нативного TabView
  List<Map<String, dynamic>> _preparePhotoCategories(MediaCleanerReady state) {
    final categories = <Map<String, dynamic>>[];

    if (state.similarCount > 0) {
      categories.add({
        'name': 'similar',
        'title': Locales.current.similar_photos,
        'subtitle': '${state.similarGroups.fold<int>(0, (sum, group) => sum + group.files.length)} ${Locales.current.photos}',
        'icon': 'rectangle.on.rectangle',
        'count': state.similarCount,
      });
    }

    if (state.photoDuplicatesCount > 0) {
      categories.add({
        'name': 'series',
        'title': Locales.current.photo_series,
        'subtitle': '${state.photoDuplicateGroups.fold<int>(0, (sum, group) => sum + group.files.length)} ${Locales.current.photos}',
        'icon': 'photo.on.rectangle',
        'count': state.photoDuplicatesCount,
      });
    }

    if (state.screenshotsCount > 0) {
      categories.add({
        'name': 'screenshots',
        'title': Locales.current.screenshots,
        'subtitle': '${state.screenshots.length} ${Locales.current.files}',
        'icon': 'camera.viewfinder',
        'count': state.screenshotsCount,
      });
    }

    if (state.blurryCount > 0) {
      categories.add({
        'name': 'blurry',
        'title': Locales.current.blurry_photos,
        'subtitle': '${state.blurry.length} ${Locales.current.photos}',
        'icon': 'eye.slash',
        'count': state.blurryCount,
      });
    }

    if (state.livePhotosCount > 0) {
      categories.add({
        'name': 'livePhotos',
        'title': Locales.current.live_photos,
        'subtitle': '${state.livePhotos.length} ${Locales.current.photos}',
        'icon': 'livephoto',
        'count': state.livePhotosCount,
      });
    }

    return categories;
  }

  /// Подготовить данные категорий видео для нативного TabView
  List<Map<String, dynamic>> _prepareVideoCategories(MediaCleanerReady state) {
    final categories = <Map<String, dynamic>>[];

    if (state.videoDuplicatesCount > 0) {
      categories.add({
        'name': 'duplicates',
        'title': Locales.current.duplicates,
        'subtitle': '${state.videoDuplicateGroups.fold<int>(0, (sum, group) => sum + group.files.length)} ${Locales.current.videos}',
        'icon': 'square.on.square',
        'count': state.videoDuplicatesCount,
      });
    }

    if (state.screenRecordingsCount > 0) {
      categories.add({
        'name': 'screenRecordings',
        'title': Locales.current.screen_recordings,
        'subtitle': '${state.screenRecordings.length} ${Locales.current.videos}',
        'icon': 'record.circle',
        'count': state.screenRecordingsCount,
      });
    }

    if (state.shortVideosCount > 0) {
      categories.add({
        'name': 'shortVideos',
        'title': Locales.current.short_videos,
        'subtitle': '${state.shortVideos.length} ${Locales.current.videos}',
        'icon': 'timer',
        'count': state.shortVideosCount,
      });
    }

    if (state.largeVideosCount > 0) {
      categories.add({
        'name': 'largeVideos',
        'title': Locales.current.large_videos,
        'subtitle': '${state.largeVideos.length} ${Locales.current.videos}',
        'icon': 'square.stack.3d.up',
        'count': state.largeVideosCount,
      });
    }

    return categories;
  }

  /// Построить нативный iOS 26 TabView
  Widget _buildNativeTabView(MediaCleanerReady state) {
    // Только для iOS
    if (!Platform.isIOS) {
      return _buildFallbackTabView(state);
    }

    final photoCategories = _preparePhotoCategories(state);
    final videoCategories = _prepareVideoCategories(state);

    return NativeTabView(
      photoCategories: photoCategories,
      videoCategories: videoCategories,
      onRescanTapped: () {
        // Запускаем повторное сканирование
        context.read<MediaCleanerBloc>().add(ScanForProblematicFiles());
      },
      onSearchTextChanged: (searchText) {
        // TODO: Реализовать поиск по категориям
        print('Search text: $searchText');
      },
      onTabChanged: (tabIndex) {
        setState(() {
          _currentTabIndex = tabIndex;
        });
      },
      onCategoryTapped: (tabType, categoryName) {
        // Открываем страницу категории
        context.router.push(
          CategoryRoute(
            categoryType: tabType,
            categoryName: categoryName,
          ),
        );
      },
    );
  }

  /// Fallback для не-iOS платформ (используем обычный Flutter TabView)
  Widget _buildFallbackTabView(MediaCleanerReady state) {
    return Column(
      children: [
        // Простой переключатель табов для Android/других платформ
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _currentTabIndex = 0),
                child: Text(Locales.current.photos),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => setState(() => _currentTabIndex = 1),
                child: Text(Locales.current.videos),
              ),
            ],
          ),
        ),
        Expanded(
          child: _currentTabIndex == 0 ? _buildPhotoTab() : _buildVideoTab(),
        ),
      ],
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
              children: [
                CupertinoActivityIndicator(radius: 16),
                SizedBox(height: 16),
                Text(
                  Locales.current.loading,
                  style: TextStyle(fontSize: 16, color: context.iosSecondaryLabel),
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
                Text(
                  Locales.current.error_occurred,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: context.iosLabel),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.iosSecondaryLabel),
                  ),
                ),
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  onPressed: () => context.read<MediaCleanerBloc>().add(LoadMediaFiles()),
                  child: Text(Locales.current.try_again),
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
                // Icon(
                //   CupertinoIcons.photo,
                //   size: 80,
                //   color: CupertinoColors.systemGrey.resolveFrom(context),
                // ),
                Image.asset(width: 70, 'assets/images/gallery_icon.png'),
                const SizedBox(height: 24),
                Text(
                  Locales.current.clean_your_gallery,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: context.iosLabel),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    Locales.current.find_and_delete_unnecessary_photos,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: context.iosSecondaryLabel),
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
    if (state.livePhotosCount > 0) currentCategories.add(PhotoCategory.livePhotos);

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
      PhotoCategory.livePhotos: (
        state.livePhotos.length,
        state.livePhotos.where((f) => f.isSelected).length,
      ),
    };

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
            Text(
              Locales.current.no_issues_found,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: context.iosLabel),
            ),
            const SizedBox(height: 8),
            Text(
              Locales.current.gallery_in_good_shape,
              style: TextStyle(color: context.iosSecondaryLabel),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoButton(
                color: context.iosSecondaryBackground,
                borderRadius: BorderRadius.circular(12),
                onPressed: isScanningInBackground
                    ? null
                    : () => context.read<MediaCleanerBloc>().add(ScanForProblematicFiles()),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.refresh,
                      color: isScanningInBackground
                          ? context.iosSecondaryLabel.withOpacity(0.3)
                          : CupertinoColors.activeBlue.resolveFrom(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Locales.current.rescan,
                      style: TextStyle(
                        color: isScanningInBackground
                            ? context.iosSecondaryLabel.withOpacity(0.3)
                            : CupertinoColors.activeBlue.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).scale(),
      );
    }

    return CustomScrollView(
      key: const PageStorageKey('photo_tab'),
      slivers: [
        // iOS Storage Header Widget
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: const IOSStorageHeader(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  Locales.current.problem_photos,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: context.iosLabel),
                ),
                if (lastScanTime != null && !isScanningInBackground)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${Locales.current.updated} ${DateFormat('dd.MM HH:mm').format(lastScanTime)}',
                      style: TextStyle(fontSize: 13, color: context.iosSecondaryLabel),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppColors.iosContainerRadius),
              child: Column(
                children: List.generate(currentCategories.length, (index) {
                  final category = currentCategories[index];
                  final (count, selectedCount) = categoryCounts[category]!;

                  // Используем StreamBuilder для реактивного обновления замочка
                  return StreamBuilder<bool>(
                    stream: PremiumService().premiumStatusStream,
                    initialData: PremiumService().isPremium,
                    builder: (context, snapshot) {
                      final bool isPremium = snapshot.data ?? false;
                      // Dev mode отключает все ограничения
                      final bool isLocked = category.requiresPremium && !isPremium && !VisionConfig.devModeUnlockAll;

                      return IOSCategoryCard(
                        key: ValueKey('photo_${category.name}'),
                        category: category,
                        count: count,
                        selectedCount: selectedCount,
                        isLocked: isLocked,
                        showSeparator: index < currentCategories.length - 1,
                        onTap: isScanningInBackground
                            ? () {
                                IOSNotification.showInfo(
                                  context,
                                  title: Locales.current.please_wait,
                                  message: Locales.current.scanning_already_in_progress,
                                );
                                return;
                              }
                            : isLocked
                                ? () {
                                    // Открываем paywall для заблокированной категории
                                    context.router.push(const PaywallThreePlansRoute());
                                  }
                                : () => context.router.push(
                                      CategoryRoute(
                                        categoryType: 'photo',
                                        categoryName: category.name,
                                      ),
                                    ),
                      )
                          .animate(key: ValueKey('anim_${category.name}'))
                          .fadeIn(
                            duration: 300.ms,
                            delay: Duration(milliseconds: index * 50),
                          )
                          .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
                    },
                  );
                }),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CupertinoButton(
              color: context.iosSecondaryBackground,
              borderRadius: BorderRadius.circular(12),
              onPressed: isScanningInBackground
                  ? null
                  : () => context.read<MediaCleanerBloc>().add(ScanForProblematicFiles()),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.refresh,
                    color: isScanningInBackground
                        ? Colors.white.withOpacity(0.3)
                        : CupertinoColors.activeBlue.resolveFrom(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Locales.current.rescan,
                    style: TextStyle(
                      color: isScanningInBackground
                          ? Colors.white.withOpacity(0.3)
                          : CupertinoColors.activeBlue.resolveFrom(context),
                    ),
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
                Text(
                  Locales.current.clean_videos,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: context.iosLabel),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    Locales.current.find_duplicate_and_unnecessary_videos,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: context.iosSecondaryLabel),
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
    if (state.largeVideosCount > 0) currentCategories.add(VideoCategory.largeVideos);

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
      VideoCategory.largeVideos: (
        state.largeVideos.length,
        state.largeVideos.where((f) => f.isSelected).length,
      ),
    };

    if (currentCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.checkmark_circle,
              size: 60,
              color: CupertinoColors.systemGreen.resolveFrom(context),
            ),
            const SizedBox(height: 16),
            Text(
              Locales.current.no_video_issues_yet,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: context.iosLabel),
            ),
            const SizedBox(height: 8),
            Text(
              Locales.current.all_videos_ok,
              style: TextStyle(color: context.iosSecondaryLabel),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoButton(
                color: context.iosSecondaryBackground,
                borderRadius: BorderRadius.circular(12),
                onPressed: isScanningInBackground
                    ? null
                    : () => context.read<MediaCleanerBloc>().add(ScanForProblematicFiles()),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.refresh,
                      color: isScanningInBackground
                          ? context.iosSecondaryLabel.withOpacity(0.3)
                          : CupertinoColors.activeBlue.resolveFrom(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Locales.current.rescan,
                      style: TextStyle(
                        color: isScanningInBackground
                            ? context.iosSecondaryLabel.withOpacity(0.3)
                            : CupertinoColors.activeBlue.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).scale(),
      );
    }

    return CustomScrollView(
      key: const PageStorageKey('video_tab'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  Locales.current.problem_videos,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: context.iosLabel),
                ),
                if (lastScanTime != null && !isScanningInBackground)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '${Locales.current.updated}  ${DateFormat('dd.MM HH:mm').format(lastScanTime)}',
                      style: TextStyle(fontSize: 13, color: context.iosSecondaryLabel),
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

              // Используем StreamBuilder для реактивного обновления замочка
              return StreamBuilder<bool>(
                stream: PremiumService().premiumStatusStream,
                initialData: PremiumService().isPremium,
                builder: (context, snapshot) {
                  final bool isPremium = snapshot.data ?? false;
                  // Dev mode отключает все ограничения
                  final bool isLocked = category.requiresPremium && !isPremium && !VisionConfig.devModeUnlockAll;

                  return Padding(
                    padding: EdgeInsets.only(bottom: index < currentCategories.length - 1 ? 12 : 0),
                    child:
                        VideoCategoryCard(
                              key: ValueKey('video_${category.name}'),
                              category: category,
                              count: count,
                              selectedCount: selectedCount,
                              isLocked: isLocked,
                              onTap: isScanningInBackground
                                  ? () {
                                      IOSNotification.showInfo(
                                        context,
                                        title: Locales.current.please_wait,
                                        message: Locales.current.scanning_already_in_progress,
                                      );
                                      return;
                                    }
                                  : isLocked
                                  ? () {
                                      // Открываем paywall для заблокированной категории
                                      context.router.push(const PaywallThreePlansRoute());
                                    }
                                  : () => context.router.push(
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
                },
              );
            }, childCount: currentCategories.length),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CupertinoButton(
              color: context.iosSecondaryBackground,
              borderRadius: BorderRadius.circular(12),
              onPressed: isScanningInBackground
                  ? null
                  : () => context.read<MediaCleanerBloc>().add(ScanForProblematicFiles()),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.refresh,
                    color: isScanningInBackground
                        ? Colors.white.withOpacity(0.3)
                        : CupertinoColors.activeBlue.resolveFrom(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Locales.current.rescan,
                    style: TextStyle(
                      color: isScanningInBackground
                          ? Colors.white.withOpacity(0.3)
                          : CupertinoColors.activeBlue.resolveFrom(context),
                    ),
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
