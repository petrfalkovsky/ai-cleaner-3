# ai_cleaner

Проект создан на Flutter 3.35.3

#### Проверить, какая версия флаттера у вас установлена, в терминале из корня проекта
```shell 
flutter --version 
```
скачать установить фреймворк можно по гайду в документации флаттер https://docs.flutter.dev/get-started/quick

#### После установки окружения, установите зависимости
```shell 
flutter pub get 
```

#### Сгенерируйте файлы
```shell 
dart run build_runner build --delete-conflicting-outputs 
```

#### Если устанавливаете новые локали (переводы) или просто новые тексты, сгенерируйте локазизацию intl
```shell 
dart run intl_utils:generate 
```

#### Генерация pigeon для межплатформенного взаимодействия:
```shell
# Создайте необходимые директории
mkdir -p ios/Runner/Generated

# Затем запустите генерацию
dart run pigeon \
  --input lib/core/pigeon/media_api.dart \
  --dart_out lib/generated/pigeon/media_api.dart \
  --swift_out ios/Runner/MediaScannerApi.swift

# или альтернативную серию комнанд для генерации
dart run pigeon --input lib/core/pigeon/media_api.dart --dart_out lib/generated/pigeon/media_api.dart --objc_header_out ios/Runner/pigeon/MediaScannerApi.h --objc_source_out ios/Runner/pigeon/MediaScannerApi.m --swift_out ios/Runner/pigeon/MediaScannerApi.swift
```

#### ВАЖНО: После генерации Pigeon-файлов
- Откройте проект в Xcode: `open ios/Runner.xcworkspace`
- Перетащите файл `MediaScannerApi.swift` в группу Runner в Xcode
- Убедитесь, что стоит галочка "Copy items if needed" и выбран Target "Runner"

#### Чтобы заменить иконку приложения, разместите в assets/app_icon.png картинку без прозрачных полей и закруглений, а затем сгенерируйте иконки приложения командой
```shell 
dart run flutter_launcher_icons
```

#### Запустить код можно на iOS-симуляторе для этого нужно установить Xcode 16.2 (на других версиях Xcode запуск не тестировался)
```shell 
flutter run
```

#### Короткое видео с основными функциями:
<!-- [Demo](https://github.com/) -->