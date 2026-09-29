import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_inventory_controller.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/toast_widget.dart';

class _CarImage {
  final String? path;
  String? url;
  bool failed = false;

  _CarImage({this.path, this.url});

  bool get isUploading => url == null && !failed;
}

class CarImagesPicker extends StatefulWidget {
  final int maxImageCount;
  final List<String> initialUrls;
  final void Function(List<String> urls, int notReady) onChanged;

  const CarImagesPicker({
    super.key,
    required this.maxImageCount,
    required this.onChanged,
    this.initialUrls = const [],
  });

  @override
  State<CarImagesPicker> createState() => _CarImagesPickerState();
}

class _CarImagesPickerState extends State<CarImagesPicker> {
  static const _allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  };

  final _picker = ImagePicker();
  late final List<_CarImage> _images = [
    for (final url in widget.initialUrls) _CarImage(url: url),
  ];

  void _notify() {
    widget.onChanged([
      for (final i in _images)
        if (i.url != null) i.url!,
    ], _images.where((i) => i.url == null).length);
  }

  Future<void> _upload(_CarImage image) async {
    setState(() => image.failed = false);
    _notify();
    try {
      image.url = await DealerInventoryController.to.uploadImage(image.path!);
    } on DealerApiException catch (e) {
      image.failed = true;
      _toast('Photo not uploaded', e.message);
    }
    if (!mounted) return;
    setState(() {});
    _notify();
  }

  Future<void> _add(List<XFile> files) async {
    final remaining = widget.maxImageCount - _images.length;
    final accepted = <_CarImage>[];
    for (final f in files.take(remaining)) {
      final ext = f.path.split('.').last.toLowerCase();
      if (!_allowedExtensions.contains(ext)) {
        _toast(
          'Unsupported file',
          'Only JPG, PNG, WEBP or HEIC photos can be added.',
        );
        continue;
      }
      accepted.add(_CarImage(path: f.path));
    }
    if (files.length > remaining) {
      _toast(
        'Limit reached',
        'Maximum ${widget.maxImageCount} images allowed.',
      );
    }
    if (accepted.isEmpty) return;
    setState(() => _images.addAll(accepted));
    for (final image in accepted) {
      if (!mounted) return;
      await _upload(image);
    }
  }

  Future<void> _pick() async {
    if (_images.length >= widget.maxImageCount) {
      _toast(
        'Limit reached',
        'Maximum ${widget.maxImageCount} images allowed.',
      );
      return;
    }
    final source = await Get.bottomSheet<ImageSource>(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            const Center(
              child: Text(
                'Add Images',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.green),
              title: const Text(
                'Camera',
                style: TextStyle(color: AppColors.green),
              ),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.blue),
              title: const Text(
                'Gallery',
                style: TextStyle(color: AppColors.blue),
              ),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      if (source == ImageSource.camera) {
        final file = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1920,
        );
        if (file != null) await _add([file]);
      } else {
        await _add(
          await _picker.pickMultiImage(imageQuality: 80, maxWidth: 1920),
        );
      }
    } catch (_) {
      _toast(
        'Could not open photos',
        'Please allow camera and photo access in Settings.',
      );
    }
  }

  void _remove(int index) {
    setState(() => _images.removeAt(index));
    _notify();
  }

  void _toast(String title, String subtitle) {
    if (!mounted) return;
    ToastWidget.show(
      context: context,
      title: title,
      subtitle: subtitle,
      type: ToastType.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount:
                _images.length +
                (_images.length < widget.maxImageCount ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              if (i == _images.length) {
                return InkWell(
                  onTap: _pick,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 70,
                    decoration: BoxDecoration(
                      color: AppColors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.grey,
                    ),
                  ),
                );
              }
              return _thumbnail(i, _images[i]);
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_images.length} / ${widget.maxImageCount} photos',
          style: const TextStyle(fontSize: 10, color: AppColors.grey),
        ),
      ],
    );
  }

  Widget _thumbnail(int index, _CarImage image) {
    final picture =
        image.path != null
            ? Image.file(
              File(image.path!),
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            )
            : CachedNetworkImage(
              imageUrl: image.url!,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: picture),
        if (image.isUploading || image.failed)
          Positioned.fill(
            child: InkWell(
              onTap: image.failed ? () => _upload(image) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child:
                      image.failed
                          ? const Icon(Icons.refresh, color: Colors.white)
                          : const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
            ),
          ),
        Positioned(
          top: -6,
          right: -6,
          child: InkWell(
            onTap: () => _remove(index),
            child: const CircleAvatar(
              radius: 10,
              backgroundColor: AppColors.black,
              child: Icon(Icons.close, size: 12, color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }
}
