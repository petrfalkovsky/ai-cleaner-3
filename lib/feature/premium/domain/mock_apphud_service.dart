import 'dart:async';
import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:flutter/foundation.dart';

/// Mock-сервис для тестирования Apphud на симуляторе
///
/// Эмулирует работу Apphud без реального подключения к App Store
/// Используется когда USE_MOCK_APPHUD=true в .env
class MockApphudService {
  static final MockApphudService _instance = MockApphudService._internal();
  factory MockApphudService() => _instance;
  MockApphudService._internal();

  // Product IDs
  static const String weekProductId = 'id_week';
  static const String yearProductId = 'id_year';
  static const String lifetimeProductId = 'id_lifetime';

  // Stream для уведомлений об изменении статуса подписки
  final _premiumStatusController = StreamController<bool>.broadcast();
  Stream<bool> get premiumStatusStream => _premiumStatusController.stream;

  bool _isInitialized = false;
  bool _isPremium = false;
  bool get isPremium => _isPremium;

  // Mock продукты
  List<ApphudProduct> _products = [];
  List<ApphudProduct> get products => _products;

  /// Инициализация mock-режима
  Future<void> initialize(String apiKey) async {
    if (_isInitialized) {
      debugPrint('🧪 MockApphudService: Уже инициализирован');
      return;
    }

    debugPrint('🧪 MockApphudService: ✅ Mock-режим активирован (тестирование на симуляторе)');
    debugPrint('🧪 MockApphudService: API Key игнорируется в mock-режиме');

    // Создаем mock-продукты
    await _loadMockProducts();

    _isInitialized = true;
    debugPrint('🧪 MockApphudService: ✅ Инициализация завершена');
  }

  /// Загрузка mock-продуктов
  Future<void> _loadMockProducts() async {
    debugPrint('🧪 MockApphudService: Загрузка mock-продуктов...');

    // Создаем mock ApphudProduct
    _products = [
      ApphudProduct(
        productId: weekProductId,
        store: 'app_store',
        name: 'Weekly Premium Subscription',
        paywallIdentifier: 'pro_paywall',
      ),
      ApphudProduct(
        productId: yearProductId,
        store: 'app_store',
        name: 'Yearly Premium Subscription',
        paywallIdentifier: 'pro_paywall',
      ),
      ApphudProduct(
        productId: lifetimeProductId,
        store: 'app_store',
        name: 'Lifetime Premium Access',
        paywallIdentifier: 'pro_paywall',
      ),
    ];

    debugPrint('🧪 MockApphudService: ✅ Загружено ${_products.length} mock-продуктов:');
    for (var product in _products) {
      debugPrint('   - ${product.productId}: ${product.name}');
    }
  }

  /// Mock покупка
  Future<bool> purchase(String productId) async {
    debugPrint('🧪 MockApphudService: 🛒 Покупка mock-продукта: $productId');

    // Симулируем задержку покупки
    await Future.delayed(const Duration(milliseconds: 500));

    // Активируем premium
    _isPremium = true;
    _premiumStatusController.add(_isPremium);

    debugPrint('🧪 MockApphudService: ✅ Mock-покупка успешна! Premium активирован');
    return true;
  }

  /// Mock восстановление покупок
  Future<bool> restorePurchases() async {
    debugPrint('🧪 MockApphudService: 🔄 Восстановление mock-покупок...');

    // Симулируем задержку
    await Future.delayed(const Duration(milliseconds: 500));

    // Если premium уже был активирован, восстанавливаем
    if (_isPremium) {
      debugPrint('🧪 MockApphudService: ✅ Mock-покупки восстановлены');
      _premiumStatusController.add(_isPremium);
      return true;
    } else {
      debugPrint('🧪 MockApphudService: ⚠️ Нет активных mock-покупок для восстановления');
      return false;
    }
  }

  /// Получить продукт по ID
  ApphudProduct? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.productId == productId);
    } catch (e) {
      debugPrint('🧪 MockApphudService: Продукт $productId не найден');
      return null;
    }
  }

  /// Сбросить premium статус (для тестирования)
  void resetPremiumStatus() {
    debugPrint('🧪 MockApphudService: ⚠️ Сброс premium статуса');
    _isPremium = false;
    _premiumStatusController.add(_isPremium);
  }

  /// Освобождение ресурсов
  void dispose() {
    _premiumStatusController.close();
    _isInitialized = false;
  }
}
