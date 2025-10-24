import 'package:ai_cleaner_2/feature/cleaner/presentation/bloc/media_cleaner_bloc.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../feature/gallery/presentation/cubit/gallery_assets/gallery_assets_cubit.dart';
import '../../core/limiters/throttler.dart';
@RoutePage()
class AppRootPage extends StatefulWidget {
  AppRootPage({super.key});
  @override
  State<AppRootPage> createState() => _AppRootPageState();
}
class _AppRootPageState extends State<AppRootPage> with WidgetsBindingObserver {
  final throttler = Throttler(3.seconds);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final mediaBloc = context.read<MediaCleanerBloc>();
    if (state == AppLifecycleState.paused) {
      debugPrint('Приложение ушло в фон, приостанавливаем сканирование');
      if (mediaBloc.state is MediaCleanerScanning) {
        mediaBloc.add(PauseScanningEvent());
      }
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('Приложение вернулось на передний план, возобновляем сканирование');
      if (mediaBloc.state is MediaCleanerScanning && 
          (mediaBloc.state as MediaCleanerScanning).isPaused) {
        mediaBloc.add(ResumeScanningEvent());
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => GalleryAssetsCubit()),
        BlocProvider(create: (context) => MediaCleanerBloc()),
      ],
      child: const AutoRouter(),
    );
  }
}