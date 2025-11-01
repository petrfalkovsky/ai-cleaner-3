# Тестирование In-App Purchases в AI Cleaner

## 🎯 Обзор

Премиум-функция "Размытые фото" (Blurry Photos) заблокирована за paywall. Пользователи без подписки видят **золотой замочек** на этой категории и при тапе открывается экран покупки.

---

## 🧪 Способы тестирования покупок

### Способ 1: StoreKit Configuration (Локальное тестирование) ✅ РЕКОМЕНДУЕТСЯ

Это самый простой способ для разработки - не требует настройки App Store Connect.

#### Шаги:

1. **Открыть проект в Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Активировать StoreKit Configuration:**
   - В Xcode: `Product` → `Scheme` → `Edit Scheme...`
   - Вкладка `Run` → `Options`
   - В разделе `StoreKit Configuration` выбрать: `Configuration.storekit`
   - Нажать `Close`

3. **Запустить приложение:**
   ```bash
   flutter run
   ```

4. **Тестировать покупку:**
   - Нажмите на категорию "Размытые" с замочком 🔒
   - Откроется экран Paywall
   - Нажмите "Start Free Trial"
   - Появится iOS диалог подтверждения (локальный, не реальный)
   - Нажмите "Subscribe" или "Buy"
   - ✅ Premium активируется, замочек исчезнет

5. **Проверить управление подписками:**
   - В Xcode: `Debug` → `StoreKit` → `Manage Transactions`
   - Здесь можно отменить, восстановить или удалить покупки

---

### Способ 2: Sandbox Testing (App Store Connect)

Требует настройки App Store Connect и создания тестовых пользователей.

#### Шаги:

1. **Создать продукт в App Store Connect:**
   - Зайти в App Store Connect
   - Выбрать ваше приложение
   - `Features` → `In-App Purchases`
   - Создать новый Non-Consumable продукт
   - Product ID: `ai_cleaner_premium_trial`
   - Reference Name: `Premium Trial`
   - Price: Free Trial + $9.99

2. **Создать Sandbox тестера:**
   - `Users and Access` → `Sandbox Testers`
   - Добавить нового тестера
   - Использовать уникальный email (можно фейковый)

3. **Выйти из App Store на устройстве:**
   - Настройки → App Store → выйти из аккаунта

4. **Запустить приложение:**
   ```bash
   flutter run --release
   ```

5. **При покупке:**
   - Войдите как Sandbox тестер
   - Совершите покупку

---

### Способ 3: Ручная активация (Для разработки) 🛠️

Для быстрого тестирования UI без реальной покупки.

#### Активировать Premium вручную:

```dart
// В любом месте приложения (например, в debug панели)
import 'package:ai_cleaner_2/feature/premium/domain/premium_service.dart';

// Активировать
PremiumService().enablePremiumForTesting();

// Деактивировать
PremiumService().disablePremiumForTesting();
```

#### Пример: Добавить кнопку в Settings Screen

```dart
// В SettingsScreen добавьте:
CupertinoButton(
  child: Text('🔓 Enable Premium (DEV)'),
  onPressed: () {
    PremiumService().enablePremiumForTesting();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Premium activated!')),
    );
  },
)
```

---

## 📱 Тестовый сценарий

### 1. Проверка блокировки категории

✅ **Без Premium:**
- [ ] Категория "Размытые" показывает золотой замочек 🔒
- [ ] При тапе открывается Paywall экран
- [ ] Нельзя открыть список размытых фото

✅ **С Premium:**
- [ ] Замочек не отображается
- [ ] При тапе открывается список размытых фото
- [ ] Можно выбирать и удалять фото

### 2. Проверка Paywall экрана

- [ ] Анимация короны работает
- [ ] Анимация Storage показывает освобождение места
- [ ] Progress bar меняет цвет (красный → зеленый)
- [ ] Тогл "Trial enabled" работает
- [ ] Цена $0.00 отображается
- [ ] Дата через 3 дня корректная
- [ ] Кнопка "Start Free Trial" работает

### 3. Проверка покупки

- [ ] iOS диалог покупки открывается
- [ ] После покупки показывается Success диалог
- [ ] Замочек исчезает
- [ ] Категория "Размытые" разблокируется
- [ ] Можно открыть и использовать

### 4. Проверка восстановления

- [ ] Кнопка "Restore Purchases" работает
- [ ] После восстановления Premium активируется
- [ ] Замочек исчезает

---

## 🐛 Troubleshooting

### Продукты не загружаются

**Ошибка:** `No products found`

**Решение:**
1. Убедитесь что `Configuration.storekit` активирован в Scheme
2. Проверьте Product ID в StoreKit файле: `ai_cleaner_premium_trial`
3. Перезапустите приложение

### Покупка не завершается

**Решение:**
1. Проверьте логи в консоли (фильтр: `🔐 PremiumService`)
2. Убедитесь что StoreKit Configuration активен
3. В Xcode: `Debug` → `StoreKit` → `Clear Transaction History`

### Premium не активируется

**Решение:**
1. Проверьте логи: `🔐 PremiumService: ✅ Premium активирован!`
2. Проверьте `PremiumService().isPremium` в коде
3. Перезапустите приложение

---

## 📊 Логи

Все действия PremiumService логируются с префиксом `🔐`:

```
🔐 PremiumService: Инициализация...
🔐 PremiumService: Загружено 1 продуктов
   - ai_cleaner_premium_trial: Premium Trial ($0.00)
🔐 PremiumService: Начинаем покупку: ai_cleaner_premium_trial
🔐 PremiumService: Обновление покупки: ai_cleaner_premium_trial - purchased
🔐 PremiumService: Покупка успешна! Активируем Premium
🔐 PremiumService: ✅ Premium активирован!
```

Следите за этими логами для отладки!

---

## 🎁 Product Details

**Product ID:** `ai_cleaner_premium_trial`
**Type:** Non-Consumable
**Price:** Free Trial → $9.99
**Trial Duration:** 3 days
**Features:**
- Доступ к категории "Размытые фото"
- Расширенный анализ качества
- Удаление всех размытых фото

---

## ✅ Готово к продакшену?

Перед релизом убедитесь:

- [ ] Product ID совпадает с App Store Connect
- [ ] Sandbox тестирование прошло успешно
- [ ] Убраны все `enablePremiumForTesting()` вызовы
- [ ] Протестировано на реальном устройстве
- [ ] Проверено восстановление покупок
- [ ] Terms & Privacy ссылки обновлены

---

Удачного тестирования! 🚀
