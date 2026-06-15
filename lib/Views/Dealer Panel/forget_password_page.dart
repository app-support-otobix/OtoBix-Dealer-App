import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/forget_password_controller.dart';
import 'package:otobix/Utils/app_images.dart';
import 'package:otobix/Widgets/button_widget.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:otobix/Utils/app_colors.dart';

class ForgetPasswordPage extends StatelessWidget {
  const ForgetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final forgetPasswordController = Get.put(ForgetPasswordController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.green),
        title: const Text(
          'Forget Password',
          style: TextStyle(
            color: AppColors.green,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        return Stack(
          children: [
            PageView(
              controller: forgetPasswordController.pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPhoneNumberPage(context, forgetPasswordController),
                _buildOtpPage(context, forgetPasswordController),
                _buildNewPasswordPage(context, forgetPasswordController),
              ],
            ),
          ],
        );
      }),
    );
  }

  // ------------ PAGE 1: Phone Number Page ------------
  Widget _buildPhoneNumberPage(
    BuildContext context,
    ForgetPasswordController forgetPasswordController,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AppImages.forgetPasswordPageOneImage, width: 150),
              const SizedBox(height: 15),
              const Text(
                'Enter your phone number',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildPhoneNumberField(forgetPasswordController),
              const SizedBox(height: 25),
              _buildButton(
                label: 'Continue',
                isLoading: forgetPasswordController.isSendOtpLoading,
                onPressed: () {
                  forgetPasswordController.unfocusKeyBoardOnApiCall();
                  forgetPasswordController.sendOTP();
                  // forgetPasswordController.goToPage(1);
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ------------ PAGE 2: OTP Page ------------
  Widget _buildOtpPage(
    BuildContext context,
    ForgetPasswordController forgetPasswordController,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Image.asset(AppImages.forgetPasswordPageTwoImage, width: 250),
              const SizedBox(height: 15),
              Text(
                'Enter the OTP sent to ${forgetPasswordController.phoneCtrl.text.trim().isEmpty ? 'your phone number' : '(+91) - ${forgetPasswordController.phoneCtrl.text.trim()}'}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildOtpFields(context, forgetPasswordController),
              const SizedBox(height: 24),
              _buildButton(
                label: 'Verify OTP',
                onPressed: () {
                  forgetPasswordController.unfocusKeyBoardOnApiCall();
                  forgetPasswordController.verifyOtp();
                  // forgetPasswordController.goToPage(2);
                },
                isLoading: forgetPasswordController.isVerifyOtpLoading,
              ),
              // TextButton(
              //   onPressed: () {
              //     // forgetPasswordController.requestOtp();
              //     forgetPasswordController.goToPage(1);
              //   },
              //   child: const Text('Resend OTP'),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------ PAGE 3: New Password Page ------------
  Widget _buildNewPasswordPage(
    BuildContext context,
    ForgetPasswordController forgetPasswordController,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: forgetPasswordController.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(AppImages.forgetPasswordPageThreeImage, width: 250),
                const SizedBox(height: 15),
                const Text(
                  'Create a new password',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildNewPasswordField(
                  forgetPasswordController: forgetPasswordController,
                ),
                const SizedBox(height: 12),
                _buildConfirmPasswordField(
                  forgetPasswordController: forgetPasswordController,
                ),
                const SizedBox(height: 24),
                _buildButton(
                  label: 'Confirm',
                  onPressed: () {
                    final form = forgetPasswordController.formKey.currentState!;
                    if (form.validate()) {
                      // match check
                      if (forgetPasswordController.passwordCtrl.text.trim() !=
                          forgetPasswordController.confirmPasswordCtrl.text
                              .trim()) {
                        ToastWidget.show(
                          context: Get.context!,
                          title: "Passwords don't match",
                          type: ToastType.error,
                        );
                        return;
                      }
                      forgetPasswordController.unfocusKeyBoardOnApiCall();
                      forgetPasswordController.setNewPassword();
                      // forgetPasswordController.goToPage(0);
                    }
                  },

                  isLoading: forgetPasswordController.isSetNewPasswordLoading,
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------ WIDGET BUILDERS ------------

  Widget _buildPhoneNumberField(
    ForgetPasswordController forgetPasswordController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: forgetPasswordController.phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
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
      ],
    );
  }

  Widget _buildOtpFields(
    BuildContext parentContext,
    ForgetPasswordController forgetPasswordController,
  ) => Obx(() {
    final isFourDigit = forgetPasswordController.isFourDigit.value;
    final otpLength = isFourDigit ? 4 : 6;

    return Column(
      children: [
        // 🔹 The actual OTP input field
        PinCodeTextField(
          key: ValueKey(otpLength), // ✅ this resets the field safely on toggle
          appContext: parentContext,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(otpLength),
          ],
          keyboardType: TextInputType.number,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          length: otpLength,
          obscureText: false,
          animationType: AnimationType.fade,
          cursorColor: AppColors.green,
          textStyle: TextStyle(fontSize: 20, color: AppColors.black),
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(8),
            fieldHeight: 50,
            fieldWidth: 40,
            activeFillColor: AppColors.green.withValues(alpha: 0.2),
            inactiveFillColor: AppColors.white,
            selectedFillColor: AppColors.green.withValues(alpha: 0.1),
            activeColor: AppColors.green,
            inactiveColor: AppColors.grey,
            selectedColor: AppColors.green,
          ),
          animationDuration: Duration(milliseconds: 300),
          enableActiveFill: true,
          onCompleted: (otpValue) {
            forgetPasswordController.otpCtrl.text = otpValue;
            forgetPasswordController.verifyOtp();
          },
          onChanged:
              (otpValue) => forgetPasswordController.otpCtrl.text = otpValue,
        ),

        // const SizedBox(height: 16),

        // // 🔹 The toggle chip
        // Align(
        //   alignment: Alignment.center,
        //   child: FilterChip(
        //     showCheckmark: false,
        //     padding: const EdgeInsets.symmetric(horizontal: 5),
        //     avatar: Icon(
        //       isFourDigit ? Icons.toggle_on : Icons.toggle_off,
        //       color: isFourDigit ? Colors.white : AppColors.green,
        //       size: 25,
        //     ),
        //     label: Text(
        //       isFourDigit ? "Switch to 6-digit" : "Switch to 4-digit",
        //       style: TextStyle(
        //         color: isFourDigit ? Colors.white : AppColors.green,
        //         fontWeight: FontWeight.w500,
        //       ),
        //     ),
        //     selected: isFourDigit,
        //     onSelected:
        //         (value) =>
        //             forgetPasswordController.isFourDigit.value = !isFourDigit,
        //     selectedColor: AppColors.green,
        //     checkmarkColor: Colors.white,
        //     backgroundColor: AppColors.green.withValues(alpha: 0.1),
        //   ),
        // ),
      ],
    );
  });

  // 🔹 New Password Field
  Widget _buildNewPasswordField({
    required ForgetPasswordController forgetPasswordController,
  }) {
    return TextFormField(
      controller: forgetPasswordController.passwordCtrl,
      keyboardType: TextInputType.visiblePassword,
      obscureText: forgetPasswordController.newPasswordObscureText.value,
      decoration: InputDecoration(
        counterText: "",
        hintText: 'New Password',
        hintStyle: TextStyle(color: AppColors.grey.withValues(alpha: .5)),
        prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
        prefixIcon: Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, color: AppColors.black, size: 20),

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
        suffixIcon: GestureDetector(
          onTap:
              () =>
                  forgetPasswordController.newPasswordObscureText.value =
                      !forgetPasswordController.newPasswordObscureText.value,
          child: Icon(
            forgetPasswordController.newPasswordObscureText.value
                ? Icons.visibility_off
                : Icons.visibility,
          ),
        ),
      ),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Password is required';
        }

        if (value.length < 8) {
          return 'Password must be at least 8 characters';
        }

        if (!RegExp(r'[A-Z]').hasMatch(value)) {
          return 'Password must include at least one uppercase letter';
        }

        if (!RegExp(r'[a-z]').hasMatch(value)) {
          return 'Password must include at least one lowercase letter';
        }

        if (!RegExp(r'[0-9]').hasMatch(value)) {
          return 'Password must include at least one number';
        }

        if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
          return 'Password must include at least one special character';
        }

        return null; // ✅ Valid
      },
    );
  }

  // 🔹 Confirm Password Field
  Widget _buildConfirmPasswordField({
    required ForgetPasswordController forgetPasswordController,
  }) {
    return TextFormField(
      controller: forgetPasswordController.confirmPasswordCtrl,
      keyboardType: TextInputType.visiblePassword,
      obscureText: forgetPasswordController.confirmPasswordObscureText.value,
      decoration: InputDecoration(
        counterText: "",
        hintText: 'Confirm Password',
        hintStyle: TextStyle(color: AppColors.grey.withValues(alpha: .5)),
        prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
        prefixIcon: Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, color: AppColors.black, size: 20),

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
        suffixIcon: GestureDetector(
          onTap:
              () =>
                  forgetPasswordController.confirmPasswordObscureText.value =
                      !forgetPasswordController
                          .confirmPasswordObscureText
                          .value,
          child: Icon(
            forgetPasswordController.confirmPasswordObscureText.value
                ? Icons.visibility_off
                : Icons.visibility,
          ),
        ),
      ),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Password is required';
        }

        if (value.length < 8) {
          return 'Password must be at least 8 characters';
        }

        if (!RegExp(r'[A-Z]').hasMatch(value)) {
          return 'Password must include at least one uppercase letter';
        }

        if (!RegExp(r'[a-z]').hasMatch(value)) {
          return 'Password must include at least one lowercase letter';
        }

        if (!RegExp(r'[0-9]').hasMatch(value)) {
          return 'Password must include at least one number';
        }

        if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
          return 'Password must include at least one special character';
        }

        return null; // ✅ Valid
      },
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    required RxBool isLoading,
    double width = double.infinity,
  }) {
    return ButtonWidget(
      text: label,
      width: width,
      isLoading: isLoading,
      onTap: onPressed,
    );
  }
}
