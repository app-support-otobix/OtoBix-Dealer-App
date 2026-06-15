import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:get/get.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/button_widget.dart';

class CongratulationsDialogWidget extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onButtonTap;
  final IconData? icon;
  final Color iconColor;
  final double iconSize;
  final double titleSize;

  const CongratulationsDialogWidget({
    super.key,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onButtonTap,
    this.icon,
    this.iconColor = AppColors.green,
    this.iconSize = 20,
    this.titleSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final ConfettiController confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // Start confetti when widget is built
    Future.delayed(Duration.zero, () => confettiController.play());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null)
                      Icon(icon!, color: iconColor, size: iconSize),
                    SizedBox(width: 5),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ButtonWidget(
                  onTap: onButtonTap,
                  text: buttonText,
                  isLoading: false.obs,
                  height: 30,
                  width: 150,
                  backgroundColor: AppColors.green,
                  textColor: AppColors.white,
                  fontSize: 12,
                ),
              ],
            ),
          ),
          Positioned(
            top: -10,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 5,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
