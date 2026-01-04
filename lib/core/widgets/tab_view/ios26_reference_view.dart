import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// iOS 26 Reference Screen
/// Точная копия NewTabView из iOS-26-by-Examples
/// Нативный UIKit экран с glassmorphism и анимациями
class iOS26ReferenceView extends StatefulWidget {
  const iOS26ReferenceView({super.key});

  @override
  State<iOS26ReferenceView> createState() => _iOS26ReferenceViewState();
}

class _iOS26ReferenceViewState extends State<iOS26ReferenceView> {
  MethodChannel? _channel;

  @override
  Widget build(BuildContext context) {
    // Только для iOS
    if (!Platform.isIOS) {
      return const Center(
        child: Text('iOS 26 Reference View is only available on iOS'),
      );
    }

    // UiKitView для отображения нативного экрана
    return UiKitView(
      viewType: 'ios26_reference_view',
      layoutDirection: TextDirection.ltr,
      creationParams: const <String, dynamic>{},
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
    );
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('ios26_reference_view_$id');

    // TODO: Настроить коммуникацию с нативным экраном при необходимости
  }

  @override
  void dispose() {
    _channel = null;
    super.dispose();
  }
}
