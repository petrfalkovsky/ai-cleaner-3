# Dev Mode - Руководство

## 🔓 Что это такое?

Dev Mode - это специальный режим разработки, который **полностью отключает все ограничения бесплатной версии** приложения для удобного тестирования.

## ⚙️ Как включить/выключить

### Включить Dev Mode

Откройте файл [lib/core/config/vision_config.dart](lib/core/config/vision_config.dart):

```dart
class VisionConfig {
  /// 🔓 DEV MODE
  static const bool devModeUnlockAll = true; // ← установите true
```

### Выключить Dev Mode (для production)

```dart
class VisionConfig {
  /// 🔓 DEV MODE
  static const bool devModeUnlockAll = false; // ← установите false
```

## ✨ Что разблокирует Dev Mode

При `devModeUnlockAll = true`:

### 📸 Категории фото
- ✅ **Blur** (размытые) - доступны без Premium
- ✅ **Similar** (похожие) - доступны без Premium
- ✅ **Series** (серии) - доступны без Premium
- ✅ **Live Photos** - доступны без Premium
- ✅ **Screenshots** - доступны без Premium

### 🎥 Категории видео
- ✅ **Duplicates** (дубликаты) - доступны без Premium
- ✅ **Screen Recordings** (записи экрана) - доступны без Premium
- ✅ **Short Videos** (короткие) - доступны без Premium
- ✅ **Large Videos** (большие) - доступны без Premium

### 🔒 Premium функции
- ✅ Все лимиты сканирования сняты
- ✅ Все функции разблокированы
- ✅ Замочки не отображаются
- ✅ Premium проверки игнорируются

## 📍 Где используется

Dev Mode автоматически проверяется в:

1. **[home_page.dart](lib/feature/cleaner/presentation/pages/home_page.dart)**
   ```dart
   final bool isLocked = category.requiresPremium && !isPremium && !VisionConfig.devModeUnlockAll;
   ```
   - Строка 551 - для фото категорий
   - Строка 806 - для видео категорий

2. **[media_category_enum.dart](lib/core/enums/media_category_enum.dart)**
   - Определяет, какие категории требуют Premium

## 🧪 Использование для тестирования

### Сценарий 1: Тестирование всех категорий

```dart
// 1. Включите dev mode
VisionConfig.devModeUnlockAll = true;

// 2. Запустите приложение
flutter run

// 3. Все категории доступны без Premium!
```

### Сценарий 2: Тестирование Vision Framework

```dart
// 1. Включите dev mode + Vision
VisionConfig.devModeUnlockAll = true;
VisionConfig.enabled = true;
VisionConfig.photo.blurDetection = true;

// 2. Тестируйте размытые фото с Vision Framework
```

### Сценарий 3: Тестирование Premium паевола

```dart
// 1. Выключите dev mode
VisionConfig.devModeUnlockAll = false;

// 2. Запустите без Premium подписки
// 3. Проверьте, что замочки отображаются правильно
```

## ⚠️ Важные замечания

### 🚨 Перед production релизом:

1. **ОБЯЗАТЕЛЬНО** установите `devModeUnlockAll = false`
2. Проверьте, что все Premium проверки работают
3. Убедитесь, что замочки отображаются
4. Протестируйте paywall

### 🔍 Как проверить текущий статус:

```dart
debugPrint('Dev Mode: ${VisionConfig.devModeUnlockAll}');
```

### 📝 Добавление новых проверок:

Если вы добавляете новые Premium проверки в коде, используйте:

```dart
final bool isLocked = requiresPremium && !isPremium && !VisionConfig.devModeUnlockAll;
```

## 📊 Примеры

### Пример 1: Проверка одной категории

```dart
// home_page.dart
final PhotoCategory category = PhotoCategory.blurry;

final bool isLocked = category.requiresPremium &&
                     !isPremium &&
                     !VisionConfig.devModeUnlockAll;

if (isLocked) {
  // Показать paywall
} else {
  // Открыть категорию
}
```

### Пример 2: Проверка перед сканированием

```dart
void startScan(VideoCategory category) {
  if (category.requiresPremium &&
      !PremiumService().isPremium &&
      !VisionConfig.devModeUnlockAll) {
    // Показать Premium экран
    return;
  }

  // Начать сканирование
}
```

## 🔄 Workflow разработки

### Обычный workflow:

```
1. devModeUnlockAll = true  → Разработка + тестирование
2. devModeUnlockAll = false → Тестирование Premium функций
3. devModeUnlockAll = false → Production релиз
```

### Git workflow:

```bash
# Разработка
git checkout develop
# devModeUnlockAll = true

# Перед коммитом
# devModeUnlockAll = false
git add .
git commit -m "feat: add new feature"

# Production
git checkout main
# ВСЕГДА devModeUnlockAll = false
```

## 🎯 Checklist перед релизом

- [ ] `VisionConfig.devModeUnlockAll = false`
- [ ] Premium проверки работают
- [ ] Замочки отображаются
- [ ] Paywall работает
- [ ] Все категории требуют Premium (кроме free)
- [ ] Протестировано с реальной подпиской

## 📖 Связанные файлы

- [vision_config.dart](lib/core/config/vision_config.dart) - главный конфиг
- [home_page.dart](lib/feature/cleaner/presentation/pages/home_page.dart) - проверки Premium
- [media_category_enum.dart](lib/core/enums/media_category_enum.dart) - определение категорий

---

**Последнее обновление:** 2025-11-30
**Версия:** 1.0.0
