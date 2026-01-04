# Vision Framework - Checklist для тестирования

## 📋 Предварительная проверка

### Файлы созданы

- [x] `lib/core/config/vision_config.dart` - конфигурация
- [x] `lib/core/vision/vision_analyzer.dart` - базовый класс
- [x] `lib/core/vision/vision_analyzer_result.dart` - модель результата
- [x] `lib/core/vision/vision_platform_channel.dart` - platform channel
- [x] `lib/core/vision/analyzers/blur_detection_analyzer.dart` - анализатор blur
- [x] `lib/core/vision/vision_framework.dart` - export файл
- [x] `lib/feature/cleaner/domain/vision_media_scanner.dart` - интеграция
- [x] `ios/Runner/VisionFrameworkHandler.swift` - iOS реализация
- [x] `ios/Runner/AppDelegate.swift` - обновлен с Vision channel

### Документация

- [x] `VISION_FRAMEWORK_GUIDE.md` - полное руководство
- [x] `VISION_FRAMEWORK_SUMMARY.md` - краткое резюме
- [x] `lib/core/vision/README.md` - быстрый старт
- [x] `lib/core/vision/HOW_IT_WORKS.md` - как работает
- [x] `lib/core/vision/INTEGRATION_EXAMPLE.dart` - примеры

## 🧪 Тестирование

### 1. Базовая проверка компиляции

```bash
# В корне проекта
cd /Users/a123/Documents/GitHub/flutterProjects/AiCleaner

# Проверить Dart код
flutter analyze lib/core/vision/
flutter analyze lib/feature/cleaner/domain/vision_media_scanner.dart

# Проверить iOS код
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -sdk iphoneos -configuration Debug clean build
```

**Ожидаемый результат:** ✅ Нет ошибок компиляции

### 2. Проверка доступности Vision Framework

```dart
// Добавьте в main.dart для теста
import 'package:ai_cleaner_2/core/vision/vision_platform_channel.dart';

void testVisionAvailability() async {
  final isAvailable = await VisionPlatformChannel.isAvailable();
  print('Vision Framework доступен: $isAvailable');

  if (isAvailable) {
    final version = await VisionPlatformChannel.getVisionVersion();
    print('Версия: $version');
  }
}
```

**Ожидаемый результат:** ✅ `true` для iOS 13.0+

### 3. Тест анализа одного фото

```dart
import 'package:ai_cleaner_2/core/vision/vision_framework.dart';

void testSinglePhotoAnalysis() async {
  const analyzer = BlurDetectionAnalyzer();

  if (!analyzer.isEnabled) {
    print('❌ Анализатор отключен в VisionConfig');
    return;
  }

  // Возьмите любое тестовое фото
  final testPhoto = ...; // MediaFile

  final result = await analyzer.analyze(testPhoto);

  print('Результат анализа:');
  print('  assetId: ${result.assetId}');
  print('  confidence: ${result.confidence}');
  print('  shouldInclude: ${result.shouldInclude}');
  print('  isSuccess: ${result.isSuccess}');

  if (result.metadata != null) {
    print('  metadata: ${result.metadata}');
  }
}
```

**Ожидаемый результат:** ✅ Получен результат с confidence 0.0-1.0

### 4. Тест batch анализа

```dart
void testBatchAnalysis() async {
  const analyzer = BlurDetectionAnalyzer();

  // Возьмите 10-20 тестовых фото
  final testPhotos = ...; // List<MediaFile>

  print('Начало batch анализа ${testPhotos.length} фото');

  final results = await analyzer.analyzeMany(testPhotos);

  print('Получено ${results.length} результатов');

  final blurryCount = results.where((r) => r.shouldInclude).length;
  print('Размытых фото: $blurryCount');

  // Статистика по confidence
  final avgConfidence = results
      .map((r) => r.confidence)
      .reduce((a, b) => a + b) / results.length;
  print('Средний confidence: ${avgConfidence.toStringAsFixed(2)}');
}
```

**Ожидаемый результат:** ✅ Все фото обработаны, получены результаты

### 5. Тест VisionMediaScanner

```dart
import 'package:ai_cleaner_2/feature/cleaner/domain/vision_media_scanner.dart';

void testVisionMediaScanner() async {
  // Возьмите набор фото (включая размытые и четкие)
  final allPhotos = ...; // List<MediaFile>

  print('Тест VisionMediaScanner с ${allPhotos.length} фото');

  final blurryPhotos = await VisionMediaScanner.findBlurryImages(allPhotos);

  print('Найдено размытых фото: ${blurryPhotos.length}');

  // Получить статистику
  final stats = VisionMediaScanner.getDetectionStats(blurryPhotos);
  print('Статистика:');
  print('  Vision Framework: ${stats['vision']}');
  print('  Classic Algorithm: ${stats['classic']}');
  print('  Unknown: ${stats['unknown']}');
}
```

**Ожидаемый результат:** ✅ Размытые фото найдены, статистика доступна

### 6. Сравнение с классическим алгоритмом

```dart
import 'package:ai_cleaner_2/feature/cleaner/domain/media_scanner.dart';

void testCompareAlgorithms() async {
  final allPhotos = ...; // List<MediaFile>

  print('Сравнение алгоритмов на ${allPhotos.length} фото');

  // Запускаем оба параллельно
  final results = await Future.wait([
    MediaScanner.findBlurryImages(allPhotos),
    VisionMediaScanner.findBlurryImages(allPhotos),
  ]);

  final classic = results[0];
  final vision = results[1];

  print('Classic: ${classic.length} фото');
  print('Vision: ${vision.length} фото');

  // Пересечение
  final classicIds = classic.map((f) => f.entity.id).toSet();
  final visionIds = vision.map((f) => f.entity.id).toSet();
  final overlap = classicIds.intersection(visionIds);

  print('Общие: ${overlap.length}');
  print('Только Classic: ${classicIds.difference(visionIds).length}');
  print('Только Vision: ${visionIds.difference(classicIds).length}');

  final accuracy = classic.isNotEmpty
      ? (overlap.length / classic.length * 100).toStringAsFixed(1)
      : '0';
  print('Согласованность: $accuracy%');
}
```

**Ожидаемый результат:** ✅ Оба алгоритма работают, есть пересечение

### 7. Тест конфигурации

```dart
void testConfiguration() {
  print('Проверка конфигурации:');
  print('  enabled: ${VisionConfig.enabled}');
  print('  visionAsPrimary: ${VisionConfig.visionAsPrimary}');
  print('  minimumConfidence: ${VisionConfig.minimumConfidence}');
  print('  maxConcurrentRequests: ${VisionConfig.maxConcurrentVisionRequests}');
  print('  enableLogging: ${VisionConfig.enableVisionLogging}');

  print('\nФото функции:');
  print('  blurDetection: ${VisionConfig.photo.blurDetection}');
  print('  similarPhotos: ${VisionConfig.photo.similarPhotos}');

  print('\nВидео функции:');
  print('  blurDetection: ${VisionConfig.video.blurDetection}');
}
```

**Ожидаемый результат:** ✅ Конфигурация читается корректно

### 8. Тест обработки ошибок

```dart
void testErrorHandling() async {
  // Тест 1: Невалидные данные
  try {
    final result = await VisionPlatformChannel.analyzeBlur(
      assetId: 'test',
      imageData: Uint8List(0), // Пустые данные
    );
    print('Результат с пустыми данными: $result');
  } catch (e) {
    print('✅ Корректная обработка ошибки: $e');
  }

  // Тест 2: Таймаут
  try {
    final result = await VisionPlatformChannel.analyzeBlur(
      assetId: 'test',
      imageData: validImageData,
      timeout: Duration(milliseconds: 1), // Очень короткий таймаут
    );
    print('Результат: $result');
  } catch (e) {
    print('✅ Таймаут обработан: $e');
  }
}
```

**Ожидаемый результат:** ✅ Ошибки обрабатываются корректно

### 9. Тест производительности

```dart
void testPerformance() async {
  final photos = ...; // 100 фото

  // Classic
  final sw1 = Stopwatch()..start();
  final classic = await MediaScanner.findBlurryImages(photos);
  sw1.stop();
  print('Classic: ${sw1.elapsedMilliseconds}ms (${classic.length} фото)');

  // Vision
  final sw2 = Stopwatch()..start();
  final vision = await VisionMediaScanner.findBlurryImages(photos);
  sw2.stop();
  print('Vision: ${sw2.elapsedMilliseconds}ms (${vision.length} фото)');

  // Сравнение
  final speedup = sw1.elapsedMilliseconds / sw2.elapsedMilliseconds;
  print('Vision быстрее в ${speedup.toStringAsFixed(2)}x раз');
}
```

**Ожидаемый результат:** ✅ Оба алгоритма завершаются за разумное время

### 10. Интеграционный тест

```dart
void testIntegration() async {
  print('=== Интеграционный тест ===\n');

  // 1. Проверка доступности
  final isAvailable = await VisionPlatformChannel.isAvailable();
  print('1. Vision доступен: $isAvailable');

  if (!isAvailable) {
    print('❌ Vision Framework недоступен');
    return;
  }

  // 2. Загрузка фото
  final photos = await PhotoManager.getAssetList(...);
  print('2. Загружено ${photos.length} фото');

  // 3. Анализ
  print('3. Запуск анализа...');
  final blurry = await VisionMediaScanner.findBlurryImages(photos);
  print('   Найдено размытых: ${blurry.length}');

  // 4. Статистика
  final stats = VisionMediaScanner.getDetectionStats(blurry);
  print('4. Статистика:');
  print('   Vision: ${stats['vision']}');
  print('   Classic: ${stats['classic']}');

  // 5. Проверка результатов
  if (blurry.isNotEmpty) {
    final first = blurry.first;
    print('5. Первое размытое фото:');
    print('   ID: ${first.entity.id}');
    print('   Имя: ${first.entity.title}');
    print('   Источник: ${first.metadata?['detectionSource']}');
  }

  print('\n✅ Интеграционный тест завершен');
}
```

**Ожидаемый результат:** ✅ Весь поток работает end-to-end

## 🔍 Ручное тестирование в UI

### Шаги:

1. Запустите приложение на iPhone (iOS 13.0+)
2. Перейдите в раздел "Размытые фото"
3. Нажмите "Сканировать"
4. Проверьте:
   - ✅ Сканирование запускается
   - ✅ Прогресс отображается
   - ✅ Размытые фото найдены
   - ✅ Можно просмотреть результаты
   - ✅ Можно удалить фото

5. Проверьте логи (если `enableVisionLogging = true`):
   ```
   [BlurDetection] ...
   [VisionMediaScanner] ...
   ```

## 📊 Критерии успеха

### Must Have (обязательно)

- [x] ✅ Код компилируется без ошибок
- [ ] ✅ Vision Framework доступен на iOS
- [ ] ✅ Анализ одного фото работает
- [ ] ✅ Batch анализ работает
- [ ] ✅ VisionMediaScanner возвращает результаты
- [ ] ✅ Fallback на Classic работает при ошибках
- [ ] ✅ Конфигурация включения/выключения работает

### Nice to Have (желательно)

- [ ] ✅ Производительность приемлема (< 10 сек для 100 фото)
- [ ] ✅ Согласованность с Classic > 70%
- [ ] ✅ Логирование работает
- [ ] ✅ Статистика корректна
- [ ] ✅ UI не зависает при анализе

## 🐛 Известные проблемы и решения

### Проблема 1: "Vision Framework недоступен"
**Решение:** Убедитесь, что iOS >= 13.0

### Проблема 2: Ошибка компиляции Swift
**Решение:**
```bash
cd ios
pod install
flutter clean
flutter build ios
```

### Проблема 3: Нет результатов от Vision
**Решение:**
- Проверьте `VisionConfig.enabled = true`
- Проверьте `VisionConfig.photo.blurDetection = true`
- Проверьте логи

### Проблема 4: Медленная работа
**Решение:**
- Уменьшите `maxConcurrentVisionRequests` до 2-3
- Используйте `visionAsPrimary = true`
- Разбейте на батчи меньшего размера

### Проблема 5: Отличаются результаты Classic vs Vision
**Решение:** Это нормально! Используйте `visionAsPrimary = false` для объединения

## 📝 Отчет о тестировании

После тестирования заполните:

```
Дата: _____________
Тестировщик: _____________
iOS версия: _____________

Результаты:
[ ] Компиляция: ☐ Pass ☐ Fail
[ ] Доступность Vision: ☐ Pass ☐ Fail
[ ] Анализ фото: ☐ Pass ☐ Fail
[ ] Batch анализ: ☐ Pass ☐ Fail
[ ] VisionMediaScanner: ☐ Pass ☐ Fail
[ ] Конфигурация: ☐ Pass ☐ Fail
[ ] Производительность: ☐ Pass ☐ Fail
[ ] UI тестирование: ☐ Pass ☐ Fail

Комментарии:
_________________________________________________
_________________________________________________
_________________________________________________
```

## 🚀 Готово к production?

Чеклист перед запуском:

- [ ] Все тесты пройдены
- [ ] Производительность приемлема
- [ ] Логирование отключено (`enableVisionLogging = false`)
- [ ] Выбрана стратегия (`visionAsPrimary`)
- [ ] Установлен правильный `minimumConfidence`
- [ ] Документация обновлена
- [ ] Код ревью выполнен

**Рекомендация:** Начните с `enabled = true`, `visionAsPrimary = false` для безопасного rollout.
