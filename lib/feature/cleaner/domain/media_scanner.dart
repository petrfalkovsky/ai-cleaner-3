import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import '../domain/media_file_entity.dart';
class MediaScanner {
  static const int _hashBatchSize = 100;
  static const int _blurBatchSize = 30;
  static const int _metadataBatchSize = 200;
  static final Map<String, String> _hashCache = {};
  static const int _maxCacheSize = 1000;
  static Future<void> initModels() async {
    debugPrint('ОПТИМИЗАЦИЯ: Используем нативные алгоритмы без ML-моделей');
    _hashCache.clear();
  }
  static void disposeModels() {
    _hashCache.clear();
    _releaseMemory();
  }
  static void _releaseMemory() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }
  static void _addToHashCache(String id, String hash) {
    if (_hashCache.length >= _maxCacheSize) {
      final keysToRemove = _hashCache.keys.take(_maxCacheSize ~/ 4).toList();
      for (final key in keysToRemove) {
        _hashCache.remove(key);
      }
    }
    _hashCache[id] = hash;
  }
  static Future<Map<String, List<MediaFile>>> findSimilarImages(List<MediaFile> files) async {
    final Map<String, List<MediaFile>> similarGroups = {};
    final Map<String, String> imageHashes = {};
    final int totalFiles = files.length;
    final int numBatches = (totalFiles / _hashBatchSize).ceil();
    debugPrint('ОПТИМИЗАЦИЯ: Обработка $totalFiles фото в $numBatches батчах');
    for (int batchIndex = 0; batchIndex < numBatches; batchIndex++) {
      final int startIdx = batchIndex * _hashBatchSize;
      final int endIdx = min((batchIndex + 1) * _hashBatchSize, totalFiles);
      final batchFiles = files.sublist(startIdx, endIdx);
      await Future.wait(
        batchFiles.where((f) => f.isImage).map((file) async {
          try {
            if (_hashCache.containsKey(file.entity.id)) {
              imageHashes[file.entity.id] = _hashCache[file.entity.id]!;
              return;
            }
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
        }),
      );
      _releaseMemory();
    }
    debugPrint('ОПТИМИЗАЦИЯ: Рассчитано ${imageHashes.length} хэшей');
    final processed = <String>{};
    int groupCounter = 0;
    for (var file in files.where((f) => f.isImage)) {
      final fileId = file.entity.id;
      if (processed.contains(fileId)) continue;
      final hash1 = imageHashes[fileId];
      if (hash1 == null) continue;
      final similarFiles = <MediaFile>[file];
      for (var entry in imageHashes.entries) {
        if (entry.key == fileId || processed.contains(entry.key)) continue;
        final similarity = _calculateHashSimilarity(hash1, entry.value);
        if (similarity >= 0.90) {
          final otherFile = files.firstWhere(
            (f) => f.entity.id == entry.key,
            orElse: () => file,
          );
          if (otherFile.entity.id != file.entity.id) {
            similarFiles.add(otherFile);
            processed.add(entry.key);
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
  static String _calculateDCTHash(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return '';
      final resized = img.copyResize(image, width: 32, height: 32);
      final gray = img.grayscale(resized);
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
      final avg = dctVals.skip(1).reduce((a, b) => a + b) / (dctVals.length - 1);
      return dctVals.skip(1).map((v) => v > avg ? '1' : '0').join();
    } catch (e) {
      debugPrint('Ошибка DCT hash: $e');
      return '';
    }
  }
  static double _calculateHashSimilarity(String hash1, String hash2) {
    if (hash1.length != hash2.length || hash1.isEmpty) return 0.0;
    int matches = 0;
    for (int i = 0; i < hash1.length; i++) {
      if (hash1[i] == hash2[i]) matches++;
    }
    return matches / hash1.length;
  }
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
      final batchResults = await Future.wait(
        batchFiles.map((file) async {
          try {
            final thumbnail = await file.entity.thumbnailDataWithSize(
              const ThumbnailSize(400, 400),
              quality: 85,
            );
            if (thumbnail != null) {
              final blurScore = await compute(_calculateBlurScore, thumbnail);
              if (blurScore < 120.0) {
                return file.copyWith(category: 'blurry');
              }
            }
          } catch (e) {
            debugPrint('Ошибка анализа размытия ${file.entity.id}: $e');
          }
          return null;
        }),
      );
      blurryImages.addAll(batchResults.whereType<MediaFile>());
      _releaseMemory();
    }
    debugPrint('ОПТИМИЗАЦИЯ: Найдено ${blurryImages.length} размытых фото');
    return blurryImages;
  }
  static double _calculateBlurScore(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return 1000.0;
      final resized = img.copyResize(image, width: 200, height: 200);
      final gray = img.grayscale(resized);
      double variance = 0.0;
      int count = 0;
      for (int y = 1; y < gray.height - 1; y++) {
        for (int x = 1; x < gray.width - 1; x++) {
          final center = img.getLuminance(gray.getPixel(x, y)).toDouble();
          final top = img.getLuminance(gray.getPixel(x, y - 1)).toDouble();
          final bottom = img.getLuminance(gray.getPixel(x, y + 1)).toDouble();
          final left = img.getLuminance(gray.getPixel(x - 1, y)).toDouble();
          final right = img.getLuminance(gray.getPixel(x + 1, y)).toDouble();
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
  static List<MediaFile> findScreenshots(List<MediaFile> files) {
    final screenshots = <MediaFile>[];
    debugPrint('ОПТИМИЗАЦИЯ: Поиск скриншотов среди ${files.length} файлов');
    for (final file in files) {
      if (!file.isImage) continue;
      final isIOSScreenshot = (file.entity.subtype & 4) != 0;
      if (isIOSScreenshot) {
        screenshots.add(file.copyWith(category: 'screenshots'));
        debugPrint('Найден скриншот (iOS metadata): ${file.entity.title}');
      }
    }
    debugPrint('ОПТИМИЗАЦИЯ: Найдено ${screenshots.length} скриншотов');
    return screenshots;
  }
  static List<MediaFile> findScreenRecordings(List<MediaFile> files) {
    final screenRecordings = <MediaFile>[];
    debugPrint('ОПТИМИЗАЦИЯ: Поиск записей экрана среди ${files.where((f) => f.isVideo).length} видео');
    for (final file in files) {
      if (!file.isVideo) continue;
      final title = file.entity.title ?? '';
      final titleLower = title.toLowerCase();
      final relativePath = file.entity.relativePath?.toLowerCase() ?? '';
      final isScreenRecording = titleLower.contains('rpreplay') ||
                                titleLower.contains('replaykit') ||
                                titleLower.contains('screen recording') ||
                                titleLower.startsWith('screen ') ||
                                relativePath.contains('replaykit');
      if (isScreenRecording) {
        screenRecordings.add(file.copyWith(category: 'screenRecordings'));
        debugPrint('✓ Найдена запись экрана: $title (путь: $relativePath)');
      } else {
        if (screenRecordings.length < 5) {
          debugPrint('  Пропущено видео: $title (путь: $relativePath)');
        }
      }
    }
    debugPrint('ОПТИМИЗАЦИЯ: Найдено ${screenRecordings.length} записей экрана');
    return screenRecordings;
  }
  static List<MediaFile> findShortVideos(List<MediaFile> files) {
    final shortVideos = <MediaFile>[];
    debugPrint('ОПТИМИЗАЦИЯ: Поиск коротких видео среди ${files.where((f) => f.isVideo).length} видео');
    for (final file in files) {
      if (!file.isVideo) continue;
      if (file.entity.duration != null && file.entity.duration! <= 2) {
        shortVideos.add(file.copyWith(category: 'shortVideos'));
      }
    }
    debugPrint('ОПТИМИЗАЦИЯ: Найдено ${shortVideos.length} коротких видео');
    return shortVideos;
  }
  static List<MediaGroup> findDuplicatePhotos(List<MediaFile> files) {
    final Map<String, List<MediaFile>> duplicateGroups = {};
    final Map<String, MediaFile> signatureMap = {};
    debugPrint('ОПТИМИЗАЦИЯ: Поиск дубликатов среди ${files.where((f) => f.isImage).length} фото');
    for (final file in files) {
      if (!file.isImage) continue;
      final createDate = file.entity.createDateTime.millisecondsSinceEpoch ~/ 1000;
      final signature = '${file.entity.size}|${file.entity.width}|${file.entity.height}|$createDate';
      if (signatureMap.containsKey(signature)) {
        if (duplicateGroups.containsKey(signature)) {
          duplicateGroups[signature]!.add(file);
        } else {
          duplicateGroups[signature] = [signatureMap[signature]!, file];
        }
      } else {
        signatureMap[signature] = file;
      }
    }
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
      }
    });
    debugPrint('ОПТИМИЗАЦИЯ: Найдено ${result.length} групп дубликатов фото');
    return result;
  }
  static List<MediaGroup> findDuplicateVideos(List<MediaFile> files) {
    final Map<String, List<MediaFile>> duplicateGroups = {};
    final Map<String, MediaFile> signatureMap = {};
    debugPrint('ОПТИМИЗАЦИЯ: Поиск дубликатов среди ${files.where((f) => f.isVideo).length} видео');
    for (final file in files) {
      if (!file.isVideo) continue;
      final duration = file.entity.duration ?? 0;
      final createDate = file.entity.createDateTime.millisecondsSinceEpoch ~/ 1000;
      final signature = '${file.entity.size}|$duration|$createDate';
      if (signatureMap.containsKey(signature)) {
        if (duplicateGroups.containsKey(signature)) {
          duplicateGroups[signature]!.add(file);
        } else {
          duplicateGroups[signature] = [signatureMap[signature]!, file];
        }
      } else {
        signatureMap[signature] = file;
      }
    }
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
      }
    });
    debugPrint('ОПТИМИЗАЦИЯ: Найдено ${result.length} групп дубликатов видео');
    return result;
  }
}