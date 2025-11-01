import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'dart:math' as math;
import '../../../gallery/presentation/cubit/gallery_assets/gallery_assets_cubit.dart';
import '../../../../app/swiper/custom_controller.dart';
import '../../../../app/swiper/swiper.dart';
import '../../../cleaner/presentation/widgets/animated_background.dart';
import 'package:photo_manager/photo_manager.dart';

@RoutePage()
class CategoriesSwiperPage extends StatefulWidget {
  const CategoriesSwiperPage({super.key, required this.ids, required this.title});

  final String title;
  final List<String> ids;

  @override
  State<CategoriesSwiperPage> createState() => _CategoriesSwipertate();
}

class _CategoriesSwipertate extends State<CategoriesSwiperPage> {
  final controller = CustomSwiperController();

  @override
  Widget build(BuildContext context) {
    final allAssets = context.watch<GalleryAssetsCubit>().state.assets;
    final assets = widget.ids
        .map((id) {
          try {
            return allAssets.firstWhere((asset) => asset.id == id);
          } catch (e) {
            return null;
          }
        })
        .whereType<AssetEntity>()
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          AssetSwiper(controller: controller, assets: assets),
        ],
      ),
    );
  }
}
