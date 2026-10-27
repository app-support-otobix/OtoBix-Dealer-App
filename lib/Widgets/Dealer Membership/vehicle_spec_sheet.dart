import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:otobix/Utils/app_colors.dart';

class VehicleSpecSheet extends StatelessWidget {
  final List<(String, String)> specs;
  final double labelSize;
  final double valueSize;

  const VehicleSpecSheet({
    super.key,
    required this.specs,
    this.labelSize = 10,
    this.valueSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < specs.length; i += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: valueSize / 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _spec(specs[i])),
              const SizedBox(width: 12),
              Expanded(
                child:
                    i + 1 < specs.length
                        ? _spec(specs[i + 1])
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _spec((String, String) spec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          spec.$1,
          style: TextStyle(fontSize: labelSize, color: AppColors.grey),
        ),
        Text(
          spec.$2.trim().isEmpty ? '—' : spec.$2,
          style: TextStyle(fontSize: valueSize, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class PriceBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const PriceBox({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.grey),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CarThumbnail extends StatelessWidget {
  final String imageUrl;
  final Color iconColor;
  final double size;

  const CarThumbnail({
    super.key,
    required this.imageUrl,
    this.iconColor = AppColors.green,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.directions_car,
      color: iconColor,
      size: size * 0.5,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        color: iconColor.withValues(alpha: 0.1),
        child:
            imageUrl.isEmpty
                ? fallback
                : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => fallback,
                ),
      ),
    );
  }
}
