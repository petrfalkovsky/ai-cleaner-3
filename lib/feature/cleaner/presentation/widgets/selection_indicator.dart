import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/media_cleaner_bloc.dart';

class SelectionIndicator extends StatelessWidget {
  final String fileId;
  final double size;

  const SelectionIndicator({Key? key, required this.fileId, this.size = 24.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
      builder: (context, state) {
        bool isSelected = false;
        int? selectionNumber;

        if (state is MediaCleanerLoaded) {
          // Получаем все выбранные файлы
          final selectedFiles = state.selectedFiles;

          // Находим позицию текущего файла в списке выбранных
          final selectedIndex = selectedFiles.indexWhere((file) => file.entity.id == fileId);

          isSelected = selectedIndex != -1;

          if (isSelected) {
            // Используем глобальный индекс + 1 как номер выбора
            selectionNumber = selectedIndex + 1;
          }
        }

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            context.read<MediaCleanerBloc>().add(ToggleFileSelectionById(fileId));
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.blue : Colors.black.withOpacity(0.5),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: isSelected
                ? Center(
                    child: Text(
                      selectionNumber?.toString() ?? '',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : SizedBox(),
          ),
        );
      },
    );
  }
}
