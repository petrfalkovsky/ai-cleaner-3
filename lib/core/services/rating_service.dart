import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Умный сервис для показа рейтинга приложения в правильные моменты
///
/// Apple ограничивает нативный диалог рейтинга (requestReview):
/// - Максимум 3 раза в год для каждого пользователя
/// - Может не показаться, если пользователь уже видел диалог недавно
///
/// Этот сервис отслеживает правильные моменты для показа рейтинга:
/// ✅ После удаления 50+ фотографий
/// ✅ После 3-го запуска приложения
/// ✅ После успешной очистки 1GB+ места
/// ✅ Не чаще 1 раза в 30 дней
class RatingService {
  static const String _keyAppLaunchCount = 'app_launch_count';
  static const String _keyTotalDeletedFiles = 'total_deleted_files';
  static const String _keyTotalFreedSpace = 'total_freed_space_bytes';
  static const String _keyLastRatingRequestDate = 'last_rating_request_date';
  static const String _keyRatingShown = 'rating_shown';

  // Пороговые значения для показа рейтинга
  static const int _minAppLaunches = 3; // Минимум 3 запуска
  static const int _minDeletedFiles = 50; // Минимум 50 удаленных файлов
  static const int _minFreedSpaceGB = 1; // Минимум 1GB освобожденного места
  static const int _minDaysBetweenRequests = 30; // Минимум 30 дней между показами

  final InAppReview _inAppReview = InAppReview.instance;

  /// Увеличивает счетчик запусков приложения
  /// Вызывать в main() при старте приложения
  Future<void> incrementAppLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_keyAppLaunchCount) ?? 0;
      await prefs.setInt(_keyAppLaunchCount, currentCount + 1);

      debugPrint('[RatingService] App launch count: ${currentCount + 1}');

      // Проверяем, можно ли показать рейтинг после запуска
      if (currentCount + 1 == _minAppLaunches) {
        await _tryShowRating(reason: 'Достигнуто $_minAppLaunches запусков');
      }
    } catch (e) {
      debugPrint('[RatingService] Error incrementing app launch: $e');
    }
  }

  /// Записывает успешное удаление файлов
  /// Вызывать после удаления файлов в Cleaner
  Future<void> recordDeletedFiles({
    required int count,
    required int freedSpaceBytes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Обновляем общее количество удаленных файлов
      final totalDeleted = (prefs.getInt(_keyTotalDeletedFiles) ?? 0) + count;
      await prefs.setInt(_keyTotalDeletedFiles, totalDeleted);

      // Обновляем общее освобожденное место
      final totalFreed =
          (prefs.getInt(_keyTotalFreedSpace) ?? 0) + freedSpaceBytes;
      await prefs.setInt(_keyTotalFreedSpace, totalFreed);

      final freedGB = freedSpaceBytes / (1024 * 1024 * 1024);
      final totalFreedGB = totalFreed / (1024 * 1024 * 1024);

      debugPrint(
        '[RatingService] Deleted: $count files, '
        'freed: ${freedGB.toStringAsFixed(2)}GB, '
        'total: $totalDeleted files, ${totalFreedGB.toStringAsFixed(2)}GB',
      );

      // Проверяем условия для показа рейтинга
      if (count >= _minDeletedFiles) {
        await _tryShowRating(
          reason: 'Удалено $count файлов за раз (>= $_minDeletedFiles)',
        );
      } else if (freedSpaceBytes >= _minFreedSpaceGB * 1024 * 1024 * 1024) {
        await _tryShowRating(
          reason:
              'Освобождено ${freedGB.toStringAsFixed(1)}GB за раз (>= $_minFreedSpaceGB GB)',
        );
      } else if (totalDeleted >= _minDeletedFiles * 2 &&
          !await _hasShownRating()) {
        // Если в сумме удалено много файлов, но еще не показывали рейтинг
        await _tryShowRating(
          reason: 'Всего удалено $totalDeleted файлов',
        );
      }
    } catch (e) {
      debugPrint('[RatingService] Error recording deleted files: $e');
    }
  }

  /// Пытается показать нативный диалог рейтинга
  /// Проверяет все условия перед показом
  Future<void> _tryShowRating({required String reason}) async {
    try {
      // Проверяем, доступен ли рейтинг на платформе
      if (!await _inAppReview.isAvailable()) {
        debugPrint('[RatingService] In-app review not available');
        return;
      }

      // Проверяем, не показывали ли недавно
      if (!await _canShowRating()) {
        debugPrint('[RatingService] Cannot show rating yet (too soon)');
        return;
      }

      debugPrint('[RatingService] ✅ Showing rating dialog: $reason');

      // Показываем нативный диалог
      await _inAppReview.requestReview();

      // Записываем время показа
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _keyLastRatingRequestDate,
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setBool(_keyRatingShown, true);
    } catch (e) {
      debugPrint('[RatingService] Error showing rating: $e');
    }
  }

  /// Проверяет, можно ли показать рейтинг
  /// (прошло достаточно времени с последнего показа)
  Future<bool> _canShowRating() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRequestMillis = prefs.getInt(_keyLastRatingRequestDate);

      if (lastRequestMillis == null) {
        return true; // Еще ни разу не показывали
      }

      final lastRequest =
          DateTime.fromMillisecondsSinceEpoch(lastRequestMillis);
      final daysSinceLastRequest = DateTime.now().difference(lastRequest).inDays;

      return daysSinceLastRequest >= _minDaysBetweenRequests;
    } catch (e) {
      debugPrint('[RatingService] Error checking if can show rating: $e');
      return false;
    }
  }

  /// Проверяет, показывали ли уже рейтинг хотя бы раз
  Future<bool> _hasShownRating() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyRatingShown) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Получает статистику для отладки
  Future<Map<String, dynamic>> getStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRequestMillis = prefs.getInt(_keyLastRatingRequestDate);

      return {
        'appLaunchCount': prefs.getInt(_keyAppLaunchCount) ?? 0,
        'totalDeletedFiles': prefs.getInt(_keyTotalDeletedFiles) ?? 0,
        'totalFreedSpaceGB':
            (prefs.getInt(_keyTotalFreedSpace) ?? 0) / (1024 * 1024 * 1024),
        'lastRatingRequestDate': lastRequestMillis != null
            ? DateTime.fromMillisecondsSinceEpoch(lastRequestMillis)
                .toIso8601String()
            : null,
        'ratingShown': prefs.getBool(_keyRatingShown) ?? false,
        'canShowRating': await _canShowRating(),
      };
    } catch (e) {
      debugPrint('[RatingService] Error getting stats: $e');
      return {};
    }
  }

  /// Сбрасывает все данные (для тестирования)
  Future<void> resetForTesting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAppLaunchCount);
      await prefs.remove(_keyTotalDeletedFiles);
      await prefs.remove(_keyTotalFreedSpace);
      await prefs.remove(_keyLastRatingRequestDate);
      await prefs.remove(_keyRatingShown);
      debugPrint('[RatingService] Reset all data for testing');
    } catch (e) {
      debugPrint('[RatingService] Error resetting: $e');
    }
  }
}
