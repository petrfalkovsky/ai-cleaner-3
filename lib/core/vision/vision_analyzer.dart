import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../feature/cleaner/domain/media_file_entity.dart';
import '../config/vision_config.dart';
import 'vision_analyzer_result.dart';

/// Абстрактный базовый класс для всех Vision Framework анализаторов
///
/// Каждый анализатор работает независимо и может быть включен/выключен
/// через [VisionConfig]. Анализаторы используют iOS Vision Framework
/// для детекции различных характеристик медиа-файлов.
abstract class VisionAnalyzer {
  const VisionAnalyzer();

  /// Название анализатора для логирования
  String get name;

  /// Проверяет, включен ли данный анализатор в конфигурации
  bool get isEnabled;

  /// Анализирует один медиа-файл
  ///
  /// Возвращает [VisionAnalyzerResult] с результатом анализа.
  /// Если анализатор отключен, возвращает результат с [isEnabled] = false
  Future<VisionAnalyzerResult> analyze(MediaFile file);

  /// Пакетный анализ нескольких файлов
  ///
  /// По умолчанию обрабатывает файлы параллельно с учетом
  /// [VisionConfig.maxConcurrentVisionRequests]
  Future<List<VisionAnalyzerResult>> analyzeMany(List<MediaFile> files) async {
    if (!isEnabled) {
      _log('Анализатор отключен в конфигурации');
      return files
          .map((f) => VisionAnalyzerResult.disabled(f.entity.id))
          .toList();
    }

    final results = <VisionAnalyzerResult>[];
    final maxConcurrent = VisionConfig.maxConcurrentVisionRequests;

    _log('Начало пакетного анализа ${files.length} файлов');

    for (int i = 0; i < files.length; i += maxConcurrent) {
      final batch = files.skip(i).take(maxConcurrent).toList();

      final batchResults = await Future.wait(
        batch.map((file) => analyze(file)),
      );

      results.addAll(batchResults);

      // Небольшая пауза между батчами для снижения нагрузки
      if (i + maxConcurrent < files.length) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    _log('Завершен анализ. Обработано ${results.length} файлов');
    return results;
  }

  /// Фильтрует файлы на основе результатов анализа
  ///
  /// Возвращает только те файлы, для которых [shouldInclude] = true
  /// и confidence >= [VisionConfig.minimumConfidence]
  List<MediaFile> filterFiles(
    List<MediaFile> files,
    List<VisionAnalyzerResult> results,
  ) {
    final filtered = <MediaFile>[];
    final minConfidence = VisionConfig.minimumConfidence;

    for (final result in results) {
      if (!result.shouldInclude) continue;
      if (result.confidence < minConfidence) continue;

      final file = files.firstWhere(
        (f) => f.entity.id == result.assetId,
        orElse: () => files.first,
      );

      if (file.entity.id == result.assetId) {
        filtered.add(file);
      }
    }

    return filtered;
  }

  /// Логирование (если включено в конфигурации)
  void _log(String message) {
    if (VisionConfig.enableVisionLogging) {
      debugPrint('[$name] $message');
    }
  }
}
