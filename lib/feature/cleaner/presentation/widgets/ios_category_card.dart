import 'package:ai_cleaner_2/core/enums/media_category_enum.dart';
import 'package:ai_cleaner_2/core/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS Settings style category card
/// Точная копия дизайна "Хранилище iPhone" из настроек iOS
class IOSCategoryCard extends StatefulWidget {
  final PhotoCategory category;
  final int count;
  final int selectedCount;
  final VoidCallback onTap;
  final bool isLocked;
  final bool showSeparator;

  const IOSCategoryCard({
    super.key,
    required this.category,
    required this.count,
    required this.selectedCount,
    required this.onTap,
    this.isLocked = false,
    this.showSeparator = true,
  });

  @override
  State<IOSCategoryCard> createState() => _IOSCategoryCardState();
}

class _IOSCategoryCardState extends State<IOSCategoryCard> {
  bool _isPressed = false;

  Color get _iconColor {
    // Цвета для разных категорий как в iOS
    switch (widget.category) {
      case PhotoCategory.similar:
        return AppColors.categoryOrange;
      case PhotoCategory.series:
        return AppColors.categoryBlue;
      case PhotoCategory.screenshots:
        return AppColors.categoryGreen;
      case PhotoCategory.blurry:
        return AppColors.categoryPurple;
      case PhotoCategory.livePhotos:
        return AppColors.categoryPink;
      default:
        return AppColors.categoryGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final backgroundColor = context.iosSecondaryBackground;
    final labelColor = context.iosLabel;
    final secondaryLabelColor = context.iosSecondaryLabel;
    final separatorColor = context.iosSeparator;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: AppColors.iosItemHeight,
        color: _isPressed
            ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8ED))
            : backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                // Иконка в квадрате с округлыми углами (как в iOS)
                Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: _iconColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        widget.category.icon,
                        color: Colors.white,
                        size: 18,
                      ),
                      if (widget.isLocked)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.lock_fill,
                              size: 12,
                              color: AppColors.accentGold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Название и подзаголовок
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.title,
                        style: TextStyle(
                          color: labelColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.41,
                        ),
                      ),
                      if (widget.selectedCount > 0)
                        Text(
                          '${widget.selectedCount} selected',
                          style: TextStyle(
                            color: AppColors.categoryBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.24,
                          ),
                        )
                      else
                        Text(
                          widget.category.description,
                          style: TextStyle(
                            color: secondaryLabelColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.24,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Размер (количество файлов)
                Text(
                  '${widget.count}',
                  style: TextStyle(
                    color: secondaryLabelColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.41,
                  ),
                ),

                const SizedBox(width: 6),

                // Chevron стрелочка
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 17,
                  color: Color(0xFFC7C7CC),
                ),
              ],
            ),

            // Разделитель (не доходит до левого края, как в iOS)
            if (widget.showSeparator)
              Padding(
                padding: const EdgeInsets.only(top: 11),
                child: Container(
                  margin: const EdgeInsets.only(left: 53),
                  height: 0.5,
                  color: separatorColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
