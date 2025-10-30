import 'package:ai_cleaner_2/feature/cleaner/domain/media_file_entity.dart';
import 'package:ai_cleaner_2/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final MediaFile file;

  const VideoPlayerWidget({super.key, required this.file});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isControlsVisible = true;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoController();

    // Скрытие контролов через 3 секунды
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isControlsVisible = false;
        });
      }
    });
  }

  Future<void> _initializeVideoController() async {
    setState(() => _isLoading = true);
    try {
      final file = await widget.file.entity.file;

      if (file == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();

      if (mounted) {
        setState(() => _isLoading = false);
        _controller!.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError || _controller == null) {
      return _buildErrorState();
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isControlsVisible = !_isControlsVisible;
        });

        // Если показали контролы, скрыть их через 3 секунды
        if (_isControlsVisible) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _isControlsVisible = false;
              });
            }
          });
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Видеоплеер
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),

          // Контролы
          if (_isControlsVisible)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Кнопка воспроизведения/паузы
                  IconButton(
                    icon: Icon(
                      _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 50,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_controller!.value.isPlaying) {
                          _controller!.pause();
                        } else {
                          _controller!.play();
                        }
                      });
                    },
                  ),

                  // Прогрессбар внизу экрана
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        // Текущее время
                        ValueListenableBuilder(
                          valueListenable: _controller!,
                          builder: (context, VideoPlayerValue value, child) {
                            return Text(
                              _formatDuration(value.position),
                              style: const TextStyle(color: Colors.white),
                            );
                          },
                        ),

                        // Полоса прогресса
                        Expanded(
                          child: VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: true,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            colors: const VideoProgressColors(
                              playedColor: Colors.red,
                              bufferedColor: Colors.grey,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                        ),

                        // Общая продолжительность
                        ValueListenableBuilder(
                          valueListenable: _controller!,
                          builder: (context, VideoPlayerValue value, child) {
                            return Text(
                              _formatDuration(value.duration),
                              style: const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Миниатюра видео
        SizedBox.expand(
          child: AssetEntityImage(
            widget.file.entity,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(400),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.black,
                child: const Icon(Icons.video_library, color: Colors.white54, size: 72),
              );
            },
          ),
        ),

        // Индикатор загрузки
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 12),
              Text(Locales.current.loading_videos, style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Миниатюра видео с затемнением
        SizedBox.expand(
          child: AssetEntityImage(
            widget.file.entity,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(400),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.black,
                child: const Icon(Icons.video_library, color: Colors.white54, size: 72),
              );
            },
          ),
        ),

        // Сообщение об ошибке
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                Locales.current.video_load_error,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _initializeVideoController,
                child: Text(Locales.current.try_again),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Форматирование продолжительности в формат MM:SS
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
