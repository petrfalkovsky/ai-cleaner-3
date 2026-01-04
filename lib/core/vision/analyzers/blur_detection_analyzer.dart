import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../feature/cleaner/domain/media_file_entity.dart';
import '../../config/vision_config.dart';
import '../vision_analyzer.dart';
import '../vision_analyzer_result.dart';
import '../vision_platform_channel.dart';

/// Vision Framework анализатор для детекции размытых фотографий
///
/// Использует iOS Vision Framework для определения качества изображения.
/// Работает параллельно с классическим Laplacian variance алгоритмом,
/// не заменяя его, а дополняя более точными результатами.
class BlurDetectionAnalyzer extends VisionAnalyzer {
  const BlurDetectionAnalyzer();

  @override
  String get name => 'BlurDetection';

  @override
  bool get isEnabled =>
      VisionConfig.enabled && VisionConfig.photo.blurDetection;

  @override
  Future<VisionAnalyzerResult> analyze(MediaFile file) async {
    // Проверяем, включен ли анализатор
    if (!isEnabled) {
      return VisionAnalyzerResult.disabled(file.entity.id);
    }

    // Работаем только с изображениями
    if (!file.isImage) {
      return VisionAnalyzerResult.success(
        assetId: file.entity.id,
        confidence: 0.0,
        shouldInclude: false,
        metadata: {'reason': 'not_an_image'},
      );
    }

    try {
      // Получаем данные изображения для анализа
      // Используем среднее качество для баланса точности и производительности
      final imageData = await file.entity.thumbnailDataWithSize(
        const ThumbnailSize(512, 512),
        quality: 85,
      );

      if (imageData == null) {
        return VisionAnalyzerResult.error(
          file.entity.id,
          'Failed to load image data',
        );
      }

      // Вызываем Vision Framework через platform channel
      final result = await VisionPlatformChannel.analyzeBlur(
        assetId: file.entity.id,
        imageData: imageData,
        timeout: Duration(seconds: VisionConfig.visionRequestTimeout),
      );

      if (result == null) {
        return VisionAnalyzerResult.error(
          file.entity.id,
          'Vision Framework returned null',
        );
      }

      // Vision Framework возвращает blur score от 0.0 (четкое) до 1.0 (размытое)
      final blurScore = result['blurScore'] as double? ?? 0.0;
      final quality = result['quality'] as String? ?? 'unknown';

      // Считаем изображение размытым, если blur score > 0.5
      final isBlurry = blurScore > 0.5;

      if (VisionConfig.enableVisionLogging && isBlurry) {
        debugPrint(
          '[$name] Обнаружено размытое фото: ${file.entity.title}, '
          'blur score: ${blurScore.toStringAsFixed(2)}, '
          'quality: $quality',
        );
      }

      return VisionAnalyzerResult.success(
        assetId: file.entity.id,
        confidence: blurScore,
        shouldInclude: isBlurry,
        metadata: {
          'blurScore': blurScore,
          'quality': quality,
          'source': 'vision_framework',
        },
      );
    } catch (e, stackTrace) {
      debugPrint('[$name] Ошибка анализа ${file.entity.id}: $e');
      debugPrint('StackTrace: $stackTrace');

      return VisionAnalyzerResult.error(
        file.entity.id,
        e.toString(),
      );
    }
  }

  /// Анализирует список фотографий и возвращает только размытые
  Future<List<MediaFile>> findBlurryPhotos(List<MediaFile> files) async {
    if (!isEnabled) {
      debugPrint('[$name] Анализатор отключен, используйте классический алгоритм');
      return [];
    }

    // Фильтруем только изображения
    final imageFiles = files.where((f) => f.isImage).toList();

    if (imageFiles.isEmpty) {
      return [];
    }

    debugPrint('[$name] Начало анализа ${imageFiles.length} изображений');

    // Выполняем пакетный анализ
    final results = await analyzeMany(imageFiles);

    // Фильтруем результаты
    final blurryFiles = filterFiles(imageFiles, results);

    debugPrint('[$name] Найдено ${blurryFiles.length} размытых изображений');

    return blurryFiles;
  }
}
