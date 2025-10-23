import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../gallery/presentation/cubit/gallery_assets/gallery_assets_cubit.dart';
import '../widgets/home_appbar.dart';
import '../../../../app/swiper/custom_controller.dart';
import '../../../../app/swiper/swiper.dart';

@RoutePage()
class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final controller = CustomSwiperController();
  int deletedAssetsCount = 0;
  @override
  Widget build(BuildContext context) {
    final assets = context.watch<GalleryAssetsCubit>().state.assets;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: HomeAppbar(),
      body: AssetSwiper(controller: controller, assets: assets),
    );
  }
}
