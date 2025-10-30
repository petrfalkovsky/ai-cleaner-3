import 'package:ai_cleaner_2/core/widgets/common/video_player.dart';
import 'package:ai_cleaner_2/feature/cleaner/domain/media_file_entity.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/selection_indicator.dart';
import 'package:ai_cleaner_2/generated/l10n.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

@RoutePage()
class MediaPreviewPage extends StatelessWidget {
  final MediaFile file;

  const MediaPreviewPage({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          file.entity.title ?? Locales.current.view,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // Заменяем кнопку на полях на наш индикатор
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SelectionIndicator(fileId: file.entity.id, size: 32),
          ),
        ],
      ),
      body: Column(
        children: [
          // Основной контент - фото или видео
          Expanded(child: file.isVideo ? _buildVideoPlayer() : _buildPhotoViewer()),

          // Информация о файле
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.entity.title ?? Locales.current.unnamed_file,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      label: DateFormat('dd.MM.yyyy').format(file.entity.createDateTime),
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.aspect_ratio,
                      label: '${file.entity.width}×${file.entity.height}',
                    ),
                    if (file.isVideo && file.entity.duration != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: _buildInfoChip(
                          icon: Icons.timer,
                          label: _formatDuration(file.entity.duration!),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoViewer() {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        child: AssetEntityImage(
          file.entity,
          isOriginal: true,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  Locales.current.image_load_error,
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return VideoPlayerWidget(entity: file.entity);
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        ],
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
