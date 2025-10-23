import 'dart:async';

import 'package:ai_cleaner_2/feature/cleaner/domain/media_file_entity.dart';
import 'package:ai_cleaner_2/feature/cleaner/domain/media_scanner.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

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
        emit(MediaCleanerError('Для доступа к галерее требуется разрешение'));
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

      emit(
        MediaCleanerLoaded(
          allFiles: mediaFiles,
          photoFiles: mediaFiles.where((f) => f.isImage).toList(),
          videoFiles: mediaFiles.where((f) => f.isVideo).toList(),
        ),
      );
    } catch (e) {
      emit(MediaCleanerError('Ошибка загрузки файлов: $e'));
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

    // Добавляем секундомер для регулярных пауз в обработке
    Stopwatch pauseStopwatch = Stopwatch()..start();
    const pauseIntervalMillis = 5000; // Каждые 5 секунд делаем паузу

    // Вспомогательная функция для обновления статуса с поддержкой пауз для UI
    Future<void> updateStatus(String message, double progressPercent, {int? currentBatch}) async {
      if (emit.isDone) return; // Проверка перед обновлением

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
      await updateStatus("Ai-модель ищет снимки экрана...", 0.05);

      final screenshots = MediaScanner.findScreenshots(currentState.photoFiles);
      currentState = currentState.copyWith(screenshots: screenshots);
      processedFiles += screenshots.length;

      // Отправляем первое обновление после нахождения скриншотов
      await updateStatus(
        "Найдено ${screenshots.length} скриншотов",
        0.1,
        currentBatch: processedFiles,
      );
      debugPrint('СКАНИРОВАНИЕ: Найдено ${screenshots.length} скриншотов');

      // 2. Ищем серии снимков - разбиваем на порции для более плавного UI
      await updateStatus("Ai-модель ищет серии снимков...", 0.15, currentBatch: processedFiles);

      // Разбиваем на порции по 100 фото
      const photoBatchSize = 100;
      List<MediaGroup> allPhotoDuplicateGroups = [];

      for (int i = 0; i < currentState.photoFiles.length; i += photoBatchSize) {
        if (emit.isDone) break;

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
              "Найдено ${allPhotoDuplicateGroups.length} групп дубликатов фото",
              progress,
              currentBatch: processedFiles,
            );
          }
        } else {
          // Если в этой порции ничего не нашли, всё равно обновляем прогресс
          final progress = 0.15 + (0.15 * end / currentState.photoFiles.length);
          await updateStatus(
            "Поиск дубликатов фото (обработано $end/${currentState.photoFiles.length})",
            progress,
            currentBatch: processedFiles + (end - i), // Добавляем проверенные файлы
          );
        }

        // Короткая пауза для отзывчивости UI
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final totalDuplicatesCount = allPhotoDuplicateGroups.fold<int>(
        0,
        (int sum, MediaGroup group) => sum + group.files.length,
      );

      await updateStatus(
        "Найдено ${allPhotoDuplicateGroups.length} групп дубликатов (${totalDuplicatesCount} фото)",
        0.3,
        currentBatch: processedFiles,
      );

      // 3. Ищем похожие фотографии - обновляем UI после каждой найденной группы
      await updateStatus(
        "Ai-модель группирует похожие фотографии...",
        0.35,
        currentBatch: processedFiles,
      );

      // Используем ещё более мелкие порции для анализа похожих фото
      const similarBatchSize = 50; // Уменьшаем размер порции
      List<MediaGroup> allSimilarGroups = [];

      for (int i = 0; i < currentState.photoFiles.length; i += similarBatchSize) {
        if (emit.isDone) break;

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
            final newGroup = MediaGroup(
              id: '${entry.key}_${i ~/ similarBatchSize}_${allSimilarGroups.length}',
              name: 'Похожие фото ${entry.key.split('_').last}',
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
              "Найдено ${allSimilarGroups.length} групп похожих фото",
              progress,
              currentBatch: processedFiles,
            );
          }
        } else {
          // Даже если не нашли группы в порции, всё равно обновляем прогресс
          final progress = 0.35 + (0.15 * end / currentState.photoFiles.length);
          await updateStatus(
            "Поиск похожих фото (обработано ${end}/${currentState.photoFiles.length})",
            progress,
            currentBatch: processedFiles + (end - i), // Добавляем проверенные файлы
          );
        }

        // Пауза между порциями для отзывчивости UI
        await Future.delayed(const Duration(milliseconds: 20));
      }

      final totalSimilarCount = allSimilarGroups.fold<int>(
        0,
        (int sum, MediaGroup group) => sum + group.files.length,
      );

      await updateStatus(
        "Найдено ${allSimilarGroups.length} групп похожих фото (${totalSimilarCount} фото)",
        0.5,
        currentBatch: processedFiles,
      );

      // 4. Находим размытые фотографии - обновляем после каждого найденного
      await updateStatus("Ai-модель ищет заблюренные фото...", 0.55, currentBatch: processedFiles);

      // Ещё меньшие порции для размытых фото
      const blurryBatchSize = 20; // Меньшие порции
      List<MediaFile> allBlurry = [];
      int lastBlurryCount = 0;

      for (int i = 0; i < currentState.photoFiles.length; i += blurryBatchSize) {
        if (emit.isDone) break;

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
            "Найдено ${allBlurry.length} размытых фото (+$newBlurryCount новых)",
            progressValue,
            currentBatch: processedFiles,
          );
        } else {
          // Даже без новых находок обновляем прогресс
          final progressValue = 0.55 + (0.15 * end / currentState.photoFiles.length);

          await updateStatus(
            "Поиск размытых фото (обработано $end/${currentState.photoFiles.length})",
            progressValue,
            currentBatch: processedFiles + (end - i), // Добавляем проверенные файлы
          );
        }

        // Еще более короткая пауза
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // 5. Обрабатываем видео - обновляем после каждой находки
      await updateStatus("Ai-модель анализирует видео...", 0.7, currentBatch: processedFiles);

      // Еще меньше порции для быстрого обновления UI
      const videoBatchSize = 20;
      List<MediaGroup> allVideoDuplicateGroups = [];
      List<MediaFile> allScreenRecordings = [];
      List<MediaFile> allShortVideos = [];

      for (int i = 0; i < currentState.videoFiles.length; i += videoBatchSize) {
        if (emit.isDone) break;

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
            "Найдено ${allVideoDuplicateGroups.length} групп дубликатов видео (+${batchVideoDuplicates.length} новых)",
            progress,
            currentBatch: processedFiles,
          );
        }

        // Находим записи экрана
        final batchScreenRecordings = MediaScanner.findScreenRecordings(videoBatch);
        if (batchScreenRecordings.isNotEmpty) {
          allScreenRecordings.addAll(batchScreenRecordings);

          // Обновляем состояние после каждой новой записи экрана
          currentState = currentState.copyWith(screenRecordings: List.from(allScreenRecordings));

          processedFiles += batchScreenRecordings.length;

          final progress = 0.75 + (0.05 * end / currentState.videoFiles.length);
          await updateStatus(
            "Найдено ${allScreenRecordings.length} записей экрана (+${batchScreenRecordings.length} новых)",
            progress,
            currentBatch: processedFiles,
          );
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
            "Найдено ${allShortVideos.length} коротких видео (+${batchShortVideos.length} новых)",
            progress,
            currentBatch: processedFiles,
          );
        }

        // Если в этой порции ничего не нашли, всё равно обновляем прогресс
        if (batchVideoDuplicates.isEmpty &&
            batchScreenRecordings.isEmpty &&
            batchShortVideos.isEmpty) {
          final progress = 0.7 + (0.15 * end / currentState.videoFiles.length);
          await updateStatus(
            "Анализ видео (обработано $end/${currentState.videoFiles.length})",
            progress,
            currentBatch: processedFiles + (end - i), // Добавляем проверенные файлы к счетчику
          );
        }

        // Пауза для отзывчивости
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Завершающая стадия - финальное обновление
      await updateStatus("Сканирование завершено", 1.0, currentBatch: processedFiles);

      // Завершаем сканирование
      if (!emit.isDone) {
        emit(currentState.copyWith(isScanningInBackground: false, lastScanTime: DateTime.now()));
        debugPrint('СКАНИРОВАНИЕ: Завершено успешно! Обработано $processedFiles файлов');
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
      switch (event.category) {
        case 'Похожие':
          categoryFiles = currentState.similarGroups.expand((group) => group.files).toList();
          break;
        case 'Серии снимков':
          // Логика для дубликатов
          break;
        case 'Снимки экрана':
          categoryFiles = currentState.screenshots;
          break;
        case 'Размытые':
          // Логика для размытых
          break;
        default:
          break;
      }
    } else {
      switch (event.category) {
        case 'Дубликаты':
          // Логика для дубликатов видео
          break;
        case 'Записи экрана':
          categoryFiles = currentState.screenRecordings;
          break;
        case 'Короткие записи':
          categoryFiles = currentState.shortVideos;
          break;
        default:
          break;
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
      // Удаляем выбранные файлы
      await PhotoManager.editor.deleteWithIds(selectedFileIds);

      // Удаляем файлы из списков
      final updatedFiles = currentState.allFiles
          .where((file) => !selectedFileIds.contains(file.entity.id))
          .toList();

      emit(
        currentState.copyWith(
          allFiles: updatedFiles,
          photoFiles: updatedFiles.where((f) => f.isImage).toList(),
          videoFiles: updatedFiles.where((f) => f.isVideo).toList(),
          selectedFiles: [],
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
}
