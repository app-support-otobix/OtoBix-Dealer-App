import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_membership_navigator.dart';

class DealerRenewalBanner extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const DealerRenewalBanner({
    super.key,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    final controller = DealerMembershipController.to;
    return Obx(() {
      final m = controller.membership.value;
      if (m == null) return const SizedBox.shrink();
      final pending = m.pendingPayment;
      if (pending == null && !m.showRenewalWarning) {
        return const SizedBox.shrink();
      }

      final String title;
      final String subtitle;
      final Color color;
      if (pending != null) {
        final plan =
            controller.config.value?.plans
                .firstWhereOrNull((p) => p.code == pending.planCode)
                ?.name ??
            pending.planCode;
        title = 'Upgrade to $plan requested';
        subtitle =
            'OtoBix will confirm your offline payment (${pending.code}) and start the plan.';
        color = AppColors.blue;
      } else {
        final days = '${m.daysLeft} ${m.daysLeft == 1 ? 'day' : 'days'} left';
        title = m.isGrace ? 'Grace period · $days' : 'You have $days';
        subtitle =
            m.isGrace
                ? 'Your ${m.plan?.name ?? 'membership'} has ended. Everything keeps working until the grace period ends.'
                : m.plan?.code == 'PROMO'
                ? 'Your free trial ends soon. Upgrade to keep your services running.'
                : 'Your plan ends soon. Upgrade to keep your services running.';
        color = m.isGrace ? AppColors.red : AppColors.deepOrange;
      }

      return Container(
        margin: margin,
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              pending != null ? Icons.hourglass_top : Icons.timer_outlined,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
            if (pending == null) ...[
              const SizedBox(width: 8),
              FilledButton(
                onPressed: DealerMembershipNavigator.openUpgrade,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 34),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Upgrade'),
              ),
            ],
          ],
        ),
      );
    });
  }
}
