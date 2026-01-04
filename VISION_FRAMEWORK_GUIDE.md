# Vision Framework Integration Guide

## Обзор

Модуль Vision Framework - это отдельный, полностью независимый слой анализа медиа-файлов, который использует iOS Vision Framework для более точной детекции различных характеристик фотографий и видео.

### Ключевые особенности

✅ **Полностью модульный** - включается/выключается через конфигурацию
✅ **Не влияет на основное приложение** - работает параллельно с классическими алгоритмами
✅ **Гибкая конфигурация** - каждая функция настраивается отдельно
✅ **Fallback стратегия** - автоматический переход на классические алгоритмы при ошибках
✅ **iOS нативная производительность** - использует оптимизированный Vision Framework

## Архитектура

```
┌─────────────────────────────────────────────────────┐
│           VisionConfig (конфигурация)                │
│  - Включение/выключение всего модуля                 │
│  - Настройки для каждой категории                    │
│  - Пороги уверенности и таймауты                     │
└─────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│         VisionMediaScanner (интеграция)              │
│  - Объединяет Vision Framework + классические        │
│  - Стратегии: primary/fallback                       │
│  - Статистика детекции                               │
└─────────────────────────────────────────────────────┘
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
┌─────────────────────┐   ┌─────────────────────┐
│  Vision Analyzers   │   │ Classic Algorithms  │
│  - BlurDetection    │   │  - Laplacian        │
│  - (Будущие)        │   │  - DCT Hash         │
└─────────────────────┘   └─────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────┐
│      VisionPlatformChannel (Flutter ↔ iOS)          │
└─────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────┐
│   VisionFrameworkHandler (iOS Native Swift)          │
│   - Детекция размытия (Laplacian + Vision)          │
│   - Feature prints (для похожих фото)                │
│   - Batch обработка                                  │
└─────────────────────────────────────────────────────┘
```

## Конфигурация

### Основные настройки

Откройте файл `lib/core/config/vision_config.dart`:

```dart
class VisionConfig {
  /// Глобальное включение/выключение Vision Framework
  static const bool enabled = true; // ← измените на false чтобы отключить

  /// Минимальный порог уверенности (0.0 - 1.0)
  static const double minimumConfidence = 0.7;

  /// Vision Framework как primary или fallback
  static const bool visionAsPrimary = true;
}
```

### Настройки для категорий

```dart
class VisionPhotoFeatures {
  /// Детекция размытых фотографий
  bool get blurDetection => true; // ← включено

  /// Похожие фотографии (пока не реализовано)
  bool get similarPhotos => false;

  /// Серии фотографий (пока не реализовано)
  bool get photoSeries => false;
}
```

## Использование

### Базовое использование

```dart
import 'package:ai_cleaner_2/feature/cleaner/domain/vision_media_scanner.dart';

// Найти размытые фотографии
final blurryPhotos = await VisionMediaScanner.findBlurryImages(allPhotos);

// Получить статистику
final stats = VisionMediaScanner.getDetectionStats(blurryPhotos);
print('Vision Framework: ${stats['vision']}');
print('Classic Algorithm: ${stats['classic']}');
```

### Прямое использование анализатора

```dart
import 'package:ai_cleaner_2/core/vision/vision_framework.dart';

const analyzer = BlurDetectionAnalyzer();

// Проверить, включен ли анализатор
if (analyzer.isEnabled) {
  // Анализировать одно фото
  final result = await analyzer.analyze(mediaFile);

  if (result.shouldInclude && result.confidence > 0.7) {
    print('Фото размыто! Confidence: ${result.confidence}');
  }
}

// Пакетный анализ
final results = await analyzer.analyzeMany(photos);
final blurryPhotos = analyzer.filterFiles(photos, results);
```

### Проверка доступности Vision Framework

```dart
import 'package:ai_cleaner_2/core/vision/vision_platform_channel.dart';

final isAvailable = await VisionPlatformChannel.isAvailable();
if (isAvailable) {
  final version = await VisionPlatformChannel.getVisionVersion();
  print('Vision Framework доступен: $version');
}
```

## Стратегии работы

### 1. Vision Primary (по умолчанию)

```dart
VisionConfig.visionAsPrimary = true;
```

- Сначала запускается Vision Framework
- Если находит результаты → возвращает их
- Если не находит → fallback на классический алгоритм

**Преимущества**: максимальная точность Vision Framework
**Недостатки**: может пропустить некоторые случаи

### 2. Classic Primary + Vision Enhancement

```dart
VisionConfig.visionAsPrimary = false;
```

- Запускаются оба алгоритма параллельно
- Результаты объединяются
- Удаляются дубликаты

**Преимущества**: максимальный охват
**Недостатки**: может быть больше ложных срабатываний

## Интеграция с существующим кодом

### Вариант 1: Замена в MediaScanner (рекомендуется для тестирования)

```dart
// В media_scanner.dart
static Future<List<MediaFile>> findBlurryImages(List<MediaFile> files) async {
  // Используем Vision Framework если включен
  if (VisionConfig.enabled && VisionConfig.photo.blurDetection) {
    return VisionMediaScanner.findBlurryImages(files);
  }

  // Иначе используем классический алгоритм
  // ... существующий код
}
```

### Вариант 2: Параллельное использование (рекомендуется для production)

```dart
// Классический алгоритм всегда доступен
final classicResults = await MediaScanner.findBlurryImages(files);

// Vision Framework опционально
final visionResults = VisionConfig.enabled
    ? await VisionMediaScanner.findBlurryImages(files)
    : <MediaFile>[];

// Выбираем результаты на основе настроек
final finalResults = VisionConfig.visionAsPrimary
    ? (visionResults.isNotEmpty ? visionResults : classicResults)
    : classicResults;
```

## Примеры конфигураций

### Конфигурация 1: Только Vision Framework

```dart
class VisionConfig {
  static const bool enabled = true;
  static const bool visionAsPrimary = true;
  static const double minimumConfidence = 0.7;
}

class VisionPhotoFeatures {
  bool get blurDetection => true;
  bool get similarPhotos => false;
}
```

### Конфигурация 2: Vision + Classic (максимальный охват)

```dart
class VisionConfig {
  static const bool enabled = true;
  static const bool visionAsPrimary = false; // ← Classic primary
  static const double minimumConfidence = 0.5; // ← Ниже порог
}
```

### Конфигурация 3: Полное отключение Vision

```dart
class VisionConfig {
  static const bool enabled = false; // ← Все отключено
}
```

## Добавление новых анализаторов

### Шаг 1: Создайте новый анализатор

```dart
class SimilarPhotosAnalyzer extends VisionAnalyzer {
  @override
  String get name => 'SimilarPhotos';

  @override
  bool get isEnabled => VisionConfig.enabled && VisionConfig.photo.similarPhotos;

  @override
  Future<VisionAnalyzerResult> analyze(MediaFile file) async {
    // Ваша логика анализа
  }
}
```

### Шаг 2: Добавьте в конфигурацию

```dart
class VisionPhotoFeatures {
  bool get similarPhotos => true; // ← включите
}
```

### Шаг 3: Реализуйте iOS метод

```swift
// В VisionFrameworkHandler.swift
static func findSimilarPhotos(...) {
  // Используйте VNGenerateImageFeaturePrintRequest
}
```

## Отладка

### Включить логирование

```dart
class VisionConfig {
  static const bool enableVisionLogging = true;
}
```

Логи будут выглядеть так:

```
[BlurDetection] Начало пакетного анализа 100 файлов
[BlurDetection] Обнаружено размытое фото: IMG_1234.jpg, blur score: 0.82, quality: blurry
[VisionMediaScanner] Vision Framework нашел 15 размытых фото
```

### Проверить статистику

```dart
final stats = VisionMediaScanner.getDetectionStats(blurryPhotos);
print('Статистика детекции:');
print('  Vision Framework: ${stats['vision']} фото');
print('  Classic Algorithm: ${stats['classic']} фото');
print('  Unknown: ${stats['unknown']} фото');
```

## Производительность

### Оптимизация батчей

```dart
class VisionConfig {
  /// Максимум 3 параллельных запроса к Vision Framework
  static const int maxConcurrentVisionRequests = 3;

  /// Таймаут 10 секунд на запрос
  static const int visionRequestTimeout = 10;
}
```

### Рекомендации

- ✅ Используйте пакетную обработку для больших объемов
- ✅ Устанавливайте разумные таймауты (10-15 секунд)
- ✅ Ограничивайте параллельные запросы (3-5 максимум)
- ❌ Не анализируйте все фото сразу (делите на батчи)
- ❌ Не устанавливайте слишком низкий `minimumConfidence` (<0.5)

## Troubleshooting

### Vision Framework не работает

1. Проверьте, что `VisionConfig.enabled = true`
2. Проверьте iOS версию (требуется iOS 13.0+)
3. Проверьте логи: `VisionConfig.enableVisionLogging = true`

### Результаты не совпадают с классическим алгоритмом

Это нормально! Vision Framework использует другие алгоритмы и может находить разные фото. Используйте:

```dart
VisionConfig.visionAsPrimary = false; // Объединяет результаты
```

### Медленная работа

1. Уменьшите `maxConcurrentVisionRequests` до 2-3
2. Увеличьте размер батчей в коде анализатора
3. Рассмотрите использование `visionAsPrimary = true` для меньшего количества запросов

## Roadmap

- [x] Детекция размытых фото
- [ ] Детекция похожих фото (VNGenerateImageFeaturePrintRequest)
- [ ] Детекция серий фото
- [ ] Детекция объектов на фото (VNRecognizeAnimalsRequest)
- [ ] Детекция текста на скриншотах (VNRecognizeTextRequest)
- [ ] Детекция размытых видео
- [ ] Анализ качества видео

## Контакты

Для вопросов и предложений по улучшению модуля Vision Framework создайте issue в репозитории проекта.
