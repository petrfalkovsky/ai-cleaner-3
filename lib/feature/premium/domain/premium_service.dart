import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Сервис для управления премиум-подписками
class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Состояние премиум-подписки
  bool _isPremium = false;
  bool get isPremium => _isPremium;

  // Product IDs
  static const String trialProductId = 'ai_cleaner_premium_trial';

  // Список доступных продуктов
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  // Stream для уведомлений об изменении статуса
  final _premiumStatusController = StreamController<bool>.broadcast();
  Stream<bool> get premiumStatusStream => _premiumStatusController.stream;

  /// Инициализация сервиса
  Future<void> initialize() async {
    debugPrint('🔐 PremiumService: Инициализация...');

    // Проверяем доступность IAP
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      debugPrint('🔐 PremiumService: In-App Purchase недоступен');
      return;
    }

    // Подписываемся на обновления покупок
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );

    // Загружаем список продуктов
    await _loadProducts();

    // Восстанавливаем покупки при старте
    await restorePurchases();

    debugPrint('🔐 PremiumService: Инициализация завершена');
  }

  /// Загрузка списка продуктов
  Future<void> _loadProducts() async {
    const Set<String> productIds = {trialProductId};

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(productIds);

    if (response.error != null) {
      debugPrint('🔐 PremiumService: Ошибка загрузки продуктов: ${response.error}');
      return;
    }

    if (response.productDetails.isEmpty) {
      debugPrint('🔐 PremiumService: Продукты не найдены');
      debugPrint('🔐 PremiumService: Для тестирования используйте StoreKit Configuration');
      return;
    }

    _products = response.productDetails;
    debugPrint('🔐 PremiumService: Загружено ${_products.length} продуктов');
    for (var product in _products) {
      debugPrint('   - ${product.id}: ${product.title} (${product.price})');
    }
  }

  /// Обработка обновлений покупок
  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      debugPrint('🔐 PremiumService: Обновление покупки: ${purchase.productID} - ${purchase.status}');

      if (purchase.status == PurchaseStatus.pending) {
        // Покупка в процессе
        debugPrint('🔐 PremiumService: Покупка в процессе...');
      } else if (purchase.status == PurchaseStatus.error) {
        // Ошибка покупки
        debugPrint('🔐 PremiumService: Ошибка покупки: ${purchase.error}');
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Покупка успешна
        debugPrint('🔐 PremiumService: Покупка успешна! Активируем Premium');
        await _activatePremium(purchase);
      }

      // Завершаем покупку
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  /// Активация премиум-статуса
  Future<void> _activatePremium(PurchaseDetails purchase) async {
    // TODO: Здесь должна быть верификация покупки на вашем сервере
    // Для тестирования просто активируем премиум
    _isPremium = true;
    _premiumStatusController.add(true);
    debugPrint('🔐 PremiumService: ✅ Premium активирован!');
  }

  /// Покупка подписки
  Future<bool> purchaseSubscription() async {
    if (_products.isEmpty) {
      debugPrint('🔐 PremiumService: Нет доступных продуктов');
      return false;
    }

    final ProductDetails product = _products.first;
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );

    try {
      debugPrint('🔐 PremiumService: Начинаем покупку: ${product.id}');
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      debugPrint('🔐 PremiumService: buyNonConsumable вернул: $success');
      return success;
    } catch (e) {
      debugPrint('🔐 PremiumService: Ошибка при покупке: $e');
      return false;
    }
  }

  /// Восстановление покупок
  Future<void> restorePurchases() async {
    debugPrint('🔐 PremiumService: Восстановление покупок...');
    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('🔐 PremiumService: Запрос на восстановление отправлен');
    } catch (e) {
      debugPrint('🔐 PremiumService: Ошибка восстановления: $e');
    }
  }

  void _updateStreamOnDone() {
    debugPrint('🔐 PremiumService: Purchase stream завершен');
    _subscription?.cancel();
  }

  void _updateStreamOnError(dynamic error) {
    debugPrint('🔐 PremiumService: Ошибка в purchase stream: $error');
  }

  /// Освобождение ресурсов
  void dispose() {
    _subscription?.cancel();
    _premiumStatusController.close();
  }

  // ===== ДЛЯ ТЕСТИРОВАНИЯ =====

  /// Активировать премиум вручную (только для тестирования!)
  void enablePremiumForTesting() {
    debugPrint('🔐 PremiumService: ⚠️ ТЕСТОВЫЙ РЕЖИМ - Premium активирован вручную');
    _isPremium = true;
    _premiumStatusController.add(true);
  }

  /// Деактивировать премиум вручную (только для тестирования!)
  void disablePremiumForTesting() {
    debugPrint('🔐 PremiumService: ⚠️ ТЕСТОВЫЙ РЕЖИМ - Premium деактивирован вручную');
    _isPremium = false;
    _premiumStatusController.add(false);
  }
}
