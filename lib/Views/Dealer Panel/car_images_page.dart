import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:otobix/Utils/app_images.dart';

class CarImagesPage extends StatelessWidget {
  final List<String> imageLabels;
  final List<String> imageUrls;
  final int initialIndex;

  const CarImagesPage({
    super.key,
    this.imageLabels = const [],
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    final RxInt currentIndex = initialIndex.obs;
    final PageController pageController = PageController(
      initialPage: initialIndex,
    );

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: Obx(
          () => Text(
            '${currentIndex.value + 1} / ${imageUrls.length}',
            style: const TextStyle(color: AppColors.white),
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: imageUrls.length,
            pageController: pageController,
            onPageChanged: (index) => currentIndex.value = index,
            backgroundDecoration: const BoxDecoration(color: AppColors.black),
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(imageUrls[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(
                  tag: 'image-$index',
                  transitionOnUserGestures: true,
                ),

                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Image(
                      image: AssetImage(AppImages.carAlternateImage),
                    ),
                  );
                },
              );
            },
            loadingBuilder:
                (context, event) => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.green,
                    strokeWidth: 2,
                  ),
                ),
          ),
          if (imageLabels.isNotEmpty)
            Obx(
              () => Positioned(
                left: 16,
                right: 16,
                bottom: 30,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: .6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    imageLabels[currentIndex.value],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
