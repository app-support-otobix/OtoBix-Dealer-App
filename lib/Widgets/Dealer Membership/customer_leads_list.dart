import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_leads_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_paged_list.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_lead_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/vehicle_spec_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

(String, Color, String) leadStatusDisplay(DealerLeadModel l) {
  final d = l.statusDetails;
  final at = DateTime.tryParse('${d['visitAt'] ?? ''}')?.toLocal();
  final followUp = DateTime.tryParse('${d['followUpDate'] ?? ''}')?.toLocal();
  switch (l.status) {
    case 'SCHEDULED_SHOWROOM_VISIT':
      final s = '${d['visitStatus'] ?? ''}';
      return (
        'VISIT ${s.toUpperCase()}',
        s == 'Visited'
            ? AppColors.green
            : s == 'Scheduled'
            ? AppColors.blue
            : s == 'Deferred'
            ? AppColors.deepOrange
            : AppColors.red,
        at == null
            ? ''
            : 'Showroom visit · ${DateFormat('d MMM yyyy, h:mm a').format(at)}',
      );
    case 'SHARED_ON_WHATSAPP':
      return (
        'WHATSAPP SHARED',
        AppColors.blue,
        followUp == null
            ? ''
            : 'Follow up on ${DateFormat('d MMM yyyy').format(followUp)}',
      );
    case 'INVENTORY_SOLD':
      return d['soldAction'] == 'PITCHED_ANOTHER'
          ? (
            'PITCHED ANOTHER',
            AppColors.blue,
            'Pitched: ${d['pitchedCar'] ?? ''}',
          )
          : (
            'CALL BACK',
            AppColors.deepOrange,
            'Call back when a similar vehicle is available',
          );
    case 'DIFFERENT_REQUIREMENT':
      return (
        'DIFFERENT NEED',
        AppColors.blue,
        'Wants: ${d['requirement'] ?? ''}',
      );
    case 'BOOKED':
      final stage = '${d['bookingStage'] ?? ''}';
      return (
        'BOOKED · ${stage.toUpperCase()}',
        stage == 'Cancelled' ? AppColors.red : AppColors.green,
        '',
      );
    case 'BOUGHT_ELSEWHERE':
      return ('BOUGHT ELSEWHERE', AppColors.grey, '');
    case 'DROPPED_IDEA':
      return ('DROPPED', AppColors.grey, '');
    case 'WINDOW_SHOPPING':
      return ('WINDOW SHOPPING', AppColors.grey, '');
    case 'NOT_INTERESTED':
      return ('NOT INTERESTED', AppColors.red, '');
    default:
      return ('NEW', AppColors.blue, l.note);
  }
}

class CustomerLeadsList extends StatelessWidget {
  final DealerPagedList<DealerLeadModel> leads;
  const CustomerLeadsList({super.key, required this.leads});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => RefreshIndicator(
        color: AppColors.green,
        onRefresh: leads.refresh,
        child: DealerStateView(
          isLoading: leads.isLoading.value,
          error: leads.error.value,
          isEmpty: leads.items.isEmpty,
          emptyIcon: Icons.people_outline,
          emptyMessage:
              'No customer leads yet. Enquiries from the OtoBix app show up here; add walk-ins with +.',
          onRetry: leads.refresh,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
                leads.load();
              }
              return false;
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: leads.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder:
                  (context, i) => _leadCard(context, leads.items[i], i),
            ),
          ),
        ),
      ),
    );
  }

  Widget _leadCard(BuildContext context, DealerLeadModel lead, int index) {
    final (label, color, detail) = leadStatusDisplay(lead);
    return DealerSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.green.withValues(alpha: 0.15),
                child: Text(
                  lead.customerName.isEmpty
                      ? '?'
                      : lead.customerName[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Source: ${lead.sourceLabel}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              DealerStatusChip(label: label, color: color),
            ],
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                detail,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _field('Contact No', lead.contactNo),
                    _field('Make', lead.make),
                    _field('Model', lead.model),
                    _field('Variant', lead.variant),
                    _field('Transmission', lead.transmission),
                    _field('Year', lead.year),
                  ],
                ),
              ),
              if (lead.carImage.isNotEmpty) ...[
                const SizedBox(width: 10),
                CarThumbnail(imageUrl: lead.carImage, size: 96),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (lead.contactNo.isNotEmpty) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        () =>
                            launchUrl(Uri(scheme: 'tel', path: lead.contactNo)),
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: AppColors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final result =
                        await showDialog<(String, Map<String, dynamic>)>(
                          context: context,
                          builder:
                              (_) => _UpdateLeadStatusDialog(
                                leadName: lead.customerName,
                              ),
                        );
                    if (result == null) return;
                    final updated = await DealerLeadsController.to.updateStatus(
                      lead.id,
                      result.$1,
                      result.$2,
                    );
                    if (updated != null && index < leads.items.length) {
                      leads.items[index] = updated;
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.deepOrange,
                    side: const BorderSide(color: AppColors.deepOrange),
                  ),
                  child: const Text('Update Status'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Outcome {
  showroomVisit('SCHEDULED_SHOWROOM_VISIT', 'A. Scheduled showroom visit'),
  sharedOnWhatsApp('SHARED_ON_WHATSAPP', 'B. Shared details on WhatsApp'),
  inventorySold('INVENTORY_SOLD', 'C. Inventory already sold'),
  boughtElsewhere('BOUGHT_ELSEWHERE', 'D. Bought from somewhere else'),
  droppedIdea('DROPPED_IDEA', 'E. Dropped the idea'),
  windowShopping('WINDOW_SHOPPING', 'F. Window shopping'),
  differentRequirement(
    'DIFFERENT_REQUIREMENT',
    'G. Has a different requirement',
  ),
  notInterested('NOT_INTERESTED', 'H. Not interested'),
  booked('BOOKED', 'I. Booked');

  final String code;
  final String label;
  const _Outcome(this.code, this.label);
}

class _UpdateLeadStatusDialog extends StatefulWidget {
  final String leadName;
  const _UpdateLeadStatusDialog({required this.leadName});

  @override
  State<_UpdateLeadStatusDialog> createState() =>
      _UpdateLeadStatusDialogState();
}

class _UpdateLeadStatusDialogState extends State<_UpdateLeadStatusDialog> {
  static final _dateFormat = DateFormat('d MMM yyyy');
  static final _dateTimeFormat = DateFormat('d MMM yyyy, h:mm a');

  _Outcome? _outcome;
  String? _error;
  DateTime? _visitAt;
  String _visitStatus = 'Scheduled';
  DateTime? _followUpDate;
  String _soldAction = 'PITCHED_ANOTHER';
  final _pitched = TextEditingController();
  final _requirement = TextEditingController();
  String _bookingStage = 'Token';

  @override
  void dispose() {
    _pitched.dispose();
    _requirement.dispose();
    super.dispose();
  }

  Future<void> _pickVisit() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _visitAt ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 180)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime:
          _visitAt != null
              ? TimeOfDay.fromDateTime(_visitAt!)
              : const TimeOfDay(hour: 11, minute: 0),
    );
    if (time == null) return;
    setState(
      () =>
          _visitAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          ),
    );
  }

  Future<void> _pickFollowUp() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? now.add(const Duration(days: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (date != null) setState(() => _followUpDate = date);
  }

  void _save() {
    final o = _outcome;
    String? error;
    Map<String, dynamic> details = {};
    switch (o) {
      case null:
        error = 'Select a status.';
      case _Outcome.showroomVisit:
        if (_visitAt == null) error = 'Pick the visit date and time.';
        details = {
          'visitAt': _visitAt?.toUtc().toIso8601String(),
          'visitStatus': _visitStatus,
        };
      case _Outcome.sharedOnWhatsApp:
        if (_followUpDate == null) error = 'Pick a follow-up date.';
        details = {'followUpDate': _followUpDate?.toUtc().toIso8601String()};
      case _Outcome.inventorySold:
        if (_soldAction == 'PITCHED_ANOTHER' && _pitched.text.trim().isEmpty) {
          error = 'Enter which car you pitched.';
        }
        details = {
          'soldAction': _soldAction,
          'pitchedCar': _pitched.text.trim(),
        };
      case _Outcome.differentRequirement:
        if (_requirement.text.trim().isEmpty) {
          error = 'Enter what the customer is looking for.';
        }
        details = {'requirement': _requirement.text.trim()};
      case _Outcome.booked:
        details = {'bookingStage': _bookingStage};
      default:
        details = {};
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop((o!.code, details));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        'Update Status · ${widget.leadName}',
        style: const TextStyle(fontSize: 16),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<_Outcome>(
                initialValue: _outcome,
                isExpanded: true,
                hint: const Text(
                  'Select status',
                  style: TextStyle(fontSize: 13),
                ),
                style: const TextStyle(fontSize: 13, color: AppColors.black),
                decoration: _decoration(),
                items: [
                  for (final o in _Outcome.values)
                    DropdownMenuItem(value: o, child: Text(o.label)),
                ],
                onChanged:
                    (o) => setState(() {
                      _outcome = o;
                      _error = null;
                    }),
              ),
              ..._followUp(),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 12, color: AppColors.red),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  List<Widget> _followUp() {
    switch (_outcome) {
      case _Outcome.showroomVisit:
        return [
          _question('Visit date & time'),
          _picker(
            Icons.event,
            _visitAt == null
                ? 'Pick date & time'
                : _dateTimeFormat.format(_visitAt!),
            _pickVisit,
          ),
          _question('Status'),
          _choice(
            ['Scheduled', 'Visited', 'Deferred', 'Cancelled'],
            _visitStatus,
            (v) => setState(() => _visitStatus = v),
          ),
          if (const ['Scheduled', 'Deferred'].contains(_visitStatus))
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                "You'll get a notification at the visit time.",
                style: TextStyle(fontSize: 11, color: AppColors.grey),
              ),
            ),
        ];
      case _Outcome.sharedOnWhatsApp:
        return [
          _question('Follow-up date'),
          _picker(
            Icons.event,
            _followUpDate == null
                ? 'Pick follow-up date'
                : _dateFormat.format(_followUpDate!),
            _pickFollowUp,
          ),
        ];
      case _Outcome.inventorySold:
        return [
          _question('What next?'),
          DropdownButtonFormField<String>(
            initialValue: _soldAction,
            isExpanded: true,
            style: const TextStyle(fontSize: 13, color: AppColors.black),
            decoration: _decoration(),
            items: const [
              DropdownMenuItem(
                value: 'PITCHED_ANOTHER',
                child: Text('Pitched another'),
              ),
              DropdownMenuItem(
                value: 'CALL_BACK',
                child: Text('Call back when similar vehicle is available'),
              ),
            ],
            onChanged: (v) => setState(() => _soldAction = v ?? _soldAction),
          ),
          const SizedBox(height: 10),
          if (_soldAction == 'PITCHED_ANOTHER')
            _text(_pitched, 'Which car? e.g. 2020 Creta SX, ₹9.10L'),
        ];
      case _Outcome.differentRequirement:
        return [
          _question('What is the customer looking for?'),
          _text(
            _requirement,
            'e.g. Automatic SUV under ₹10L, 2019 or newer',
            maxLines: 2,
          ),
        ];
      case _Outcome.booked:
        return [
          _question('Booking stage'),
          _choice(
            ['Token', 'Sold', 'Delivered', 'Cancelled'],
            _bookingStage,
            (v) => setState(() => _bookingStage = v),
          ),
        ];
      default:
        return const [];
    }
  }

  Widget _question(String text) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    ),
  );

  InputDecoration _decoration({String? hint}) => InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 12),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  );

  Widget _picker(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: _decoration(),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  Widget _choice(
    List<String> options,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      style: const TextStyle(fontSize: 13, color: AppColors.black),
      decoration: _decoration(),
      items: [
        for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _text(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: _decoration(hint: hint),
    );
  }
}

Future<DealerLeadModel?> showAddLeadDialog(
  BuildContext context, {
  String carId = '',
}) async {
  final body = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _AddLeadDialog(carId: carId),
  );
  return body == null ? null : DealerLeadsController.to.addLead(body);
}

class _AddLeadDialog extends StatefulWidget {
  final String carId;
  const _AddLeadDialog({required this.carId});

  @override
  State<_AddLeadDialog> createState() => _AddLeadDialogState();
}

class _AddLeadDialogState extends State<_AddLeadDialog> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final vehicle = TextEditingController();
  final note = TextEditingController();
  String? error;

  @override
  void dispose() {
    for (final c in [name, phone, vehicle, note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _add() {
    final digits = phone.text.replaceAll(RegExp(r'\D'), '');
    final mobile =
        digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    final problem =
        name.text.trim().isEmpty
            ? "Enter the customer's name."
            : !RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile)
            ? "Enter the customer's 10 digit mobile number."
            : null;
    if (problem != null) {
      setState(() => error = problem);
      return;
    }
    final words = vehicle.text.trim().split(RegExp(r'\s+'));
    Navigator.pop(context, {
      'customerName': name.text.trim(),
      'contactNo': mobile,
      if (widget.carId.isNotEmpty) 'carId': widget.carId,
      if (widget.carId.isEmpty && vehicle.text.trim().isNotEmpty) ...{
        'make': words.first,
        'model': words.skip(1).join(' '),
      },
      'note': note.text.trim(),
      'source': 'OTHER',
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Lead', style: TextStyle(fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Customer name'),
            ),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile number'),
            ),
            if (widget.carId.isEmpty)
              TextField(
                controller: vehicle,
                decoration: const InputDecoration(
                  labelText: 'Car of interest (make model)',
                ),
              ),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  error!,
                  style: const TextStyle(color: AppColors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _add, child: const Text('Add')),
      ],
    );
  }
}
