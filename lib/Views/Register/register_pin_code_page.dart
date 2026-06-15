import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/register_pin_code_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_images.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class RegisterPinCodePage extends StatelessWidget {
  final String phoneNumber;
  final String userRole;
  final String requestId;

  RegisterPinCodePage({
    super.key,
    required this.phoneNumber,
    required this.userRole,
    required this.requestId,
  });

  final RegisterPinCodeController pinCodeFieldsController = Get.put(
    RegisterPinCodeController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Verify Phone'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              _buildAppLogo(),
              SizedBox(height: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildOtpMessageText(),
                  SizedBox(height: 30),
                  _buildPinCodeTextField(context, requestId),
                  SizedBox(height: 20),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     pinCodeFieldsController.verifyOtp(
                  //       phoneNumber: phoneNumber,
                  //       otp: value,
                  //     );
                  //   },
                  //   style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  //   child: Text("Verify", style: TextStyle(color: Colors.white)),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // App Logo
  Widget _buildAppLogo() =>
      Image.asset(AppImages.otobixLogo, height: 150, width: 150);

  Widget _buildOtpMessageText() => Column(
    children: [
      Text(
        "Enter the OTP sent to",
        style: TextStyle(fontSize: 16, color: AppColors.black),
      ),

      SizedBox(height: 8),
      Text(
        '(+91) - $phoneNumber',
        style: TextStyle(
          fontSize: 18,
          color: AppColors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _buildPinCodeTextField(
    BuildContext parentContext,
    String requestId,
  ) => Obx(() {
    final isFourDigit = pinCodeFieldsController.isFourDigit.value;
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
            // pinCodeFieldsController.dummyVerifyOtp(
            //   phoneNumber: phoneNumber,
            //   otp: otpValue,
            //   userType: userRole,
            // );

            pinCodeFieldsController.verifyOtp(
              requestId: requestId,
              otp: otpValue,
              phoneNumber: phoneNumber,
            );
          },
          onChanged: (otpValue) {},
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
        //             pinCodeFieldsController.isFourDigit.value = !isFourDigit,
        //     selectedColor: AppColors.green,
        //     checkmarkColor: Colors.white,
        //     backgroundColor: AppColors.green.withValues(alpha: 0.1),
        //   ),
        // ),
      ],
    );
  });
}
