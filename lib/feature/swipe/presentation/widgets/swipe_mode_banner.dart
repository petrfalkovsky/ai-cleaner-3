import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../../../core/router/router.gr.dart';

class SwipeModeBanner extends StatelessWidget {
  final List<String> mediaIds;
  final String title;

  const SwipeModeBanner({super.key, required this.mediaIds, required this.title});

  @override
  Widget build(BuildContext context) {
    if (mediaIds.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // Переходим на экран свайпера с выбранной категорией файлов
        context.router.push(CategoriesSwiperRoute(ids: mediaIds, title: title));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          color: Colors.white.withOpacity(0.1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              children: [
                Icon(Icons.swipe, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Попробуйте режим смахивания',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Удаляйте или сохраняйте файлы простым свайпом',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
