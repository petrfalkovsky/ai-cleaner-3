import 'dart:async';

import 'package:ai_cleaner_2/generated/l10n.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../feature/gallery/presentation/cubit/gallery_assets/gallery_assets_cubit.dart';
import '../../core/bootstrap.dart';
import '../../core/router/router.gr.dart';
import 'package:permission_handler/permission_handler.dart';
import 'widgets/shader_warmup_animation.dart';
import '../../feature/cleaner/presentation/pages/category_page.dart';
import '../../feature/cleaner/presentation/bloc/media_cleaner_bloc.dart';
import '../../core/services/first_launch_tracker.dart';

@RoutePage()
class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  bool _isInitialized = false;
  OverlayEntry? _warmupOverlay;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _warmupOverlay?.remove();
    _warmupOverlay = null;
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Отмечаем что приложение только запустилось
    FirstLaunchTracker.instance.markAppJustLaunched();

    // Запускаем инициализацию
    scheduleMicrotask(() async {
      await Bootstrap.instance.initialize();
    });

    // Ждем минимум 2 секунды для warmup анимации
    await Future.wait([
      Bootstrap.instance.ensureInitialized,
      Future.delayed(const Duration(seconds: 2)),
    ]);

    if (!mounted) return;

    setState(() {
      _isInitialized = true;
    });

    // Прогрев CategoryPage (незаметно для пользователя)
    _warmupCategoryPage();

    // Навигация
    final status = await Permission.photos.status;
    if (!mounted) return;

    if (status.isGranted) {
      await context.read<GalleryAssetsCubit>().loadAssets();
      if (!mounted) return;
      context.router.replaceAll([HomeRoute()]);
    } else {
      context.router.replaceAll([PermissionRequestRoute()]);
    }
  }

  /// Незаметно открывает CategoryPage за кадром для прогрева GPU/шейдеров
  void _warmupCategoryPage() {
    if (!mounted) return;

    final bloc = context.read<MediaCleanerBloc>();

    // Проверяем, есть ли хоть одна категория с данными
    if (bloc.state is! MediaCleanerReady) return;

    final state = bloc.state as MediaCleanerReady;

    // Определяем первую доступную категорию
    String? categoryType;
    String? categoryName;

    if (state.screenshots.isNotEmpty) {
      categoryType = 'photo';
      categoryName = 'screenshots';
    } else if (state.blurry.isNotEmpty) {
      categoryType = 'photo';
      categoryName = 'blurry';
    } else if (state.livePhotos.isNotEmpty) {
      categoryType = 'photo';
      categoryName = 'livePhotos';
    } else if (state.similarGroups.isNotEmpty) {
      categoryType = 'photo';
      categoryName = 'similar';
    } else if (state.photoDuplicateGroups.isNotEmpty) {
      categoryType = 'photo';
      categoryName = 'series';
    } else if (state.screenRecordings.isNotEmpty) {
      categoryType = 'video';
      categoryName = 'screenRecordings';
    } else if (state.shortVideos.isNotEmpty) {
      categoryType = 'video';
      categoryName = 'shortVideos';
    }

    // Если есть категория, прогреваем ее
    if (categoryType != null && categoryName != null) {
      _warmupOverlay = OverlayEntry(
        builder: (context) => Positioned(
          left: -10000, // За пределами экрана
          top: -10000,
          child: Opacity(
            opacity: 0.0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: CategoryPage(categoryType: categoryType!, categoryName: categoryName!),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(_warmupOverlay!);

      // Удаляем через 100ms (достаточно для прогрева)
      Future.delayed(const Duration(milliseconds: 100), () {
        _warmupOverlay?.remove();
        _warmupOverlay = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Stack(
        children: [
          // Warmup анимация (прогрев шейдеров и GPU)
          const Positioned.fill(child: ShaderWarmupAnimation()),

          // Текст в центре
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 360),

                // App Name
                 Text(
                  Locales.current.ai_cleaner,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.2,
                  ),
                ).animate().fadeIn(duration: 1000.ms).slideY(begin: 0.3, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
