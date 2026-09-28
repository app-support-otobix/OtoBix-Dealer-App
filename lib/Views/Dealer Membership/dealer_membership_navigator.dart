import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/bottom_navigation_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Views/Dealer%20Membership/activity_log_page.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_registration_page.dart';
import 'package:otobix/Views/Dealer%20Membership/membership_dashboard_page.dart';
import 'package:otobix/Views/Dealer%20Membership/upgrade_membership_page.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';

class DealerFeature {
  final String label;
  final IconData icon;
  final List<String> keywords;
  final void Function(BuildContext context) open;

  const DealerFeature(this.label, this.icon, this.keywords, this.open);
}

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
    DealerFeature('Upgrade Membership', Icons.upgrade, [
      'membership',
      'upgrade',
      'renew',
      'plan',
      'pro',
      'payment',
    ], (_) => openUpgrade()),
  ];

  static void openMembership() => Get.to(() => const MembershipDashboardPage());

  static void openActivityLog() => Get.to(() => const ActivityLogPage());

  static void openUpgrade() => Get.to(() => const UpgradeMembershipPage());

  static void openDealerDetails() =>
      Get.to(() => const DealerRegistrationPage());

  static void openAuctions() => Get.to(
    () => Scaffold(
      appBar: AppBarWidget(title: 'Auctions'),
      body: Get.find<BottomNavigationController>().auctionsPage,
    ),
  );

  static void openTarget(String type, String id) => openMembership();

  static Color categoryColor(String category) =>
      category == 'MEMBERSHIP' ? Colors.teal : AppColors.grey;
}
