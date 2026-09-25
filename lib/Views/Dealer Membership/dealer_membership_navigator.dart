import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/bottom_navigation_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Views/Dealer%20Membership/activity_log_page.dart';
import 'package:otobix/Views/Dealer%20Membership/membership_dashboard_page.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';

/// A feature reachable from the Home search box.
class DealerFeature {
  final String label;
  final IconData icon;
  final List<String> keywords;
  final void Function(BuildContext context) open;

  const DealerFeature(this.label, this.icon, this.keywords, this.open);
}

/// Every route into the Dealer Membership screens: Home modules, the feature
/// search and deep links from activities and notifications all go through
/// here, so a destination is defined once.
class DealerMembershipNavigator {
  DealerMembershipNavigator._();

  static final List<DealerFeature> features = [
    DealerFeature(
      'Membership & Point Ledger',
      Icons.workspace_premium_outlined,
      ['membership', 'points', 'ledger', 'plan', 'renew', 'upgrade'],
      (_) => openMembership(),
    ),
    DealerFeature('OtoBix Auctions', Icons.gavel_outlined, [
      'buy',
      'auction',
      'live',
      'bid',
      'otobuy',
    ], (_) => openAuctions()),
    DealerFeature('Activity Log', Icons.history, [
      'activity',
      'log',
      'history',
      'notifications',
    ], (_) => openActivityLog()),
  ];

  static void openMembership() => Get.to(() => const MembershipDashboardPage());

  static void openActivityLog() => Get.to(() => const ActivityLogPage());

  /// The existing auction screens (Upcoming / Live / OtoBuy / PD).
  static void openAuctions() => Get.to(
    () => Scaffold(
      appBar: AppBarWidget(title: 'Auctions'),
      body: Get.find<BottomNavigationController>().auctionsPage,
    ),
  );

  /// Opens the object an activity or notification is about - every
  /// membership activity belongs to the membership screen.
  static void openTarget(String type, String id) => openMembership();

  static Color categoryColor(String category) =>
      category == 'MEMBERSHIP' ? Colors.teal : AppColors.grey;
}
