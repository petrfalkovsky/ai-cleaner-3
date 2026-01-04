import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';

import '../domain/media_file_entity.dart';
import '../domain/media_metadata_service.dart';

class MediaScanner {
  // Оптимизированный размер батчей для разных операций
  static const int _hashBatchSize = 100; // Для хэширования
  static const int _blurBatchSize = 30; // Для детекции размытия
  static const int _metadataBatchSize = 200; // Для работы с метаданными

  // Лимит одновременных запросов к iOS PHCachingImageManager
  // Предотвращает EXC_BAD_ACCESS при большом количестве параллельных запросов
  static const int _maxConcurrentRequests = 5;

  // Кэш для хэшей изображений (ограничен по размеру)
  static final Map<String, String> _hashCache = {};
  static const int _maxCacheSize = 1000; // Максимум 1000 хэшей в памяти

  // Инициализация моделей больше не требуется - используем только алгоритмы
  static Future<void> initModels() async {
    debugPrint('ОПТИМИЗАЦИЯ: Используем нативные алгоритмы без ML-моделей');
    _hashCache.clear();
  }

  // Освобождение ресурсов
  static void disposeModels() {
    _hashCache.clear();
    _releaseMemory();
  }

  // Вспомогательный метод для освобождения памяти
  static void _releaseMemory() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  // Управление кэшем хэшей
  static void _addToHashCache(String id, String hash) {
    if (_hashCache.length >= _maxCacheSize) {
      // Удаляем старые записи
      final keysToRemove = _hashCache.keys.take(_maxCacheSize ~/ 4).toList();
      for (final key in keysToRemove) {
        _hashCache.remove(key);
      }
    }
    _hashCache[id] = hash;
  }

  // Обработка списка элементов с ограничением параллельности
  // Предотвращает перегрузку iOS PHCachingImageManager
  static Future<List<T>> _processWithLimitedConcurrency<T, R>(
    List<R> items,
    Future<T?> Function(R item) processor,
  ) async {
    final results = <T>[];

    for (int i = 0; i < items.length; i += _maxConcurrentRequests) {
      final chunk = items.skip(i).take(_maxConcurrentRequests).toList();
      final chunkResults = await Future.wait(
        chunk.map((item) => processor(item)),
      );
      results.addAll(chunkResults.whereType<T>());
    }

    return results;
  }

  // УЛУЧШЕННАЯ функция поиска похожих изображений с DCT perceptual hash
  static Future<Map<String, List<MediaFile>>> findSimilarImages(List<MediaFile> files) async {
    final Map<String, List<MediaFile>> similarGroups = {};
    final Map<String, String> imageHashes = {};

    // Делим файлы на батчи для оптимизации памяти
    final int totalFiles = files.length;
    final int numBatches = (totalFiles / _hashBatchSize).ceil();

    debugPrint('ОПТИМИЗАЦИЯ: Обработка $totalFiles фото в $numBatches батчах');

    for (int batchIndex = 0; batchIndex < numBatches; batchIndex++) {
      final int startIdx = batchIndex * _hashBatchSize;
      final int endIdx = min((batchIndex + 1) * _hashBatchSize, totalFiles);
      final batchFiles = files.sublist(startIdx, endIdx);

      // Рассчитываем хэши для текущего батча с ограниченной параллельностью
      final imageFiles = batchFiles.where((f) => f.isImage).toList();
      await _processWithLimitedConcurrency<void, MediaFile>(
        imageFiles,
        (file) async {
          try {
            // Проверяем кэш
            if (_hashCache.containsKey(file.entity.id)) {
              imageHashes[file.entity.id] = _hashCache[file.entity.id]!;
              return;
            }

            // Получаем миниатюру вместо полного файла (экономия памяти)
            final thumbnail = await file.entity.thumbnailDataWithSize(
              const ThumbnailSize(256, 256),
              quality: 70,
            );

            if (thumbnail != null) {
              final hash = await compute(_calculateDCTHash, thumbnail);
              if (hash.isNotEmpty) {
                imageHashes[file.entity.id] = hash;
                _addToHashCache(file.entity.id, hash);
              }
            }
          } catch (e) {
            debugPrint('Ошибка расчета хэша для ${file.entity.id}: $e');
          }
          return null;
        },
      );

      _releaseMemory();
    }

    debugPrint('ОПТИМИЗАЦИЯ: Рассчитано ${imageHashes.length} хэшей');

    // Группируем похожие изображения
    final processed = <String>{};
    int groupCounter = 0;

    for (var file in files.where((f) => f.isImage)) {
      final fileId = file.entity.id;
      if (processed.contains(fileId)) continue;

      final hash1 = imageHashes[fileId];
      if (hash1 == null) continue;

      final similarFiles = <MediaFile>[file];

      // Сравниваем со всеми остальными
      for (var entry in imageHashes.entries) {
        if (entry.key == fileId || processed.contains(entry.key)) continue;

        final similarity = _calculateHashSimilarity(hash1, entry.value);

        // Понижаем порог для DCT hash до 85% для лучшего обнаружения похожих фото
        if (similarity >= 0.85) {
          final otherFile = files.firstWhere(
            (f) => f.entity.id == entry.key,
            orElse: () => file,
          );
          if (otherFile.entity.id != file.entity.id) {
            similarFiles.add(otherFile);
            processed.add(entry.key);
            debugPrint('  Найдено похожее фото: сходство ${(similarity * 100).toStringAsFixed(1)}%');
          }
        }
      }

      if (similarFiles.length > 1) {
        final groupId = 'similar_group_${groupCounter++}';
        similarGroups[groupId] = similarFiles;
      }

      processed.add(fileId);
    }

    debugPrint('ОПТИМИЗАЦИЯ: Найдено ${similarGroups.length} групп\nпохожих');
    return similarGroups;
  }

  // DCT (Discrete Cosine Transform) perceptual hash - более точный и быстрый
  static String _calculateDCTHash(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return '';

      // Resize к 32x32 для лучшей точности
      final resized = img.copyResize(image, width: 32, height: 32);
      final gray = img.grayscale(resized);

      // Упрощенный DCT для 8x8 области
      final dctVals = <double>[];
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          double sum = 0;
          for (int v = 0; v < 32; v++) {
            for (int u = 0; u < 32; u++) {
              final pixel = gray.getPixel(u, v);
              final intensity = img.getLuminance(pixel).toDouble();
              final angle = pi * (2 * u + 1) * x / (2 * 32) +
                           pi * (2 * v + 1) * y / (2 * 32);
              sum += intensity * cos(angle);
            }
          }
          dctVals.add(sum / 32);
        }
      }

      // Вычисляем среднее (игнорируя DC компонент)
      final avg = dctVals.skip(1).reduce((a, b) => a + b) / (dctVals.length - 1);

      // Создаем хэш
      return dctVals.skip(1).map((v) => v > avg ? '1' : '0').join();
    } catch (e) {
      debugPrint('Ошибка DCT hash: $e');
      return '';
    }
  }

  // Hamming distance для сравнения хэшей
  static double _calculateHashSimilarity(String hash1, String hash2) {
    if (hash1.length != hash2.length || hash1.isEmpty) return 0.0;

    int matches = 0;
    for (int i = 0; i < hash1.length; i++) {
      if (hash1[i] == hash2[i]) matches++;
    }

    return matches / hash1.length;
  }

  // ОПТИМИЗИРОВАННАЯ детекция размытых изображений
  static Future<List<MediaFile>> findBlurryImages(List<MediaFile> files) async {
    final blurryImages = <MediaFile>[];

    final int totalFiles = files.where((f) => f.isImage).length;
    final int numBatches = (totalFiles / _blurBatchSize).ceil();
    final imageFiles = files.where((f) => f.isImage).toList();

    debugPrint('ОПТИМИЗАЦИЯ: Анализ размытия $totalFiles фото в $numBatches батчах');

    for (int batchIndex = 0; batchIndex < numBatches; batchIndex++) {
      final int startIdx = batchIndex * _blurBatchSize;
      final int endIdx = min((batchIndex + 1) * _blurBatchSize, imageFiles.length);
      final batchFiles = imageFiles.sublist(startIdx, endIdx);

      // Обработка батча с ограниченной параллельностью
      final batchResults = await _processWithLimitedConcurrency<MediaFile, MediaFile>(
        batchFiles,
        (file) async {
          try {
            // Используем миниатюру для экономии памяти
            final thumbnail = await file.entity.thumbnailDataWithSize(
              const ThumbnailSize(400, 400),
              quality: 85,
            );

            if (thumbnail != null) {
              final blurScore = await compute(_calculateBlurScore, thumbnail);

              // Пороговое значение (чем меньше, тем более размыто)
              if (blurScore < 120.0) {
                return file.copyWith(category: 'blurry');
              }
            }
          } catch (e) {
            debugPrint('Ошибка анализа размытия ${file.entity.id}: $e');
          }
          return null;
        },
      );

      blurryImages.addAll(batchResults);
      _releaseMemory();
    }

    debugPrint('ОПТИМИЗАЦИЯ: Найдено ${blurryImages.length} размытых фото');
    return blurryImages;
  }

  // Улучшенный Laplacian variance для детекции размытия
  static double _calculateBlurScore(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return 1000.0;

      // Уменьшаем до 200px для быстрой обработки
      final resized = img.copyResize(image, width: 200, height: 200);
      final gray = img.grayscale(resized);

      // Применяем Laplacian оператор
      double variance = 0.0;
      int count = 0;

      for (int y = 1; y < gray.height - 1; y++) {
        for (int x = 1; x < gray.width - 1; x++) {
          final center = img.getLuminance(gray.getPixel(x, y)).toDouble();
          final top = img.getLuminance(gray.getPixel(x, y - 1)).toDouble();
          final bottom = img.getLuminance(gray.getPixel(x, y + 1)).toDouble();
          final left = img.getLuminance(gray.getPixel(x - 1, y)).toDouble();
          final right = img.getLuminance(gray.getPixel(x + 1, y)).toDouble();

          // Laplacian = -4*center + top + bottom + left + right
          final lap = -4 * center + top + bottom + left + right;
          variance += lap * lap;
          count++;
        }
      }

      return count > 0 ? variance / count : 0.0;
    } catch (e) {
      debugPrint('Ошибка расчета blur score: $e');
      return 1000.0;
    }
  }

  // ОПТИМИЗИРОВАННЫЙ поиск скриншотов - только по iOS метаданным
  static List<MediaFile> findScreenshots(List<MediaFile> files) {
    final screenshots = <MediaFile>[];

    debugPrint('ОПТИМИЗАЦИЯ: Поиск скриншотов среди ${files.length} файлов');

    for (final file in files) {
      if (!file.isImage) continue;

      // iOS помечает скриншоты через PHAssetMediaSubtype.screenshot (бит 4 = 1 << 2)
      // В photo_manager это доступно через entity.subtype
      final isIOSScreenshot = (file.entity.subtype & 4) != 0;

      if (isIOSScreenshot) {
        screenshots.add(file.copyWith(category: 'screenshots'));
        debugPrint('Найден скриншот (iOS metadata): ${file.entity.title}');
      }
    }

    debugPrint('ОПТИМИЗАЦИЯ: Найдено ${screenshots.length} скриншотов');
    return screenshots;
  }

  // ОБНОВЛЕННЫЙ поиск записей экрана - использует нативные iOS метаданные
  static Future<List<MediaFile>> findScreenRecordings(List<MediaFile> files) async {
    final screenRecordings = <MediaFile>[];
    final videoFiles = files.where((f) => f.isVideo).toList();

    debugPrint('ОПТИМИЗАЦИЯ: Поиск записей экрана среди ${videoFiles.length} видео');

    // Обрабатываем видео батчами для оптимизации
    const batchSize = 20;
    for (int i = 0; i < videoFiles.length; i += batchSize) {
      final end = min(i + batchSize, videoFiles.length);
      final batch = videoFiles.sublist(i, end);

      // Получаем метаданные для каждого видео в батче с ограниченной параллельностью
      final batchResults = await _processWithLimitedConcurrency<MediaFile, MediaFile>(
        batch,
        (file) async {
          try {
            // СНАЧАЛА проверяем уже загруженные метаданные
            bool isScreenRecording = file.isScreenRecording;

            // Если метаданных нет, запрашиваем их из нативного кода
            if (file.metadata == null) {
              final metadata = await MediaMetadataService.getMediaMetadata(file.entity.id);

              if (metadata != null) {
                // Создаем новый файл с метаданными
                final fileWithMetadata = file.copyWith(metadata: metadata);
                isScreenRecording = fileWithMetadata.isScreenRecording;

                if (isScreenRecording) {
                  final originalFilename = metadata['originalFilename'] ?? file.entity.title ?? '';
                  debugPrint('✓ Найдена запись экрана (iOS metadata): $originalFilename');
                  return fileWithMetadata.copyWith(category: 'screenRecordings');
                }
              }
            } else if (isScreenRecording) {
              // Метаданные уже есть и указывают, что это запись экрана
              final originalFilename = file.metadata!['originalFilename'] ?? file.entity.title ?? '';
              debugPrint('✓ Найдена запись экрана (cached metadata): $originalFilename');
              return file.copyWith(category: 'screenRecordings');
            }

            // Fallback: если метаданные недоступны, проверяем по имени файла
            // Это нужно для Android или если iOS API недоступен
            if (file.metadata == null) {
              final title = file.entity.title ?? '';
              final titleLower = title.toLowerCase();

              // Проверяем ТОЛЬКО надёжные префиксы для iOS
              final isScreenRecordingByName = titleLower.startsWith('rpreplay') ||
                                            titleLower.startsWith('screen recording');

              if (isScreenRecordingByName) {
                debugPrint('✓ Найдена запись экрана (fallback по имени): $title');
                return file.copyWith(category: 'screenRecordings');
              }
            }
          } catch (e) {
            debugPrint('Ошибка проверки записи экрана для ${file.entity.id}: $e');
          }

          return null;
        },
      );

      screenRecordings.addAll(batchResults);

      // Небольшая пауза между батчами
      if (i + batchSize < videoFiles.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    debugPrint('ОПТИМИЗАЦИЯ: Найдено ${screenRecordings.length} записей экрана');
    return screenRecordings;
  }

  // ОБНОВЛЕННЫЙ поиск коротких видео - до 2 секунд
  static List<MediaFile> findShortVideos(List<MediaFile> files) {
    final shortVideos = <MediaFile>[];

    debugPrint('ОПТИМИЗАЦИЯ: Поиск коротких видео среди ${files.where((f) => f.isVideo).length} видео');

    for (final file in files) {
      if (!file.isVideo) continue;

      // Видео короче или равно 2 секунд
      if (file.entity.duration != null && file.entity.duration! <= 2) {
        shortVideos.add(file.copyWith(category: 'shortVideos'));
      }
    }

    debugPrint('ОПТИМИЗАЦИЯ: Найдено ${shortVideos.length} коротких видео');
    return shortVideos;
  }

  // ОПТИМИЗИРОВАННЫЙ поиск дубликатов фото - метаданные + дата создания
  static List<MediaGroup> findDuplicatePhotos(List<MediaFile> files) {
    final Map<String, List<MediaFile>> duplicateGroups = {};
    final Map<String, MediaFile> signatureMap = {};

    final imageFiles = files.where((f) => f.isImage).toList();
    debugPrint('ОПТИМИЗАЦИЯ: Поиск дубликатов среди ${imageFiles.length} фото');

    for (final file in imageFiles) {
      // Сигнатура: размер файла + разрешение + дата создания (с точностью до минуты)
      // Расширяем точность до минуты, так как некоторые дубликаты могут быть созданы в разные секунды
      final createDate = file.entity.createDateTime.millisecondsSinceEpoch ~/ 60000; // Минуты
      final signature = '${file.entity.size}|${file.entity.width}|${file.entity.height}|$createDate';

      if (signatureMap.containsKey(signature)) {
        if (duplicateGroups.containsKey(signature)) {
          duplicateGroups[signature]!.add(file);
          debugPrint('  Добавлено в группу дубликатов: ${file.entity.title} (размер: ${file.entity.size}, разрешение: ${file.entity.width}x${file.entity.height})');
        } else {
          duplicateGroups[signature] = [signatureMap[signature]!, file];
          debugPrint('  Создана новая группа дубликатов: ${signatureMap[signature]!.entity.title} + ${file.entity.title}');
        }
      } else {
        signatureMap[signature] = file;
      }
    }

    // Преобразуем в MediaGroup
    final List<MediaGroup> result = [];
    int groupCounter = 0;

    duplicateGroups.forEach((signature, groupFiles) {
      if (groupFiles.length > 1) {
        result.add(
          MediaGroup(
            id: 'dup_${groupCounter++}',
            name: '',
            files: groupFiles,
          ),
        );
        debugPrint('  Группа дубликатов #$groupCounter: ${groupFiles.length} файлов');
      }
    });

    debugPrint('ОПТИМИЗАЦИЯ: Найдено ${result.length} групп дубликатов фото (всего ${duplicateGroups.values.fold(0, (sum, group) => sum + group.length)} файлов)');
    return result;
  }

  // ОПТИМИЗИРОВАННЫЙ поиск дубликатов видео - метаданные
  static List<MediaGroup> findDuplicateVideos(List<MediaFile> files) {
    final Map<String, List<MediaFile>> duplicateGroups = {};
    final Map<String, MediaFile> signatureMap = {};

    final videoFiles = files.where((f) => f.isVideo).toList();
    debugPrint('ОПТИМИЗАЦИЯ: Поиск дубликатов среди ${videoFiles.length} видео');

    for (final file in videoFiles) {
      // Сигнатура: размер файла + длительность + дата создания (с точностью до минуты)
      final duration = file.entity.duration ?? 0;
      final createDate = file.entity.createDateTime.millisecondsSinceEpoch ~/ 60000; // Минуты
      final signature = '${file.entity.size}|$duration|$createDate';

      if (signatureMap.containsKey(signature)) {
        if (duplicateGroups.containsKey(signature)) {
          duplicateGroups[signature]!.add(file);
          debugPrint('  Добавлено в группу дубликатов видео: ${file.entity.title} (размер: ${file.entity.size}, длительность: $duration сек)');
        } else {
          duplicateGroups[signature] = [signatureMap[signature]!, file];
          debugPrint('  Создана новая группа дубликатов видео: ${signatureMap[signature]!.entity.title} + ${file.entity.title}');
        }
      } else {
        signatureMap[signature] = file;
      }
    }

    // Преобразуем в MediaGroup
    final List<MediaGroup> result = [];
    int groupCounter = 0;

    duplicateGroups.forEach((signature, groupFiles) {
      if (groupFiles.length > 1) {
        result.add(
          MediaGroup(
            id: 'vdup_${groupCounter++}',
            name: 'Видео-дубликаты ${groupCounter}',
            files: groupFiles,
          ),
        );
        debugPrint('  Группа дубликатов видео #$groupCounter: ${groupFiles.length} файлов');
      }
    });

    debugPrint('ОПТИМИЗАЦИЯ: Найдено ${result.length} групп дубликатов видео (всего ${duplicateGroups.values.fold(0, (sum, group) => sum + group.length)} файлов)');
    return result;
  }

  // Поиск Live Photos - используя iOS метаданные
  static List<MediaFile> findLivePhotos(List<MediaFile> files) {
    final livePhotos = <MediaFile>[];

    debugPrint('ОПТИМИЗАЦИЯ: Поиск Live Photos среди ${files.length} файлов');

    for (final file in files) {
      if (!file.isImage) continue;

      // iOS помечает Live Photos через PHAssetMediaSubtype.photoLive (бит 3 = 1 << 3 = 8)
      // В photo_manager это доступно через entity.subtype
      final isLivePhoto = (file.entity.subtype & 8) != 0;

      if (isLivePhoto) {
        livePhotos.add(file.copyWith(category: 'livePhotos'));
        debugPrint('Найдено Live Photo: ${file.entity.title}');
      }
    }

    debugPrint('ОПТИМИЗАЦИЯ: Найдено ${livePhotos.length} Live Photos');
    return livePhotos;
  }

  // Поиск больших видео (>180MB)
  static Future<List<MediaFile>> findLargeVideos(List<MediaFile> files) async {
    final largeVideos = <MediaFile>[];
    const int largeSizeThreshold = 180 * 1024 * 1024; // 180 MB в байтах

    debugPrint('ОПТИМИЗАЦИЯ: Поиск больших видео (>180MB) среди ${files.where((f) => f.isVideo).length} видео');

    for (final file in files) {
      if (!file.isVideo) continue;

      try {
        // Получаем файл для определения размера
        final assetFile = await file.entity.file;
        if (assetFile == null) continue;

        final fileSize = await assetFile.length();

        // Проверяем размер файла
        if (fileSize >= largeSizeThreshold) {
          largeVideos.add(file.copyWith(category: 'largeVideos'));
          final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
          debugPrint('Найдено большое видео: ${file.entity.title} (${sizeMB}MB)');
        }
      } catch (e) {
        debugPrint('Ошибка при проверке размера видео ${file.entity.id}: $e');
      }
    }

    debugPrint('ОПТИМИЗАЦИЯ: Найдено ${largeVideos.length} больших видео');
    return largeVideos;
  }

  // Поиск медиа из приложений (WhatsApp, Instagram, Telegram и т.д.)
  static Map<String, List<MediaFile>> findAppSpecificMedia(List<MediaFile> files) {
    final Map<String, List<MediaFile>> appGroups = {};

    debugPrint('ОПТИМИЗАЦИЯ: Поиск медиа из приложений среди ${files.length} файлов');

    // Определяем паттерны для каждого приложения
    final appPatterns = {
      'WhatsApp': [
        'whatsapp',
        'wa_',
        '.wa.',
      ],
      'Instagram': [
        'instagram',
        'insta_',
        '.insta.',
      ],
      'Telegram': [
        'telegram',
        'tg_',
        '.tg.',
      ],
      'Messenger': [
        'messenger',
        'fb_messenger',
        'fbm_',
      ],
      'Snapchat': [
        'snapchat',
        'snap_',
        '.snap.',
      ],
    };

    for (final file in files) {
      final title = file.entity.title?.toLowerCase() ?? '';

      // Проверяем каждое приложение
      for (final entry in appPatterns.entries) {
        final appName = entry.key;
        final patterns = entry.value;

        // Проверяем, соответствует ли имя файла одному из паттернов
        final matches = patterns.any((pattern) => title.contains(pattern));

        if (matches) {
          if (!appGroups.containsKey(appName)) {
            appGroups[appName] = [];
          }
          appGroups[appName]!.add(file.copyWith(category: 'app_$appName'));
          debugPrint('Найден файл из $appName: ${file.entity.title}');
          break; // Выходим из цикла, чтобы не добавлять файл в несколько групп
        }
      }
    }

    // Выводим статистику по каждому приложению
    appGroups.forEach((appName, files) {
      debugPrint('ОПТИМИЗАЦИЯ: Найдено ${files.length} файлов из $appName');
    });

    return appGroups;
  }
}
