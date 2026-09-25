import 'package:flutter/material.dart';
import 'package:otobix/Utils/app_colors.dart';

/// Rounded white card used to group related content.
class DealerSectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double elevation;

  const DealerSectionCard({
    super.key,
    this.title,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: elevation,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 10),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class DealerStatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const DealerStatTile({
    super.key,
    required this.value,
    required this.label,
    this.color = AppColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.grey),
        ),
      ],
    );
  }
}

class DealerStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;

  const DealerStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: small ? 9 : 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Loading, error (with retry) and empty states shared by every screen, so a
/// list is never blank without saying why.
class DealerStateView extends StatelessWidget {
  final bool isLoading;
  final String error;
  final bool isEmpty;
  final IconData emptyIcon;
  final String emptyMessage;
  final VoidCallback? onRetry;
  final Widget child;

  const DealerStateView({
    super.key,
    required this.isLoading,
    required this.error,
    required this.isEmpty,
    required this.emptyMessage,
    required this.child,
    this.emptyIcon = Icons.inbox_outlined,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }
    if (error.isNotEmpty && isEmpty) {
      return _message(
        Icons.cloud_off_outlined,
        error,
        action:
            onRetry == null
                ? null
                : TextButton(
                  onPressed: onRetry,
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: AppColors.green),
                  ),
                ),
      );
    }
    if (isEmpty) return _message(emptyIcon, emptyMessage);
    return child;
  }

  Widget _message(IconData icon, String text, {Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.grayWithOpacity1),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.grey),
            ),
            if (action != null) action,
          ],
        ),
      ),
    );
  }
}
