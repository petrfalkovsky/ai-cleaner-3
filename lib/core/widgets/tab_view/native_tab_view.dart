import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Нативный iOS 26 TabView с Summary/Sharing табами, поиском и Bottom Accessory
class NativeTabView extends StatefulWidget {
  final VoidCallback? onRescanTapped;
  final ValueChanged<String>? onSearchTextChanged;
  final ValueChanged<int>? onTabChanged;
  final ScrollController? scrollController;

  const NativeTabView({
    super.key,
    this.onRescanTapped,
    this.onSearchTextChanged,
    this.onTabChanged,
    this.scrollController,
  });

  @override
  State<NativeTabView> createState() => _NativeTabViewState();
}

class _NativeTabViewState extends State<NativeTabView> {
  MethodChannel? _channel;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_onScroll);
    if (widget.scrollController == null) {
      _scrollController?.dispose();
    }
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  void _onScroll() {
    if (_channel != null && _scrollController != null) {
      _channel!.invokeMethod('handleScroll', {
        'offsetY': _scrollController!.offset,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Только для iOS
    if (!Platform.isIOS) {
      return _buildFallback();
    }

    return UiKitView(
      viewType: 'ios_tab_view',
      creationParams: {},
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('ios_tab_view_$id');
    _channel?.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onRescanTapped':
        widget.onRescanTapped?.call();
        break;

      case 'onSearchTextChanged':
        final String text = call.arguments as String;
        widget.onSearchTextChanged?.call(text);
        break;

      case 'onTabChanged':
        final int index = call.arguments as int;
        widget.onTabChanged?.call(index);
        break;
    }
  }

  /// Установить активный таб
  Future<void> setSelectedTab(int index) async {
    await _channel?.invokeMethod('setSelectedTab', index);
  }

  /// Fallback для не-iOS платформ
  Widget _buildFallback() {
    return Center(
      child: Text(
        'iOS 26 TabView доступен только на iOS',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
