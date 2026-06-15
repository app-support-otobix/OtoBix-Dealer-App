import 'package:flutter/material.dart';
import 'package:otobix/Controllers/login_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_images.dart';
import 'package:otobix/Views/Dealer%20Panel/forget_password_page.dart';
import 'package:otobix/Views/Login/login_page.dart';
import 'package:otobix/Controllers/register_controller.dart';
import 'package:get/get.dart';
import 'package:otobix/Widgets/button_widget.dart';

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final RegisterController getxController = Get.put(RegisterController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAppLogo(),
                  SizedBox(height: 20),
                  _buildWelcomeText(),
                  SizedBox(height: 40),
                  // _buildRoleSelection(),
                  // SizedBox(height: 30),
                  _buildPhoneNumberField(context),
                  SizedBox(height: 10),
                  _buildForgetPasswordButton(),
                  SizedBox(height: 15),
                  _buildContinueButton(context),
                  SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(color: AppColors.grey),
                      ),
                      SizedBox(width: 5),
                      InkWell(
                        onTap: () {
                          Get.delete<LoginController>();
                          Get.to(() => LoginPage());
                        },
                        borderRadius: BorderRadius.circular(50),

                        // onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // App Logo
  Widget _buildAppLogo() =>
      Image.asset(AppImages.otobixLogo, height: 150, width: 150);

  //Welcome Text
  Widget _buildWelcomeText() => Column(
    children: [
      Text(
        'Create an Account',
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
      ),
      Text(
        'Welcome! Please enter your details',
        style: TextStyle(fontSize: 12, color: AppColors.grey),
      ),
    ],
  );

  // Widget _buildRoleSelection() => Column(
  //   crossAxisAlignment: CrossAxisAlignment.center,
  //   children: [
  //     Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //       children: [
  //         _buildRoleSelectionButton(
  //           icon: Icons.group,
  //           titleText: 'Customer',
  //           role: AppConstants.roles.customer,
  //         ),
  //         _buildRoleSelectionButton(
  //           icon: Icons.person,
  //           titleText: 'Sales Manager',
  //           role: AppConstants.roles.salesManager,
  //         ),
  //         _buildRoleSelectionButton(
  //           icon: Icons.phone,
  //           titleText: 'Dealer',
  //           role: AppConstants.roles.dealer,
  //         ),
  //       ],
  //     ),
  //     SizedBox(height: 10),
  //     Text(
  //       'Select Role',
  //       style: TextStyle(
  //         fontSize: 15,
  //         fontWeight: FontWeight.bold,
  //         color: AppColors.black,
  //       ),
  //     ),
  //   ],
  // );

  // Role Selection Button
  // Widget _buildRoleSelectionButton({
  //   required IconData icon,
  //   required String titleText,
  //   required String role,
  // }) => GetBuilder<RegisterController>(
  //   builder:
  //       (getxController) => InkWell(
  //         onTap: () => getxController.setSelectedRole(role),
  //         borderRadius: BorderRadius.circular(100),
  //         child: Container(
  //           // padding: const EdgeInsets.all(25),
  //           width: 90,
  //           height: 90,
  //           decoration: BoxDecoration(
  //             shape: BoxShape.circle,
  //             color:
  //                 getxController.selectedRole.value == role
  //                     ? AppColors.green
  //                     : AppColors.grey.withValues(alpha: .2),
  //             // borderRadius: BorderRadius.circular(10),
  //             // border: Border.all(
  //             // color:
  //             //     getxController.selectedRole.value == role
  //             //         ? AppColors.green
  //             //         // : getxController.selectedRole.value.isEmpty
  //             //         // ? AppColors.red
  //             //         : AppColors.green,
  //             // ),
  //           ),
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Icon(
  //                 icon,
  //                 color:
  //                     getxController.selectedRole.value == role
  //                         ? AppColors.white
  //                         : AppColors.grey,
  //               ),
  //               SizedBox(height: 5),
  //               Text(
  //                 titleText,
  //                 textAlign: TextAlign.center,
  //                 style: TextStyle(
  //                   fontSize: 10,
  //                   color:
  //                       getxController.selectedRole.value == role
  //                           ? AppColors.white
  //                           : AppColors.grey,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  // );

  Widget _buildPhoneNumberField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Number',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        SizedBox(height: 5),
        TextField(
          controller: getxController.phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: InputDecoration(
            counterText: "",
            hintText: 'e.g. 9876543210',
            hintStyle: TextStyle(color: AppColors.grey.withValues(alpha: .5)),
            prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
            prefixIcon: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+91',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(width: 1, height: 20, color: Colors.grey),
                  SizedBox(width: 8),
                ],
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.green, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          ),
        ),
        // SizedBox(height: 15),
      ],
    );
  }

  // Forget Password Button
  Widget _buildForgetPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: GestureDetector(
          onTap: () {
            Get.to(() => ForgetPasswordPage());
          },
          child: Text(
            'Forgot Password?',
            style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  //Continue Button
  Widget _buildContinueButton(BuildContext context) => ButtonWidget(
    text: 'Continue',
    isLoading: getxController.isLoading,
    onTap:
        () => getxController.sendOTP(
          phoneNumber: getxController.phoneController.text,
        ),
    // onTap:
    //     () => getxController.dummySendOtp(
    //       phoneNumber: getxController.phoneController.text,
    //     ),
    height: 40,
    width: 150,
    backgroundColor: AppColors.green,
    textColor: AppColors.white,
    loaderSize: 15,
    loaderStrokeWidth: 1,
    loaderColor: AppColors.white,
  );
}
