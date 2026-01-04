import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:apphud/apphud.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_data.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_provider.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Сервис аналитики для AppsFlyer + Apphud + ASA
///
/// Управляет:
/// - AppsFlyer SDK инициализацией и событиями
/// - Apple Search Ads (ASA) атрибуцией через Apphud
/// - App Tracking Transparency (ATT) запросом
/// - Device ID генерацией и хранением
class AnalyticsService {
  AnalyticsService._();

  // ---- Константы AppsFlyer ----
  static final _afDevKey = dotenv.env['APSFLYER_AFD_KEY']!;
  static final _iosAppId = dotenv.env['APPLE_APP_ID']!;

  // ---- Хранилище ----
  static const _storage = FlutterSecureStorage();
  static const _deviceIdKey = 'device_id';
  static const _installTrackedKey = 'install_tracked';

  // ---- События ----
  static const _eventInstall = 'app_install';

  // ---- AppsFlyer SDK ----
  static final AppsFlyerOptions _options = AppsFlyerOptions(
    afDevKey: _afDevKey,
    appId: _iosAppId, // только iOS
    showDebug: kDebugMode, // debug mode только в dev сборках
    manualStart: true,
    timeToWaitForATTUserAuthorization: 15,
  );

  static final AppsflyerSdk _appsFlyer = AppsflyerSdk(_options);

  /// Инициализация аналитики
  ///
  /// Вызывать один раз после онбординга
  static Future<void> init() async {
    try {
      // Запрос ATT только на iOS
      if (Platform.isIOS) {
        await _requestATTIfNeeded();
      }

      // Инициализация AppsFlyer SDK
      await _appsFlyer.initSdk(registerConversionDataCallback: true);

      // Обработка conversion data для Apphud
      _appsFlyer.onInstallConversionData((result) async {
        final uid = await _appsFlyer.getAppsFlyerUID();
        final status = result['status'];
        final payload = Map<String, dynamic>.from(result['payload'] as Map);

        if (status == 'success') {
          Apphud.setAttribution(
            provider: ApphudAttributionProvider.appsFlyer,
            data: ApphudAttributionData(rawData: payload),
            identifier: uid,
          );
        } else {
          Apphud.setAttribution(
            provider: ApphudAttributionProvider.appsFlyer,
            data: ApphudAttributionData(rawData: {'error': payload['data']}),
            identifier: uid,
          );
        }
      });

      // Запуск AppsFlyer SDK
      _appsFlyer.startSDK();

      // Apple Search Ads (ASA) атрибуция
      if (kDebugMode) {
        debugPrint('🔄 [Analytics] Not collecting search ads attribution in debug mode');
      } else {
        // Должно вызываться после Apphud.start()
        await Apphud.collectSearchAdsAttribution();
        final idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
        await Apphud.setAdvertisingIdentifier(idfa);
      }

      // Трекинг установки приложения (один раз)
      await _trackInstallIfNeeded();

      debugPrint('✅ [Analytics] Initialized successfully');
    } catch (e, stackTrace) {
      // Ошибки аналитики не должны падать на пользователя
      debugPrint('❌ [Analytics] Error during initialization: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  /// Получить Device ID (генерируется один раз и сохраняется)
  static Future<String> getDeviceId() async {
    try {
      final existing = await _storage.read(key: _deviceIdKey);
      if (existing != null && existing.isNotEmpty) return existing;

      final uuid = _generateUuidV4();
      await _storage.write(key: _deviceIdKey, value: uuid);
      return uuid;
    } catch (e) {
      debugPrint('❌ [Analytics] Error getting device ID: $e');
      return _generateUuidV4();
    }
  }

  /// Получить AppsFlyer UID
  static Future<String?> getAFUID() async {
    try {
      return await _appsFlyer.getAppsFlyerUID();
    } catch (e) {
      debugPrint('❌ [Analytics] Error getting AF UID: $e');
      return null;
    }
  }

  /// Логирование кастомного события в AppsFlyer
  static Future<void> logEvent(String eventName, [Map<String, dynamic>? params]) async {
    try {
      await _appsFlyer.logEvent(eventName, params);
      debugPrint('📊 [Analytics] Event logged: $eventName ${params ?? ""}');
    } catch (e) {
      debugPrint('❌ [Analytics] Error logging event: $e');
    }
  }

  /// Трекинг установки приложения (вызывается один раз)
  static Future<void> _trackInstallIfNeeded() async {
    try {
      final flag = await _storage.read(key: _installTrackedKey);
      if (flag == '1') {
        debugPrint('ℹ️ [Analytics] Install already tracked');
        return;
      }

      await _appsFlyer.logEvent(_eventInstall, null);
      await _storage.write(key: _installTrackedKey, value: '1');
      debugPrint('✅ [Analytics] Install event tracked');
    } catch (e) {
      debugPrint('❌ [Analytics] Error tracking install: $e');
    }
  }

  /// Запрос ATT (App Tracking Transparency) на iOS
  static Future<TrackingStatus> _requestATTIfNeeded() async {
    if (!Platform.isIOS) return TrackingStatus.notSupported;

    try {
      var status = await AppTrackingTransparency.trackingAuthorizationStatus;
      debugPrint('ℹ️ [Analytics] Current ATT status: $status');

      if (status == TrackingStatus.notDetermined) {
        status = await AppTrackingTransparency.requestTrackingAuthorization();
        debugPrint('✅ [Analytics] ATT requested. New status: $status');
      }

      return status;
    } catch (e) {
      debugPrint('❌ [Analytics] Error requesting ATT: $e');
      return TrackingStatus.notSupported;
    }
  }

  /// Генерация UUID v4
  static String _generateUuidV4() => const Uuid().v4();

  /// Проверить, доступен ли AppsFlyer
  static Future<bool> isAppsFlyerAvailable() async {
    try {
      final uid = await _appsFlyer.getAppsFlyerUID();
      return uid != null && uid.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Получить текущий статус ATT
  static Future<TrackingStatus> getTrackingStatus() async {
    if (!Platform.isIOS) return TrackingStatus.notSupported;

    try {
      return await AppTrackingTransparency.trackingAuthorizationStatus;
    } catch (e) {
      debugPrint('❌ [Analytics] Error getting tracking status: $e');
      return TrackingStatus.notSupported;
    }
  }
}
