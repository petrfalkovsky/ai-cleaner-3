import 'dart:async';
import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'apphud_service.dart';

/// Сервис для управления премиум-подписками
///
/// Это тонкая обертка над ApphudService для обратной совместимости
/// Использует Apphud SDK для управления подписками и аналитики
class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  final ApphudService _apphudService = ApphudService();
  StreamSubscription<bool>? _apphudSubscription;

  // Состояние премиум-подписки
  bool get isPremium => _apphudService.isPremium;

  // Product IDs - используем Apphud IDs
  static const String weekProductId = ApphudService.weekProductId;
  static const String yearProductId = ApphudService.yearProductId;
  static const String lifetimeProductId = ApphudService.lifetimeProductId;

  // Список доступных продуктов
  List<ApphudProduct> get products => _apphudService.products;

  // Stream для уведомлений об изменении статуса
  final _premiumStatusController = StreamController<bool>.broadcast();
  Stream<bool> get premiumStatusStream => _premiumStatusController.stream;

  /// Инициализация сервиса
  Future<void> initialize() async {
    debugPrint('🔐 PremiumService: Инициализация...');

    try {
      // Получаем API ключ из .env файла
      final apphudApiKey = dotenv.env['APPHUD_API_KEY'];

      if (apphudApiKey == null || apphudApiKey.isEmpty) {
        debugPrint('🔐 PremiumService: ⚠️ APPHUD_API_KEY не найден в .env');
        debugPrint('🔐 PremiumService: ⚠️ Добавьте APPHUD_API_KEY=ваш_ключ в файл .env');
        throw Exception('APPHUD_API_KEY не найден в .env');
      }

      // Инициализируем Apphud
      debugPrint('🔐 PremiumService: Инициализация Apphud SDK...');
      await _apphudService.initialize(apphudApiKey);

      // Подписываемся на изменения статуса от Apphud
      _apphudSubscription = _apphudService.premiumStatusStream.listen((isPremium) {
        _premiumStatusController.add(isPremium);
      });

      // Пробрасываем начальное состояние
      if (_apphudService.isPremium) {
        _premiumStatusController.add(true);
      }

      debugPrint('🔐 PremiumService: ✅ Инициализация завершена');
    } catch (e) {
      debugPrint('🔐 PremiumService: ❌ Ошибка инициализации: $e');
      rethrow;
    }
  }

  /// Покупка подписки
  ///
  /// [productId] - ID продукта (weekProductId, yearProductId, lifetimeProductId)
  Future<bool> purchaseSubscription([String? productId]) async {
    try {
      final targetProductId = productId ?? weekProductId;
      debugPrint('🔐 PremiumService: Покупка через Apphud: $targetProductId');
      return await _apphudService.purchase(targetProductId);
    } catch (e) {
      debugPrint('🔐 PremiumService: Ошибка при покупке: $e');
      return false;
    }
  }

  /// Восстановление покупок
  Future<bool> restorePurchases() async {
    debugPrint('🔐 PremiumService: Восстановление покупок...');

    try {
      return await _apphudService.restorePurchases();
    } catch (e) {
      debugPrint('🔐 PremiumService: Ошибка восстановления: $e');
      return false;
    }
  }

  /// Получить список доступных продуктов Apphud
  List<String> get availableProductIds {
    return products.map((p) => p.productId).toList();
  }

  /// Освобождение ресурсов
  void dispose() {
    _apphudSubscription?.cancel();
    _premiumStatusController.close();
    _apphudService.dispose();
  }

  // ===== ДЛЯ ТЕСТИРОВАНИЯ =====

  /// Активировать премиум вручную (только для тестирования!)
  void enablePremiumForTesting() {
    debugPrint('🔐 PremiumService: ⚠️ ТЕСТОВЫЙ РЕЖИМ - Premium активирован вручную');
    _apphudService.setTestPremiumStatus(true);
  }

  /// Деактивировать премиум вручную (только для тестирования!)
  void disablePremiumForTesting() {
    debugPrint('🔐 PremiumService: ⚠️ ТЕСТОВЫЙ РЕЖИМ - Premium деактивирован вручную');
    _apphudService.setTestPremiumStatus(false);
  }
}
