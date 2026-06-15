import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/car_images_gallery_controller.dart';
import 'package:otobix/Models/car_gallery_sections_model.dart';
import 'package:otobix/Models/car_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Views/Dealer%20Panel/car_images_page.dart';
import 'package:shimmer/shimmer.dart';

class CarImagesGalleryPage extends StatelessWidget {
  final CarModel car;
  final String initialSectionId;
  final int initialSectionIndex;
  final String currentOpenSection;
  final RxString remainingAuctionTime;

  const CarImagesGalleryPage({
    super.key,
    required this.car,
    required this.initialSectionId,
    required this.initialSectionIndex,
    required this.currentOpenSection,
    required this.remainingAuctionTime,
  });

  @override
  Widget build(BuildContext context) {
    final getxController = Get.put(
      CarImagesGalleryController(
        car,
        initialSectionId,
        initialSectionIndex,
        currentOpenSection,
        remainingAuctionTime,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Car Images Gallery',
          style: TextStyle(fontSize: 16, color: AppColors.white),
        ),
        backgroundColor: AppColors.green,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Column(
        children: [
          _buildChipsBar(controller: getxController),
          Expanded(
            child: Obx(
              () => ListView.builder(
                controller: getxController.scrollController,
                padding: EdgeInsets.only(bottom: getxController.outerPad),
                itemCount: getxController.sections.length,
                itemBuilder:
                    (_, i) => _sectionBlock(
                      key:
                          getxController.sectionKeys[getxController
                              .sections[i]
                              .id],
                      controller: getxController,
                      section: getxController.sections[i],
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipsBar({required CarImagesGalleryController controller}) {
    return Material(
      color: Colors.white,
      child: Container(
        key: controller.headerKey,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Obx(
          // Wrap this around the entire ListView
          () {
            final selected = controller.selectedIndex.value;
            return SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: controller.sections.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final isSelected = selected == i;
                  final title = controller.sections[i].title;
                  return GestureDetector(
                    onTap: () => controller.onChipTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.green.withValues(alpha: 0.1)
                                : AppColors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.green
                                  : AppColors.grey.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                isSelected
                                    ? AppColors.green
                                    : AppColors.black.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionBlock({
    required CarImagesGalleryController controller,
    required CarGallerySectionsModel section,
    required GlobalKey? key,
  }) {
    final gap = controller.gridGap;
    final cols = controller.gridColumns;

    // Calculate the number of rows based on the number of images and columns
    final rowCount = (section.images.length / cols).ceil();
    final validRowCount =
        rowCount > 0 ? rowCount : 1; // Ensure at least one row
    return Padding(
      key: key, // ✅ attach the provided GlobalKey here

      padding: EdgeInsets.fromLTRB(
        controller.outerPad,
        6,
        controller.outerPad,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: Theme.of(
              Get.context!,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),

          // Grid layout
          LayoutBuilder(
            builder: (context, constraints) {
              final columnSizes = List.generate(cols, (_) => 1.fr);
              return LayoutGrid(
                columnSizes: columnSizes,
                rowSizes: List.generate(validRowCount, (_) => auto),
                columnGap: gap,
                rowGap: gap,
                children: [
                  for (int i = 0; i < section.images.length; i++)
                    _buildImageTile(
                      url: section.images[i],
                      onTap: () {
                        // controller.openViewer(section, i);
                        // debugPrint('Image $i clicked');
                        Get.to(
                          () => CarImagesPage(
                            imageUrls: section.images,
                            initialIndex: i,
                          ),
                        );
                      },
                    ).withGridPlacement(
                      columnStart: i % cols,
                      rowStart: i ~/ cols,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildImageTile({required String url, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: const Color(0xFFF2F2F2),
        child: InkWell(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 3 / 4, // portrait-ish
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder:
                  (_, __) => Shimmer.fromColors(
                    baseColor: const Color(0xFFE5E7EB),
                    highlightColor: const Color(0xFFF3F4F6),
                    child: Container(color: const Color(0xFFE5E7EB)),
                  ),
              errorWidget:
                  (_, __, ___) => const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      ),
    );
  }
}
