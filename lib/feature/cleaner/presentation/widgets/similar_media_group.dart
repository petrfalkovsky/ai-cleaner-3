import 'dart:ui';

import 'package:ai_cleaner_2/feature/cleaner/domain/media_file_entity.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/bloc/media_cleaner_bloc.dart';
import 'package:ai_cleaner_2/feature/cleaner/presentation/widgets/selection_indicator.dart';
import 'package:ai_cleaner_2/generated/l10n.dart';
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
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
                      // Оптимизация производительности
                      cacheExtent: 500.0, // Предзагрузка элементов за пределами видимой области
                      addAutomaticKeepAlives: true,
                      addRepaintBoundaries: true,
                      itemCount: group.files.length,
                      itemBuilder: (context, index) {
                        return RepaintBoundary(
                          child: _buildMediaItem(context, group.files[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Кнопка "Выбрать все"
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                allSelected ? Locales.current.cancel : Locales.current.select_all,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
        final isSelected =
            state is MediaCleanerLoaded &&
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
