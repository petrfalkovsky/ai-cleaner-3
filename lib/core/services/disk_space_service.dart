import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Сервис для получения информации о дисковом пространстве через platform channels
class DiskSpaceService {
  DiskSpaceService._();

  static final DiskSpaceService instance = DiskSpaceService._();

  static const MethodChannel _channel = MethodChannel('com.ai_cleaner.disk_space');

  /// Получить общий размер диска в GB
  Future<double?> getTotalDiskSpace() async {
    try {
      final result = await _channel.invokeMethod<double>('getTotalDiskSpace');
      return result;
    } catch (e) {
      debugPrint('DiskSpaceService: Error getting total disk space: $e');
      return null;
    }
  }

  /// Получить свободное место на диске в GB
  Future<double?> getFreeDiskSpace() async {
    try {
      final result = await _channel.invokeMethod<double>('getFreeDiskSpace');
      return result;
    } catch (e) {
      debugPrint('DiskSpaceService: Error getting free disk space: $e');
      return null;
    }
  }

  /// Получить используемое место на диске в GB
  Future<double?> getUsedDiskSpace() async {
    try {
      final total = await getTotalDiskSpace();
      final free = await getFreeDiskSpace();

      if (total != null && free != null) {
        return total - free;
      }
      return null;
    } catch (e) {
      debugPrint('DiskSpaceService: Error calculating used disk space: $e');
      return null;
    }
  }
}
