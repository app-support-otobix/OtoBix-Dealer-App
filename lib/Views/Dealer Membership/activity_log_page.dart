import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_activity_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_membership_navigator.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  final list = DealerMembershipController.to.activity()..refresh();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(title: 'Activity Log'),
      body: SafeArea(
        child: Obx(
          () => RefreshIndicator(
            color: AppColors.green,
            onRefresh: list.refresh,
            child: DealerStateView(
              isLoading: list.isLoading.value,
              error: list.error.value,
              isEmpty: list.items.isEmpty,
              emptyIcon: Icons.history,
              emptyMessage: 'No activity here yet.',
              onRetry: list.refresh,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
                    list.load();
                  }
                  return false;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _row(list.items[i]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(DealerActivityModel a) {
    return InkWell(
      onTap:
          () => DealerMembershipNavigator.openTarget(a.targetType, a.targetId),
      borderRadius: BorderRadius.circular(12),
      child: DealerSectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DealerStatusChip(
              label: a.category,
              color: DealerMembershipNavigator.categoryColor(a.category),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (a.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      a.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    GlobalFunctions.timeAgo(a.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
