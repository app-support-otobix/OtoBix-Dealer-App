import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_services_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_rc_check_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/vehicle_spec_sheet.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';
import 'package:otobix/Widgets/button_widget.dart';

class RcChallanCheckPage extends StatefulWidget {
  const RcChallanCheckPage({super.key});

  @override
  State<RcChallanCheckPage> createState() => _RcChallanCheckPageState();
}

class _RcChallanCheckPageState extends State<RcChallanCheckPage> {
  final DealerServicesController controller = Get.put(
    DealerServicesController(),
  );
  final _regNoController = TextEditingController();

  @override
  void dispose() {
    _regNoController.dispose();
    Get.delete<DealerServicesController>();
    super.dispose();
  }

  void _check() {
    FocusScope.of(context).unfocus();
    controller.check(_regNoController.text);
  }

  Future<void> _requestMobile() async {
    final consented = await showDialog<bool>(
      context: context,
      builder: (_) => _MobileConsentDialog(cost: controller.mobileCost),
    );
    if (consented == true) controller.fetchOwnerMobile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(title: 'RC & Challan Check'),
      body: SafeArea(
        child: Obx(() {
          final r = controller.result.value;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _searchCard(),
              if (r != null) ...[
                const SizedBox(height: 10),
                Text(
                  '${r.pointsCharged} points used · balance ${r.availablePoints}',
                  style: const TextStyle(fontSize: 11, color: AppColors.grey),
                ),
                const SizedBox(height: 10),
                _rcDetailsCard(r.vehicle),
                const SizedBox(height: 12),
                _challanCard(r),
                const SizedBox(height: 12),
                _mobileCard(r),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _searchCard() {
    final cost = controller.checkCost;
    return DealerSectionCard(
      title: 'Registration Number',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _regNoController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                    LengthLimitingTextInputFormatter(13),
                  ],
                  onSubmitted: (_) => _check(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'e.g. WB02AB1234',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      letterSpacing: 0,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ButtonWidget(
                text: 'Check',
                isLoading: controller.isChecking,
                width: 90,
                height: 40,
                onTap: _check,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            controller.error.value.isNotEmpty
                ? controller.error.value
                : 'RC details and challans for this vehicle${cost > 0 ? ' · $cost points' : ''}. '
                    'Points are only used for lookups that succeed.',
            style: TextStyle(
              fontSize: 11,
              color:
                  controller.error.value.isNotEmpty
                      ? AppColors.red
                      : AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rcDetailsCard(DealerVehicleFactsModel v) {
    final active = v.rcStatus.toUpperCase() == 'ACTIVE';
    return _resultCard(
      icon: Icons.assignment_outlined,
      color: AppColors.blue,
      title: 'RC Details',
      trailing:
          v.rcStatus.isEmpty
              ? null
              : DealerStatusChip(
                label: v.rcStatus.toUpperCase(),
                color: active ? AppColors.green : AppColors.red,
                small: true,
              ),
      children: [
        Text(
          v.registrationNumber,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        VehicleSpecSheet(
          labelSize: 11,
          valueSize: 13,
          specs: [
            ('Make', v.make.isNotEmpty ? v.make : v.makerDescription),
            ('Model', v.model.isNotEmpty ? v.model : v.makerModel),
            ('Variant', v.variant),
            ('Fuel Type', v.fuelType),
            ('Mfg Year', v.mfgYear > 0 ? '${v.mfgYear}' : ''),
            ('Regn Date', v.registrationDate),
            ('Color', v.colour),
            ('Euro Norm', v.normsType),
            ('Registration Type', v.registrationType),
            ('RTO', v.rto),
            ('Own Srl No', v.ownerSerialNo > 0 ? '${v.ownerSerialNo}' : ''),
            ('Body Type', v.bodyType),
          ],
        ),
        _subheading('Validity & Finance'),
        VehicleSpecSheet(
          labelSize: 11,
          valueSize: 13,
          specs: [
            ('Registration Valid Till', v.fitnessUpto),
            ('Tax Valid Till', v.taxUpto),
            ('Insurance Valid Till', v.insuranceUpto),
            ('Insurance From', v.insuranceProvider),
            ('Hypothecation', v.financed ? 'Yes' : 'No'),
            ('Finance From', v.financier),
            ('PUCC Valid Till', v.pucUpto),
          ],
        ),
        _subheading('Compliance'),
        Row(
          children: [
            Expanded(
              child: _complianceTile('Blacklist Status', v.blacklistStatus),
            ),
            Expanded(child: _complianceTile('State NOC Status', v.nocStatus)),
          ],
        ),
        _subheading('Owner & Identifiers'),
        _fullWidthField('Owner Name', v.ownerMasked),
        _fullWidthField('Engine No', v.engineMasked),
        _fullWidthField('Chassis No', v.chassisMasked),
        const Text(
          'Owner personal data is withheld · identifiers are masked.',
          style: TextStyle(fontSize: 10, color: AppColors.grey),
        ),
      ],
    );
  }

  Widget _challanCard(DealerRcCheckModel r) {
    final challans = r.challans;
    return _resultCard(
      icon: Icons.receipt_long_outlined,
      color: AppColors.red,
      title: 'Challans',
      trailing:
          challans == null
              ? null
              : DealerStatusChip(
                label:
                    r.pendingChallans == 0
                        ? 'NO DUES'
                        : '${r.pendingChallans} PENDING',
                color: r.pendingChallans == 0 ? AppColors.green : AppColors.red,
                small: true,
              ),
      children: [
        if (challans == null)
          Text(
            r.challanError,
            style: const TextStyle(fontSize: 12, color: AppColors.grey),
          )
        else if (challans.isEmpty)
          const Text(
            'No challan records for this vehicle.',
            style: TextStyle(fontSize: 12, color: AppColors.grey),
          )
        else ...[
          if (r.pendingChallans > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Pending dues: ${GlobalFunctions.formatRupees(r.pendingTotal)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.red,
                ),
              ),
            ),
          for (final c in challans) _challanRow(c),
        ],
      ],
    );
  }

  Widget _mobileCard(DealerRcCheckModel r) {
    final mobile = controller.ownerMobile.value;
    final consentAt = controller.mobileConsentAt.value;
    return _resultCard(
      icon: Icons.phone_iphone,
      color: AppColors.green,
      title: 'Owner Mobile (RC to Mobile)',
      children: [
        if (mobile.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.verified_user, size: 18, color: AppColors.green),
              const SizedBox(width: 8),
              Text(
                mobile,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Owner consent recorded ${DateFormat('d MMM yyyy, h:mm a').format((consentAt ?? DateTime.now()).toLocal())}',
            style: const TextStyle(fontSize: 11, color: AppColors.grey),
          ),
        ] else ...[
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 18, color: AppColors.grey),
              const SizedBox(width: 8),
              Text(
                '+91 ••••• •••••',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.grey.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            controller.mobileError.value.isNotEmpty
                ? controller.mobileError.value
                : r.rcToMobileAvailable
                ? "The owner's mobile number is personal data - it is shown only after you confirm the owner's consent."
                : 'Owner mobile lookup is not available yet.',
            style: TextStyle(
              fontSize: 11,
              color:
                  controller.mobileError.value.isNotEmpty
                      ? AppColors.red
                      : AppColors.grey,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  r.rcToMobileAvailable && !controller.isFetchingMobile.value
                      ? _requestMobile
                      : null,
              icon:
                  controller.isFetchingMobile.value
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.how_to_reg_outlined, size: 18),
              label: Text(
                'Get Mobile Number${controller.mobileCost > 0 ? ' · ${controller.mobileCost} points' : ''}',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _resultCard({
    required IconData icon,
    required Color color,
    required String title,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return DealerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _subheading(String text) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: AppColors.grey,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _complianceTile(String label, String value) {
    final ok = value.toLowerCase().startsWith('not');
    final color = ok ? AppColors.green : AppColors.red;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.grey),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                ok ? Icons.check_circle : Icons.error,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fullWidthField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.grey),
          ),
          Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _challanRow(DealerChallanModel c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.offence.isEmpty ? 'Challan' : c.offence,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                GlobalFunctions.formatRupees(c.amount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [c.date, c.place].where((s) => s.isNotEmpty).join(' · '),
            style: const TextStyle(fontSize: 11, color: AppColors.grey),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Challan No. ${c.challanNumber}',
                  style: const TextStyle(fontSize: 11, color: AppColors.grey),
                ),
              ),
              DealerStatusChip(
                label: c.status.toUpperCase(),
                color: c.isPending ? AppColors.red : AppColors.green,
                small: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileConsentDialog extends StatefulWidget {
  final int cost;
  const _MobileConsentDialog({required this.cost});

  @override
  State<_MobileConsentDialog> createState() => _MobileConsentDialogState();
}

class _MobileConsentDialogState extends State<_MobileConsentDialog> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Row(
        children: [
          Icon(Icons.privacy_tip_outlined, color: AppColors.green),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Owner Consent Required',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "The mobile number linked to this RC belongs to the vehicle owner. It can only be fetched with the owner's consent, "
            'and used for this vehicle transaction.${widget.cost > 0 ? ' This uses ${widget.cost} points.' : ''}',
            style: const TextStyle(fontSize: 12, color: AppColors.grey),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            value: _agreed,
            onChanged: (v) => setState(() => _agreed = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.green,
            dense: true,
            title: const Text(
              'I confirm the vehicle owner has consented to OtoBix fetching and showing me their mobile number for this transaction.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _agreed ? () => Navigator.pop(context, true) : null,
          child: const Text('Agree & Fetch'),
        ),
      ],
    );
  }
}
