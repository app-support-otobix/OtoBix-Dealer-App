import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_connections_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_connection_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_membership_navigator.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';
import 'package:otobix/Widgets/button_widget.dart';

class RequestConnectionPage extends StatefulWidget {
  final String negotiationId;
  final String connectionId;
  final String carId;
  final String buyerDealerCode;

  const RequestConnectionPage({
    super.key,
    this.negotiationId = '',
    this.connectionId = '',
    this.carId = '',
    this.buyerDealerCode = '',
  });

  @override
  State<RequestConnectionPage> createState() => _RequestConnectionPageState();
}

class _RequestConnectionPageState extends State<RequestConnectionPage> {
  final controller = DealerConnectionsController.to;
  final precheck = Rxn<DealerConnectionPrecheckModel>();
  final connection = Rxn<DealerConnectionModel>();
  final isLoading = true.obs;

  Map<String, String> get _target =>
      widget.negotiationId.isNotEmpty
          ? {'negotiationId': widget.negotiationId}
          : {'carId': widget.carId, 'buyerDealerCode': widget.buyerDealerCode};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    if (widget.connectionId.isNotEmpty) {
      connection.value = await controller.get(widget.connectionId);
    } else {
      precheck.value = await controller.precheck(_target);
    }
    isLoading.value = false;
  }

  Future<void> _request() async {
    final created = await controller.request(_target);
    if (created != null) connection.value = created;
  }

  Future<void> _respond(bool accept) async {
    final points = connection.value?.pointsPerSide ?? 0;
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          accept ? 'Accept and connect?' : 'Decline this request?',
          style: const TextStyle(fontSize: 16),
        ),
        content: Text(
          accept
              ? '$points points are charged from your balance, identities are revealed to both of you and the Deal Room opens.'
              : 'The other dealer’s reserved points are released. Nothing is charged to you.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              accept ? 'Accept' : 'Decline',
              style: TextStyle(color: accept ? AppColors.green : AppColors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final updated = await controller.respond(
      connection.value!.id,
      accept: accept,
    );
    if (updated == null) return;
    connection.value = updated;
    if (accept && updated.dealRoomId.isNotEmpty) {
      DealerMembershipNavigator.openDealRoom(updated.dealRoomId, replace: true);
    }
  }

  Future<void> _withdraw() async {
    final updated = await controller.cancel(connection.value!.id);
    if (updated != null) connection.value = updated;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(title: 'Request Connection'),
      body: SafeArea(
        child: Obx(() {
          final c = connection.value;
          final p = precheck.value;
          if (c == null && p == null) {
            return DealerStateView(
              isLoading: isLoading.value,
              error: isLoading.value ? '' : 'This request could not be loaded.',
              isEmpty: true,
              emptyMessage: '',
              onRetry: _load,
              child: const SizedBox(),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: c != null ? _connectionState(c) : _precheck(p!),
          );
        }),
      ),
    );
  }

  List<Widget> _precheck(DealerConnectionPrecheckModel p) {
    return [
      DealerSectionCard(
        title: 'Pre-checks',
        child: Column(
          children: [
            _checkRow(
              p.membershipActive,
              p.membershipActive
                  ? 'Membership active · ${p.planName}'
                  : 'Membership not active',
            ),
            _checkRow(
              p.availablePoints >= p.cost,
              'Points available: ${p.availablePoints}',
            ),
            _checkRow(
              p.listingActive,
              p.listingActive
                  ? 'Listing still active'
                  : 'Listing no longer active',
            ),
            _checkRow(
              p.pendingByMe < p.maxPending,
              'Your pending requests: ${p.pendingByMe} of ${p.maxPending}',
            ),
            _checkRow(
              p.pendingOnListing < p.maxPendingPerListing,
              'Pending on this listing: ${p.pendingOnListing} of ${p.maxPendingPerListing}',
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Text(
        '${p.cost} points will be reserved now. Charged only if the other dealer accepts within ${p.expiryHours} hours. '
        'Declined or expired requests release the reservation in full.',
        style: const TextStyle(color: AppColors.grey, fontSize: 12),
      ),
      if (!p.canRequest) ...[
        const SizedBox(height: 10),
        Text(
          p.reason,
          style: const TextStyle(
            color: AppColors.red,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
      const SizedBox(height: 20),
      if (p.canRequest)
        ButtonWidget(
          text: 'Confirm · Reserve ${p.cost} points',
          isLoading: controller.isActing,
          width: double.infinity,
          onTap: _request,
        )
      else if (!p.membershipActive || p.availablePoints < p.cost)
        OutlinedButton(
          onPressed: DealerMembershipNavigator.openMembership,
          child: const Text('View Membership'),
        ),
    ];
  }

  List<Widget> _connectionState(DealerConnectionModel c) {
    final counterpart =
        c.counterpart.isRevealed
            ? '${c.counterpart.name} · ${c.counterpart.phone}'
            : '${c.counterpart.dealerType} · ${c.counterpart.city} · anonymous';
    final color =
        {'PENDING': AppColors.deepOrange, 'ACCEPTED': AppColors.green}[c
            .status] ??
        AppColors.grey;
    final canRespond = c.isPending && !c.initiatedByMe;
    return [
      DealerSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DealerStatusChip(label: c.status, color: color),
                const Spacer(),
                if (c.isPending)
                  Text(
                    GlobalFunctions.timeLeft(c.expiresAt),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepOrange,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              c.carTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '${c.initiatedByMe ? 'To' : 'From'}: $counterpart',
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
            ),
            Text(
              '${c.connectionCode} · ${c.pointsPerSide} points per side',
              style: const TextStyle(color: AppColors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Text(
        _explain(c),
        style: const TextStyle(color: AppColors.grey, fontSize: 12),
      ),
      const SizedBox(height: 20),
      if (canRespond) ...[
        ButtonWidget(
          text: 'Accept · ${c.pointsPerSide} points',
          isLoading: controller.isActing,
          width: double.infinity,
          onTap: () => _respond(true),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => _respond(false),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.red,
            minimumSize: const Size(double.infinity, 40),
          ),
          child: const Text('Decline'),
        ),
      ] else if (c.isPending)
        OutlinedButton(
          onPressed: controller.isActing.value ? null : _withdraw,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.red,
            minimumSize: const Size(double.infinity, 40),
          ),
          child: const Text('Withdraw request'),
        )
      else if (c.status == 'ACCEPTED' && c.dealRoomId.isNotEmpty)
        ButtonWidget(
          text: 'Open Deal Room',
          isLoading: false.obs,
          width: double.infinity,
          onTap: () => DealerMembershipNavigator.openDealRoom(c.dealRoomId),
        ),
      if (c.negotiationId.isNotEmpty) ...[
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => DealerMembershipNavigator.openChat(c.negotiationId),
          child: const Text('Open the conversation'),
        ),
      ],
    ];
  }

  String _explain(DealerConnectionModel c) {
    switch (c.status) {
      case 'PENDING':
        return c.initiatedByMe
            ? '${c.pointsPerSide} points reserved · waiting for the other dealer to accept. Withdraw any time to release them.'
            : 'Accepting charges ${c.pointsPerSide} points to each side, reveals both identities and opens the Deal Room.';
      case 'ACCEPTED':
        return 'Connected · both sides charged ${c.pointsPerSide} points · identities revealed.';
      case 'DECLINED':
        return 'Declined · the reservation was released in full.';
      case 'EXPIRED':
        return 'Expired without a reply · no points were charged.';
      default:
        return 'Withdrawn · the reservation was released in full.';
    }
  }

  Widget _checkRow(bool ok, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            color: ok ? AppColors.green : AppColors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
