import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_images.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ShowImagePage extends StatelessWidget {
  final List<String> imageUrls;
  final List<String>? imageLabels;
  final int initialIndex;

  // Single constructor that handles both single and multiple images
  ShowImagePage({
    super.key,
    required dynamic imageUrls,
    dynamic imageLabels,
    int initialIndex = 0,
  }) : imageUrls = _parseImageUrls(imageUrls),
       imageLabels = _parseImageLabels(
         imageLabels,
         _parseImageUrls(imageUrls).length,
       ),
       initialIndex = _validateInitialIndex(
         initialIndex,
         _parseImageUrls(imageUrls).length,
       );

  // Helper to parse image URLs (accepts String or List<String>)
  static List<String> _parseImageUrls(dynamic urls) {
    if (urls == null) {
      return [];
    }
    if (urls is String) {
      return [urls];
    }
    if (urls is List<String>) {
      return urls;
    }
    if (urls is List) {
      return urls.cast<String>();
    }
    return [];
  }

  // Helper to parse image labels (accepts String, List<String>, or null)
  static List<String>? _parseImageLabels(dynamic labels, int urlCount) {
    if (labels == null) {
      return null;
    }
    if (labels is String) {
      return [labels];
    }
    if (labels is List<String>) {
      return labels.length == urlCount ? labels : null;
    }
    if (labels is List) {
      final casted = labels.cast<String>();
      return casted.length == urlCount ? casted : null;
    }
    return null;
  }

  // Helper to validate initial index
  static int _validateInitialIndex(int index, int length) {
    if (length == 0) return 0;
    return index.clamp(0, length - 1);
  }

  @override
  Widget build(BuildContext context) {
    // Validate that we have images to show
    if (imageUrls.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          title: const Text(
            'No Image',
            style: TextStyle(color: AppColors.white),
          ),
          iconTheme: const IconThemeData(color: AppColors.white),
        ),
        body: const Center(
          child: Text(
            'No image available',
            style: TextStyle(color: AppColors.white),
          ),
        ),
      );
    }

    // Check if single image or multiple
    final bool isSingleImage = imageUrls.length == 1;

    final RxInt currentIndex = initialIndex.obs;
    final PageController? pageController =
        isSingleImage ? null : PageController(initialPage: initialIndex);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title:
            isSingleImage
                ? const Text(
                  'Image View',
                  style: TextStyle(color: AppColors.white),
                )
                : Obx(
                  () => Text(
                    '${currentIndex.value + 1} / ${imageUrls.length}',
                    style: const TextStyle(color: AppColors.white),
                  ),
                ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Stack(
        children: [
          // Auto-detect whether to show single image or gallery
          isSingleImage
              ? _buildSingleImageView()
              : _buildGalleryView(pageController!, currentIndex),

          // Show label overlay if labels are provided
          if (imageLabels != null && imageLabels!.isNotEmpty)
            isSingleImage
                ? _buildSingleImageLabel(imageLabels!.first)
                : _buildLabelOverlay(currentIndex, imageLabels!),
        ],
      ),
    );
  }

  Widget _buildSingleImageView() {
    return Center(
      child: PhotoView(
        imageProvider: CachedNetworkImageProvider(imageUrls.first),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        backgroundDecoration: const BoxDecoration(color: AppColors.black),
        heroAttributes: PhotoViewHeroAttributes(
          tag: 'image-0',
          transitionOnUserGestures: true,
        ),
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Image(
              image: AssetImage(AppImages.carAlternateImage),
              width: 200,
              height: 200,
            ),
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
    );
  }

  Widget _buildGalleryView(PageController pageController, RxInt currentIndex) {
    return PhotoViewGallery.builder(
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
                width: 200,
                height: 200,
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
    );
  }

  Widget _buildLabelOverlay(RxInt currentIndex, List<String> labels) {
    // Only show label if labels match the current index
    if (currentIndex.value >= labels.length) return const SizedBox.shrink();

    return Obx(
      () => Positioned(
        left: 16,
        right: 16,
        bottom: 30,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: .6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            labels[currentIndex.value],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleImageLabel(String label) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 30,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: .6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
