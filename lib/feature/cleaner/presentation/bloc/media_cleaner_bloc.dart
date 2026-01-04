import 'dart:async';
import 'dart:convert';

import 'package:ai_cleaner_2/core/enums/media_category_enum.dart';
import 'package:ai_cleaner_2/core/services/rating_service.dart';
import 'package:ai_cleaner_2/feature/cleaner/domain/media_file_entity.dart';
import 'package:ai_cleaner_2/feature/cleaner/domain/media_scanner.dart';
import 'package:ai_cleaner_2/generated/l10n.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'media_cleaner_event.dart';
part 'media_cleaner_state.dart';

class MediaCleanerBloc extends Bloc<MediaCleanerEvent, MediaCleanerState> {
  MediaCleanerBloc() : super(MediaCleanerInitial()) {
    on<LoadMediaFiles>(_onLoadMediaFiles);
    on<ScanForProblematicFiles>(_onScanForProblematicFiles);
    on<ToggleFileSelection>(_onToggleFileSelection);
    on<ToggleFileSelectionById>(_onToggleFileSelectionById);
    on<SelectAllInCategory>(_onSelectAllInCategory);
    on<UnselectAllFiles>(_onUnselectAllFiles);
    on<DeleteSelectedFiles>(_onDeleteSelectedFiles);

    on<SelectAllFiles>(_onSelectAllFiles);
    on<SelectAllInGroup>(_onSelectAllInGroup);

    on<PauseScanningEvent>(_onPauseScanning);
    on<ResumeScanningEvent>(_onResumeScanning);
  }

  Future<void> _onLoadMediaFiles(LoadMediaFiles event, Emitter<MediaCleanerState> emit) async {
    emit(MediaCleanerLoading());

    try {
      // Запрос разрешений
      final PermissionState permissionState = await PhotoManager.requestPermissionExtend();
      if (!permissionState.hasAccess) {
        emit(MediaCleanerError(Locales.current.gallery_permission_required));
        return;
      }

      // Загружаем все файлы
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(onlyAll: true);
      if (paths.isEmpty) {
        emit(MediaCleanerEmpty());
        return;
      }

      final List<AssetEntity> assets = await paths.first.getAssetListPaged(page: 0, size: 10000);
      final List<MediaFile> mediaFiles = assets.map((asset) => MediaFile(entity: asset)).toList();

      // Проверяем, было ли завершено первое сканирование
      final hasCompletedScan = await _hasCompletedFirstScan();

      if (hasCompletedScan) {
        debugPrint('PERSISTENCE: Отображаем экран с ранее найденными группами');

        // Загружаем сохраненные результаты сканирования
        final savedResults = await _loadScanResults(mediaFiles);

        if (savedResults != null) {
          debugPrint('PERSISTENCE: Восстановлено ${savedResults.similarGroups.length} групп похожих, '
              '${savedResults.screenshots.length} скриншотов, '
              '${savedResults.blurry.length} размытых, '
              '${savedResults.livePhotos.length} Live Photos');
          emit(savedResults);
        } else {
          // Если не удалось загрузить, показываем пустое состояние
          final lastScanTime = await _getLastScanTime();
          emit(
            MediaCleanerReady(
              allFiles: mediaFiles,
              photoFiles: mediaFiles.where((f) => f.isImage).toList(),
              videoFiles: mediaFiles.where((f) => f.isVideo).toList(),
              similarGroups: const [],
              screenshots: const [],
              blurry: const [],
              photoDuplicateGroups: const [],
              videoDuplicateGroups: const [],
              screenRecordings: const [],
              shortVideos: const [],
              livePhotos: const [],
              largeVideos: const [],
              appMediaGroups: const {},
              lastScanTime: lastScanTime,
              isScanningInBackground: false,
            ),
          );
        }
      } else {
        // Если это первое сканирование, показываем обычное состояние Loaded
        emit(
          MediaCleanerLoaded(
            allFiles: mediaFiles,
            photoFiles: mediaFiles.where((f) => f.isImage).toList(),
            videoFiles: mediaFiles.where((f) => f.isVideo).toList(),
          ),
        );
      }
    } catch (e) {
      emit(MediaCleanerError('${Locales.current.files_load_error} $e'));
    }
  }

  Future<void> _onScanForProblematicFiles(
    ScanForProblematicFiles event,
    Emitter<MediaCleanerState> emit,
  ) async {
    if (state is! MediaCleanerLoaded) return;

    final currentState = state as MediaCleanerLoaded;

    // Создаем начальное состояние с пустыми группами
    final initialScanState = MediaCleanerReady(
      allFiles: currentState.allFiles,
      photoFiles: currentState.photoFiles,
      videoFiles: currentState.videoFiles,
      selectedFiles: currentState.selectedFiles,
      similarGroups: const [],
      screenshots: const [],
      blurry: const [],
      photoDuplicateGroups: const [],
      videoDuplicateGroups: const [],
      screenRecordings: const [],
      shortVideos: const [],
      isScanningInBackground: true,
    );

    // Отправляем начальное состояние Ready, но с флагом сканирования
    emit(initialScanState);

    // ВАЖНО: нужно использовать await здесь
    await _performIncrementalScan(initialScanState, emit);
  }

  Future<void> _performIncrementalScan(
    MediaCleanerReady initialState,
    Emitter<MediaCleanerState> emit,
  ) async {
    MediaCleanerReady currentState = initialState;
    final totalPhotoFiles = currentState.photoFiles.length;
    final totalVideoFiles = currentState.videoFiles.length;
    final totalFiles = totalPhotoFiles + totalVideoFiles;

    int processedFiles = 0;
    bool isPaused = false; // Флаг для отслеживания паузы

    // Добавляем секундомер для регулярных пауз в обработке
    Stopwatch pauseStopwatch = Stopwatch()..start();
    const pauseIntervalMillis = 5000; // Каждые 5 секунд делаем паузу

    // Вспомогательная функция для обновления статуса с поддержкой пауз для UI
    Future<void> updateStatus(String message, double progressPercent, {int? currentBatch}) async {
      if (emit.isDone) return; // Проверка перед обновлением

      // Проверяем состояние паузы
      if (state is MediaCleanerScanning && (state as MediaCleanerScanning).isPaused) {
        isPaused = true;
        return;
      }

      // Логирование прогресса
      debugPrint(
        '$message: ${currentBatch != null ? "$currentBatch из $totalFiles" : ""} (${(progressPercent * 100).toStringAsFixed(1)}%)',
      );

      // Отправляем текущее состояние
      emit(
        MediaCleanerScanning(
          allFiles: currentState.allFiles,
          photoFiles: currentState.photoFiles,
          videoFiles: currentState.videoFiles,
          selectedFiles: currentState.selectedFiles,
          scanProgress: progressPercent,
          scanMessage: message,
          processedFiles: currentBatch ?? processedFiles,
          totalFiles: totalFiles,
          similarGroups: currentState.similarGroups,
          screenshots: currentState.screenshots,
          blurry: currentState.blurry,
          photoDuplicateGroups: currentState.photoDuplicateGroups,
          videoDuplicateGroups: currentState.videoDuplicateGroups,
          screenRecordings: currentState.screenRecordings,
          shortVideos: currentState.shortVideos,
        ),
      );

      // Делаем небольшую паузу каждые pauseIntervalMillis, чтобы UI успел обновиться
      if (pauseStopwatch.elapsedMilliseconds >= pauseIntervalMillis) {
        debugPrint('СКАНИРОВАНИЕ: Делаем паузу на 200мс для обновления UI');
        await Future.delayed(const Duration(milliseconds: 200));
        pauseStopwatch.reset();
        pauseStopwatch.start();
      }
    }

    try {
      // Инициализируем модели TFLite
      await MediaScanner.initModels();
      debugPrint('СКАНИРОВАНИЕ: Инициализация моделей завершена');

      // 1. Находим скриншоты - быстрая операция
      await updateStatus(Locales.current.ai_model_searching_screenshots, 0.05);

      final screenshots = MediaScanner.findScreenshots(currentState.photoFiles);
      currentState = currentState.copyWith(screenshots: screenshots);
      processedFiles += screenshots.length;

      // Отправляем первое обновление после нахождения скриншотов
      await updateStatus(
        '${Locales.current.found} ${screenshots.length} ${Locales.current.screenshots_count.toLowerCase()}',
        0.1,
        currentBatch: processedFiles,
      );
      debugPrint(
        'СКАНИРОВАНИЕ: Найдено ${screenshots.length} ${Locales.current.screenshots_count.toLowerCase()}',
      );

      // 2. Ищем серии снимков - разбиваем на порции для более плавного UI
      await updateStatus('Ai-модель ищет серии снимков...', 0.15, currentBatch: processedFiles);

      // Разбиваем на порции по 100 фото
      const photoBatchSize = 100;
      List<MediaGroup> allPhotoDuplicateGroups = [];

      for (int i = 0; i < currentState.photoFiles.length; i += photoBatchSize) {
        if (emit.isDone || isPaused) break; // Проверка паузы

        final end = (i + photoBatchSize < currentState.photoFiles.length)
            ? i + photoBatchSize
            : currentState.photoFiles.length;

        final photoBatch = currentState.photoFiles.sublist(i, end);

        debugPrint(
          'СКАНИРОВАНИЕ: Обработка порции дубликатов фото ${i + 1}-$end из ${currentState.photoFiles.length}',
        );

        // Находим серии снимков в текущей порции
        final batchDuplicates = MediaScanner.findDuplicatePhotos(photoBatch);

        if (batchDuplicates.isNotEmpty) {
          // Добавляем каждую новую группу и обновляем UI после каждой группы
          for (final group in batchDuplicates) {
            if (isPaused) break; // Проверка паузы

            allPhotoDuplicateGroups.add(group);

            // Обновляем текущее состояние после каждой новой группы
            currentState = currentState.copyWith(
              photoDuplicateGroups: List.from(allPhotoDuplicateGroups),
            );

            // Обновляем счетчик и прогресс
            processedFiles += group.files.length;

            final progress =
                0.15 + (0.15 * (i + photoBatchSize / 2) / currentState.photoFiles.length);
            await updateStatus(
              '${Locales.current.found} ${allPhotoDuplicateGroups.length} ${Locales.current.duplicate_photo_groups.toLowerCase()}',
              progress,
              currentBatch: processedFiles,
            );
            if (isPaused) break;
          }
        } else {
          // Если в этой порции ничего не нашли, всё равно обновляем прогресс
          final progress = 0.15 + (0.15 * end / currentState.photoFiles.length);
          await updateStatus(
            '${Locales.current.searching_duplicate_photos_processed} $end/${currentState.photoFiles.length})',
            progress,
            currentBatch: processedFiles + (end - i), // Добавляем проверенные файлы
          );
          if (isPaused) break; // Проверка после updateStatus
        }

        // Короткая пауза для отзывчивости UI
        await Future.delayed(const Duration(milliseconds: 10));
      }

      if (isPaused) {
        debugPrint('СКАНИРОВАНИЕ: Приостановлено пользователем');
        return; // Выходим из функции
      }

      final totalDuplicatesCount = allPhotoDuplicateGroups.fold<int>(
        0,
        (int sum, MediaGroup group) => sum + group.files.length,
      );

      await updateStatus(
        '${Locales.current.found} ${allPhotoDuplicateGroups.length} ${Locales.current.duplicate_groups.toLowerCase()} ($totalDuplicatesCount ${Locales.current.photos.toLowerCase()})',
        0.3,
        currentBatch: processedFiles,
      );

      // 3. Ищем похожие фотографии - обновляем UI после каждой найденной группы
      await updateStatus(
        Locales.current.ai_model_grouping_similar_photos,
        0.35,
        currentBatch: processedFiles,
      );

      // Используем ещё более мелкие порции для анализа похожих фото
      const similarBatchSize = 50; // Уменьшаем размер порции
      List<MediaGroup> allSimilarGroups = [];

      for (int i = 0; i < currentState.photoFiles.length; i += similarBatchSize) {
        if (emit.isDone || isPaused) break; // Проверка паузы

        final end = (i + similarBatchSize < currentState.photoFiles.length)
            ? i + similarBatchSize
            : currentState.photoFiles.length;

        final photoBatch = currentState.photoFiles.sublist(i, end);

        debugPrint(
          'СКАНИРОВАНИЕ: Обработка порции похожих фото ${i + 1}-${end} из ${currentState.photoFiles.length}',
        );

        // Находим похожие в текущей порции
        final similarGroupsMap = await MediaScanner.findSimilarImages(photoBatch);

        if (similarGroupsMap.isNotEmpty) {
          // Для каждой найденной группы сразу обновляем UI
          for (final entry in similarGroupsMap.entries) {
            if (isPaused) break; // Проверка паузы

            final newGroup = MediaGroup(
              id: '${entry.key}_${i ~/ similarBatchSize}_${allSimilarGroups.length}',
              name: '',
              files: entry.value,
            );

            allSimilarGroups.add(newGroup);

            // Обновляем текущее состояние после каждой новой группы
            currentState = currentState.copyWith(similarGroups: List.from(allSimilarGroups));

            // Обновляем счетчик файлов
            processedFiles += newGroup.files.length;

            // Обновляем UI после каждой новой группы
            final progress =
                0.35 + (0.15 * ((i + similarBatchSize / 2) / currentState.photoFiles.length));
            await updateStatus(
              '${Locales.current.found} ${allSimilarGroups.length} ${Locales.current.similar_photo_groups_multiline.toLowerCase()}',
              progress,
              currentBatch: processedFiles,
            );
            if (isPaused) break; // Проверка после updateStatus
          }
        } else {
          // Даже если не нашли группы в порции, всё равно обновляем прогресс
          final progress = 0.35 + (0.15 * end / currentState.photoFiles.length);
          await updateStatus(
            '${Locales.current.searching_similar_photos_processed} ${end}/${currentState.photoFiles.length})',
            progress,
            currentBatch: processedFiles + (end - i), // Добавляем проверенные файлы
          );
          if (isPaused) break; // Проверка после updateStatus
        }

        // Пауза между порциями для отзывчивости UI
        await Future.delayed(const Duration(milliseconds: 20));
      }

      if (isPaused) {
        debugPrint('СКАНИРОВАНИЕ: Приостановлено пользователем');
        return;
      }

      final totalSimilarCount = allSimilarGroups.fold<int>(
        0,
        (int sum, MediaGroup group) => sum + group.files.length,
      );

      await updateStatus(
        '${Locales.current.found} ${allSimilarGroups.length} ${Locales.current.similar_photo_groups_multiline.toLowerCase()} (${totalSimilarCount})',
        0.5,
        currentBatch: processedFiles,
      );

      // 4. Находим размытые фотографии - обновляем после каждого найденного
      await updateStatus(
        Locales.current.ai_model_searching_blurry_photos,
        0.55,
        currentBatch: processedFiles,
      );

      // Ещё меньшие порции для размытых фото
      const blurryBatchSize = 20; // Меньшие порции
      List<MediaFile> allBlurry = [];
      int lastBlurryCount = 0;

      for (int i = 0; i < currentState.photoFiles.length; i += blurryBatchSize) {
        if (emit.isDone || isPaused) break; // Проверка паузы

        final end = (i + blurryBatchSize < currentState.photoFiles.length)
            ? i + blurryBatchSize
            : currentState.photoFiles.length;

        final photoBatch = currentState.photoFiles.sublist(i, end);

        debugPrint(
          'СКАНИРОВАНИЕ: Обработка порции размытых фото ${i + 1}-$end из ${currentState.photoFiles.length}',
        );

        final blurryBatch = await MediaScanner.findBlurryImages(photoBatch);

        // Если нашли новые размытые фото, сразу обновляем UI
        if (blurryBatch.isNotEmpty) {
          allBlurry.addAll(blurryBatch);

          // Обновляем текущее состояние
          currentState = currentState.copyWith(blurry: List.from(allBlurry));

          // Считаем новые найденные файлы
          final newBlurryCount = allBlurry.length - lastBlurryCount;
          lastBlurryCount = allBlurry.length;

          processedFiles += newBlurryCount;

          // Обновляем UI после каждой порции с новыми размытыми фото
          final progressValue = 0.55 + (0.15 * end / currentState.photoFiles.length);

          await updateStatus(
            '${Locales.current.found} ${allBlurry.length} ${Locales.current.blurry_photos.toLowerCase()} (+$newBlurryCount ${Locales.current.new_word.toLowerCase()})',
            progressValue,
            currentBatch: processedFiles,
          );
          if (isPaused) break; // Проверка после updateStatus
        } else {
          // Даже без новых находок обновляем прогресс
          final progressValue = 0.55 + (0.15 * end / currentState.photoFiles.length);

          await updateStatus(
            '${Locales.current.searching_similar_photos_processed} $end/${currentState.photoFiles.length})',
            progressValue,
            currentBatch: processedFiles + (end - i), // Добавляем проверенные файлы
          );
          if (isPaused) break; // Проверка после updateStatus
        }

        // Еще более короткая пауза
        await Future.delayed(const Duration(milliseconds: 10));
      }

      if (isPaused) {
        debugPrint('СКАНИРОВАНИЕ: Приостановлено пользователем');
        return;
      }

      // 5. Обрабатываем видео - обновляем после каждой находки
      await updateStatus(
        Locales.current.ai_model_analyzing_videos,
        0.7,
        currentBatch: processedFiles,
      );

      // Еще меньше порции для быстрого обновления UI
      const videoBatchSize = 20;
      List<MediaGroup> allVideoDuplicateGroups = [];
      List<MediaFile> allScreenRecordings = [];
      List<MediaFile> allShortVideos = [];

      for (int i = 0; i < currentState.videoFiles.length; i += videoBatchSize) {
        if (emit.isDone || isPaused) break; // Проверка паузы

        final end = (i + videoBatchSize < currentState.videoFiles.length)
            ? i + videoBatchSize
            : currentState.videoFiles.length;

        final videoBatch = currentState.videoFiles.sublist(i, end);

        debugPrint(
          'СКАНИРОВАНИЕ: Обработка порции видео ${i + 1}-${end} из ${currentState.videoFiles.length}',
        );

        // Находим дубликаты видео
        final batchVideoDuplicates = MediaScanner.findDuplicateVideos(videoBatch);
        if (batchVideoDuplicates.isNotEmpty) {
          allVideoDuplicateGroups.addAll(batchVideoDuplicates);

          // Обновляем состояние после каждого найденного дубликата
          currentState = currentState.copyWith(
            videoDuplicateGroups: List.from(allVideoDuplicateGroups),
          );

          final videoDuplicatesCount = batchVideoDuplicates.fold<int>(
            0,
            (int sum, MediaGroup group) => sum + group.files.length,
          );

          processedFiles += videoDuplicatesCount;

          final progress = 0.7 + (0.05 * end / currentState.videoFiles.length);
          await updateStatus(
            '${Locales.current.found} ${allVideoDuplicateGroups.length} групп дубликатов видео (+${batchVideoDuplicates.length} ${Locales.current.new_word.toLowerCase()})',
            progress,
            currentBatch: processedFiles,
          );
          if (isPaused) break; // Проверка после updateStatus
        }

        // Находим записи экрана (теперь асинхронно с нативными метаданными)
        final batchScreenRecordings = await MediaScanner.findScreenRecordings(videoBatch);
        if (batchScreenRecordings.isNotEmpty) {
          allScreenRecordings.addAll(batchScreenRecordings);

          // Обновляем состояние после каждой новой записи экрана
          currentState = currentState.copyWith(screenRecordings: List.from(allScreenRecordings));

          processedFiles += batchScreenRecordings.length;

          final progress = 0.75 + (0.05 * end / currentState.videoFiles.length);
          await updateStatus(
            '${Locales.current.found} ${allScreenRecordings.length} ${Locales.current.screen_recordings_2.toLowerCase()} (+${batchScreenRecordings.length} ${Locales.current.new_word.toLowerCase()})',
            progress,
            currentBatch: processedFiles,
          );
          if (isPaused) break;
        }

        // Находим короткие видео
        final batchShortVideos = MediaScanner.findShortVideos(videoBatch);
        if (batchShortVideos.isNotEmpty) {
          allShortVideos.addAll(batchShortVideos);

          // Обновляем состояние после каждого короткого видео
          currentState = currentState.copyWith(shortVideos: List.from(allShortVideos));

          processedFiles += batchShortVideos.length;

          final progress = 0.8 + (0.05 * end / currentState.videoFiles.length);
          await updateStatus(
            '${Locales.current.found} ${allShortVideos.length} ${Locales.current.short_videos.toLowerCase()} (+${batchShortVideos.length} ${Locales.current.new_word.toLowerCase()})',
            progress,
            currentBatch: processedFiles,
          );
          if (isPaused) break;
        }

        // Если в этой порции ничего не нашли, всё равно обновляем прогресс
        if (batchVideoDuplicates.isEmpty &&
            batchScreenRecordings.isEmpty &&
            batchShortVideos.isEmpty) {
          final progress = 0.7 + (0.15 * end / currentState.videoFiles.length);
          await updateStatus(
            '${Locales.current.analyzing_videos_processed} $end/${currentState.videoFiles.length})',
            progress,
            currentBatch: processedFiles + (end - i),
          );
          if (isPaused) break;
        }

        // Пауза для отзывчивости
        await Future.delayed(const Duration(milliseconds: 10));
      }

      if (isPaused) {
        debugPrint('СКАНИРОВАНИЕ: Приостановлено пользователем');
        return;
      }

      // 6. Находим Live Photos
      await updateStatus(
        Locales.current.searching_live_photos,
        0.85,
        currentBatch: processedFiles,
      );

      final livePhotos = MediaScanner.findLivePhotos(currentState.photoFiles);
      if (livePhotos.isNotEmpty) {
        currentState = currentState.copyWith(livePhotos: livePhotos);
        processedFiles += livePhotos.length;
        await updateStatus(
          '${Locales.current.found} ${livePhotos.length} Live Photos',
          0.88,
          currentBatch: processedFiles,
        );
      }

      if (isPaused) {
        debugPrint('СКАНИРОВАНИЕ: Приостановлено пользователем');
        return;
      }

      // 7. Находим большие видео
      await updateStatus(
        Locales.current.searching_large_videos,
        0.90,
        currentBatch: processedFiles,
      );

      final largeVideos = await MediaScanner.findLargeVideos(currentState.videoFiles);
      if (largeVideos.isNotEmpty) {
        currentState = currentState.copyWith(largeVideos: largeVideos);
        processedFiles += largeVideos.length;
        await updateStatus(
          '${Locales.current.found} ${largeVideos.length} ${Locales.current.large_videos.toLowerCase()}',
          0.93,
          currentBatch: processedFiles,
        );
      }

      if (isPaused) {
        debugPrint('СКАНИРОВАНИЕ: Приостановлено пользователем');
        return;
      }

      // 8. Находим медиа из приложений
      await updateStatus(
        Locales.current.searching_app_media,
        0.95,
        currentBatch: processedFiles,
      );

      final appMediaGroups = MediaScanner.findAppSpecificMedia(currentState.allFiles);
      if (appMediaGroups.isNotEmpty) {
        currentState = currentState.copyWith(appMediaGroups: appMediaGroups);
        final totalAppMedia = appMediaGroups.values.fold<int>(0, (sum, files) => sum + files.length);
        processedFiles += totalAppMedia;
        await updateStatus(
          '${Locales.current.found} $totalAppMedia ${Locales.current.files_from_apps.toLowerCase()}',
          0.98,
          currentBatch: processedFiles,
        );
      }

      if (isPaused) {
        debugPrint('СКАНИРОВАНИЕ: Приостановлено пользователем');
        return;
      }

      // Завершающая стадия - финальное обновление
      await updateStatus(Locales.current.scan_completed, 1.0, currentBatch: processedFiles);

      // Завершаем сканирование
      if (!emit.isDone) {
        emit(currentState.copyWith(isScanningInBackground: false, lastScanTime: DateTime.now()));
        debugPrint('СКАНИРОВАНИЕ: Завершено успешно! Обработано $processedFiles файлов');

        // Сохраняем флаг о завершении первого сканирования и результаты
        await _saveFirstScanCompleted();
        await _saveScanResults(currentState);
      } else {
        debugPrint(
          'СКАНИРОВАНИЕ: Обработчик событий завершен при попытке отправить финальный статус',
        );
      }

      // Освобождаем ресурсы
      MediaScanner.disposeModels();
    } catch (e) {
      debugPrint('ОШИБКА при сканировании файлов: $e');
      debugPrint(StackTrace.current.toString());

      // Сохраняем найденные данные, но добавляем информацию об ошибке
      if (!emit.isDone) {
        emit(
          currentState.copyWith(
            isScanningInBackground: false,
            scanError: 'Часть файлов не была просканирована: $e',
          ),
        );
      }

      // Освобождаем ресурсы
      MediaScanner.disposeModels();
    }
  }

  void _onToggleFileSelection(ToggleFileSelection event, Emitter<MediaCleanerState> emit) {
    if (state is! MediaCleanerReady) return;

    final currentState = state as MediaCleanerReady;
    // Перенаправляю на новый обработчик для согласованности
    add(ToggleFileSelectionById(event.fileId));
  }

  void _onToggleFileSelectionById(ToggleFileSelectionById event, Emitter<MediaCleanerState> emit) {
    if (state is! MediaCleanerLoaded) return;

    final currentState = state as MediaCleanerLoaded;

    // Найдем файл, который нужно выделить/снять выделение
    final MediaFile? targetFile = currentState.allFiles
        .where((file) => file.entity.id == event.fileId)
        .firstOrNull;

    if (targetFile == null) return;

    // Получаем текущие выбранные файлы
    List<MediaFile> newSelectedFiles = [...currentState.selectedFiles];

    // Проверяем, выбран ли файл
    final bool isAlreadySelected = newSelectedFiles.any((file) => file.entity.id == event.fileId);

    // Если файл уже выбран - удаляем его из выбранных
    if (isAlreadySelected) {
      newSelectedFiles.removeWhere((file) => file.entity.id == event.fileId);
    }
    // Иначе добавляем его в конец списка выбранных
    else {
      final updatedFile = targetFile.copyWith(isSelected: true);
      newSelectedFiles.add(updatedFile);
    }

    // Обновляем все файлы, устанавливая правильные флаги isSelected
    final updatedFiles = currentState.allFiles.map((file) {
      if (file.entity.id == event.fileId) {
        return file.copyWith(isSelected: !isAlreadySelected);
      }
      return file;
    }).toList();

    // Обновляем состояние
    if (currentState is MediaCleanerReady) {
      emit(
        (currentState as MediaCleanerReady).copyWith(
          allFiles: updatedFiles,
          photoFiles: updatedFiles.where((f) => f.isImage).toList(),
          videoFiles: updatedFiles.where((f) => f.isVideo).toList(),
          selectedFiles: newSelectedFiles,
        ),
      );
    } else {
      emit(
        MediaCleanerLoaded(
          allFiles: updatedFiles,
          photoFiles: updatedFiles.where((f) => f.isImage).toList(),
          videoFiles: updatedFiles.where((f) => f.isVideo).toList(),
          selectedFiles: newSelectedFiles,
        ),
      );
    }
  }

  void _onSelectAllInCategory(SelectAllInCategory event, Emitter<MediaCleanerState> emit) {
    if (state is! MediaCleanerReady) return;

    final currentState = state as MediaCleanerReady;

    // Определяем файлы категории
    List<MediaFile> categoryFiles = [];
    if (event.isPhoto) {
      // Парсим PhotoCategory из строки
      try {
        final photoCategory = PhotoCategory.values.firstWhere((e) => e.name == event.category);
        switch (photoCategory) {
          case PhotoCategory.similar:
            categoryFiles = currentState.similarGroups.expand((group) => group.files).toList();
            break;
          case PhotoCategory.series:
            categoryFiles = currentState.photoDuplicateGroups.expand((group) => group.files).toList();
            break;
          case PhotoCategory.screenshots:
            categoryFiles = currentState.screenshots;
            break;
          case PhotoCategory.blurry:
            categoryFiles = currentState.blurry;
            break;
          case PhotoCategory.livePhotos:
            categoryFiles = currentState.livePhotos;
            break;
        }
      } catch (e) {
        // Неизвестная категория
        return;
      }
    } else {
      // Парсим VideoCategory из строки
      try {
        final videoCategory = VideoCategory.values.firstWhere((e) => e.name == event.category);
        switch (videoCategory) {
          case VideoCategory.duplicates:
            categoryFiles = currentState.videoDuplicateGroups.expand((group) => group.files).toList();
            break;
          case VideoCategory.screenRecordings:
            categoryFiles = currentState.screenRecordings;
            break;
          case VideoCategory.shortVideos:
            categoryFiles = currentState.shortVideos;
            break;
          case VideoCategory.largeVideos:
            categoryFiles = currentState.largeVideos;
            break;
        }
      } catch (e) {
        // Неизвестная категория
        return;
      }
    }

    if (categoryFiles.isEmpty) return;

    // Получаем ID файлов в категории
    final categoryIds = categoryFiles.map((file) => file.entity.id).toList();

    // Получаем ID выбранных файлов
    final selectedIds = currentState.selectedFiles.map((file) => file.entity.id).toList();

    // Проверяем, все ли файлы категории уже выбраны
    final allSelected = categoryIds.every((id) => selectedIds.contains(id));

    // Обновляем выбор файлов
    List<MediaFile> updatedSelectedFiles;
    List<MediaFile> updatedAllFiles;

    if (allSelected) {
      // Снимаем выбор со всех файлов категории
      updatedSelectedFiles = currentState.selectedFiles
          .where((file) => !categoryIds.contains(file.entity.id))
          .toList();

      updatedAllFiles = currentState.allFiles.map((file) {
        if (categoryIds.contains(file.entity.id)) {
          return file.copyWith(isSelected: false);
        }
        return file;
      }).toList();
    } else {
      // Выбираем все файлы категории, которые еще не выбраны
      updatedSelectedFiles = [...currentState.selectedFiles];
      for (final id in categoryIds) {
        if (!selectedIds.contains(id)) {
          final fileToAdd = currentState.allFiles.firstWhere((file) => file.entity.id == id);
          updatedSelectedFiles.add(fileToAdd.copyWith(isSelected: true));
        }
      }

      updatedAllFiles = currentState.allFiles.map((file) {
        if (categoryIds.contains(file.entity.id)) {
          return file.copyWith(isSelected: true);
        }
        return file;
      }).toList();
    }

    // Обновляем состояние
    emit(
      currentState.copyWith(
        allFiles: updatedAllFiles,
        photoFiles: updatedAllFiles.where((f) => f.isImage).toList(),
        videoFiles: updatedAllFiles.where((f) => f.isVideo).toList(),
        selectedFiles: updatedSelectedFiles,
      ),
    );
  }

  void _onUnselectAllFiles(UnselectAllFiles event, Emitter<MediaCleanerState> emit) {
    if (state is! MediaCleanerReady) return;

    final currentState = state as MediaCleanerReady;

    // Снимаем выбор со всех файлов
    final updatedFiles = currentState.allFiles
        .map((file) => file.copyWith(isSelected: false))
        .toList();

    // Обновляем состояние
    emit(
      currentState.copyWith(
        allFiles: updatedFiles,
        photoFiles: updatedFiles.where((f) => f.isImage).toList(),
        videoFiles: updatedFiles.where((f) => f.isVideo).toList(),
        selectedFiles: [],
      ),
    );
  }

  Future<void> _onDeleteSelectedFiles(
    DeleteSelectedFiles event,
    Emitter<MediaCleanerState> emit,
  ) async {
    if (state is! MediaCleanerReady) return;

    final currentState = state as MediaCleanerReady;
    final selectedFileIds = currentState.selectedFiles.map((f) => f.entity.id).toList();

    try {
      // Подсчитываем примерный размер файлов перед удалением для RatingService
      // Используем приблизительный расчет: ширина * высота * 3 (RGB) для фото
      int totalSizeBytes = 0;
      for (final file in currentState.selectedFiles) {
        // Приблизительный размер: для фото ~ width * height * 3, для видео ~ 10MB
        if (file.isImage) {
          totalSizeBytes += file.entity.width * file.entity.height * 3;
        } else if (file.isVideo) {
          // Примерный размер видео: duration (сек) * 1.5MB
          final duration = file.entity.duration;
          totalSizeBytes += ((duration * 1.5 * 1024 * 1024).toInt());
        }
      }

      // Удаляем выбранные файлы
      await PhotoManager.editor.deleteWithIds(selectedFileIds);

      // Записываем статистику удаления для умного показа рейтинга
      try {
        await RatingService().recordDeletedFiles(
          count: selectedFileIds.length,
          freedSpaceBytes: totalSizeBytes,
        );
      } catch (e) {
        debugPrint('[MediaCleanerBloc] Error recording deletion stats: $e');
      }

      // Удаляем файлы из всех списков
      final updatedFiles = currentState.allFiles
          .where((file) => !selectedFileIds.contains(file.entity.id))
          .toList();

      // Удаляем из скриншотов
      final updatedScreenshots = currentState.screenshots
          .where((file) => !selectedFileIds.contains(file.entity.id))
          .toList();

      // Удаляем из размытых
      final updatedBlurry = currentState.blurry
          .where((file) => !selectedFileIds.contains(file.entity.id))
          .toList();

      // Удаляем из записей экрана
      final updatedScreenRecordings = currentState.screenRecordings
          .where((file) => !selectedFileIds.contains(file.entity.id))
          .toList();

      // Удаляем из коротких видео
      final updatedShortVideos = currentState.shortVideos
          .where((file) => !selectedFileIds.contains(file.entity.id))
          .toList();

      // Удаляем из групп похожих
      final updatedSimilarGroups = currentState.similarGroups
          .map((group) {
            final updatedGroupFiles = group.files
                .where((file) => !selectedFileIds.contains(file.entity.id))
                .toList();
            return updatedGroupFiles.isEmpty ? null : group.copyWith(files: updatedGroupFiles);
          })
          .where((group) => group != null)
          .cast<MediaGroup>()
          .toList();

      // Удаляем из групп дубликатов фото
      final updatedPhotoDuplicateGroups = currentState.photoDuplicateGroups
          .map((group) {
            final updatedGroupFiles = group.files
                .where((file) => !selectedFileIds.contains(file.entity.id))
                .toList();
            return updatedGroupFiles.isEmpty ? null : group.copyWith(files: updatedGroupFiles);
          })
          .where((group) => group != null)
          .cast<MediaGroup>()
          .toList();

      // Удаляем из групп дубликатов видео
      final updatedVideoDuplicateGroups = currentState.videoDuplicateGroups
          .map((group) {
            final updatedGroupFiles = group.files
                .where((file) => !selectedFileIds.contains(file.entity.id))
                .toList();
            return updatedGroupFiles.isEmpty ? null : group.copyWith(files: updatedGroupFiles);
          })
          .where((group) => group != null)
          .cast<MediaGroup>()
          .toList();

      emit(
        currentState.copyWith(
          allFiles: updatedFiles,
          photoFiles: updatedFiles.where((f) => f.isImage).toList(),
          videoFiles: updatedFiles.where((f) => f.isVideo).toList(),
          selectedFiles: [],
          screenshots: updatedScreenshots,
          blurry: updatedBlurry,
          screenRecordings: updatedScreenRecordings,
          shortVideos: updatedShortVideos,
          similarGroups: updatedSimilarGroups,
          photoDuplicateGroups: updatedPhotoDuplicateGroups,
          videoDuplicateGroups: updatedVideoDuplicateGroups,
        ),
      );
    } catch (e) {
      emit(MediaCleanerError('Ошибка при удалении файлов: $e'));
    }
  }

  // Обработчик выбора всех файлов
  void _onSelectAllFiles(SelectAllFiles event, Emitter<MediaCleanerState> emit) {
    if (state is! MediaCleanerLoaded) return;

    final currentState = state as MediaCleanerLoaded;

    // Проверим, все ли файлы уже выбраны
    final allSelected = currentState.allFiles.length == currentState.selectedFiles.length;

    if (allSelected) {
      // Если все уже выбраны - снимаем выбор
      emit(
        currentState is MediaCleanerReady
            ? (currentState as MediaCleanerReady).copyWith(
                allFiles: currentState.allFiles.map((f) => f.copyWith(isSelected: false)).toList(),
                photoFiles: currentState.photoFiles
                    .map((f) => f.copyWith(isSelected: false))
                    .toList(),
                videoFiles: currentState.videoFiles
                    .map((f) => f.copyWith(isSelected: false))
                    .toList(),
                selectedFiles: [],
              )
            : MediaCleanerLoaded(
                allFiles: currentState.allFiles.map((f) => f.copyWith(isSelected: false)).toList(),
                photoFiles: currentState.photoFiles
                    .map((f) => f.copyWith(isSelected: false))
                    .toList(),
                videoFiles: currentState.videoFiles
                    .map((f) => f.copyWith(isSelected: false))
                    .toList(),
                selectedFiles: [],
              ),
      );
    } else {
      // Если не все выбраны - выбираем все
      final updatedFiles = currentState.allFiles.map((f) => f.copyWith(isSelected: true)).toList();

      emit(
        currentState is MediaCleanerReady
            ? (currentState as MediaCleanerReady).copyWith(
                allFiles: updatedFiles,
                photoFiles: updatedFiles.where((f) => f.isImage).toList(),
                videoFiles: updatedFiles.where((f) => f.isVideo).toList(),
                selectedFiles: updatedFiles,
              )
            : MediaCleanerLoaded(
                allFiles: updatedFiles,
                photoFiles: updatedFiles.where((f) => f.isImage).toList(),
                videoFiles: updatedFiles.where((f) => f.isVideo).toList(),
                selectedFiles: updatedFiles,
              ),
      );
    }
  }

  // Обработчик выбора всех файлов в группе
  void _onSelectAllInGroup(SelectAllInGroup event, Emitter<MediaCleanerState> emit) {
    if (state is! MediaCleanerReady) return;

    final currentState = state as MediaCleanerReady;

    // Находим группу
    final targetGroup = currentState.similarGroups.firstWhere(
      (group) => group.id == event.groupId,
      orElse: () => MediaGroup(id: '', name: '', files: []),
    );

    if (targetGroup.files.isEmpty) return;

    // Проверяем, все ли файлы в группе выбраны
    final allSelected = targetGroup.allSelected;

    // Обновляем выбор для всех файлов в группе
    final updatedFiles = currentState.allFiles.map((file) {
      if (targetGroup.files.any((groupFile) => groupFile.entity.id == file.entity.id)) {
        return file.copyWith(isSelected: !allSelected);
      }
      return file;
    }).toList();

    // Обновляем список выбранных файлов
    List<MediaFile> updatedSelectedFiles;

    if (allSelected) {
      // Если все были выбраны - удаляем их из выбранных
      updatedSelectedFiles = currentState.selectedFiles
          .where(
            (file) => !targetGroup.files.any((groupFile) => groupFile.entity.id == file.entity.id),
          )
          .toList();
    } else {
      // Если не все были выбраны - добавляем невыбранные
      updatedSelectedFiles = [...currentState.selectedFiles];

      for (final groupFile in targetGroup.files) {
        if (!groupFile.isSelected) {
          // Найдем файл в общем списке и добавим его как выбранный
          final fileToAdd = updatedFiles.firstWhere(
            (file) => file.entity.id == groupFile.entity.id,
            orElse: () => groupFile.copyWith(isSelected: true),
          );

          if (!updatedSelectedFiles.any((file) => file.entity.id == fileToAdd.entity.id)) {
            updatedSelectedFiles.add(fileToAdd);
          }
        }
      }
    }

    // Обновляем состояние
    emit(
      currentState.copyWith(
        allFiles: updatedFiles,
        photoFiles: updatedFiles.where((f) => f.isImage).toList(),
        videoFiles: updatedFiles.where((f) => f.isVideo).toList(),
        selectedFiles: updatedSelectedFiles,
      ),
    );
  }

  void _onPauseScanning(PauseScanningEvent event, Emitter<MediaCleanerState> emit) {
    if (state is MediaCleanerScanning) {
      final currentState = state as MediaCleanerScanning;
      emit(currentState.copyWith(isPaused: true));
    }
  }

  void _onResumeScanning(ResumeScanningEvent event, Emitter<MediaCleanerState> emit) {
    if (state is MediaCleanerScanning && (state as MediaCleanerScanning).isPaused) {
      final currentState = state as MediaCleanerScanning;

      // Просто меняем флаг - пользователь увидит, что сканирование возобновлено
      emit(currentState.copyWith(isPaused: false));

      // Если сканирование не завершено (progress < 1.0), начинаем новое сканирование
      // с текущими результатами в качестве начальных данных
      if (currentState.scanProgress < 1.0) {
        // Сохраняем текущее состояние как готовое к продолжению сканирования
        final resumeState = MediaCleanerReady(
          allFiles: currentState.allFiles,
          photoFiles: currentState.photoFiles,
          videoFiles: currentState.videoFiles,
          selectedFiles: currentState.selectedFiles,
          similarGroups: currentState.similarGroups,
          screenshots: currentState.screenshots,
          blurry: currentState.blurry,
          photoDuplicateGroups: currentState.photoDuplicateGroups,
          videoDuplicateGroups: currentState.videoDuplicateGroups,
          screenRecordings: currentState.screenRecordings,
          shortVideos: currentState.shortVideos,
          isScanningInBackground: true,
        );

        // Запускаем метод сканирования на продолжение
        _performIncrementalScan(resumeState, emit);
      }
    }
  }

  // Сохраняем флаг о завершении первого сканирования
  Future<void> _saveFirstScanCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('first_scan_completed', true);
      await prefs.setString('last_scan_time', DateTime.now().toIso8601String());
      debugPrint('PERSISTENCE: Первое сканирование сохранено в SharedPreferences');
    } catch (e) {
      debugPrint('PERSISTENCE: Ошибка при сохранении флага сканирования: $e');
    }
  }

  // Проверяем, было ли завершено первое сканирование
  Future<bool> _hasCompletedFirstScan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompleted = prefs.getBool('first_scan_completed') ?? false;

      if (hasCompleted) {
        final lastScanTimeStr = prefs.getString('last_scan_time');
        debugPrint('PERSISTENCE: Найдено завершенное сканирование. Последнее сканирование: $lastScanTimeStr');
      } else {
        debugPrint('PERSISTENCE: Первое сканирование еще не выполнено');
      }

      return hasCompleted;
    } catch (e) {
      debugPrint('PERSISTENCE: Ошибка при проверке флага сканирования: $e');
      return false;
    }
  }

  Future<DateTime?> _getLastScanTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString('last_scan_time');
      if (timeString != null) {
        return DateTime.parse(timeString);
      }
      return null;
    } catch (e) {
      debugPrint('PERSISTENCE: Ошибка при получении времени последнего сканирования: $e');
      return null;
    }
  }

  // Сохранение результатов сканирования
  Future<void> _saveScanResults(MediaCleanerReady state) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Создаем JSON структуру с ID файлов
      final scanResults = {
        'lastScanTime': state.lastScanTime?.toIso8601String(),
        'screenshots': state.screenshots.map((f) => f.entity.id).toList(),
        'blurry': state.blurry.map((f) => f.entity.id).toList(),
        'livePhotos': state.livePhotos.map((f) => f.entity.id).toList(),
        'shortVideos': state.shortVideos.map((f) => f.entity.id).toList(),
        'screenRecordings': state.screenRecordings.map((f) => f.entity.id).toList(),
        'largeVideos': state.largeVideos.map((f) => f.entity.id).toList(),
        'similarGroups': state.similarGroups
            .map((group) => {
                  'id': group.id,
                  'name': group.name,
                  'fileIds': group.files.map((f) => f.entity.id).toList(),
                })
            .toList(),
        'photoDuplicateGroups': state.photoDuplicateGroups
            .map((group) => {
                  'id': group.id,
                  'name': group.name,
                  'fileIds': group.files.map((f) => f.entity.id).toList(),
                })
            .toList(),
        'videoDuplicateGroups': state.videoDuplicateGroups
            .map((group) => {
                  'id': group.id,
                  'name': group.name,
                  'fileIds': group.files.map((f) => f.entity.id).toList(),
                })
            .toList(),
        'appMediaGroups': state.appMediaGroups.map(
          (key, value) => MapEntry(key, value.map((f) => f.entity.id).toList()),
        ),
      };

      final jsonString = jsonEncode(scanResults);
      await prefs.setString('scan_results', jsonString);

      debugPrint('PERSISTENCE: Результаты сканирования сохранены (${jsonString.length} байт)');
    } catch (e) {
      debugPrint('PERSISTENCE: Ошибка при сохранении результатов сканирования: $e');
    }
  }

  // Загрузка результатов сканирования
  Future<MediaCleanerReady?> _loadScanResults(List<MediaFile> allMediaFiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('scan_results');

      if (jsonString == null) {
        debugPrint('PERSISTENCE: Нет сохраненных результатов');
        return null;
      }

      final scanResults = jsonDecode(jsonString) as Map<String, dynamic>;

      // Создаем Map для быстрого поиска MediaFile по ID
      final mediaFilesMap = <String, MediaFile>{};
      for (final file in allMediaFiles) {
        mediaFilesMap[file.entity.id] = file;
      }

      // Вспомогательная функция для восстановления файлов по ID
      List<MediaFile> restoreFiles(List<dynamic> ids) {
        return ids
            .map((id) => mediaFilesMap[id as String])
            .where((file) => file != null)
            .cast<MediaFile>()
            .toList();
      }

      // Вспомогательная функция для восстановления групп
      List<MediaGroup> restoreGroups(List<dynamic> groups) {
        return groups.map((group) {
          final groupData = group as Map<String, dynamic>;
          final fileIds = groupData['fileIds'] as List<dynamic>;
          final files = restoreFiles(fileIds);

          return MediaGroup(
            id: groupData['id'] as String,
            name: groupData['name'] as String,
            files: files,
          );
        }).where((group) => group.files.isNotEmpty).toList();
      }

      // Восстанавливаем категории
      final screenshots = restoreFiles(scanResults['screenshots'] as List<dynamic>? ?? []);
      final blurry = restoreFiles(scanResults['blurry'] as List<dynamic>? ?? []);
      final livePhotos = restoreFiles(scanResults['livePhotos'] as List<dynamic>? ?? []);
      final shortVideos = restoreFiles(scanResults['shortVideos'] as List<dynamic>? ?? []);
      final screenRecordings = restoreFiles(scanResults['screenRecordings'] as List<dynamic>? ?? []);
      final largeVideos = restoreFiles(scanResults['largeVideos'] as List<dynamic>? ?? []);

      // Восстанавливаем группы
      final similarGroups = restoreGroups(scanResults['similarGroups'] as List<dynamic>? ?? []);
      final photoDuplicateGroups = restoreGroups(scanResults['photoDuplicateGroups'] as List<dynamic>? ?? []);
      final videoDuplicateGroups = restoreGroups(scanResults['videoDuplicateGroups'] as List<dynamic>? ?? []);

      // Восстанавливаем группы приложений
      final appMediaGroups = <String, List<MediaFile>>{};
      final appGroupsData = scanResults['appMediaGroups'] as Map<String, dynamic>? ?? {};
      for (final entry in appGroupsData.entries) {
        final files = restoreFiles(entry.value as List<dynamic>);
        if (files.isNotEmpty) {
          appMediaGroups[entry.key] = files;
        }
      }

      // Восстанавливаем время последнего сканирования
      DateTime? lastScanTime;
      final lastScanTimeStr = scanResults['lastScanTime'] as String?;
      if (lastScanTimeStr != null) {
        lastScanTime = DateTime.parse(lastScanTimeStr);
      }

      debugPrint('PERSISTENCE: Загружено результатов - '
          'скриншотов: ${screenshots.length}, '
          'размытых: ${blurry.length}, '
          'Live Photos: ${livePhotos.length}, '
          'групп похожих: ${similarGroups.length}');

      return MediaCleanerReady(
        allFiles: allMediaFiles,
        photoFiles: allMediaFiles.where((f) => f.isImage).toList(),
        videoFiles: allMediaFiles.where((f) => f.isVideo).toList(),
        similarGroups: similarGroups,
        screenshots: screenshots,
        blurry: blurry,
        photoDuplicateGroups: photoDuplicateGroups,
        videoDuplicateGroups: videoDuplicateGroups,
        shortVideos: shortVideos,
        screenRecordings: screenRecordings,
        livePhotos: livePhotos,
        largeVideos: largeVideos,
        appMediaGroups: appMediaGroups,
        lastScanTime: lastScanTime,
        isScanningInBackground: false,
      );
    } catch (e) {
      debugPrint('PERSISTENCE: Ошибка при загрузке результатов сканирования: $e');
      return null;
    }
  }
}
