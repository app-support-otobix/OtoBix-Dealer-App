import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/tab_bar_widget_controller.dart';
import 'package:otobix/Controllers/profile_controller.dart';
import 'package:otobix/Controllers/bottom_navigation_controller.dart';
import 'package:otobix/Services/user_activity_log_service.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Views/Dealer%20Panel/dealer_guide_page.dart';
import 'package:otobix/Views/Dealer%20Panel/delete_account_page.dart';
import 'package:otobix/Views/Dealer%20Panel/edit_account_page.dart';
import 'package:otobix/Views/Dealer%20Panel/privacy_policy_page.dart';
import 'package:otobix/Views/Dealer%20Panel/terms_and_conditions_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileController accountController = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(
          () => SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Obx(() {
                          final imageUrl =
                              accountController
                                  .imageUrl
                                  .value; // make sure `user` is reactive

                          return CircleAvatar(
                            radius: 55,
                            backgroundImage:
                                // ignore: unnecessary_null_comparison
                                imageUrl != null && imageUrl.isNotEmpty
                                    ? NetworkImage(
                                      imageUrl.startsWith('http')
                                          ? imageUrl
                                          : imageUrl,
                                    )
                                    : null,
                            child:
                                // ignore: unnecessary_null_comparison
                                imageUrl == null || imageUrl.isEmpty
                                    ? const Icon(Icons.person, size: 55)
                                    : null,
                          );
                        }),

                        SizedBox(height: 12),
                        Text(
                          accountController.username.value,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          accountController.useremail.value,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  ProfileOption(
                    icon: Icons.edit,
                    color: Colors.green,
                    title: "Edit Profile",
                    description: "Change your name, email, and more.",
                    onTap: () {
                      Get.to(EditProfileScreen());
                    },
                  ),

                  // ProfileOption(
                  //   icon: Icons.settings,
                  //   color: AppColors.grey,
                  //   title: "User Preferences",
                  //   description: "Set user preferences.",
                  //   onTap: () {
                  //     Get.to(UserPreferencesPage());
                  //   },
                  // ),
                  ProfileOption(
                    icon: Icons.gavel,
                    color: Colors.blue,
                    title: "My Bids",
                    description: "View all your active and past bids.",
                    onTap: () {
                      // final navController =
                      //     Get.find<BottomNavigationController>();
                      // navController.currentIndex.value = 1;

                      // final tabBarWidgetController = Get.put(
                      //   TabBarWidgetController(tabLength: 2),
                      // );
                      // tabBarWidgetController.setSelectedTab(0);
                      final nav = Get.find<BottomNavigationController>();
                      nav.currentIndex.value = 1;
                      Future.microtask(() {
                        final tabs = Get.put(
                          TabBarWidgetController(tabLength: 3),
                          tag:
                              AppConstants
                                  .tabBarWidgetControllerTags
                                  .myCarsTabs,
                        );
                        tabs.setSelectedTab(0); // 0 = My Bids, 2 = Wishlist
                      });
                    },
                  ),
                  ProfileOption(
                    icon: Icons.favorite_border,
                    color: Colors.red,
                    title: "Wishlist",
                    description: "See cars you've saved for later.",
                    onTap: () {
                      final nav = Get.find<BottomNavigationController>();
                      nav.currentIndex.value = 1;
                      Future.microtask(() {
                        final tabs = Get.put(
                          TabBarWidgetController(tabLength: 3),
                          tag:
                              AppConstants
                                  .tabBarWidgetControllerTags
                                  .myCarsTabs,
                        );
                        tabs.setSelectedTab(2); // 0 = My Bids, 2 = Wishlist
                      });
                    },
                  ),
                  ProfileOption(
                    icon: Icons.description,
                    color: AppColors.green,
                    title: "Terms and Conditions",
                    description: "View terms and conditions.",
                    onTap: () {
                      Get.to(TermsAndConditionsPage());
                    },
                  ),
                  ProfileOption(
                    icon: Icons.lock,
                    color: AppColors.grey,
                    title: "Privacy Policy",
                    description: "View privacy policy.",
                    onTap: () {
                      Get.to(PrivacyPolicyPage());
                    },
                  ),
                  ProfileOption(
                    icon: Icons.menu_book,
                    color: AppColors.blue,
                    title: "Dealer Guide",
                    description: "View dealer guide.",
                    onTap: () {
                      Get.to(DealerGuidePage());
                    },
                  ),
                  ProfileOption(
                    icon: Icons.delete,
                    color: Colors.red,
                    title: "Delete Account",
                    description: "Delete your account securely.",
                    onTap: () {
                      Get.to(DeleteAccountPage());
                    },
                  ),
                  ProfileOption(
                    icon: Icons.logout,
                    color: Colors.red,
                    title: "Logout",
                    description: "Sign out of your account securely.",
                    onTap: () async {
                      await accountController.logout();
                    },
                  ),
                  const SizedBox(height: 15),
                  FutureBuilder(
                    future: UserActivityLogService.getAppVersion(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            'App Version: ${snapshot.data}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? description;
  final VoidCallback onTap;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: .5),
                width: 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment:
                  description != null
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
