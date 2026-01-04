/// Конфигурация для iOS Vision Framework модуля
///
/// Этот файл управляет включением/выключением различных функций Vision Framework.
/// Vision Framework - это отдельный слой анализа, который работает параллельно
/// с существующими алгоритмами и не влияет на основную функциональность приложения.
class VisionConfig {
  /// 🔓 DEV MODE - отключает все ограничения бесплатной версии
  ///
  /// При true:
  /// - ✅ Все категории доступны без Premium (blur, similar, series, live photos, etc.)
  /// - ✅ Все лимиты сканирования сняты
  /// - ✅ Все функции разблокированы для тестирования
  /// - ✅ Premium проверки игнорируются
  /// - ✅ Замочки не отображаются в UI
  ///
  /// Использование:
  /// ```dart
  /// // Для разработки и тестирования
  /// static const bool devModeUnlockAll = true;
  ///
  /// // Для production релиза
  /// static const bool devModeUnlockAll = false;
  /// ```
  ///
  /// ⚠️ ВАЖНО: Установите false перед production релизом!
  /// 📖 Подробнее: DEV_MODE_GUIDE.md
  static const bool devModeUnlockAll = false;

  /// Глобальное включение/выключение Vision Framework
  /// При false - все функции Vision Framework отключены
  static const bool enabled = true;

  /// Конфигурация для категорий фото
  static const VisionPhotoFeatures photo = VisionPhotoFeatures();

  /// Конфигурация для категорий видео
  static const VisionVideoFeatures video = VisionVideoFeatures();

  /// Минимальный порог уверенности для Vision Framework результатов (0.0 - 1.0)
  /// Результаты с confidence ниже этого значения будут отброшены
  static const double minimumConfidence = 0.7;

  /// Максимальное количество параллельных запросов к Vision Framework
  /// Слишком много параллельных запросов может привести к проблемам с памятью
  static const int maxConcurrentVisionRequests = 3;

  /// Таймаут для одного Vision запроса (в секундах)
  static const int visionRequestTimeout = 10;

  /// Использовать Vision Framework как primary или fallback
  /// - true: Vision Framework используется первым, затем классические алгоритмы
  /// - false: сначала классические алгоритмы, Vision Framework как fallback
  static const bool visionAsPrimary = true;

  /// Логирование Vision Framework операций
  static const bool enableVisionLogging = true;
}

/// Настройки Vision Framework для фото
class VisionPhotoFeatures {
  const VisionPhotoFeatures();

  /// Детекция размытых фотографий через Vision Framework
  /// Использует VNImageRequestHandler с качественным анализом
  bool get blurDetection => true;

  /// Детекция похожих фотографий через Vision Framework
  /// Использует VNGenerateImageFeaturePrintRequest
  bool get similarPhotos => false; // Пока отключено, будет добавлено позже

  /// Детекция серий фотографий
  bool get photoSeries => false; // Пока отключено

  /// Детекция скриншотов
  bool get screenshots => false; // Пока отключено

  /// Детекция Live Photos
  bool get livePhotos => false; // Пока отключено
}

/// Настройки Vision Framework для видео
class VisionVideoFeatures {
  const VisionVideoFeatures();

  /// Детекция размытых видео
  bool get blurDetection => false; // Пока отключено

  /// Детекция похожих видео
  bool get similarVideos => false; // Пока отключено

  /// Детекция записей экрана
  bool get screenRecordings => false; // Пока отключено
}
