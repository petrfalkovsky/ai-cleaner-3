import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/media_cleaner_bloc.dart';

class SelectedFilesCounter extends StatelessWidget {
  const SelectedFilesCounter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
      builder: (context, state) {
        if (state is! MediaCleanerLoaded) {
          return const SizedBox.shrink();
        }

        final selectedCount = (state as MediaCleanerLoaded).selectedFiles.length;

        if (selectedCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Выбрано: $selectedCount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<MediaCleanerBloc>().add(DeleteSelectedFiles());
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Удалить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
