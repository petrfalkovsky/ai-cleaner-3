import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import '../../../../generated/l10n.dart';
import '../../../../core/services/disk_space_service.dart';

class IPhoneStorageWidget extends StatefulWidget {
  final bool showOnlyPhotos;
  final String title;

  const IPhoneStorageWidget({super.key, this.showOnlyPhotos = false, this.title = 'iPhone'});

  @override
  State<IPhoneStorageWidget> createState() => _IPhoneStorageWidgetState();
}

class _IPhoneStorageWidgetState extends State<IPhoneStorageWidget> with SingleTickerProviderStateMixin {
  double? _totalSpace; // В GB
  double? _freeSpace; // В GB
  double? _usedSpace; // В GB
  int? _guessedDeviceSize; // Угаданный размер устройства в GB

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Инициализация контроллера анимации
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 2 секунды для плавной анимации
    );

    // Анимация прогресса от 0 до 1
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Анимация цвета от желтого к красному
    _colorAnimation = ColorTween(
      begin: const Color(0xFFFFCC00), // Желтый
      end: const Color(0xFFFF3B30), // Красный
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _loadStorageInfo();

    // Запускаем анимацию сразу после инициализации (только один раз)
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadStorageInfo() async {
    try {
      debugPrint('IPhoneStorageWidget: Starting to load storage info...');

      final totalGB = await DiskSpaceService.instance.getTotalDiskSpace();
      debugPrint('IPhoneStorageWidget: totalDiskSpace = $totalGB GB');

      final freeGB = await DiskSpaceService.instance.getFreeDiskSpace();
      debugPrint('IPhoneStorageWidget: freeDiskSpace = $freeGB GB');

      if (totalGB != null && freeGB != null) {
        final usedGB = totalGB - freeGB;

        // Угадываем реальный размер устройства
        final guessedSize = _guessDeviceSize(totalGB, usedGB, freeGB);

        debugPrint(
          'IPhoneStorageWidget: Calculated - Total: ${totalGB.toStringAsFixed(1)} GB, Free: ${freeGB.toStringAsFixed(1)} GB, Used: ${usedGB.toStringAsFixed(1)} GB, Guessed Device Size: $guessedSize GB',
        );

        if (mounted) {
          setState(() {
            _totalSpace = totalGB;
            _freeSpace = freeGB;
            _usedSpace = usedGB;
            _guessedDeviceSize = guessedSize;
          });
          debugPrint('IPhoneStorageWidget: State updated successfully');
        }
      } else {
        debugPrint('IPhoneStorageWidget: WARNING - Got null values from DiskSpaceService');
      }
    } catch (e, stackTrace) {
      // Если не удалось получить данные, оставляем значения null
      debugPrint('IPhoneStorageWidget: ERROR - Failed to load storage info: $e');
      debugPrint('IPhoneStorageWidget: Stack trace: $stackTrace');
    }
  }

  /// Угадывает реальный размер устройства, округляя до стандартных значений
  int _guessDeviceSize(double totalGB, double usedGB, double freeGB) {
    // Стандартные размеры iPhone/iPad (начиная с 64 GB для современных устройств)
    const deviceSizes = [64, 128, 256, 512, 1024, 2048];

    // Реальное занятое место (used + free)
    final actualUsedSpace = usedGB + freeGB;

    debugPrint('IPhoneStorageWidget: actualUsedSpace = ${actualUsedSpace.toStringAsFixed(1)} GB');

    // Находим ближайший подходящий размер устройства
    // Система резервирует ~5-10% места, поэтому actual может быть 58-60 GB для 64 GB устройства
    for (final size in deviceSizes) {
      // Проверяем, что actualUsedSpace умещается в диапазон для данного размера
      // Для 64 GB: от 55 до 64 GB
      // Для 128 GB: от 115 до 128 GB и т.д.
      if (actualUsedSpace <= size && actualUsedSpace > (size * 0.85)) {
        return size;
      }
    }

    // Если не нашли точное совпадение, берем ближайший больший размер
    for (final size in deviceSizes) {
      if (actualUsedSpace <= size) {
        return size;
      }
    }

    return deviceSizes.last;
  }

  @override
  Widget build(BuildContext context) {
    const double radius = 14;
    const double smoothing = 1;

    return Container(
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.all(
            SmoothRadius(cornerRadius: radius, cornerSmoothing: smoothing),
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок + инфо
          Row(
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  letterSpacing: -1.0,
                ),
              ),
              const Spacer(),
              if (!widget.showOnlyPhotos &&
                  _usedSpace != null &&
                  _guessedDeviceSize != null &&
                  _freeSpace != null)
                Text(
                  '${_usedSpace!.toStringAsFixed(1)} GB ${Locales.current.of_1} $_guessedDeviceSize GB ${Locales.current.used}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                    height: 1.3,
                  ),
                )
              else if (!widget.showOnlyPhotos)
                const Text(
                  '63.34 GB of 64 GB used',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1.2,
                  ),
                ),
              if (widget.showOnlyPhotos && _usedSpace != null)
                Text(
                  '${(_usedSpace! * 0.6).toStringAsFixed(1)} GB', // ~60% от используемого места - это фото/видео
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1.2,
                  ),
                )
              else if (widget.showOnlyPhotos)
                const Text(
                  '38.34 GB',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1.2,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 0),

          // Индикатор заполненности памяти
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 20,
              child: widget.showOnlyPhotos
                  ? AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return Row(
                          children: [
                            _AnimatedStorageBarSegment(
                              color: _colorAnimation.value ?? const Color(0xFFFFCC00),
                              progress: _progressAnimation.value,
                              targetFlex: 19,
                            ), // Photos with animation
                            _StorageBarSegment(
                              color: const Color(0xFFE5E5EA),
                              flex: 1,
                            ), // Remaining space
                          ],
                        );
                      },
                    )
                  : Row(
                      children: const [
                        _StorageBarSegment(color: Color(0xFFFF3B30), flex: 4), // Applications
                        _StorageBarSegment(color: Color(0xFFFF9500), flex: 1), // Messages
                        _StorageBarSegment(color: Color(0xFFFFCC00), flex: 7), // Photos
                        _StorageBarSegment(color: Color(0xFF34C759), flex: 1), // Mail
                        _StorageBarSegment(color: Color(0xFFAEAEB2), flex: 2), // iOS
                        _StorageBarSegment(color: Color(0xFFE5E5EA), flex: 2), // System Data
                      ],
                    ),
            ),
          ),

          if (!widget.showOnlyPhotos) ...[
            const SizedBox(height: 16),

            // Легенда
            Wrap(
              spacing: 10,
              runSpacing: 2,
              children: const [
                _LegendItem(color: Color(0xFFFF3B30), label: 'Applications'),
                _LegendItem(color: Color(0xFFFF9500), label: 'Messages'),
                _LegendItem(color: Color(0xFFFFCC00), label: 'Photos'),
                _LegendItem(color: Color(0xFF34C759), label: 'Mail'),
                _LegendItem(color: Color(0xFFAEAEB2), label: 'iOS'),
                _LegendItem(color: Color(0xFFE5E5EA), label: 'System Data'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StorageBarSegment extends StatelessWidget {
  final Color color;
  final int flex;

  const _StorageBarSegment({required this.color, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex == 0 ? 1 : flex,
      child: Container(color: color),
    );
  }
}

class _AnimatedStorageBarSegment extends StatelessWidget {
  final Color color;
  final double progress; // от 0.0 до 1.0
  final int targetFlex;

  const _AnimatedStorageBarSegment({
    required this.color,
    required this.progress,
    required this.targetFlex,
  });

  @override
  Widget build(BuildContext context) {
    // Вычисляем текущий flex на основе прогресса
    final currentFlex = (targetFlex * progress).clamp(0, targetFlex).toInt();

    return Expanded(
      flex: currentFlex == 0 ? 1 : currentFlex,
      child: Container(color: color),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 6,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black, letterSpacing: -.5)),
      ],
    );
  }
}
