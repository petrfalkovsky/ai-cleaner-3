import 'package:ai_cleaner_2/feature/cleaner/domain/media_file_entity.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/bloc/media_cleaner_bloc.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/selection_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
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
      onTap: () {
        // Переключаем выбор файла напрямую
        context.read<MediaCleanerBloc>().add(ToggleFileSelectionById(file.entity.id));
      },
      onLongPress: onPreview,
      child: BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
        builder: (context, state) {
          // Проверяем, выбран ли файл в текущем состоянии
          bool isSelected = false;
          if (state is MediaCleanerLoaded) {
            isSelected = state.selectedFiles.any((f) => f.entity.id == file.entity.id);
          }

          return Stack(
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

              // Индикатор видео
              if (file.isVideo)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow, color: Colors.white, size: 12),
                        if (file.entity.duration != null && file.entity.duration! > 0)
                          Text(
                            _formatDuration(file.entity.duration!),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                ),

              // Рамка выделения
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                  ),
                ),

              // Индикатор выбора
              Positioned(
                top: 4,
                right: 4,
                child: SelectionIndicator(fileId: file.entity.id, size: 24),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(int durationInSeconds) {
    final duration = Duration(seconds: durationInSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
