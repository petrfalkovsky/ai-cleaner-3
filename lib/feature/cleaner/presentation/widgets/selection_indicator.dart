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
          final selectedFiles = state.selectedFiles;
          final selectedIndex = selectedFiles.indexWhere((file) => file.entity.id == fileId);
          isSelected = selectedIndex != -1;
          if (isSelected) {
            selectionNumber = selectedIndex + 1;
          }
        }
        final numberText = selectionNumber?.toString() ?? '';
        final needsExpansion = numberText.length >= 2;
        final containerWidth = needsExpansion ? size * 1.4 : size;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            context.read<MediaCleanerBloc>().add(ToggleFileSelectionById(fileId));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: containerWidth,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(needsExpansion ? size / 2 : size),
              color: isSelected ? Colors.blue : Colors.black.withOpacity(0.5),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: isSelected
                ? Center(
                    child: Text(
                      numberText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : const SizedBox(),
          ),
        );
      },
    );
  }
}