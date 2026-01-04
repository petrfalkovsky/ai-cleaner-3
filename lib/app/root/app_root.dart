import 'package:ai_cleaner_2/feature/cleaner/presentation/bloc/media_cleaner_bloc.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../feature/gallery/presentation/cubit/gallery_assets/gallery_assets_cubit.dart';
import '../../feature/premium/domain/premium_service.dart';
import '../../core/limiters/throttler.dart';

@RoutePage()
class AppRootPage extends StatefulWidget {
  const AppRootPage({super.key});
  
  @override
  State<AppRootPage> createState() => _AppRootPageState();
}

class _AppRootPageState extends State<AppRootPage> with WidgetsBindingObserver {
  final throttler = Throttler(3.seconds);
  MediaCleanerBloc? _mediaCleanerBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Инициализируем Premium Service
    PremiumService().initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Проверяем что блок уже создан
    if (_mediaCleanerBloc == null) return;

    if (state == AppLifecycleState.paused) {
      // Приложение ушло в фон
      debugPrint('Приложение ушло в фон, приостанавливаем сканирование');

      // Приостанавливаем сканирование
      if (_mediaCleanerBloc!.state is MediaCleanerScanning) {
        _mediaCleanerBloc!.add(PauseScanningEvent());
      }
    } else if (state == AppLifecycleState.resumed) {
      // Приложение вернулось на передний план
      debugPrint('Приложение вернулось на передний план, возобновляем сканирование');

      // Возобновляем сканирование, если оно было приостановлено
      if (_mediaCleanerBloc!.state is MediaCleanerScanning &&
          (_mediaCleanerBloc!.state as MediaCleanerScanning).isPaused) {
        _mediaCleanerBloc!.add(ResumeScanningEvent());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Создаем блок один раз
    _mediaCleanerBloc ??= MediaCleanerBloc();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => GalleryAssetsCubit()),
        BlocProvider.value(value: _mediaCleanerBloc!),
      ],
      child: const AutoRouter(),
    );
  }
}