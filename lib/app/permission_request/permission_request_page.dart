import 'dart:math' as math;

import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/animated_background.dart';
import 'package:ai_cleaner_2/generated/l10n.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../../feature/gallery/presentation/cubit/gallery_assets/gallery_assets_cubit.dart';
import '../../core/router/router.gr.dart';
import 'package:photo_manager/photo_manager.dart';

@RoutePage()
class PermissionRequestPage extends StatefulWidget {
  const PermissionRequestPage({super.key});

  @override
  State<PermissionRequestPage> createState() => _PermissionRequestPageState();
}

class _PermissionRequestPageState extends State<PermissionRequestPage> {
  bool _isLoading = false;

  Future<void> _requestPermission() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final startTime = DateTime.now();

    try {
      final state = await PhotoManager.requestPermissionExtend();

      // Гарантируем минимум 3 секунды loading
      final elapsed = DateTime.now().difference(startTime);
      final remaining = const Duration(seconds: 3) - elapsed;
      if (remaining.isNegative == false) {
        await Future.delayed(remaining);
      }

      if (!mounted) return;

      if (state.hasAccess) {
        await context.read<GalleryAssetsCubit>().loadAssets();
        if (!mounted) return;
        context.router.replaceAll([HomeRoute()]);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 80),
      child: Scaffold(
        body: Stack(
          children: [
            // Анимированный фон с паттернами
            const Positioned.fill(child: AnimatedBackground()),

            // Кнопка "Оставить"
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 300),
                GestureDetector(
                  onTap: _isLoading ? null : _requestPermission,
                  child: LiquidGlass(
                    settings: LiquidGlassSettings(
                      blur: 5,
                      ambientStrength: 0.8,
                      lightAngle: 0.2 * math.pi,
                      glassColor: CupertinoColors.white.withOpacity(0.3),
                      thickness: 15,
                    ),
                    shape: const LiquidRoundedSuperellipse(borderRadius: Radius.circular(16)),
                    glassContainsChild: false,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                              radius: 12,
                            )
                          : Text(
                              Locales.current.continue_action,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
