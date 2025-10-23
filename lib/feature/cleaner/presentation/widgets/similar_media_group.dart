import 'package:ai_cleaner_2/feature/cleaner/domain/media_file_entity.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/bloc/media_cleaner_bloc.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/selection_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class SimilarMediaGroup extends StatelessWidget {
  final MediaGroup group;
  final Function(String) onFileSelected;
  final Function(MediaFile) onPreviewFile;
  final Function(List<String>) onSelectAllInGroup;

  const SimilarMediaGroup({
    super.key,
    required this.group,
    required this.onFileSelected,
    required this.onPreviewFile,
    required this.onSelectAllInGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Заголовок группы
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.image_search, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${group.name} (${group.files.length})",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                _buildSelectAllButton(context),
              ],
            ),
          ),

          // Галерея изображений
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: group.files.length,
              itemBuilder: (context, index) {
                return _buildMediaItem(context, group.files[index]);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Кнопка "Выбрать все" - полностью переписан
  Widget _buildSelectAllButton(BuildContext context) {
    return BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
      builder: (context, state) {
        if (state is! MediaCleanerReady) {
          return const SizedBox();
        }

        // Проверяем, все ли файлы в группе выбраны
        final fileIds = group.files.map((file) => file.entity.id).toList();
        final selectedIds = state.selectedFiles.map((file) => file.entity.id).toList();

        // Проверяем, сколько файлов из группы выбрано
        final selectedCount = fileIds.where((id) => selectedIds.contains(id)).length;
        final allSelected = selectedCount == fileIds.length;

        return TextButton.icon(
          onPressed: () {
            // Если все выбраны - снимаем выбор
            if (allSelected) {
              for (final fileId in fileIds) {
                if (selectedIds.contains(fileId)) {
                  context.read<MediaCleanerBloc>().add(ToggleFileSelectionById(fileId));
                }
              }
            }
            // Иначе - выбираем все невыбранные
            else {
              for (final fileId in fileIds) {
                if (!selectedIds.contains(fileId)) {
                  context.read<MediaCleanerBloc>().add(ToggleFileSelectionById(fileId));
                }
              }
            }
          },
          icon: Icon(
            allSelected ? Icons.check_circle : Icons.check_circle_outline,
            size: 18,
            color: Colors.blue,
          ),
          label: Text(
            allSelected ? "Отменить выбор" : "Выбрать все",
            style: const TextStyle(fontSize: 13, color: Colors.blue),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      },
    );
  }

  // Миниатюра медиафайла в группе
  Widget _buildMediaItem(BuildContext context, MediaFile file) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: file.isSelected
            ? Border.all(color: Colors.blue, width: 2)
            : Border.all(color: Colors.transparent),
      ),
      child: Stack(
        children: [
          // Основное изображение с возможностью просмотра
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onPreviewFile(file),
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
              ),
            ),
          ),

          // Заменяем старый выбор на наш новый SelectionIndicator
          Positioned(top: 4, right: 4, child: SelectionIndicator(fileId: file.entity.id, size: 20)),

          // Индикатор для видео
          if (file.isVideo)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}
