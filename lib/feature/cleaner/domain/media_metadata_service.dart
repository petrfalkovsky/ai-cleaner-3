import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Сервис для получения метаданных медиафайлов из нативного iOS кода
/// Использует Method Channel для взаимодействия с PHAsset API
class MediaMetadataService {
  static const MethodChannel _channel = MethodChannel('ai_cleaner/media_metadata');

  /// Кэш метаданных для избежания повторных запросов к нативному коду
  static final Map<String, Map<String, dynamic>> _metadataCache = {};

  /// Получить метаданные для медиафайла по его ID (localIdentifier)
  ///
  /// Возвращает Map с ключами:
  /// - isScreenRecording: bool - является ли видео записью экрана
  /// - originalFilename: String - оригинальное имя файла
  /// - mediaType: String - тип медиа ("video" или "image")
  /// - duration: double - длительность (для видео)
  /// - pixelWidth: int - ширина в пикселях
  /// - pixelHeight: int - высота в пикселях
  static Future<Map<String, dynamic>?> getMediaMetadata(String assetId) async {
    // Проверяем кэш
    if (_metadataCache.containsKey(assetId)) {
      return _metadataCache[assetId];
    }

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getMediaMetadata',
        {'assetId': assetId},
      );

      if (result != null) {
        // Преобразуем Map<Object?, Object?> в Map<String, dynamic>
        final metadata = Map<String, dynamic>.from(result);

        // Сохраняем в кэш
        _metadataCache[assetId] = metadata;

        return metadata;
      }
    } catch (e) {
      debugPrint('MediaMetadataService: Ошибка получения метаданных для $assetId: $e');
    }

    return null;
  }

  /// Очистить кэш метаданных
  static void clearCache() {
    _metadataCache.clear();
  }

  /// Получить размер кэша
  static int get cacheSize => _metadataCache.length;
}
