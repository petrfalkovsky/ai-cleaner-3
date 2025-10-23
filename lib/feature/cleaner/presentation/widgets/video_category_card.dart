import 'package:ai_cleaner_2/core/enums/media_category_enum.dart';
import 'package:ai_cleaner_2/feature/categories/presentation/widgets/animated_counter.dart';
import 'package:flutter/material.dart';
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
    // Создаем уникальные ключи для счетчиков
    final String countKey = 'video_category_${category.name}_count';
    final String selectedCountKey = 'video_category_${category.name}_selected';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Иконка категории
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getIconColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: _getIconColor(), size: 24),
              ),
              const SizedBox(width: 16),

              // Информация о категории
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Количество файлов и выбранных
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Используем анимированный счетчик с сохранением состояния
                  CategoryAnimatedCounter(
                    targetValue: count,
                    counterKey: countKey,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    animationDuration: const Duration(milliseconds: 1200),
                    minIncrement: 1,
                    maxIncrement: 3,
                  ),
                  if (selectedCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: CategoryAnimatedCounter(
                        targetValue: selectedCount,
                        counterKey: selectedCountKey,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        animationDuration: const Duration(milliseconds: 800),
                        minIncrement: 1,
                        maxIncrement: 1,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getIconColor() {
    switch (category) {
      case VideoCategory.duplicates:
        return Colors.orange;
      case VideoCategory.screenRecordings:
        return Colors.red;
      case VideoCategory.shortVideos:
        return Colors.purple;
    }
  }
}