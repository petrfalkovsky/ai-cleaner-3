import 'dart:ui';
import 'package:ai_cleaner_2/core/enums/media_category_enum.dart';
import 'package:ai_cleaner_2/feature/categories/presentation/widgets/animated_counter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PhotoCategoryCard extends StatefulWidget {
  final PhotoCategory category;
  final int count;
  final int selectedCount;
  final VoidCallback onTap;

  const PhotoCategoryCard({
    super.key,
    required this.category,
    required this.count,
    required this.selectedCount,
    required this.onTap,
  });

  @override
  State<PhotoCategoryCard> createState() => _PhotoCategoryCardState();
}

class _PhotoCategoryCardState extends State<PhotoCategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final countKey = 'photo_category_${widget.category.name}_count';
    final selectedCountKey = 'photo_category_${widget.category.name}_selected';

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CupertinoColors.systemGrey6.resolveFrom(context),
                CupertinoColors.systemGrey5.resolveFrom(context),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.8),
                      Colors.white.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Иконка с градиентом
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getGradientColors(),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _getIconColor().withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.category.icon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Информация
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              color: CupertinoColors.label.resolveFrom(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.category.description,
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
                          targetValue: widget.count,
                          counterKey: countKey,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                          animationDuration: const Duration(milliseconds: 1200),
                          minIncrement: 1,
                          maxIncrement: 3,
                        ),
                        if (widget.selectedCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    CupertinoColors.activeBlue,
                                    CupertinoColors.systemBlue,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: CategoryAnimatedCounter(
                                targetValue: widget.selectedCount,
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
                      ],
                    ),

                    // Chevron
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 18,
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getIconColor() {
    switch (widget.category) {
      case PhotoCategory.similar:
        return CupertinoColors.systemGreen;
      case PhotoCategory.series:
        return CupertinoColors.systemOrange;
      case PhotoCategory.screenshots:
        return CupertinoColors.systemTeal;
      case PhotoCategory.blurry:
        return CupertinoColors.systemPurple;
    }
  }

  List<Color> _getGradientColors() {
    switch (widget.category) {
      case PhotoCategory.similar:
        return [
          CupertinoColors.systemGreen.withOpacity(0.9),
          CupertinoColors.systemGreen.darkColor,
        ];
      case PhotoCategory.series:
        return [
          CupertinoColors.systemOrange.withOpacity(0.9),
          CupertinoColors.systemOrange.darkColor,
        ];
      case PhotoCategory.screenshots:
        return [
          CupertinoColors.systemTeal.withOpacity(0.9),
          CupertinoColors.systemTeal.darkColor,
        ];
      case PhotoCategory.blurry:
        return [
          CupertinoColors.systemPurple.withOpacity(0.9),
          CupertinoColors.systemPurple.darkColor,
        ];
    }
  }
}
