import 'package:ai_cleaner_2/feature/cleaner/domain/media_file_entity.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/bloc/media_cleaner_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class MediaGridItem extends StatelessWidget {
  final MediaFile file;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  const MediaGridItem({
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
              // Изображение БЕЗ скругления (как в iOS Photos или Telegram)
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

              // Индикатор видео (в правом нижнем углу)
              if (file.isVideo)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.play_fill,
                          color: Colors.white,
                          size: 10,
                        ),
                        if (file.entity.duration != null && file.entity.duration! > 0) ...[
                          const SizedBox(width: 2),
                          Text(
                            _formatDuration(file.entity.duration!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Рамка выделения (как в iOS)
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: CupertinoColors.activeBlue,
                        width: 3,
                      ),
                    ),
                  ),
                ),

              // Кнопка выбора (кружок с галочкой, как в iOS Photos)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () {
                    context.read<MediaCleanerBloc>().add(
                      ToggleFileSelectionById(file.entity.id),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? CupertinoColors.activeBlue
                          : Colors.white.withOpacity(0.3),
                      border: Border.all(
                        color: isSelected
                            ? CupertinoColors.activeBlue
                            : Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(
                            CupertinoIcons.check_mark,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(int durationInSeconds) {
    final duration = Duration(seconds: durationInSeconds);
    final minutes = duration.inMinutes.toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
