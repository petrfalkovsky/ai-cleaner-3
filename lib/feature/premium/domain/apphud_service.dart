import 'dart:async';
import 'package:ai_cleaner_2/core/services/analytics_service.dart';
import 'package:apphud/apphud.dart';
import 'package:apphud/models/apphud_models/apphud_paywalls.dart';
import 'package:apphud/models/apphud_models/apphud_placement.dart';
import 'package:apphud/models/apphud_models/apphud_subscription.dart';
import 'package:apphud/models/apphud_models/apphud_non_renewing_purchase.dart';
import 'package:apphud/models/apphud_models/apphud_user.dart';
import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:apphud/models/apphud_models/android/android_purchase_wrapper.dart';
import 'package:apphud/models/apphud_models/composite/apphud_product_composite.dart';
import 'package:apphud/models/apphud_models/apphud_debug_level.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'mock_apphud_service.dart';

/// Сервис для работы с Apphud SDK (версия 2.7.4)
/// Управляет подписками, аналитикой и валидацией покупок
///
/// ВАЖНО: Использует ApphudListener для получения paywalls и продуктов
/// Продукты загружаются автоматически через Apphud SDK
///
/// MOCK MODE: Установите USE_MOCK_APPHUD=true в .env для тестирования на симуляторе
class ApphudService implements ApphudListener {
  static final ApphudService _instance = ApphudService._internal();
  factory ApphudService() => _instance;
  ApphudService._internal();

  // Product IDs согласно структуре Apphud
  static const String weekProductId = 'id_week';
  static const String yearProductId = 'id_year';
  static const String lifetimeProductId = 'id_lifetime';

  // Paywall identifier
  static const String mainPaywallId = 'pro_paywall';

  // Permission Group
  static const String premiumPermissionGroup = 'Premium';

  // Mock режим
  bool _isMockMode = false;
  bool get isMockMode => _isMockMode;
  final MockApphudService _mockService = MockApphudService();

  // Stream для уведомлений об изменении статуса подписки
  final _premiumStatusController = StreamController<bool>.broadcast();
  Stream<bool> get premiumStatusStream => _isMockMode
      ? MockApphudService().premiumStatusStream
      : _premiumStatusController.stream;

  bool _isInitialized = false;
  bool _isPremium = false;
  bool get isPremium => _isMockMode ? _mockService.isPremium : _isPremium;

  // Продукты загружаются через Apphud paywalls
  ApphudPaywalls? _paywalls;
  ApphudPaywalls? get paywalls => _paywalls;

  List<ApphudProduct> _products = [];
  List<ApphudProduct> get products => _products;

  ApphudUser? _apphudUser;

  @override
  Future<void> apphudDidChangeUserID(String userId) async {
    debugPrint('🔐 ApphudService: 👤 User ID changed: $userId');
  }

  @override
  Future<void> apphudDidFecthProducts(List<ApphudProductComposite> products) async {
    debugPrint('🔐 ApphudService: 📦 StoreKit Products fetched: ${products.length}');
    for (var product in products) {
      if (product.skProductWrapper != null) {
        debugPrint('   - iOS: ${product.skProductWrapper!.productIdentifier} - ${product.skProductWrapper!.localizedTitle}');
      }
      if (product.productDetailsWrapper != null) {
        debugPrint('   - Android: ${product.productDetailsWrapper!.productId} - ${product.productDetailsWrapper!.title}');
      }
    }
  }

  @override
  Future<void> apphudNonRenewingPurchasesUpdated(
    List<ApphudNonRenewingPurchase> purchases,
  ) async {
    debugPrint('🔐 ApphudService: 🛒 Non-renewing purchases updated: ${purchases.length}');
    await _checkSubscriptionStatus();
  }

  @override
  Future<void> apphudSubscriptionsUpdated(
    List<ApphudSubscriptionWrapper> subscriptions,
  ) async {
    debugPrint('🔐 ApphudService: 💳 Subscriptions updated: ${subscriptions.length}');
    await _checkSubscriptionStatus();
  }

  @override
  Future<void> paywallsDidFullyLoad(ApphudPaywalls paywalls) async {
    debugPrint('🔐 ApphudService: ✅ Paywalls fully loaded!');
    _paywalls = paywalls;

    // Извлекаем продукты из paywalls
    _products = [];
    for (final paywall in paywalls.paywalls) {
      final products = paywall.products;
      if (products != null && products.isNotEmpty) {
        debugPrint('🔐 ApphudService:   - Paywall: ${paywall.identifier} (${products.length} products)');
        _products.addAll(products);
      }
    }

    debugPrint('🔐 ApphudService: ✅ Загружено ${_products.length} продуктов из ${paywalls.paywalls.length} paywalls');
    debugPrint('🔐 ApphudService: 📋 Детали продуктов:');
    for (var product in _products) {
      final hasSkProduct = product.skProduct != null;
      final hasProductDetails = product.productDetails != null;
      debugPrint('   - ${product.productId}: ${product.name ?? "No name"}');
      debugPrint('     • skProduct: ${hasSkProduct ? "✅ populated" : "❌ NULL"}');
      debugPrint('     • productDetails: ${hasProductDetails ? "✅ populated" : "❌ NULL"}');
      if (hasSkProduct) {
        debugPrint('     • SKProduct ID: ${product.skProduct!.productIdentifier}');
        debugPrint('     • Price: ${product.skProduct!.price} ${product.skProduct!.priceLocale.currencyCode}');
      }
    }
  }

  @override
  Future<void> placementsDidFullyLoad(List<ApphudPlacement> placements) async {
    debugPrint('🔐 ApphudService: 📍 Placements loaded: ${placements.length}');
  }

  @override
  Future<void> userDidLoad(ApphudUser user) async {
    debugPrint('🔐 ApphudService: 👤 User loaded: ${user.userId}');
    _apphudUser = user;
    await _checkSubscriptionStatus();
  }

  @override
  Future<void> apphudDidReceivePurchase(AndroidPurchaseWrapper purchase) async {
    debugPrint('🔐 ApphudService: 💰 Android purchase received');
  }

  // ========== INITIALIZATION ==========

  /// Инициализация Apphud SDK
  ///
  /// Требуется API Key из Apphud Dashboard:
  /// https://app.apphud.com/settings/general
  Future<void> initialize(String apiKey) async {
    if (_isInitialized) {
      debugPrint('🔐 ApphudService: Уже инициализирован');
      return;
    }

    try {
      // Проверяем флаг USE_MOCK_APPHUD
      String? useMockEnv;
      try {
        useMockEnv = dotenv.env['USE_MOCK_APPHUD'];
      } catch (e) {
        debugPrint('🔐 ApphudService: ⚠️ Ошибка чтения .env: $e');
        debugPrint('🔐 ApphudService: ⚠️ Убедитесь что DotEnv.instance.load() вызван в bootstrap');
        rethrow;
      }

      final useMock = useMockEnv?.toLowerCase() == 'true';
      _isMockMode = useMock;

      if (_isMockMode) {
        debugPrint('🧪 ApphudService: ========================================');
        debugPrint('🧪 ApphudService: 🎭 MOCK MODE АКТИВИРОВАН');
        debugPrint('🧪 ApphudService: Тестирование на симуляторе БЕЗ StoreKit');
        debugPrint('🧪 ApphudService: ========================================');
        await _mockService.initialize(apiKey);
        _isInitialized = true;
        return;
      }

      debugPrint('🔐 ApphudService: ========================================');
      debugPrint('🔐 ApphudService: 🚀 PRODUCTION MODE');
      debugPrint('🔐 ApphudService: Начинаем инициализацию с реальным Apphud...');
      debugPrint('🔐 ApphudService: ========================================');

      try {
        // Устанавливаем себя как listener
        Apphud.setListener(listener: this);

        // Включаем debug логи
        await Apphud.enableDebugLogs(level: ApphudDebugLevel.high);

        // Инициализация SDK - это запустит все callbacks
        debugPrint('🔐 ApphudService: Запускаем Apphud.start()...');
        final user = await Apphud.start(apiKey: apiKey);
        debugPrint('🔐 ApphudService: ✅ Apphud.start() завершен, user: ${user.userId}');

        // Инициализация AppsFlyer + ASA (после Apphud.start)
        await AnalyticsService.init();

        _isInitialized = true;
        debugPrint('🔐 ApphudService: ✅ Инициализация завершена успешно');
      } catch (e) {
        debugPrint('🔐 ApphudService: ❌ Ошибка инициализации: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('🔐 ApphudService: ❌ CRITICAL ERROR в initialize(): $e');
      rethrow;
    }
  }

  /// Проверка статуса подписки
  Future<void> _checkSubscriptionStatus() async {
    try {
      // Получаем активные подписки
      final subscriptions = await Apphud.subscriptions();
      final hasActiveSubscription = subscriptions.any((s) => s.isActive == true);

      // Проверяем non-renewing purchases (lifetime)
      final purchases = await Apphud.nonRenewingPurchases();
      final hasActivePurchase = purchases.any((p) => p.isActive == true);

      final newPremiumStatus = hasActiveSubscription || hasActivePurchase;

      if (_isPremium != newPremiumStatus) {
        _isPremium = newPremiumStatus;
        _premiumStatusController.add(_isPremium);

        final statusEmoji = _isPremium ? '✅' : '❌';
        debugPrint('🔐 ApphudService: $statusEmoji Premium статус изменен: $_isPremium');
      }

      debugPrint('🔐 ApphudService: Подписок: ${subscriptions.length}, Покупок: ${purchases.length}');
    } catch (e) {
      debugPrint('🔐 ApphudService: Ошибка проверки статуса: $e');
    }
  }

  // ========== PURCHASE METHODS ==========

  /// Покупка продукта
  ///
  /// [productId] - ID продукта (id_week, id_year, id_lifetime)
  /// Или передайте ApphudProductComposite напрямую
  ///
  /// В mock-режиме эмулирует покупку
  Future<bool> purchase(String productId) async {
    debugPrint('🔐 ApphudService: 🛒 Покупка продукта: $productId (Mock: $_isMockMode)');

    if (!_isInitialized) {
      debugPrint('🔐 ApphudService: ❌ SDK не инициализирован');
      return false;
    }

    // Mock режим
    if (_isMockMode) {
      return await _mockService.purchase(productId);
    }

    // Production режим
    if (_products.isEmpty) {
      debugPrint('🔐 ApphudService: ❌ Продукты не загружены. Ожидайте paywallsDidFullyLoad callback');
      return false;
    }

    // Находим продукт по ID
    ApphudProduct? product;
    try {
      product = _products.firstWhere((p) => p.productId == productId);
    } catch (e) {
      debugPrint('🔐 ApphudService: ❌ Продукт $productId не найден в загруженных продуктах');
      debugPrint('🔐 ApphudService: Доступные продукты: ${_products.map((p) => p.productId).join(", ")}');
      return false;
    }

    debugPrint('🔐 ApphudService: Начинаем покупку: ${product.productId}');

    try {
      // Покупка через Apphud SDK
      final result = await Apphud.purchase(product: product);

      debugPrint('🔐 ApphudService: Результат покупки - error: ${result.error}');

      if (result.error == null) {
        debugPrint('🔐 ApphudService: ✅ Покупка успешна!');
        // Проверяем статус после покупки
        await _checkSubscriptionStatus();
        return true;
      } else {
        debugPrint('🔐 ApphudService: ❌ Ошибка покупки: ${result.error}');
        return false;
      }
    } catch (e) {
      debugPrint('🔐 ApphudService: ❌ Исключение при покупке: $e');
      return false;
    }
  }

  /// Восстановление покупок
  Future<bool> restorePurchases() async {
    debugPrint('🔐 ApphudService: 🔄 Восстановление покупок (Mock: $_isMockMode)...');

    if (!_isInitialized) {
      debugPrint('🔐 ApphudService: ❌ SDK не инициализирован');
      return false;
    }

    // Mock режим
    if (_isMockMode) {
      return await _mockService.restorePurchases();
    }

    // Production режим
    try {
      final result = await Apphud.restorePurchases();

      debugPrint('🔐 ApphudService: Результат восстановления - error: ${result.error}');

      if (result.error != null) {
        debugPrint('🔐 ApphudService: ❌ Ошибка восстановления: ${result.error}');
        return false;
      }

      // Проверяем статус после восстановления
      await _checkSubscriptionStatus();

      final statusText = _isPremium ? '✅ Покупки восстановлены' : '⚠️ Активные покупки не найдены';
      debugPrint('🔐 ApphudService: $statusText');

      return _isPremium;
    } catch (e) {
      debugPrint('🔐 ApphudService: ❌ Исключение при восстановлении: $e');
      return false;
    }
  }

  /// Получить продукт по ID
  ApphudProduct? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.productId == productId);
    } catch (e) {
      debugPrint('🔐 ApphudService: Продукт $productId не найден');
      return null;
    }
  }

  /// Проверить доступ к premium
  Future<bool> hasAccess(String permissionGroup) async {
    try {
      final isEntitled = await Apphud.hasActiveSubscription();
      return isEntitled == true;
    } catch (e) {
      debugPrint('🔐 ApphudService: Ошибка проверки доступа: $e');
      return false;
    }
  }

  /// Освобождение ресурсов
  void dispose() {
    _premiumStatusController.close();
    _isInitialized = false;
  }

  // ===== ДЛЯ ТЕСТИРОВАНИЯ =====

  /// Принудительно установить премиум статус (только для тестирования!)
  void setTestPremiumStatus(bool isPremium) {
    debugPrint('🔐 ApphudService: ⚠️ ТЕСТОВЫЙ РЕЖИМ - Premium ${isPremium ? "активирован" : "деактивирован"}');

    if (_isMockMode) {
      // В mock режиме сбрасываем через mock service
      if (!isPremium) {
        _mockService.resetPremiumStatus();
      }
    } else {
      _isPremium = isPremium;
      _premiumStatusController.add(_isPremium);
    }
  }

  /// Сбросить premium статус в mock режиме (для тестирования restore)
  void resetMockPremium() {
    if (_isMockMode) {
      debugPrint('🧪 ApphudService: Сброс mock premium для тестирования restore');
      _mockService.resetPremiumStatus();
    }
  }
}
