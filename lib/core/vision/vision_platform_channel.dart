import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform channel для взаимодействия с iOS Vision Framework
///
/// Этот класс предоставляет интерфейс для вызова нативных методов
/// Vision Framework из Dart кода.
class VisionPlatformChannel {
  static const MethodChannel _channel = MethodChannel('ai_cleaner/vision');

  /// Проверяет, доступен ли Vision Framework на текущей платформе
  static Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      debugPrint('[VisionPlatformChannel] Ошибка проверки доступности: $e');
      return false;
    }
  }

  /// Анализирует изображение на предмет размытия
  ///
  /// Параметры:
  /// - [assetId]: ID медиа-файла для логирования
  /// - [imageData]: данные изображения в формате JPEG/PNG
  /// - [timeout]: максимальное время ожидания результата
  ///
  /// Возвращает Map с результатами:
  /// - 'blurScore': double от 0.0 (четкое) до 1.0 (размытое)
  /// - 'quality': String описание качества ('sharp', 'moderate', 'blurry')
  static Future<Map<String, dynamic>?> analyzeBlur({
    required String assetId,
    required Uint8List imageData,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final result = await _channel
          .invokeMethod<Map<dynamic, dynamic>>(
            'analyzeBlur',
            {
              'assetId': assetId,
              'imageData': imageData,
            },
          )
          .timeout(timeout);

      if (result == null) return null;

      // Преобразуем dynamic Map в Map<String, dynamic>
      return result.map((key, value) => MapEntry(key.toString(), value));
    } on TimeoutException {
      debugPrint('[VisionPlatformChannel] Timeout при анализе $assetId');
      return null;
    } on PlatformException catch (e) {
      debugPrint('[VisionPlatformChannel] Platform exception: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[VisionPlatformChannel] Ошибка анализа размытия: $e');
      return null;
    }
  }

  /// Анализирует несколько изображений на предмет размытия (batch)
  ///
  /// Более эффективен чем множественные вызовы [analyzeBlur],
  /// так как использует один platform channel вызов.
  static Future<List<Map<String, dynamic>>> analyzeBlurBatch({
    required List<String> assetIds,
    required List<Uint8List> imageDataList,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (assetIds.length != imageDataList.length) {
      throw ArgumentError('assetIds и imageDataList должны иметь одинаковую длину');
    }

    try {
      final result = await _channel
          .invokeMethod<List<dynamic>>(
            'analyzeBlurBatch',
            {
              'assetIds': assetIds,
              'imageDataList': imageDataList,
            },
          )
          .timeout(timeout);

      if (result == null) return [];

      // Преобразуем в List<Map<String, dynamic>>
      return result
          .map((item) {
            if (item is Map) {
              return item.map((key, value) => MapEntry(key.toString(), value));
            }
            return <String, dynamic>{};
          })
          .toList();
    } on TimeoutException {
      debugPrint('[VisionPlatformChannel] Timeout при batch анализе');
      return [];
    } on PlatformException catch (e) {
      debugPrint('[VisionPlatformChannel] Platform exception: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('[VisionPlatformChannel] Ошибка batch анализа размытия: $e');
      return [];
    }
  }

  /// Генерирует feature print для изображения (для поиска похожих)
  ///
  /// Будет использоваться в будущем для детекции похожих фотографий
  static Future<Map<String, dynamic>?> generateFeaturePrint({
    required String assetId,
    required Uint8List imageData,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final result = await _channel
          .invokeMethod<Map<dynamic, dynamic>>(
            'generateFeaturePrint',
            {
              'assetId': assetId,
              'imageData': imageData,
            },
          )
          .timeout(timeout);

      if (result == null) return null;

      return result.map((key, value) => MapEntry(key.toString(), value));
    } catch (e) {
      debugPrint('[VisionPlatformChannel] Ошибка генерации feature print: $e');
      return null;
    }
  }

  /// Получает версию Vision Framework
  static Future<String?> getVisionVersion() async {
    try {
      return await _channel.invokeMethod<String>('getVisionVersion');
    } catch (e) {
      debugPrint('[VisionPlatformChannel] Ошибка получения версии: $e');
      return null;
    }
  }
}
