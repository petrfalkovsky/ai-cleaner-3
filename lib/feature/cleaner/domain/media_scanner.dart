import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../domain/media_file_entity.dart';

class MediaScanner {
  static Interpreter? _blurDetectionInterpreter;
  static const int _batchSize = 50; // Обрабатываем файлы порциями

  // Инициализация моделей TFLite
  static Future<void> initModels() async {
    try {
      if (_blurDetectionInterpreter == null) {
        final options = InterpreterOptions()..threads = 2; // Ограничиваем количество потоков
        _blurDetectionInterpreter = await Interpreter.fromAsset(
          'assets/models/blur_detection.tflite',
          options: options,
        );
      }
    } catch (e) {
      debugPrint('Error loading TFLite models: $e');
    }
  }

  // Освобождение ресурсов
  static void disposeModels() {
    _blurDetectionInterpreter?.close();
    _blurDetectionInterpreter = null;
    // Вызываем сборщик мусора
    _releaseMemory();
  }

  // Вспомогательный метод для освобождения памяти
  static void _releaseMemory() {
    // Это подсказка для сборщика мусора
    imageCache.clear();
    imageCache.clearLiveImages();

    // Программно вызвать сборку мусора нельзя напрямую в Dart,
    // но можно подсказать системе, что стоит это сделать
  }

  // Функция поиска похожих изображений - оптимизирована для работы батчами
  static Future<Map<String, List<MediaFile>>> findSimilarImages(List<MediaFile> files) async {
    final Map<String, List<MediaFile>> similarGroups = {};
    final Map<String, String> imageHashes = {};

    // Делим файлы на батчи для уменьшения потребления памяти
    final int totalFiles = files.length;
    final int numBatches = (totalFiles / _batchSize).ceil();

    for (int batchIndex = 0; batchIndex < numBatches; batchIndex++) {
      final int startIdx = batchIndex * _batchSize;
      final int endIdx = min((batchIndex + 1) * _batchSize, totalFiles);
      final batchFiles = files.sublist(startIdx, endIdx);

      // Рассчитываем хэши для текущего батча
      for (var file in batchFiles) {
        if (file.isImage) {
          try {
            final imageFile = await file.entity.file;
            if (imageFile != null) {
              final bytes = await imageFile.readAsBytes();
              final hash = await compute(_calculateSimpleHash, bytes);
              imageHashes[file.entity.id] = hash;
            }
          } catch (e) {
            debugPrint('Error calculating hash for ${file.entity.id}: $e');
          }
        }
      }

      // Освобождаем ресурсы после каждого батча
      _releaseMemory();
    }

    // Теперь сравниваем хэши и группируем похожие изображения
    final processed = <String>{};
    int groupCounter = 0;

    // Снова обрабатываем батчами для сравнения
    for (int batchIndex = 0; batchIndex < numBatches; batchIndex++) {
      final int startIdx = batchIndex * _batchSize;
      final int endIdx = min((batchIndex + 1) * _batchSize, totalFiles);
      final batchFiles = files.sublist(startIdx, endIdx);

      for (var file in batchFiles) {
        final fileId = file.entity.id;

        if (!file.isImage || processed.contains(fileId)) continue;

        final hash1 = imageHashes[fileId];
        if (hash1 == null) continue;

        final similarFiles = <MediaFile>[file];

        // Сравниваем со всеми остальными хэшами
        for (var entry in imageHashes.entries) {
          if (entry.key == fileId || processed.contains(entry.key)) continue;

          final hash2 = entry.value;
          final similarity = _calculateHashSimilarity(hash1, hash2);

          if (similarity >= 0.85) {
            // Порог сходства 85%
            // Найдем соответствующий файл
            final otherFile = files.firstWhere((f) => f.entity.id == entry.key, orElse: () => file);
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

      // Освобождаем ресурсы после каждого батча сравнения
      _releaseMemory();
    }

    // Очищаем память после использования
    imageHashes.clear();
    return similarGroups;
  }

  // Оптимизированный метод для расчета хэша
  static Future<String> _calculateSimpleHash(Uint8List bytes) async {
    try {
      // Декодируем изображение
      final image = img.decodeImage(bytes);
      if (image == null) return '';

      // Уменьшаем изображение до 8x8 для хэширования
      final resized = img.copyResize(image, width: 8, height: 8, maintainAspect: false);

      // Преобразуем в оттенки серого
      final grayImage = img.grayscale(resized);

      final pixels = <int>[];
      double sum = 0.0;

      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final pixel = grayImage.getPixel(x, y);
          final gray = img.getLuminance(pixel).round();
          pixels.add(gray);
          sum += gray;
        }
      }

      // Вычисляем средний цвет
      final avg = sum / 64;

      // Создаем хэш: 1 если пиксель > среднего, 0 если <= среднего
      final hashBits = StringBuffer();
      for (final p in pixels) {
        hashBits.write(p > avg ? '1' : '0');
      }

      return hashBits.toString();
    } catch (e) {
      debugPrint('Error in hash calculation: $e');
      return '';
    }
  }

  // Сравниваем хэши изображений
  static double _calculateHashSimilarity(String hash1, String hash2) {
    if (hash1.length != hash2.length) return 0.0;

    int matches = 0;
    for (int i = 0; i < hash1.length; i++) {
      if (hash1[i] == hash2[i]) matches++;
    }

    return matches / hash1.length;
  }

  // Определение размытых изображений - оптимизировано для работы батчами
  static Future<List<MediaFile>> findBlurryImages(List<MediaFile> files) async {
    final blurryImages = <MediaFile>[];

    // Обрабатываем файлы батчами
    final int totalFiles = files.length;
    final int numBatches = (totalFiles / _batchSize).ceil();

    for (int batchIndex = 0; batchIndex < numBatches; batchIndex++) {
      final int startIdx = batchIndex * _batchSize;
      final int endIdx = min((batchIndex + 1) * _batchSize, totalFiles);
      final batchFiles = files.sublist(startIdx, endIdx);

      // Используем isolate для параллельной обработки батча
      final batchResults = await Future.wait(
        batchFiles.map((file) async {
          if (!file.isImage) return null;

          try {
            final imageFile = await file.entity.file;
            if (imageFile != null) {
              final bytes = await imageFile.readAsBytes();
              final isBlurry = await compute(_isImageBlurry, bytes);

              if (isBlurry) {
                return file.copyWith(category: 'blurry');
              }
            }
          } catch (e) {
            debugPrint('Error analyzing blur for ${file.entity.id}: $e');
          }

          return null;
        }),
      );

      // Фильтруем null значения и добавляем результаты
      blurryImages.addAll(batchResults.whereType<MediaFile>());

      // Освобождаем ресурсы после каждого батча
      _releaseMemory();
    }

    return blurryImages;
  }

  // Оптимизированный метод оценки размытости изображения
  static Future<bool> _isImageBlurry(Uint8List bytes) async {
    try {
      // Декодируем изображение
      final rawImage = img.decodeImage(bytes);
      if (rawImage == null) return false;

      // Сильно уменьшаем для анализа - максимум 320px по большей стороне
      int targetWidth, targetHeight;
      if (rawImage.width > rawImage.height) {
        targetWidth = 320;
        targetHeight = (rawImage.height * (320 / rawImage.width)).round();
      } else {
        targetHeight = 320;
        targetWidth = (rawImage.width * (320 / rawImage.height)).round();
      }

      final image = img.copyResize(rawImage, width: targetWidth, height: targetHeight);

      final gray = img.grayscale(image);

      // Используем алгоритм Лапласиана для оценки резкости
      final laplacian = _computeLaplacian(gray);

      // Пороговое значение размытости (подобрано экспериментально)
      return laplacian < 100.0;
    } catch (e) {
      debugPrint('Error analyzing blur: $e');
      return false;
    }
  }

  // Расчет Лапласиана для определения резкости
  static double _computeLaplacian(img.Image image) {
    final width = image.width;
    final height = image.height;
    final kernel = [0, 1, 0, 1, -4, 1, 0, 1, 0];
    double variance = 0.0;

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        double sum = 0.0;
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = image.getPixel(x + kx, y + ky);
            final intensity = img.getLuminance(pixel).toDouble();
            sum += intensity * kernel[(ky + 1) * 3 + (kx + 1)];
          }
        }
        variance += sum * sum;
      }
    }

    // Нормализуем по количеству пикселей
    return variance / ((width - 2) * (height - 2));
  }

  // Поиск скриншотов - используем оба метода для надежного обнаружения
  static List<MediaFile> findScreenshots(List<MediaFile> files) {
    final screenshots = <MediaFile>[];

    for (final file in files) {
      if (!file.isImage) continue;

      // Проверяем имя файла для обнаружения скриншотов
      final fileName = file.entity.title?.toLowerCase() ?? '';
      final hasScreenshotName =
          fileName.contains('screenshot') ||
          fileName.contains('screen shot') ||
          fileName.contains('скриншот') ||
          fileName.contains('снимок экрана');

      if (hasScreenshotName) {
        screenshots.add(file.copyWith(category: 'screenshots'));
        continue;
      }

      // Проверяем соотношение сторон для распространенных размеров экрана
      // Для iOS устройств с соотношением сторон 16:9 или 19.5:9
      final aspectRatio = file.entity.width / file.entity.height;

      final commonRatios = [
        16.0 / 9.0, // iPhone SE, 7, 8
        19.5 / 9.0, // iPhone X и новее
        4.0 / 3.0, // iPad
        2.165, // iPhone 12/13 Pro Max
      ];

      bool matchesCommonRatio = false;
      for (final ratio in commonRatios) {
        if ((aspectRatio - ratio).abs() < 0.05) {
          matchesCommonRatio = true;
          break;
        }
      }

      if (matchesCommonRatio) {
        screenshots.add(file.copyWith(category: 'screenshots'));
      }
    }

    return screenshots;
  }

  // Поиск записей экрана - исправленный метод для RPReplay
  static List<MediaFile> findScreenRecordings(List<MediaFile> files) {
    final screenRecordings = <MediaFile>[];

    for (final file in files) {
      if (!file.isVideo) continue;

      // Проверка на префикс RPReplay
      final fileName = file.entity.title?.toLowerCase() ?? '';
      if (fileName.contains('rpreplay')) {
        screenRecordings.add(file.copyWith(category: 'screenRecordings'));
      }
    }

    return screenRecordings;
  }

  // Поиск коротких видео по длительности
  static List<MediaFile> findShortVideos(List<MediaFile> files) {
    final shortVideos = <MediaFile>[];

    for (final file in files) {
      if (!file.isVideo) continue;

      // Видео короче 5 секунд
      if (file.entity.duration != null && file.entity.duration! < 5) {
        shortVideos.add(file.copyWith(category: 'shortVideos'));
      }
    }

    return shortVideos;
  }

  // Поиск дубликатов фото по метаданным
  static List<MediaGroup> findDuplicatePhotos(List<MediaFile> files) {
    final Map<String, List<MediaFile>> duplicateGroups = {};
    final Map<String, MediaFile> signatureMap = {};

    // Для фото дубликаты определяются по размеру, ширине, высоте
    for (final file in files) {
      if (!file.isImage) continue;

      // Создаем простую сигнатуру на основе размера, ширины, высоты
      final signature = '${file.entity.size}|${file.entity.width}|${file.entity.height}';

      if (signatureMap.containsKey(signature)) {
        // Если уже есть группа для этой сигнатуры
        if (duplicateGroups.containsKey(signature)) {
          duplicateGroups[signature]!.add(file);
        } else {
          // Создаем новую группу с существующим файлом и текущим
          duplicateGroups[signature] = [signatureMap[signature]!, file];
        }
      } else {
        // Запоминаем файл для дальнейшего сравнения
        signatureMap[signature] = file;
      }
    }

    // Преобразуем Map в список MediaGroup
    final List<MediaGroup> result = [];
    int groupCounter = 0;

    duplicateGroups.forEach((signature, groupFiles) {
      if (groupFiles.length > 1) {
        result.add(
          MediaGroup(
            id: 'dup_${groupCounter++}',
            name: 'Серии снимков ${groupCounter}',
            files: groupFiles,
          ),
        );
      }
    });

    // Очищаем память
    signatureMap.clear();
    duplicateGroups.clear();

    return result;
  }

  // Поиск дубликатов для видео
  static List<MediaGroup> findDuplicateVideos(List<MediaFile> files) {
    final Map<String, List<MediaFile>> duplicateGroups = {};
    final Map<String, MediaFile> signatureMap = {};

    for (final file in files) {
      if (!file.isVideo) continue;

      // Для видео учитываем размер файла и продолжительность
      final duration = file.entity.duration ?? 0;
      final signature = '${file.entity.size}|$duration';

      if (signatureMap.containsKey(signature)) {
        // Если уже есть группа для этой сигнатуры
        if (duplicateGroups.containsKey(signature)) {
          duplicateGroups[signature]!.add(file);
        } else {
          // Создаем новую группу с существующим файлом и текущим
          duplicateGroups[signature] = [signatureMap[signature]!, file];
        }
      } else {
        signatureMap[signature] = file;
      }
    }

    // Преобразуем Map в список MediaGroup
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

    signatureMap.clear();
    duplicateGroups.clear();

    return result;
  }

  // Метод для деления коллекции на батчи
  static List<List<T>> _batchList<T>(List<T> items, int batchSize) {
    List<List<T>> batches = [];
    for (var i = 0; i < items.length; i += batchSize) {
      batches.add(items.sublist(i, min(i + batchSize, items.length)));
    }
    return batches;
  }
}
