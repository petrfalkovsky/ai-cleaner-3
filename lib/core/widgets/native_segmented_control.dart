import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Нативный iOS UISegmentedControl с поддержкой iOS 26 дизайна
class NativeSegmentedControl extends StatefulWidget {
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onSegmentChanged;

  const NativeSegmentedControl({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSegmentChanged,
  });

  @override
  State<NativeSegmentedControl> createState() => _NativeSegmentedControlState();
}

class _NativeSegmentedControlState extends State<NativeSegmentedControl> {
  MethodChannel? _channel;

  @override
  Widget build(BuildContext context) {
    // Только для iOS используем нативный компонент
    if (!Platform.isIOS) {
      return _buildFallback();
    }

    return UiKitView(
      viewType: 'native_segmented_control',
      creationParams: {
        'items': widget.items,
        'selectedIndex': widget.selectedIndex,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('native_segmented_control_$id');
    _channel?.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSegmentChanged':
        final int index = call.arguments as int;
        widget.onSegmentChanged(index);
        break;
    }
  }

  /// Fallback для не-iOS платформ (Android, Web, etc)
  Widget _buildFallback() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: widget.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == widget.selectedIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => widget.onSegmentChanged(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  item,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }
}
