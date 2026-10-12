import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_membership_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_type_picker.dart';
import 'package:otobix/Widgets/button_widget.dart';
import 'package:otobix/Widgets/toast_widget.dart';

/// The dealer type, asked once of dealers enrolled before registration asked
/// it: New Car Dealer, Used Car Dealer or Broker. Dealer Home shows this in
/// place of its content until they choose; a membership feature opened another
/// way ([pushed]) comes here first.
class DealerTypeChoicePage extends StatefulWidget {
  const DealerTypeChoicePage({super.key, this.pushed = false});

  final bool pushed;

  @override
  State<DealerTypeChoicePage> createState() => _DealerTypeChoicePageState();
}

class _DealerTypeChoicePageState extends State<DealerTypeChoicePage> {
  final controller = DealerMembershipController.to;
  List<DealerRegisterAsModel> _options = DealerRegisterAsModel.fallback;
  String? _type;

  @override
  void initState() {
    super.initState();
    controller.loadRegisterAsOptions().then((options) {
      if (mounted && options.isNotEmpty) setState(() => _options = options);
    });
  }

  Future<void> _continue() async {
    final type = _type;
    if (type == null) {
      ToastWidget.show(
        context: context,
        title: 'Choose your dealer type',
        type: ToastType.warning,
      );
      return;
    }
    final saved = await controller.chooseDealerType(type);
    if (saved && widget.pushed && mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final onTrial = controller.membership.value?.plan?.isTrial ?? true;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            const Text(
              'Choose your dealer type',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'OtoBix now has a plan for each kind of dealer. Choose yours to continue.',
              style: TextStyle(fontSize: 13, color: AppColors.grey),
            ),
            const SizedBox(height: 16),
            DealerTypePicker(
              options: _options,
              selected: _type,
              onSelected: (type) => setState(() => _type = type),
            ),
            if (_type == 'Broker') ...[
              const SizedBox(height: 10),
              Text(
                onTrial
                    ? "Brokers sell their customers' cars, from Sell and Membership. "
                        'Broker Trial starts today and your Promo points end.'
                    : "Brokers sell their customers' cars, from Sell and Membership. "
                        'OtoBix will move you to the Broker plan; your current plan keeps working until then.',
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            ],
            const SizedBox(height: 20),
            ButtonWidget(
              text: 'Continue',
              isLoading: controller.isSubmitting,
              width: double.infinity,
              onTap: _continue,
            ),
          ],
        ),
      ),
    );
  }
}
