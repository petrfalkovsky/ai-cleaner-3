import 'package:flutter/foundation.dart';

import '../../../core/config/vision_config.dart';
import '../../../core/vision/analyzers/blur_detection_analyzer.dart';
import 'media_file_entity.dart';
import 'media_scanner.dart';

/// Интеграционный слой между Vision Framework и классическими алгоритмами
///
/// Этот класс объединяет результаты Vision Framework и классических алгоритмов,
/// обеспечивая плавное переключение между ними в зависимости от конфигурации.
class VisionMediaScanner {
  static const _blurAnalyzer = BlurDetectionAnalyzer();

  /// Поиск размытых изображений с использованием Vision Framework
  ///
  /// Стратегия работы зависит от [VisionConfig.visionAsPrimary]:
  /// - true: сначала Vision Framework, затем классический алгоритм как fallback
  /// - false: сначала классический алгоритм, Vision Framework как дополнение
  static Future<List<MediaFile>> findBlurryImages(List<MediaFile> files) async {
    if (!VisionConfig.enabled || !VisionConfig.photo.blurDetection) {
      debugPrint('[VisionMediaScanner] Vision Framework отключен, используем классический алгоритм');
      return MediaScanner.findBlurryImages(files);
    }

    final imageFiles = files.where((f) => f.isImage).toList();

    if (imageFiles.isEmpty) {
      return [];
    }

    debugPrint('[VisionMediaScanner] Начало анализа размытия для ${imageFiles.length} изображений');

    try {
      if (VisionConfig.visionAsPrimary) {
        // Стратегия 1: Vision Framework primary
        return await _visionPrimaryStrategy(imageFiles);
      } else {
        // Стратегия 2: Классический алгоритм primary
        return await _classicPrimaryStrategy(imageFiles);
      }
    } catch (e) {
      debugPrint('[VisionMediaScanner] Ошибка при анализе: $e');
      debugPrint('[VisionMediaScanner] Fallback на классический алгоритм');
      return MediaScanner.findBlurryImages(files);
    }
  }

  /// Стратегия: Vision Framework как primary
  static Future<List<MediaFile>> _visionPrimaryStrategy(
    List<MediaFile> imageFiles,
  ) async {
    debugPrint('[VisionMediaScanner] Используем Vision Framework (primary)');

    // Запускаем Vision Framework анализ
    final visionResults = await _blurAnalyzer.findBlurryPhotos(imageFiles);

    // Если Vision Framework вернул результаты, используем их
    if (visionResults.isNotEmpty) {
      debugPrint('[VisionMediaScanner] Vision Framework нашел ${visionResults.length} размытых фото');
      return visionResults;
    }

    // Fallback на классический алгоритм
    debugPrint('[VisionMediaScanner] Vision Framework не нашел результатов, используем классический алгоритм');
    return MediaScanner.findBlurryImages(imageFiles);
  }

  /// Стратегия: Классический алгоритм как primary
  static Future<List<MediaFile>> _classicPrimaryStrategy(
    List<MediaFile> imageFiles,
  ) async {
    debugPrint('[VisionMediaScanner] Используем классический алгоритм (primary)');

    // Запускаем оба анализа параллельно
    final results = await Future.wait([
      MediaScanner.findBlurryImages(imageFiles),
      _blurAnalyzer.findBlurryPhotos(imageFiles),
    ]);

    final classicResults = results[0];
    final visionResults = results[1];

    debugPrint('[VisionMediaScanner] Классический алгоритм: ${classicResults.length}');
    debugPrint('[VisionMediaScanner] Vision Framework: ${visionResults.length}');

    // Объединяем результаты (используем Set для удаления дубликатов)
    final combinedIds = <String>{};
    final combined = <MediaFile>[];

    // Добавляем результаты классического алгоритма
    for (final file in classicResults) {
      if (!combinedIds.contains(file.entity.id)) {
        combinedIds.add(file.entity.id);
        combined.add(file.copyWith(
          metadata: {
            ...?file.metadata,
            'detectionSource': 'classic',
          },
        ));
      }
    }

    // Добавляем уникальные результаты Vision Framework
    for (final file in visionResults) {
      if (!combinedIds.contains(file.entity.id)) {
        combinedIds.add(file.entity.id);
        combined.add(file.copyWith(
          metadata: {
            ...?file.metadata,
            'detectionSource': 'vision',
          },
        ));
      }
    }

    debugPrint('[VisionMediaScanner] Всего найдено ${combined.length} размытых фото');
    return combined;
  }

  /// Получает статистику по источникам детекции
  ///
  /// Полезно для отладки и понимания, какой алгоритм работает лучше
  static Map<String, int> getDetectionStats(List<MediaFile> files) {
    final stats = <String, int>{
      'classic': 0,
      'vision': 0,
      'unknown': 0,
    };

    for (final file in files) {
      final source = file.metadata?['detectionSource'] as String? ?? 'unknown';
      stats[source] = (stats[source] ?? 0) + 1;
    }

    return stats;
  }
}
