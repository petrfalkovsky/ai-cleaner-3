import 'dart:math' as math;

import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/animated_background.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../../feature/gallery/presentation/cubit/gallery_assets/gallery_assets_cubit.dart';
import '../../core/extensions/core_extensions.dart';
import '../../core/router/router.gr.dart';
import '../../core/theme/button.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pixelarticons/pixel.dart';

@RoutePage()
class PermissionRequestPage extends StatelessWidget {
  const PermissionRequestPage({super.key});

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
                  onTap: () async {
                    final state = await PhotoManager.requestPermissionExtend();
                    if (state.hasAccess) {
                      if (!context.mounted) return;
                      await context.read<GalleryAssetsCubit>().loadAssets();
                      if (!context.mounted) return;
                      context.router.replaceAll([HomeRoute()]);
                    }
                  },
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
                      child: const Text(
                        'Give gallery access',
                        style: TextStyle(
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
