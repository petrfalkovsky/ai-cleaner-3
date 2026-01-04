// Пример интеграции Vision Framework с существующим MediaScanner
//
// Этот файл показывает, как безопасно интегрировать Vision Framework
// в существующий код без нарушения работы приложения.

// ignore_for_file: unused_import, unused_element

import 'package:ai_cleaner_2/core/config/vision_config.dart';
import 'package:ai_cleaner_2/feature/cleaner/domain/media_file_entity.dart';
import 'package:ai_cleaner_2/feature/cleaner/domain/media_scanner.dart';
import 'package:ai_cleaner_2/feature/cleaner/domain/vision_media_scanner.dart';

/// ВАРИАНТ 1: Прямая замена в MediaScanner (рекомендуется для тестирования)
///
/// Измените метод findBlurryImages в media_scanner.dart:
class MediaScannerExample1 {
  static Future<List<MediaFile>> findBlurryImages(List<MediaFile> files) async {
    // Проверяем, включен ли Vision Framework
    if (VisionConfig.enabled && VisionConfig.photo.blurDetection) {
      // Используем Vision Framework
      return VisionMediaScanner.findBlurryImages(files);
    }

    // Fallback на классический алгоритм
    return MediaScanner.findBlurryImages(files);
  }
}

/// ВАРИАНТ 2: Параллельное использование (рекомендуется для production)
///
/// Оба алгоритма доступны, выбор зависит от конфигурации
class MediaScannerExample2 {
  static Future<List<MediaFile>> findBlurryImages(List<MediaFile> files) async {
    // Всегда запускаем классический алгоритм (надежный fallback)
    final classicResults = await MediaScanner.findBlurryImages(files);

    // Если Vision отключен, сразу возвращаем классические результаты
    if (!VisionConfig.enabled || !VisionConfig.photo.blurDetection) {
      return classicResults;
    }

    try {
      // Запускаем Vision Framework
      final visionResults = await VisionMediaScanner.findBlurryImages(files);

      // Выбираем результаты на основе стратегии
      if (VisionConfig.visionAsPrimary) {
        // Vision primary: используем Vision если есть результаты
        return visionResults.isNotEmpty ? visionResults : classicResults;
      } else {
        // Classic primary: уже вернули классические результаты выше
        // Здесь можно добавить логирование для сравнения
        _compareResults(classicResults, visionResults);
        return classicResults;
      }
    } catch (e) {
      // При ошибке Vision Framework возвращаем классические результаты
      print('Vision Framework error: $e, using classic algorithm');
      return classicResults;
    }
  }

  static void _compareResults(
    List<MediaFile> classic,
    List<MediaFile> vision,
  ) {
    print('=== Сравнение результатов ===');
    print('Classic: ${classic.length} фото');
    print('Vision: ${vision.length} фото');

    // Найти уникальные для каждого алгоритма
    final classicIds = classic.map((f) => f.entity.id).toSet();
    final visionIds = vision.map((f) => f.entity.id).toSet();

    final onlyClassic = classicIds.difference(visionIds);
    final onlyVision = visionIds.difference(classicIds);

    print('Только Classic: ${onlyClassic.length}');
    print('Только Vision: ${onlyVision.length}');
    print('Общие: ${classicIds.intersection(visionIds).length}');
  }
}

/// ВАРИАНТ 3: A/B тестирование
///
/// Запускает оба алгоритма и собирает статистику для сравнения
class MediaScannerExample3 {
  static Future<List<MediaFile>> findBlurryImages(List<MediaFile> files) async {
    // Запускаем оба параллельно
    final results = await Future.wait([
      MediaScanner.findBlurryImages(files),
      VisionConfig.enabled && VisionConfig.photo.blurDetection
          ? VisionMediaScanner.findBlurryImages(files)
          : Future.value(<MediaFile>[]),
    ]);

    final classicResults = results[0];
    final visionResults = results[1];

    // Логируем для анализа
    _logABTestResults(classicResults, visionResults);

    // Возвращаем на основе конфигурации
    return VisionConfig.visionAsPrimary && visionResults.isNotEmpty
        ? visionResults
        : classicResults;
  }

  static void _logABTestResults(
    List<MediaFile> classic,
    List<MediaFile> vision,
  ) {
    final classicIds = classic.map((f) => f.entity.id).toSet();
    final visionIds = vision.map((f) => f.entity.id).toSet();

    final overlap = classicIds.intersection(visionIds).length;
    final accuracy = classic.isNotEmpty
        ? (overlap / classic.length * 100).toStringAsFixed(1)
        : '0';

    print('A/B Test Results:');
    print('  Classic: ${classic.length} photos');
    print('  Vision: ${vision.length} photos');
    print('  Overlap: $overlap (${accuracy}%)');
  }
}

/// ВАРИАНТ 4: Постепенный rollout
///
/// Включает Vision Framework только для определенного процента пользователей
class MediaScannerExample4 {
  // Установите процент пользователей, для которых включен Vision Framework
  static const int visionRolloutPercentage = 50; // 50% пользователей

  static Future<List<MediaFile>> findBlurryImages(
    List<MediaFile> files, {
    String? userId,
  }) async {
    final useVision = _shouldUseVision(userId);

    if (useVision && VisionConfig.enabled && VisionConfig.photo.blurDetection) {
      try {
        return await VisionMediaScanner.findBlurryImages(files);
      } catch (e) {
        print('Vision error, fallback to classic: $e');
      }
    }

    return MediaScanner.findBlurryImages(files);
  }

  static bool _shouldUseVision(String? userId) {
    if (userId == null) return false;

    // Простой хэш для консистентного распределения
    final hash = userId.hashCode.abs();
    return (hash % 100) < visionRolloutPercentage;
  }
}

/// ВАРИАНТ 5: Умная стратегия (рекомендуется для production)
///
/// Выбирает алгоритм на основе контекста и предыдущих результатов
class MediaScannerExample5 {
  static Future<List<MediaFile>> findBlurryImages(List<MediaFile> files) async {
    final imageFiles = files.where((f) => f.isImage).toList();

    // Для малого количества фото используем Vision (более точный)
    if (imageFiles.length < 100) {
      return _useVisionWithFallback(imageFiles);
    }

    // Для большого количества используем Classic (быстрее)
    if (imageFiles.length > 1000) {
      return MediaScanner.findBlurryImages(files);
    }

    // Для среднего количества - смешанная стратегия
    return _useHybridStrategy(imageFiles);
  }

  static Future<List<MediaFile>> _useVisionWithFallback(
    List<MediaFile> files,
  ) async {
    if (!VisionConfig.enabled || !VisionConfig.photo.blurDetection) {
      return MediaScanner.findBlurryImages(files);
    }

    try {
      final results = await VisionMediaScanner.findBlurryImages(files);
      return results.isNotEmpty ? results : MediaScanner.findBlurryImages(files);
    } catch (e) {
      return MediaScanner.findBlurryImages(files);
    }
  }

  static Future<List<MediaFile>> _useHybridStrategy(
    List<MediaFile> files,
  ) async {
    // Запускаем оба параллельно
    final results = await Future.wait([
      MediaScanner.findBlurryImages(files),
      VisionConfig.enabled && VisionConfig.photo.blurDetection
          ? VisionMediaScanner.findBlurryImages(files)
          : Future.value(<MediaFile>[]),
    ]);

    final classic = results[0];
    final vision = results[1];

    // Объединяем результаты, приоритет Vision Framework
    final combinedIds = <String>{};
    final combined = <MediaFile>[];

    // Сначала добавляем Vision результаты (выше точность)
    for (final file in vision) {
      combinedIds.add(file.entity.id);
      combined.add(file);
    }

    // Затем добавляем уникальные Classic результаты
    for (final file in classic) {
      if (!combinedIds.contains(file.entity.id)) {
        combinedIds.add(file.entity.id);
        combined.add(file);
      }
    }

    return combined;
  }
}
