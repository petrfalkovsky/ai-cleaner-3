import 'package:ai_cleaner_2/feature/cleaner/domain/media_file_entity.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/bloc/media_cleaner_bloc.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/selection_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'dart:math' as math;

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
      child: LiquidGlass(
        settings: LiquidGlassSettings(
          blur: 8,
          ambientStrength: 0.8,
          lightAngle: 0.3 * math.pi,
          glassColor: Colors.white.withOpacity(0.15),
          thickness: 20,
        ),
        shape: LiquidRoundedSuperellipse(
          borderRadius: const Radius.circular(16),
        ),
        glassContainsChild: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Заголовок группы
              Row(
                children: [
                  const Icon(Icons.image_search, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${group.name} (${group.files.length})",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _buildSelectAllButton(context),
                ],
              ),
              const SizedBox(height: 12),

              // Галерея изображений
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: group.files.length,
                  itemBuilder: (context, index) {
                    return _buildMediaItem(context, group.files[index]);
                  },
                ),
              ),
            ],
          ),
        ),
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

        return GestureDetector(
          onTap: () {
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
          child: LiquidGlass(
            settings: LiquidGlassSettings(
              blur: 3,
              ambientStrength: 0.6,
              lightAngle: 0.2 * math.pi,
              glassColor: CupertinoColors.activeBlue.withOpacity(0.3),
              thickness: 12,
            ),
            shape: LiquidRoundedSuperellipse(
              borderRadius: const Radius.circular(12),
            ),
            glassContainsChild: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    allSelected ? Icons.check_circle : Icons.check_circle_outline,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    allSelected ? "Отменить" : "Выбрать все",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Миниатюра медиафайла в группе
  Widget _buildMediaItem(BuildContext context, MediaFile file) {
    return BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
      builder: (context, state) {
        // Правильная проверка: используем state.selectedFiles вместо file.isSelected
        final isSelected = state is MediaCleanerLoaded &&
            state.selectedFiles.any((f) => f.entity.id == file.entity.id);

        return Container(
          width: 100,
          margin: const EdgeInsets.only(right: 8),
          child: Stack(
            children: [
              // Основное изображение с возможностью просмотра
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
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

              // Затемнение при выборе
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

              // Индикатор выбора
              Positioned(
                top: 4,
                right: 4,
                child: SelectionIndicator(fileId: file.entity.id, size: 20),
              ),

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
      },
    );
  }
}
