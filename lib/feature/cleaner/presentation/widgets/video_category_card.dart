import 'dart:ui';
import 'dart:math' as math;
import 'package:ai_cleaner_2/core/enums/media_category_enum.dart';
import 'package:ai_cleaner_2/feature/categories/presentation/widgets/animated_counter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class VideoCategoryCard extends StatelessWidget {
  final VideoCategory category;
  final int count;
  final int selectedCount;
  final VoidCallback onTap;

  const VideoCategoryCard({
    super.key,
    required this.category,
    required this.count,
    required this.selectedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final countKey = 'video_category_${category.name}_count';
    final selectedCountKey = 'video_category_${category.name}_selected';

    return GestureDetector(
      onTap: onTap,
      child: LiquidGlass(
        settings: LiquidGlassSettings(
          blur: 8,
          ambientStrength: 2.0,
          lightAngle: 0.3 * math.pi,
          glassColor: Colors.white.withOpacity(0.08),
          thickness: 30,
        ),
        shape: LiquidRoundedSuperellipse(
          borderRadius: const Radius.circular(20),
        ),
        glassContainsChild: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Иконка - белая на матовом фоне
              LiquidGlass(
                settings: LiquidGlassSettings(
                  blur: 3,
                  ambientStrength: 0.5,
                  lightAngle: 0.2 * math.pi,
                  glassColor: Colors.white.withOpacity(0.2),
                  thickness: 15,
                ),
                shape: LiquidRoundedSuperellipse(
                  borderRadius: const Radius.circular(16),
                ),
                glassContainsChild: false,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    category.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Счетчики
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CategoryAnimatedCounter(
                    targetValue: count,
                    counterKey: countKey,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                    animationDuration: const Duration(milliseconds: 1200),
                    minIncrement: 1,
                    maxIncrement: 3,
                  ),
                  if (selectedCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: LiquidGlass(
                        settings: LiquidGlassSettings(
                          blur: 2,
                          ambientStrength: 0.3,
                          lightAngle: 0.1 * math.pi,
                          glassColor: CupertinoColors.activeBlue.withOpacity(0.3),
                          thickness: 8,
                        ),
                        shape: LiquidRoundedSuperellipse(
                          borderRadius: const Radius.circular(12),
                        ),
                        glassContainsChild: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: CategoryAnimatedCounter(
                            targetValue: selectedCount,
                            counterKey: selectedCountKey,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            animationDuration: const Duration(milliseconds: 800),
                            minIncrement: 1,
                            maxIncrement: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Chevron
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 18,
                color: Colors.white60,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
