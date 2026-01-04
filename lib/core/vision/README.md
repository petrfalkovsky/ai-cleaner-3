# Vision Framework Module

Модульная система для интеграции iOS Vision Framework в приложение AiCleaner.

## Быстрый старт

### 1. Включение модуля

```dart
// lib/core/config/vision_config.dart
class VisionConfig {
  static const bool enabled = true; // ← включить/выключить
}
```

### 2. Использование

```dart
import 'package:ai_cleaner_2/feature/cleaner/domain/vision_media_scanner.dart';

// Найти размытые фото
final blurryPhotos = await VisionMediaScanner.findBlurryImages(allPhotos);
```

### 3. Настройка

```dart
class VisionConfig {
  static const bool enabled = true;
  static const bool visionAsPrimary = true; // true = Vision primary, false = Classic primary
  static const double minimumConfidence = 0.7; // порог уверенности
}
```

## Структура файлов

```
lib/core/vision/
├── vision_framework.dart          # Главный export файл
├── vision_analyzer.dart           # Базовый класс для анализаторов
├── vision_analyzer_result.dart    # Модель результата анализа
├── vision_platform_channel.dart   # Flutter ↔ iOS коммуникация
└── analyzers/
    └── blur_detection_analyzer.dart  # Анализатор размытых фото

lib/core/config/
└── vision_config.dart             # Конфигурация модуля

lib/feature/cleaner/domain/
└── vision_media_scanner.dart      # Интеграционный слой

ios/Runner/
├── VisionFrameworkHandler.swift   # iOS Vision Framework логика
└── AppDelegate.swift              # Platform channel setup
```

## Доступные функции

### ✅ Реализовано

- **Детекция размытых фото** - использует Laplacian variance + Vision Framework
  - Конфигурация: `VisionConfig.photo.blurDetection`
  - Метод: `VisionMediaScanner.findBlurryImages()`

### 🔜 В разработке

- **Похожие фото** - VNGenerateImageFeaturePrintRequest
- **Серии фото** - анализ временных меток
- **Детекция объектов** - VNRecognizeAnimalsRequest
- **Размытые видео** - анализ видео фреймов

## Примеры

### Проверить доступность

```dart
import 'package:ai_cleaner_2/core/vision/vision_platform_channel.dart';

if (await VisionPlatformChannel.isAvailable()) {
  print('Vision Framework доступен');
}
```

### Анализировать одно фото

```dart
import 'package:ai_cleaner_2/core/vision/vision_framework.dart';

const analyzer = BlurDetectionAnalyzer();
final result = await analyzer.analyze(photo);

if (result.isSuccess && result.shouldInclude) {
  print('Размыто с confidence ${result.confidence}');
}
```

### Получить статистику

```dart
final stats = VisionMediaScanner.getDetectionStats(photos);
print('Vision: ${stats['vision']}, Classic: ${stats['classic']}');
```

## Конфигурация категорий

```dart
class VisionPhotoFeatures {
  bool get blurDetection => true;     // ✅ Размытые фото
  bool get similarPhotos => false;    // 🔜 Похожие фото
  bool get photoSeries => false;      // 🔜 Серии
  bool get screenshots => false;      // 🔜 Скриншоты
  bool get livePhotos => false;       // 🔜 Live Photos
}

class VisionVideoFeatures {
  bool get blurDetection => false;    // 🔜 Размытые видео
  bool get similarVideos => false;    // 🔜 Похожие видео
  bool get screenRecordings => false; // 🔜 Записи экрана
}
```

## Отключение модуля

Чтобы полностью отключить Vision Framework и использовать только классические алгоритмы:

```dart
// lib/core/config/vision_config.dart
class VisionConfig {
  static const bool enabled = false; // ← отключить
}
```

Это не повлияет на работу приложения - автоматически будут использоваться классические алгоритмы.

## Документация

Полная документация: [VISION_FRAMEWORK_GUIDE.md](../../../VISION_FRAMEWORK_GUIDE.md)

## Лицензия

Часть проекта AiCleaner
