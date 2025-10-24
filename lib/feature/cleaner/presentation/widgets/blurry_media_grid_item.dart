import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../../cleaner/domain/media_file_entity.dart';
import '../widgets/selection_indicator.dart';
import '../widgets/blur_indicator.dart';
import '../bloc/media_cleaner_bloc.dart';

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
      onTap: onPreview, // Тап на превью = полноэкранный просмотр
      child: BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
        builder: (context, state) {
          bool isSelected = false;
          if (state is MediaCleanerLoaded) {
            isSelected = state.selectedFiles.any((f) => f.entity.id == file.entity.id);
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Миниатюра БЕЗ скругления (как в iOS Photos)
              AssetEntityImage(
                file.entity,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(300),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: CupertinoColors.systemGrey5,
                    child: const Icon(
                      CupertinoIcons.photo,
                      color: CupertinoColors.systemGrey3,
                    ),
                  );
                },
              ),

              // Индикатор размытости в правом нижнем углу
              Positioned(
                bottom: 4,
                right: 4,
                child: BlurIndicator(
                  blurScore: 0.8,
                  size: 28,
                ),
              ),

              // Затемнение выделенного фото
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),

              // Индикатор выбора
              Positioned(
                top: 6,
                right: 6,
                child: SelectionIndicator(fileId: file.entity.id, size: 24),
              ),
            ],
          );
        },
      ),
    );
  }
}
