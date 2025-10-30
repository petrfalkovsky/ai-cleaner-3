import 'dart:ui';
import 'package:ai_cleaner_2/core/enums/media_category_enum.dart';
import 'package:ai_cleaner_2/feature/categories/presentation/widgets/animated_counter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class VideoCategoryCard extends StatefulWidget {
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
  State<VideoCategoryCard> createState() => _VideoCategoryCardState();
}

class _VideoCategoryCardState extends State<VideoCategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final countKey = 'video_category_${widget.category.name}_count';
    final selectedCountKey = 'video_category_${widget.category.name}_selected';

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Иконка
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: Icon(widget.category.icon, color: Colors.white, size: 28),
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
                          widget.category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.category.description,
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                        animationDuration: const Duration(milliseconds: 1200),
                        minIncrement: 1,
                        maxIncrement: 3,
                      ),
                      if (widget.selectedCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.activeBlue.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: CupertinoColors.activeBlue.withOpacity(0.4),
                                    width: 1,
                                  ),
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
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.chevron_right, size: 18, color: Colors.white60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
