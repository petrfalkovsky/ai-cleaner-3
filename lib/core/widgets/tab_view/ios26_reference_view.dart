import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOS 26 Reference Screen Helper
/// Открывает полностью нативный iOS 26 экран через Method Channel
/// Используется как Swift модуль во Flutter проекте
class iOS26ReferenceHelper {
  static const MethodChannel _channel = MethodChannel('ios26_reference_channel');

  /// Открыть нативный iOS 26 Reference Screen (UIKit версия)
  /// Экран откроется модально в полноэкранном режиме
  static Future<void> openNativeScreen() async {
    if (!Platform.isIOS) {
      throw PlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'iOS 26 Reference Screen is only available on iOS',
      );
    }

    try {
      await _channel.invokeMethod('openNativeScreen');
    } on PlatformException catch (e) {
      print('Error opening native screen: ${e.message}');
      rethrow;
    }
  }

  /// Открыть ОРИГИНАЛЬНЫЙ SwiftUI экран из iOS-26-by-Examples
  /// Это NewTabView.swift без каких-либо изменений
  static Future<void> openOriginalSwiftUIScreen() async {
    if (!Platform.isIOS) {
      throw PlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'Original SwiftUI Screen is only available on iOS',
      );
    }

    try {
      await _channel.invokeMethod('openOriginalSwiftUIScreen');
    } on PlatformException catch (e) {
      print('Error opening original SwiftUI screen: ${e.message}');
      rethrow;
    }
  }
}
