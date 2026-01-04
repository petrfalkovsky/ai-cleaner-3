import 'package:ai_cleaner_2/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import '../../../../core/services/disk_space_service.dart';
import '../../../../generated/l10n.dart';

/// iOS Settings style storage header widget
/// Точная копия виджета хранилища из настроек iPhone
class IOSStorageHeader extends StatefulWidget {
  const IOSStorageHeader({super.key});

  @override
  State<IOSStorageHeader> createState() => _IOSStorageHeaderState();
}

class _IOSStorageHeaderState extends State<IOSStorageHeader>
    with SingleTickerProviderStateMixin {
  double? _totalSpace;
  double? _freeSpace;
  double? _usedSpace;
  int? _guessedDeviceSize;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Анимация прогресс-бара
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: const Color(0xFFFFCC00), // Желтый
      end: const Color(0xFFFF3B30), // Красный
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _loadStorageInfo();
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadStorageInfo() async {
    try {
      debugPrint('IOSStorageHeader: Starting to load storage info...');

      final totalGB = await DiskSpaceService.instance.getTotalDiskSpace();
      debugPrint('IOSStorageHeader: totalDiskSpace = $totalGB GB');

      final freeGB = await DiskSpaceService.instance.getFreeDiskSpace();
      debugPrint('IOSStorageHeader: freeDiskSpace = $freeGB GB');

      if (totalGB != null && freeGB != null) {
        final usedGB = totalGB - freeGB;

        // Угадываем реальный размер устройства
        final guessedSize = _guessDeviceSize(totalGB, usedGB, freeGB);

        debugPrint(
          'IOSStorageHeader: Calculated - Total: ${totalGB.toStringAsFixed(1)} GB, Free: ${freeGB.toStringAsFixed(1)} GB, Used: ${usedGB.toStringAsFixed(1)} GB, Guessed Device Size: $guessedSize GB',
        );

        if (mounted) {
          setState(() {
            _totalSpace = totalGB;
            _freeSpace = freeGB;
            _usedSpace = usedGB;
            _guessedDeviceSize = guessedSize;
          });
          debugPrint('IOSStorageHeader: State updated successfully');
        }
      } else {
        debugPrint('IOSStorageHeader: WARNING - Got null values from DiskSpaceService');
      }
    } catch (e, stackTrace) {
      // Если не удалось получить данные, оставляем значения null
      debugPrint('IOSStorageHeader: ERROR - Failed to load storage info: $e');
      debugPrint('IOSStorageHeader: Stack trace: $stackTrace');
    }
  }

  /// Угадывает реальный размер устройства, округляя до стандартных значений
  int _guessDeviceSize(double totalGB, double usedGB, double freeGB) {
    // Стандартные размеры iPhone/iPad (начиная с 64 GB для современных устройств)
    const deviceSizes = [64, 128, 256, 512, 1024, 2048];

    // Реальное занятое место (used + free)
    final actualUsedSpace = usedGB + freeGB;

    debugPrint('IOSStorageHeader: actualUsedSpace = ${actualUsedSpace.toStringAsFixed(1)} GB');

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
    const double smoothing = 1;

    final backgroundColor = context.iosSecondaryBackground;
    final labelColor = context.iosLabel;
    final secondaryLabelColor = context.iosSecondaryLabel;

    return Container(
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.all(
            SmoothRadius(
              cornerRadius: AppColors.iosContainerRadius,
              cornerSmoothing: smoothing,
            ),
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
                'iPhone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                  letterSpacing: -1.0,
                ),
              ),
              const Spacer(),
              if (_usedSpace != null &&
                  _guessedDeviceSize != null &&
                  _freeSpace != null)
                Text(
                  '${_usedSpace!.toStringAsFixed(1)} GB ${Locales.current.of_1} $_guessedDeviceSize GB ${Locales.current.used}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryLabelColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                    height: 1.3,
                  ),
                )
              else
                Text(
                  '63.3 GB ${Locales.current.of_1} 64 GB ${Locales.current.used}',
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryLabelColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 0),

          // Индикатор заполненности памяти с анимацией
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 20,
                  child: Row(
                    children: [
                      _AnimatedStorageSegment(
                        color: _colorAnimation.value ?? AppColors.categoryYellow,
                        progress: _progressAnimation.value,
                        targetFlex: 19, // 95% заполненности
                      ),
                      const _StorageSegment(
                        color: Color(0xFFE5E5EA), // Свободное место (светло-серый)
                        flex: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Легенда
          Wrap(
            spacing: 10,
            runSpacing: 2,
            children: const [
              _LegendItem(color: AppColors.categoryRed, label: 'Applications'),
              _LegendItem(color: AppColors.categoryOrange, label: 'Messages'),
              _LegendItem(color: AppColors.categoryYellow, label: 'Photos'),
              _LegendItem(color: AppColors.categoryGreen, label: 'Mail'),
              _LegendItem(color: AppColors.categoryGray, label: 'iOS'),
              _LegendItem(color: Color(0xFFE5E5EA), label: 'System Data'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorageSegment extends StatelessWidget {
  final Color color;
  final int flex;

  const _StorageSegment({required this.color, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex == 0 ? 1 : flex,
      child: Container(color: color),
    );
  }
}

class _AnimatedStorageSegment extends StatelessWidget {
  final Color color;
  final double progress;
  final int targetFlex;

  const _AnimatedStorageSegment({
    required this.color,
    required this.progress,
    required this.targetFlex,
  });

  @override
  Widget build(BuildContext context) {
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
    final labelColor = context.iosLabel;

    return Row(
      spacing: 6,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: labelColor,
            letterSpacing: -.5,
          ),
        ),
      ],
    );
  }
}
