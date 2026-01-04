import 'dart:ui';

import 'package:ai_cleaner_2/feature/premium/domain/premium_service.dart';
import 'package:ai_cleaner_2/generated/l10n.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/router/router.gr.dart';

class SwipeModeBanner extends StatelessWidget {
  final List<String> mediaIds;
  final String title;

  const SwipeModeBanner({super.key, required this.mediaIds, required this.title});

  @override
  Widget build(BuildContext context) {
    if (mediaIds.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<bool>(
      stream: PremiumService().premiumStatusStream,
      initialData: PremiumService().isPremium,
      builder: (context, snapshot) {
        final bool isPremium = snapshot.data ?? false;

        return GestureDetector(
          onTap: () {
            if (!isPremium) {
              // Если нет премиума - открываем paywall
              context.router.push(const PaywallThreePlansRoute());
            } else {
              // Переходим на экран свайпера с выбранной категорией файлов
              context.router.push(CategoriesSwiperRoute(ids: mediaIds, title: title));
            }
          },
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  color: Colors.white.withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // Иконка свайпа с замочком если не премиум
                          Icon(Icons.swipe, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Locales.current.try_swipe_mode,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Locales.current.swipe_hint,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
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
              ),

              if (!isPremium)
                Positioned(
                  top: 2,
                  right: 12,
                  child: Icon(CupertinoIcons.lock_circle, size: 20, color: Color(0xFFFFD700)),
                ),
            ],
          ),
        );
      },
    );
  }
}
