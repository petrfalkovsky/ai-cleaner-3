import 'package:ai_cleaner_2/feature/cleaner/presentation/bloc/media_cleaner_bloc.dart';
import 'package:ai_cleaner_2/generated/l10n.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:math' as math;
import 'custom_controller.dart';
import '../../feature/gallery/domain/asset_entity_image.dart';
import '../../core/extensions/core_extensions.dart';
import '../../core/limiters/throttler.dart';

class AssetSwiper extends StatefulWidget {
  const AssetSwiper({super.key, required this.assets, required this.controller});

  final List<AssetEntity> assets;
  final CustomSwiperController controller;

  @override
  State<AssetSwiper> createState() => _AssetSwiperState();
}

class _AssetSwiperState extends State<AssetSwiper> {
  final throttler = Throttler(225.ms);
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Column(
              spacing: 24,
              children: [
                Flexible(
                  child: AppinioSwiper(
                    controller: widget.controller,
                    swipeOptions: SwipeOptions.symmetric(horizontal: true, vertical: false),
                    loop: false,
                    duration: 175.ms,
                    onSwipeEnd: (targetIndex, nextIndex, activity) {
                      if (activity.end != null && activity.end!.dx != 0) {
                        final MediaCleanerBloc cleanerBloc = context.read<MediaCleanerBloc>();
                        final currentAsset = widget.assets[targetIndex];

                        if (activity.direction == AxisDirection.left) {
                          // Смахивание влево (удаление)
                          final state = cleanerBloc.state;
                          if (state is MediaCleanerLoaded) {
                            final isAlreadySelected = state.selectedFiles.any(
                              (file) => file.entity.id == currentAsset.id,
                            );

                            if (!isAlreadySelected) {
                              cleanerBloc.add(ToggleFileSelectionById(currentAsset.id));
                            }
                          }
                        } else if (activity.direction == AxisDirection.right) {
                          // Смахивание вправо (оставить)
                          final state = cleanerBloc.state;
                          if (state is MediaCleanerLoaded) {
                            final isAlreadySelected = state.selectedFiles.any(
                              (file) => file.entity.id == currentAsset.id,
                            );

                            if (isAlreadySelected) {
                              cleanerBloc.add(ToggleFileSelectionById(currentAsset.id));
                            }
                          }
                        }
                      }
                    },
                    backgroundCardCount: 4,
                    backgroundCardOffset: const Offset(25, 25),
                    cardBuilder: (BuildContext context, int index) {
                      final asset = widget.assets[index % widget.assets.length];

                      return ImageItemWidget(
                        entity: asset,
                        index: index,
                        option: ThumbnailOption.ios(size: ThumbnailSize(720, 1560)),
                        controller: widget.controller,
                      );
                    },
                    cardCount: widget.assets.length,
                  ).animate().fadeIn(curve: Curves.fastOutSlowIn, duration: 850.ms),
                ),
                Row(
                  spacing: 24,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Кнопка "Выбрать" с liquid glass
                    Flexible(
                      child: BlocBuilder<MediaCleanerBloc, MediaCleanerState>(
                        builder: (context, state) {
                          final selectedCount = state is MediaCleanerLoaded
                              ? state.selectedFiles.length
                              : 0;

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  widget.controller.swipeLeft();
                                },
                                onLongPress: () async {
                                  if (_deleting ||
                                      state is! MediaCleanerLoaded ||
                                      selectedCount == 0)
                                    return;
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _deleting = true;
                                  });
                                  context.read<MediaCleanerBloc>().add(DeleteSelectedFiles());
                                  setState(() {
                                    _deleting = false;
                                  });
                                },
                                child: LiquidGlass(
                                  settings: LiquidGlassSettings(
                                    blur: 5,
                                    ambientStrength: 0.8,
                                    lightAngle: 0.2 * math.pi,
                                    glassColor: CupertinoColors.systemRed.withOpacity(0.3),
                                    thickness: 15,
                                  ),
                                  shape: const LiquidRoundedSuperellipse(
                                    borderRadius: Radius.circular(16),
                                  ),
                                  glassContainsChild: false,
                                  child: Container(
                                    height: 52,
                                    alignment: Alignment.center,
                                    child: _deleting
                                        ? const CupertinoActivityIndicator(color: Colors.white)
                                        : Text(
                                            Locales.current.select,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              // Badge с количеством
                              if (selectedCount > 0)
                                Positioned(
                                  right: -6,
                                  top: -6,
                                  child:
                                      AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: CupertinoColors.systemRed,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                            child: Text(
                                              selectedCount.toString(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                          .animate(target: selectedCount > 0 ? 1 : 0)
                                          .scale(
                                            begin: const Offset(0.5, 0.5),
                                            end: const Offset(1.0, 1.0),
                                            duration: 200.ms,
                                            curve: Curves.easeOutBack,
                                          )
                                          .fadeIn(curve: Curves.fastOutSlowIn),
                                ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Кнопка откатить
                    GestureDetector(
                      onTap: () {
                        throttler.run(() async {
                          HapticFeedback.selectionClick();
                          if (widget.controller.cardIndex == null) {
                            return;
                          }
                          if (widget.controller.cardIndex! == 0) return;
                          await widget.controller.unswipe();
                        });
                      },
                      child: LiquidGlass(
                        settings: LiquidGlassSettings(
                          blur: 5,
                          ambientStrength: 0.8,
                          lightAngle: 0.2 * math.pi,
                          glassColor: Colors.white.withOpacity(0.15),
                          thickness: 15,
                        ),
                        shape: const LiquidRoundedSuperellipse(borderRadius: Radius.circular(16)),
                        glassContainsChild: false,
                        child: Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          child: const Icon(
                            CupertinoIcons.arrow_uturn_left,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),

                    // Кнопка "Оставить"
                    Flexible(
                      child: GestureDetector(
                        onTap: () {
                          widget.controller.swipeRight();
                        },
                        child: LiquidGlass(
                          settings: LiquidGlassSettings(
                            blur: 5,
                            ambientStrength: 0.8,
                            lightAngle: 0.2 * math.pi,
                            glassColor: CupertinoColors.systemGreen.withOpacity(0.3),
                            thickness: 15,
                          ),
                          shape: const LiquidRoundedSuperellipse(borderRadius: Radius.circular(16)),
                          glassContainsChild: false,
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            child: Text(
                              Locales.current.keep,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ).fallback(const SizedBox.shrink(), when: widget.assets.isEmpty),
          ],
        ),
      ),
    );
  }
}
