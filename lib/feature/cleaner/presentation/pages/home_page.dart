import 'package:ai_cleaner_2/core/enums/media_category_enum.dart';
import 'package:ai_cleaner_2/core/router/router.gr.dart';
import 'package:ai_cleaner_2/feature/cleaner/domain/media_file_entity.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/scan_button.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/scan_status_banner.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/selected_files_counter.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Для отслеживания категорий, которые уже отображались
  Set<PhotoCategory> _previousPhotoCategories = {};
  Set<VideoCategory> _previousVideoCategories = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);

    // При запуске проверяем наличие сохраненных данных или начинаем сканирование
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<MediaCleanerBloc>();
      bloc.add(LoadMediaFiles());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Cleaner', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Фото'),
            Tab(text: 'Видео'),
          ],
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
        builder: (context, state) {
          return Column(
            children: [
              // Показываем статус сканирования всегда сверху
              const ScanStatusBanner(),

              // Основной контент страницы
              Expanded(child: _buildMainContent(state)),
            ],
          );
        },
      ),
      bottomNavigationBar: SelectedFilesCounter(),
    );
  }

  Widget _buildMainContent(MediaCleanerState state) {
    // Обработка различных состояний
    if (state is MediaCleanerInitial || state is MediaCleanerLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is MediaCleanerError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Произошла ошибка при сканировании', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(state.message, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<MediaCleanerBloc>().add(LoadMediaFiles()),
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      );
    }

    if (state is MediaCleanerEmpty) {
      return const Center(child: Text('Нет доступных медиафайлов'));
    }

    // Если это состояние сканирования, но у нас нет категорий (не MediaCleanerReady)
    if (state is MediaCleanerScanning && !(state is MediaCleanerReady)) {
      return SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/placeholder.webp', width: 150, height: 150),
              const SizedBox(height: 16),
              const Text(
                'Анализ вашей галереи',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Ai модель ищет похожие фотографии и видео для очистки галереи',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Если файлы загружены, но еще не просканированы (нет категорий)
    if (state is MediaCleanerLoaded && !(state is MediaCleanerReady)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/placeholder.webp', width: 150, height: 150),
            const SizedBox(height: 16),
            const Text(
              'Очистите свою галерею',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Найдите и удалите ненужные фотографии и видео для освобождения места',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
            // Кнопка запуска сканирования
            const ScanButton(),
          ],
        ),
      );
    }

    // Когда сканирование завершено и у нас есть результаты (MediaCleanerReady)
    return TabBarView(
      controller: _tabController,
      children: [
        // Вкладка Фото
        _buildPhotoTab(state),

        // Вкладка Видео
        _buildVideoTab(state),
      ],
    );
  }

  Widget _buildPhotoTab(MediaCleanerState state) {
    // Если у нас MediaCleanerReady, то показываем категории
    if (state is MediaCleanerReady) {
      return _buildPhotoTabContent(state);
    }

    // Если состояние не Ready, но есть сканирование в фоне
    if (state is MediaCleanerLoaded && state.isScanningInBackground) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Подождите, идет анализ фотографий', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      );
    }

    // Если ничего не загружено
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.photo_library, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Категории фото будут доступны после сканирования',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTabContent(MediaCleanerReady state) {
    // Определяем статус сканирования и время последнего сканирования
    final bool isScanningInBackground = state.isScanningInBackground;
    final DateTime? lastScanTime = state.lastScanTime;

    // Создаем список категорий, которые должны отображаться
    final List<PhotoCategory> currentCategories = [];
    if (state.similarCount > 0) currentCategories.add(PhotoCategory.similar);
    if (state.photoDuplicatesCount > 0) currentCategories.add(PhotoCategory.series);
    if (state.screenshotsCount > 0) currentCategories.add(PhotoCategory.screenshots);
    if (state.blurryCount > 0) currentCategories.add(PhotoCategory.blurry);

    // Получаем статистику для каждой категории
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

    // Определяем новые категории, которых не было раньше
    final Set<PhotoCategory> newCategories = currentCategories.toSet().difference(
      _previousPhotoCategories,
    );

    // Обновляем предыдущие категории для следующего сравнения
    _previousPhotoCategories = currentCategories.toSet();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Проблемные фото',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // if (isScanningInBackground) ...[
                //   const SizedBox(width: 12),
                //   const SizedBox(
                //     width: 14,
                //     height: 14,
                //     child: CircularProgressIndicator(strokeWidth: 2),
                //   ),
                // ],
              ],
            ),

            // Информация о последнем сканировании
            if (lastScanTime != null && !isScanningInBackground)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 16),
                child: Text(
                  'Последнее сканирование: ${DateFormat('dd.MM.yyyy HH:mm').format(lastScanTime)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),

        // Карточки категорий
        ...currentCategories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final (count, selectedCount) = categoryCounts[category]!;

          final isNewCategory = newCategories.contains(category);

          return Column(
            children: [
              _buildAnimatedPhotoCard(
                category: category,
                count: count,
                selectedCount: selectedCount,
                isNew: isNewCategory, // Только для действительно новых категорий
                index: index,
              ),
              if (index < currentCategories.length - 1) const SizedBox(height: 12),
            ],
          );
        }).toList(),

        const SizedBox(height: 24),

        // Кнопка повторного сканирования
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить сканирование'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Theme.of(context).primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isScanningInBackground
                  ? null // Отключаем кнопку, если сканирование уже идет
                  : () => context.read<MediaCleanerBloc>().add(ScanForProblematicFiles()),
            ),
          ),
        ),
      ],
    );
  }

  // Метод для создания анимированных карточек фото-категорий
  Widget _buildAnimatedPhotoCard({
    required PhotoCategory category,
    required int count,
    required int selectedCount,
    required bool isNew,
    required int index,
  }) {
    // Уникальный ключ для категории
    final keyString = 'photo_${category.name}';

    // Если это новая категория - анимируем ее появление
    if (isNew) {
      return AnimatedSlide(
        duration: Duration(milliseconds: 400 + (index * 100)),
        offset: const Offset(0, 0),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 400 + (index * 100)),
          opacity: 1.0,
          curve: Curves.easeOutCubic,
          child: PhotoCategoryCard(
            key: ValueKey(keyString),
            category: category,
            count: count,
            selectedCount: selectedCount,
            onTap: () => context.router.push(
              CategoryRoute(categoryType: 'photo', categoryName: category.name),
            ),
          ),
        ),
      );
    } else {
      // Для существующих категорий - просто обновляем без анимации
      return PhotoCategoryCard(
        key: ValueKey(keyString),
        category: category,
        count: count,
        selectedCount: selectedCount,
        onTap: () =>
            context.router.push(CategoryRoute(categoryType: 'photo', categoryName: category.name)),
      );
    }
  }

  Widget _buildVideoTab(MediaCleanerState state) {
    // Если у нас MediaCleanerReady, то показываем категории
    if (state is MediaCleanerReady) {
      return _buildVideoTabContent(state);
    }

    // Если состояние не Ready, но есть сканирование в фоне
    if (state is MediaCleanerLoaded && state.isScanningInBackground) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Подождите, идет анализ видеофайлов', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      );
    }

    // Если ничего не загружено
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.videocam, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Категории видео будут доступны после сканирования',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoTabContent(MediaCleanerReady state) {
    // Определяем статус сканирования и время последнего сканирования
    final bool isScanningInBackground = state.isScanningInBackground;
    final DateTime? lastScanTime = state.lastScanTime;

    // Создаем список категорий, которые должны отображаться
    final List<VideoCategory> currentCategories = [];
    if (state.videoDuplicatesCount > 0) currentCategories.add(VideoCategory.duplicates);
    if (state.screenRecordingsCount > 0) currentCategories.add(VideoCategory.screenRecordings);
    if (state.shortVideosCount > 0) currentCategories.add(VideoCategory.shortVideos);

    // Получаем статистику для каждой категории
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

    // Определяем новые категории, которых не было раньше
    final Set<VideoCategory> newCategories = currentCategories.toSet().difference(
      _previousVideoCategories,
    );

    // Обновляем предыдущие категории для следующего сравнения
    _previousVideoCategories = currentCategories.toSet();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Проблемные видео',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // if (isScanningInBackground) ...[
                //   const SizedBox(width: 12),
                //   const SizedBox(
                //     width: 14,
                //     height: 14,
                //     child: CircularProgressIndicator(strokeWidth: 2),
                //   ),
                // ],
              ],
            ),

            // Информация о последнем сканировании
            if (lastScanTime != null && !isScanningInBackground)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 16),
                child: Text(
                  'Последнее сканирование: ${DateFormat('dd.MM.yyyy HH:mm').format(lastScanTime)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),

        // Карточки категорий
        ...currentCategories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final (count, selectedCount) = categoryCounts[category]!;

          final isNewCategory = newCategories.contains(category);

          return Column(
            children: [
              _buildAnimatedVideoCard(
                category: category,
                count: count,
                selectedCount: selectedCount,
                isNew: isNewCategory,
                index: index,
              ),
              if (index < currentCategories.length - 1) const SizedBox(height: 12),
            ],
          );
        }).toList(),

        const SizedBox(height: 24),

        // Кнопка повторного сканирования
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить сканирование'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Theme.of(context).primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isScanningInBackground
                  ? null
                  : () => context.read<MediaCleanerBloc>().add(ScanForProblematicFiles()),
            ),
          ),
        ),
      ],
    );
  }

  // Метод для создания анимированных карточек видео-категорий
  Widget _buildAnimatedVideoCard({
    required VideoCategory category,
    required int count,
    required int selectedCount,
    required bool isNew,
    required int index,
  }) {
    final keyString = 'video_${category.name}';

    if (isNew) {
      return AnimatedSlide(
        duration: Duration(milliseconds: 400 + (index * 100)),
        offset: const Offset(0, 0),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 400 + (index * 100)),
          opacity: 1.0,
          curve: Curves.easeOutCubic,
          child: VideoCategoryCard(
            key: ValueKey(keyString),
            category: category,
            count: count,
            selectedCount: selectedCount,
            onTap: () => context.router.push(
              CategoryRoute(categoryType: 'video', categoryName: category.name),
            ),
          ),
        ),
      );
    } else {
      return VideoCategoryCard(
        key: ValueKey(keyString),
        category: category,
        count: count,
        selectedCount: selectedCount,
        onTap: () =>
            context.router.push(CategoryRoute(categoryType: 'video', categoryName: category.name)),
      );
    }
  }
}
