import 'package:ai_cleaner_2/feature/cleaner/presentation/bloc/media_cleaner_bloc.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pixelarticons/pixel.dart';
import 'custom_controller.dart';
import '../../feature/gallery/domain/asset_entity_image.dart';
import '../../core/extensions/core_extensions.dart';
import '../../core/limiters/throttler.dart';
import '../../core/theme/button.dart';
import '../../core/widgets/common/widgets/text_swapper.dart';

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
                          // Только добавляем в выбранные, если еще не выбран
                          final state = cleanerBloc.state;
                          if (state is MediaCleanerLoaded) {
                            final isAlreadySelected = state.selectedFiles.any(
                              (file) => file.entity.id == currentAsset.id,
                            );

                            // Если файл еще не выбран, выбираем его
                            if (!isAlreadySelected) {
                              cleanerBloc.add(ToggleFileSelectionById(currentAsset.id));
                            }
                            // Если уже выбран, ничего не делаем - сохраняем выбор
                          }
                        } else if (activity.direction == AxisDirection.right) {
                          // Смахивание вправо (оставить)
                          // Убираем из выбранных, если был выбран
                          final state = cleanerBloc.state;
                          if (state is MediaCleanerLoaded) {
                            final isAlreadySelected = state.selectedFiles.any(
                              (file) => file.entity.id == currentAsset.id,
                            );

                            // Если файл был выбран, снимаем выбор
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
                                child: StyledButton.filled(
                                  title: "Выбрать",
                                  isLoading: _deleting,
                                  fullWidth: true,
                                  onPressed: () {
                                    widget.controller.swipeLeft();
                                  },
                                ),
                              ),
                              Positioned(
                                    right: -6,
                                    top: -6,
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        border: Border.all(color: Colors.white, width: 1),
                                      ),
                                      child: Row(
                                        children: [
                                          ...selectedCount.toString().padLeft(2, '0').split('').map(
                                            (char) {
                                              return TextSwapper(
                                                char,
                                                style: const TextStyle(fontSize: 8),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .animate(target: selectedCount > 0 ? 1 : 0)
                                  .moveY(curve: Curves.fastOutSlowIn, begin: -20, end: 0)
                                  .fadeIn(curve: Curves.fastOutSlowIn),
                            ],
                          );
                        },
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [const BoxShadow(color: Colors.white, offset: Offset(3, 3))],
                      ),
                      child: IconButton(
                        icon: const Icon(Pixel.cornerdownright, color: Colors.white),
                        onPressed: () {
                          throttler.run(() async {
                            HapticFeedback.selectionClick();
                            if (widget.controller.cardIndex == null) {
                              return;
                            }
                            if (widget.controller.cardIndex! == 0) return;
                            await widget.controller.unswipe();
                          });
                        },
                      ),
                    ),

                    Flexible(
                      child: StyledButton.filled(
                        title: "Оставить",
                        fullWidth: true,
                        onPressed: () {
                          widget.controller.swipeRight();
                        },
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
