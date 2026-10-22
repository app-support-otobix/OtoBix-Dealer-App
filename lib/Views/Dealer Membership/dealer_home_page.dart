import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Controllers/home_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_activity_model.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_membership_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_images.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_membership_navigator.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_type_choice_page.dart';
import 'package:otobix/Views/Dealer%20Panel/user_notifications_page.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_renewal_banner.dart';
import 'package:otobix/Widgets/Dealer%20Membership/showroom_location_widgets.dart';

class DealerHomePage extends StatefulWidget {
  const DealerHomePage({super.key});

  @override
  State<DealerHomePage> createState() => _DealerHomePageState();
}

class _DealerHomePageState extends State<DealerHomePage> {
  final DealerMembershipController controller = DealerMembershipController.to;
  final _searchController = TextEditingController();
  String _query = '';
  late final Worker _membershipWorker;

  @override
  void initState() {
    super.initState();
    controller.syncSession();
    // A dealer with no showroom location is asked for it once the membership
    // is in, whether it loads now or already had.
    _membershipWorker = ever(
      controller.membership,
      (_) => _askForShowroomLocation(),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _askForShowroomLocation(),
    );
  }

  @override
  void dispose() {
    _membershipWorker.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _askForShowroomLocation() {
    if (mounted && controller.shouldAskForShowroomLocation()) {
      askForShowroomLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Enrolled before registration asked the dealer type: chosen once, first.
    return Obx(
      () =>
          controller.membership.value?.needsDealerType ?? false
              ? const DealerTypeChoicePage()
              : _buildHome(),
    );
  }

  Widget _buildHome() {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: controller.loadHome,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildSearchBar(),
              if (_query.isNotEmpty) _buildSearchResults(),
              const SizedBox(height: 14),
              // Each of these hides itself while OtoBix has its module off
              // (CRM App Access), spacing included.
              _buildMembershipCard(),
              _buildPromoBanner(),
              _buildModuleGrid(),
              Row(
                children: [
                  const Text(
                    'Latest Activity',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: DealerMembershipNavigator.openActivityLog,
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              AppImages.otobixLogo,
              height: 36,
              width: 104,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text(
              'Dealer Home Screen',
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        IconButton(
          icon: Obx(
            () => Badge.count(
              count:
                  Get.isRegistered<HomeController>()
                      ? Get.find<HomeController>()
                          .unreadNotificationsCount
                          .value
                      : 0,
              isLabelVisible:
                  Get.isRegistered<HomeController>() &&
                  Get.find<HomeController>().unreadNotificationsCount.value > 0,
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.grey,
              ),
            ),
          ),
          onPressed: () => Get.to(() => UserNotificationsPage()),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search features…',
          hintStyle: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.6),
            fontSize: 13,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.grey, size: 20),
          suffixIcon:
              _query.isEmpty
                  ? null
                  : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(color: AppColors.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(color: AppColors.green, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() => Obx(() {
    final matches =
        DealerMembershipNavigator.features
            .where(
              (f) =>
                  DealerMembershipNavigator.isFeatureShown(f) &&
                  (f.label.toLowerCase().contains(_query) ||
                      f.keywords.any((k) => k.contains(_query))),
            )
            .toList();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DealerSectionCard(
        padding: EdgeInsets.zero,
        child:
            matches.isEmpty
                ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'No matching feature',
                    style: TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                )
                : Column(
                  children: [
                    for (final f in matches)
                      ListTile(
                        dense: true,
                        leading: Icon(f.icon, color: AppColors.green, size: 20),
                        title: Text(
                          f.label,
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.grey,
                          size: 18,
                        ),
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          _searchController.clear();
                          setState(() => _query = '');
                          f.open(context);
                        },
                      ),
                  ],
                ),
      ),
    );
  });

  Widget _buildMembershipCard() {
    return Obx(() {
      final m = controller.membership.value;
      if (m == null ||
          !controller.moduleEnabled(
            DealerMembershipController.moduleMembership,
          )) {
        return const SizedBox.shrink();
      }
      final month =
          m.cycleStartAt == null
              ? ''
              : '${DateFormat('MMMM').format(m.cycleStartAt!.toLocal())} cycle';
      return Column(
        children: [
          InkWell(
            onTap: DealerMembershipNavigator.openMembership,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.08),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_outlined,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (m.plan?.name ?? 'Dealer Membership').toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (controller.dealerName.value.isNotEmpty)
                              controller.dealerName.value,
                            m.dealerCode,
                          ].join(' · '),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                        Text(
                          [
                            if (month.isNotEmpty) month,
                            if (m.city.isNotEmpty) m.city,
                          ].join(' · '),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        GlobalFunctions.formatNumber(m.availablePoints),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.green,
                        ),
                      ),
                      const Text(
                        'points',
                        style: TextStyle(fontSize: 10, color: AppColors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const DealerRenewalBanner(margin: EdgeInsets.zero),
          const SizedBox(height: 10),
        ],
      );
    });
  }

  // Adds a customer's car, so it belongs to Sell.
  Widget _buildPromoBanner() => Obx(() {
    if (!controller.moduleEnabled(DealerMembershipController.moduleSell)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: DealerMembershipNavigator.openAddCustomerCar,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELL YOUR CAR, GET THE BEST PRICE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.green,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Verified buyers · instant payment',
                style: TextStyle(fontSize: 12, color: AppColors.black),
              ),
            ],
          ),
        ),
      ),
    );
  });

  Widget _buildModuleGrid() {
    final modules = <_ModuleItem>[
      _ModuleItem(
        'Sell',
        DealerMembershipController.moduleSell,
        AppImages.dealerModuleSell,
        Colors.green,
        DealerMembershipNavigator.openSell,
      ),
      _ModuleItem(
        'Buy',
        DealerMembershipController.moduleBuy,
        AppImages.dealerModuleBuy,
        Colors.blue,
        () => DealerMembershipNavigator.openBuyDrawer(context),
      ),
      _ModuleItem(
        'Services',
        DealerMembershipController.moduleServices,
        AppImages.dealerModuleServices,
        Colors.deepPurple,
        () => DealerMembershipNavigator.openServicesDrawer(context),
      ),
      _ModuleItem(
        'Leads',
        DealerMembershipController.moduleLeads,
        AppImages.dealerModuleLeads,
        Colors.deepOrange,
        DealerMembershipNavigator.openLeads,
      ),
      _ModuleItem(
        'Membership',
        DealerMembershipController.moduleMembership,
        AppImages.dealerModuleMembership,
        Colors.teal,
        DealerMembershipNavigator.openMembership,
      ),
    ];

    // Only the modules OtoBix has on for this dealer (CRM App Access); one
    // switched off disappears at once. Filtered here, not in itemBuilder
    // (which runs outside Obx).
    return Obx(() {
      final shown =
          modules.where((m) => controller.moduleEnabled(m.code)).toList();
      if (shown.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modules',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shown.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, i) {
              final m = shown[i];
              return InkWell(
                onTap: m.onTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: m.color.withValues(alpha: 0.1),
                    border: Border.all(color: m.color, width: 0.75),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(m.iconAsset, width: 66, height: 66),
                      const SizedBox(height: 6),
                      Text(
                        m.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      );
    });
  }

  Widget _buildActivity() {
    return Obx(() {
      // Nothing that would open a module OtoBix has off.
      final pending =
          controller.pendingActivities
              .where(
                (p) => DealerMembershipNavigator.isTargetShown(p.targetType),
              )
              .toList();
      final latest =
          controller.latestActivities
              .where(
                (a) => DealerMembershipNavigator.isTargetShown(a.targetType),
              )
              .toList();
      if (controller.isLoadingHome.value && pending.isEmpty && latest.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.green),
          ),
        );
      }
      if (controller.homeError.value.isNotEmpty &&
          pending.isEmpty &&
          latest.isEmpty) {
        return DealerStateView(
          isLoading: false,
          error: controller.homeError.value,
          isEmpty: true,
          emptyMessage: '',
          onRetry: controller.loadHome,
          child: const SizedBox.shrink(),
        );
      }
      if (pending.isEmpty && latest.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No activity yet. Offers, connection requests and matches will show up here.',
            style: TextStyle(fontSize: 12, color: AppColors.grey),
          ),
        );
      }
      return Column(
        children: [
          for (final p in pending) _pendingCard(p),
          for (final a in latest) _activityCard(a),
        ],
      );
    });
  }

  Widget _pendingCard(DealerPendingActivityModel p) {
    final isConnection = p.type == 'CONNECTION_REQUEST';
    final timeLeft = GlobalFunctions.timeLeft(p.expiresAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap:
            () =>
                DealerMembershipNavigator.openTarget(p.targetType, p.targetId),
        borderRadius: BorderRadius.circular(12),
        child: DealerSectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                isConnection ? Icons.link : Icons.local_offer_outlined,
                color: AppColors.blue,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      [
                        p.subtitle,
                        if (timeLeft.isNotEmpty) timeLeft,
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              DealerStatusChip(
                label: isConnection ? 'Deal Room Request' : 'Offer to Review',
                color: AppColors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityCard(DealerActivityModel a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap:
            () =>
                DealerMembershipNavigator.openTarget(a.targetType, a.targetId),
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
                        fontSize: 12,
                      ),
                    ),
                    if (a.subtitle.isNotEmpty)
                      Text(
                        a.subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey,
                        ),
                      ),
                    Text(
                      GlobalFunctions.timeAgo(a.createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleItem {
  final String label;
  final String code; // DealerMembershipController.module*
  final String iconAsset;
  final Color color;
  final VoidCallback onTap;
  _ModuleItem(this.label, this.code, this.iconAsset, this.color, this.onTap);
}
