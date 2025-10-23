import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/media_cleaner_bloc.dart';

class ScanStatusBanner extends StatelessWidget {
  const ScanStatusBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
      builder: (context, state) {
        // Показываем баннер при сканировании или ошибке
        bool showBanner = false;
        String? message;
        double? progress;
        bool isError = false;
        int? processedFiles;
        int? totalFiles;

        if (state is MediaCleanerScanning) {
          showBanner = true;
          message = state.scanMessage;
          progress = state.scanProgress;
          processedFiles = state.processedFiles;
          totalFiles = state.totalFiles;
        } else if (state is MediaCleanerLoaded && state.isScanningInBackground) {
          showBanner = true;
          message = "Ai-модель анализирует вашу медиатеку...";
        } else if (state is MediaCleanerLoaded && state.scanError != null) {
          showBanner = true;
          message = state.scanError;
          isError = true;
        } else if (state is MediaCleanerError) {
          showBanner = true;
          message = state.message;
          isError = true;
        } else {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: Colors.white, offset: const Offset(3, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isError)
                    const Icon(Icons.error_outline, color: Colors.red, size: 20)
                  else
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message ?? "Сканирование...",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),

              // Показываем прогрессбар и счетчик обработанных файлов
              if (progress != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        // Явно указываем начальное и конечное значение как double
                        tween: Tween<double>(begin: 0.0, end: progress),
                        builder: (context, value, child) {
                          // Проверяем progress перед использованием
                          final color = ColorTween(
                            begin: Colors.blue,
                            end: progress! > 0.9 ? Colors.green : Colors.white,
                          ).evaluate(AlwaysStoppedAnimation(value))!;

                          return LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          );
                        },
                      ),
                    ),
                    if (processedFiles != null && totalFiles != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        '$processedFiles из $totalFiles',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],

              const SizedBox(height: 8),
              const Text(
                "Приложение «Ai Cleaner» сканирует Вашу медиатеку, "
                "чтобы найти похожие и заблюренные фото. Сканирование "
                "продолжится, когда iPhone будет заблокирован "
                "и подключен к источнику питания.",
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }
}
