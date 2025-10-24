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
      final PermissionState permissionState = await PhotoManager.requestPermissionExtend();
      if (!permissionState.hasAccess) {
        emit(MediaCleanerError('Для доступа к галерее требуется разрешение'));
        return;
      }
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
    emit(initialScanState);
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
    bool isPaused = false;
    Stopwatch pauseStopwatch = Stopwatch()..start();
    const pauseIntervalMillis = 5000;
    Future<void> updateStatus(String message, double progressPercent, {int? currentBatch}) async {
      if (emit.isDone) return;
      if (state is MediaCleanerScanning && (state as MediaCleanerScanning).isPaused) {
        isPaused = true;
        return;
      }
      debugPrint(
        '$message: ${currentBatch != null ? "$currentBatch из $totalFiles" : ""} (${(progressPercent * 100).toStringAsFixed(1)}%)',
      );
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
      if (pauseStopwatch.elapsedMilliseconds >= pauseIntervalMillis) {
        debugPrint('СКАНИРОВАНИЕ: Делаем паузу на 200мс для обновления UI');
        await Future.delayed(const Duration(milliseconds: 200));
        pauseStopwatch.reset();
        pauseStopwatch.start();
      }
    }
    try {
      await MediaScanner.initModels();
      debugPrint('СКАНИРОВАНИЕ: Инициализация моделей завершена');
      await updateStatus("Ai-модель ищет снимки экрана...", 0.05);
      final screenshots = MediaScanner.findScreenshots(currentState.photoFiles);
      currentState = currentState.copyWith(screenshots: screenshots);
      processedFiles += screenshots.length;
      await updateStatus(
        "Найдено ${screenshots.length} скриншотов",
        0.1,
        currentBatch: processedFiles,
      );
      debugPrint('СКАНИРОВАНИЕ: Найдено ${screenshots.length} скриншотов');
      await updateStatus("Ai-модель ищет серии снимков...", 0.15, currentBatch: processedFiles);
      const photoBatchSize = 100;
      List<MediaGroup> allPhotoDuplicateGroups = [];
      for (int i = 0; i < currentState.photoFiles.length; i += photoBatchSize) {
        if (emit.isDone || isPaused) break;
        final end = (i + photoBatchSize < currentState.photoFiles.length)
            ? i + photoBatchSize
            : currentState.photoFiles.length;
        final photoBatch = currentState.photoFiles.sublist(i, end);
        debugPrint(
          'СКАНИРОВАНИЕ: Обработка порции дубликатов фото ${i + 1}-$end из ${currentState.photoFiles.length}',
        );
        final batchDuplicates = MediaScanner.findDuplicatePhotos(photoBatch);
        if (batchDuplicates.isNotEmpty) {
          for (final group in batchDuplicates) {
            if (isPaused) break;
            allPhotoDuplicateGroups.add(group);
            currentState = currentState.copyWith(
              photoDuplicateGroups: List.from(allPhotoDuplicateGroups),
            );
            processedFiles += group.files.length;
            final progress =
                0.15 + (0.15 * (i + photoBatchSize / 2) / currentState.photoFiles.length);
            await updateStatus(
              "Найдено ${allPhotoDuplicateGroups.length} групп дубликатов фото",
              progress,
              currentBatch: processedFiles,
            );
            if (isPaused) break;
          }
        } else {
          final progress = 0.15 + (0.15 * end / currentState.photoFiles.length);
          await updateStatus(
            "Поиск дубликатов фото (обработано $end/${currentState.photoFiles.length})",
            progress,
            currentBatch: processedFiles + (end - i),
          );
          if (isPaused) break;
        }
        await Future.delayed(const Duration(milliseconds: 10));
      }
      if (isPaused) {
        debugPrint('СКАНИРОВАНИЕ: Приостановлено пользователем');
        return;
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
      await updateStatus(
        "Ai-модель группирует похожие фотографии...",
        0.35,
        currentBatch: processedFiles,
      );
      const similarBatchSize = 50;
      List<MediaGroup> allSimilarGroups = [];
      for (int i = 0; i < currentState.photoFiles.length; i += similarBatchSize) {
        if (emit.isDone || isPaused) break;
        final end = (i + similarBatchSize < currentState.photoFiles.length)
            ? i + similarBatchSize
            : currentState.photoFiles.length;
        final photoBatch = currentState.photoFiles.sublist(i, end);
        debugPrint(
          'СКАНИРОВАНИЕ: Обработка порции похожих фото ${i + 1}-${end} из ${currentState.photoFiles.length}',
        );
        final similarGroupsMap = await MediaScanner.findSimilarImages(photoBatch);
        if (similarGroupsMap.isNotEmpty) {
          for (final entry in similarGroupsMap.entries) {
            if (isPaused) break;
            final newGroup = MediaGroup(
              id: '${entry.key}_${i ~/ similarBatchSize}_${allSimilarGroups.length}',
              name: '',
              files: entry.value,
            );
            allSimilarGroups.add(newGroup);
            currentState = currentState.copyWith(similarGroups: List.from(allSimilarGroups));
            processedFiles += newGroup.files.length;
            final progress =
                0.35 + (0.15 * ((i + similarBatchSize / 2) / currentState.photoFiles.length));
            await updateStatus(
              "Найдено ${allSimilarGroups.length} групп\nпохожих фото",
              progress,
              currentBatch: processedFiles,
            );
            if (isPaused) break;
          }
        } else {
          final progress = 0.35 + (0.15 * end / currentState.photoFiles.length);
          await updateStatus(
            "Поиск похожих фото (обработано ${end}/${currentState.photoFiles.length})",
            progress,
            currentBatch: processedFiles + (end - i),
          );
          if (isPaused) break;
        }
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
        "Найдено ${allSimilarGroups.length} групп похожих фото (${totalSimilarCount} фото)",
        0.5,
        currentBatch: processedFiles,
      );
      await updateStatus("Ai-модель ищет заблюренные фото...", 0.55, currentBatch: processedFiles);
      const blurryBatchSize = 20;
      List<MediaFile> allBlurry = [];
      int lastBlurryCount = 0;
      for (int i = 0; i < currentState.photoFiles.length; i += blurryBatchSize) {
        if (emit.isDone || isPaused) break;
        final end = (i + blurryBatchSize < currentState.photoFiles.length)
            ? i + blurryBatchSize
            : currentState.photoFiles.length;
        final photoBatch = currentState.photoFiles.sublist(i, end);
        debugPrint(
          'СКАНИРОВАНИЕ: Обработка порции размытых фото ${i + 1}-$end из ${currentState.photoFiles.length}',
        );
        final blurryBatch = await MediaScanner.findBlurryImages(photoBatch);
        if (blurryBatch.isNotEmpty) {
          allBlurry.addAll(blurryBatch);
          currentState = currentState.copyWith(blurry: List.from(allBlurry));
          final newBlurryCount = allBlurry.length - lastBlurryCount;
          lastBlurryCount = allBlurry.length;
          processedFiles += newBlurryCount;
          final progressValue = 0.55 + (0.15 * end / currentState.photoFiles.length);
          await updateStatus(
            "Найдено ${allBlurry.length} размытых фото (+$newBlurryCount новых)",
            progressValue,
            currentBatch: processedFiles,
          );
          if (isPaused) break;
        } else {
          final progressValue = 0.55 + (0.15 * end / currentState.photoFiles.length);
          await updateStatus(
            "Поиск размытых фото (обработано $end/${currentState.photoFiles.length})",
            progressValue,
            currentBatch: processedFiles + (end - i),
          );
          if (isPaused) break;
        }
        await Future.delayed(const Duration(milliseconds: 10));
      }
      if (isPaused) {
        debugPrint('СКАНИРОВАНИЕ: Приостановлено пользователем');
        return;
      }
      await updateStatus("Ai-модель анализирует видео...", 0.7, currentBatch: processedFiles);
      const videoBatchSize = 20;
      List<MediaGroup> allVideoDuplicateGroups = [];
      List<MediaFile> allScreenRecordings = [];
      List<MediaFile> allShortVideos = [];
      for (int i = 0; i < currentState.videoFiles.length; i += videoBatchSize) {
        if (emit.isDone || isPaused) break;
        final end = (i + videoBatchSize < currentState.videoFiles.length)
            ? i + videoBatchSize
            : currentState.videoFiles.length;
        final videoBatch = currentState.videoFiles.sublist(i, end);
        debugPrint(
          'СКАНИРОВАНИЕ: Обработка порции видео ${i + 1}-${end} из ${currentState.videoFiles.length}',
        );
        final batchVideoDuplicates = MediaScanner.findDuplicateVideos(videoBatch);
        if (batchVideoDuplicates.isNotEmpty) {
          allVideoDuplicateGroups.addAll(batchVideoDuplicates);
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
          if (isPaused) break;
        }
        final batchScreenRecordings = MediaScanner.findScreenRecordings(videoBatch);
        if (batchScreenRecordings.isNotEmpty) {
          allScreenRecordings.addAll(batchScreenRecordings);
          currentState = currentState.copyWith(screenRecordings: List.from(allScreenRecordings));
          processedFiles += batchScreenRecordings.length;
          final progress = 0.75 + (0.05 * end / currentState.videoFiles.length);
          await updateStatus(
            "Найдено ${allScreenRecordings.length} записей экрана (+${batchScreenRecordings.length} новых)",
            progress,
            currentBatch: processedFiles,
          );
          if (isPaused) break;
        }
        final batchShortVideos = MediaScanner.findShortVideos(videoBatch);
        if (batchShortVideos.isNotEmpty) {
          allShortVideos.addAll(batchShortVideos);
          currentState = currentState.copyWith(shortVideos: List.from(allShortVideos));
          processedFiles += batchShortVideos.length;
          final progress = 0.8 + (0.05 * end / currentState.videoFiles.length);
          await updateStatus(
            "Найдено ${allShortVideos.length} коротких видео (+${batchShortVideos.length} новых)",
            progress,
            currentBatch: processedFiles,
          );
          if (isPaused) break;
        }
        if (batchVideoDuplicates.isEmpty &&
            batchScreenRecordings.isEmpty &&
            batchShortVideos.isEmpty) {
          final progress = 0.7 + (0.15 * end / currentState.videoFiles.length);
          await updateStatus(
            "Анализ видео (обработано $end/${currentState.videoFiles.length})",
            progress,
            currentBatch: processedFiles + (end - i),
          );
          if (isPaused) break;
        }
        await Future.delayed(const Duration(milliseconds: 10));
      }
      if (isPaused) {
        debugPrint('СКАНИРОВАНИЕ: Приостановлено пользователем');
        return;
      }
      await updateStatus("Сканирование завершено", 1.0, currentBatch: processedFiles);
      if (!emit.isDone) {
        emit(currentState.copyWith(isScanningInBackground: false, lastScanTime: DateTime.now()));
        debugPrint('СКАНИРОВАНИЕ: Завершено успешно! Обработано $processedFiles файлов');
      } else {
        debugPrint(
          'СКАНИРОВАНИЕ: Обработчик событий завершен при попытке отправить финальный статус',
        );
      }
      MediaScanner.disposeModels();
    } catch (e) {
      debugPrint('ОШИБКА при сканировании файлов: $e');
      debugPrint(StackTrace.current.toString());
      if (!emit.isDone) {
        emit(
          currentState.copyWith(
            isScanningInBackground: false,
            scanError: 'Часть файлов не была просканирована: $e',
          ),
        );
      }
      MediaScanner.disposeModels();
    }
  }
  void _onToggleFileSelection(ToggleFileSelection event, Emitter<MediaCleanerState> emit) {
    if (state is! MediaCleanerReady) return;
    final currentState = state as MediaCleanerReady;
    add(ToggleFileSelectionById(event.fileId));
  }
  void _onToggleFileSelectionById(ToggleFileSelectionById event, Emitter<MediaCleanerState> emit) {
    if (state is! MediaCleanerLoaded) return;
    final currentState = state as MediaCleanerLoaded;
    final MediaFile? targetFile = currentState.allFiles
        .where((file) => file.entity.id == event.fileId)
        .firstOrNull;
    if (targetFile == null) return;
    List<MediaFile> newSelectedFiles = [...currentState.selectedFiles];
    final bool isAlreadySelected = newSelectedFiles.any((file) => file.entity.id == event.fileId);
    if (isAlreadySelected) {
      newSelectedFiles.removeWhere((file) => file.entity.id == event.fileId);
    }
    else {
      final updatedFile = targetFile.copyWith(isSelected: true);
      newSelectedFiles.add(updatedFile);
    }
    final updatedFiles = currentState.allFiles.map((file) {
      if (file.entity.id == event.fileId) {
        return file.copyWith(isSelected: !isAlreadySelected);
      }
      return file;
    }).toList();
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
    List<MediaFile> categoryFiles = [];
    if (event.isPhoto) {
      switch (event.category) {
        case 'Похожие':
          categoryFiles = currentState.similarGroups.expand((group) => group.files).toList();
          break;
        case 'Серии снимков':
          break;
        case 'Снимки экрана':
          categoryFiles = currentState.screenshots;
          break;
        case 'Размытые':
          break;
        default:
          break;
      }
    } else {
      switch (event.category) {
        case 'Дубликаты':
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
    final categoryIds = categoryFiles.map((file) => file.entity.id).toList();
    final selectedIds = currentState.selectedFiles.map((file) => file.entity.id).toList();
    final allSelected = categoryIds.every((id) => selectedIds.contains(id));
    List<MediaFile> updatedSelectedFiles;
    List<MediaFile> updatedAllFiles;
    if (allSelected) {
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
    final updatedFiles = currentState.allFiles
        .map((file) => file.copyWith(isSelected: false))
        .toList();
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
      await PhotoManager.editor.deleteWithIds(selectedFileIds);
      final updatedFiles = currentState.allFiles
          .where((file) => !selectedFileIds.contains(file.entity.id))
          .toList();
      final updatedScreenshots = currentState.screenshots
          .where((file) => !selectedFileIds.contains(file.entity.id))
          .toList();
      final updatedBlurry = currentState.blurry
          .where((file) => !selectedFileIds.contains(file.entity.id))
          .toList();
      final updatedScreenRecordings = currentState.screenRecordings
          .where((file) => !selectedFileIds.contains(file.entity.id))
          .toList();
      final updatedShortVideos = currentState.shortVideos
          .where((file) => !selectedFileIds.contains(file.entity.id))
          .toList();
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
  void _onSelectAllFiles(SelectAllFiles event, Emitter<MediaCleanerState> emit) {
    if (state is! MediaCleanerLoaded) return;
    final currentState = state as MediaCleanerLoaded;
    final allSelected = currentState.allFiles.length == currentState.selectedFiles.length;
    if (allSelected) {
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
  void _onSelectAllInGroup(SelectAllInGroup event, Emitter<MediaCleanerState> emit) {
    if (state is! MediaCleanerReady) return;
    final currentState = state as MediaCleanerReady;
    final targetGroup = currentState.similarGroups.firstWhere(
      (group) => group.id == event.groupId,
      orElse: () => MediaGroup(id: '', name: '', files: []),
    );
    if (targetGroup.files.isEmpty) return;
    final allSelected = targetGroup.allSelected;
    final updatedFiles = currentState.allFiles.map((file) {
      if (targetGroup.files.any((groupFile) => groupFile.entity.id == file.entity.id)) {
        return file.copyWith(isSelected: !allSelected);
      }
      return file;
    }).toList();
    List<MediaFile> updatedSelectedFiles;
    if (allSelected) {
      updatedSelectedFiles = currentState.selectedFiles
          .where(
            (file) => !targetGroup.files.any((groupFile) => groupFile.entity.id == file.entity.id),
          )
          .toList();
    } else {
      updatedSelectedFiles = [...currentState.selectedFiles];
      for (final groupFile in targetGroup.files) {
        if (!groupFile.isSelected) {
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
      emit(currentState.copyWith(isPaused: false));
      if (currentState.scanProgress < 1.0) {
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
        _performIncrementalScan(resumeState, emit);
      }
    }
  }
}