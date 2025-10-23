import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../../cleaner/domain/media_file_entity.dart';
import '../widgets/selection_indicator.dart';
import '../widgets/blur_indicator.dart';

class BlurryMediaGridItem extends StatelessWidget {
  final MediaFile file;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  const BlurryMediaGridItem({
    super.key,
    required this.file,
    required this.onTap,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onPreview,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Миниатюра файла
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AssetEntityImage(
              file.entity,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize.square(200),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          ),

          // Индикатор размытости (полупрозрачное наложение)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
          ),

          // Индикатор размытости
          Positioned(
            bottom: 8,
            right: 8,
            child: BlurIndicator(
              // Предполагаем, что размытость где-то между 0.6-0.9
              blurScore: 0.8,
              size: 28,
            ),
          ),

          // Индикатор выбора
          Positioned(top: 8, right: 8, child: SelectionIndicator(fileId: file.entity.id, size: 24)),
        ],
      ),
    );
  }
}
