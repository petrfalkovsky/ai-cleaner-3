import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Нативный iOS 26 TabView с Summary/Sharing табами, поиском и Bottom Accessory
class NativeTabView extends StatefulWidget {
  final VoidCallback? onRescanTapped;
  final ValueChanged<String>? onSearchTextChanged;
  final ValueChanged<int>? onTabChanged;
  final Function(String tabType, String categoryName)? onCategoryTapped;
  final ScrollController? scrollController;
  final List<Map<String, dynamic>>? photoCategories;
  final List<Map<String, dynamic>>? videoCategories;

  const NativeTabView({
    super.key,
    this.onRescanTapped,
    this.onSearchTextChanged,
    this.onTabChanged,
    this.onCategoryTapped,
    this.scrollController,
    this.photoCategories,
    this.videoCategories,
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

  /// Обновить категории фото
  Future<void> _updatePhotoCategories(List<Map<String, dynamic>> categories) async {
    await _channel?.invokeMethod('updatePhotoCategories', categories);
  }

  /// Обновить категории видео
  Future<void> _updateVideoCategories(List<Map<String, dynamic>> categories) async {
    await _channel?.invokeMethod('updateVideoCategories', categories);
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

    // Отправляем категории после создания view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.photoCategories != null) {
        _updatePhotoCategories(widget.photoCategories!);
      }
      if (widget.videoCategories != null) {
        _updateVideoCategories(widget.videoCategories!);
      }
    });
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

      case 'onCategoryTapped':
        final Map<dynamic, dynamic> args = call.arguments as Map<dynamic, dynamic>;
        final String tabType = args['tabType'] as String;
        final String categoryName = args['categoryName'] as String;
        widget.onCategoryTapped?.call(tabType, categoryName);
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
