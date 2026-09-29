import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_chat_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_connections_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_deal_room_model.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_negotiation_model.dart';
import 'package:otobix/Network/socket_service.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Utils/socket_events.dart';
import 'package:otobix/Views/Dealer%20Membership/deal_room_exceptions_page.dart';
import 'package:otobix/Widgets/Dealer%20Membership/chat_message_bubble.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';
import 'package:otobix/Widgets/button_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class DealRoomPage extends StatefulWidget {
  final String dealRoomId;
  const DealRoomPage({super.key, required this.dealRoomId});

  @override
  State<DealRoomPage> createState() => _DealRoomPageState();
}

class _DealRoomPageState extends State<DealRoomPage> {
  final controller = DealerConnectionsController.to;
  final room = Rxn<DealerDealRoomModel>();
  final chat = Rxn<DealerChatController>();
  final isLoading = true.obs;
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    SocketService.instance.on(SocketEvents.dealerDealRoomUpdated, _onRoomEvent);
    _load();
  }

  @override
  void dispose() {
    SocketService.instance.off(
      SocketEvents.dealerDealRoomUpdated,
      _onRoomEvent,
    );
    final negotiationId = room.value?.negotiationId;
    if (negotiationId != null) {
      Get.delete<DealerChatController>(tag: 'room-$negotiationId');
    }
    _input.dispose();
    super.dispose();
  }

  void _onRoomEvent(dynamic data) {
    if (data is Map && data['dealRoomId'] == widget.dealRoomId) _reloadRoom();
  }

  Future<void> _load() async {
    isLoading.value = true;
    await _reloadRoom();
    final r = room.value;
    if (r != null && chat.value == null) {
      chat.value = Get.put(
        DealerChatController(r.negotiationId),
        tag: 'room-${r.negotiationId}',
      );
    }
    isLoading.value = false;
  }

  Future<void> _reloadRoom() async {
    final r = await controller.getDealRoom(widget.dealRoomId);
    if (r != null) room.value = r;
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    chat.value?.send(text);
    _input.clear();
  }

  Future<void> _call(String phone) async {
    if (phone.isEmpty) return;
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _moveTo(DealerDealRoomModel r, String status) async {
    var amount = 0;
    if ((status == 'AGREED' || status == 'COMPLETED') && r.agreedAmount <= 0) {
      final entered = await showDealerOfferDialog(
        context,
        title: 'Agreed price',
        suggested: r.askingPrice,
      );
      if (entered == null) return;
      amount = entered;
    }
    if (status == 'COMPLETED') {
      final price = GlobalFunctions.formatRupees(
        amount > 0 ? amount : r.agreedAmount,
      );
      final ok = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Mark Deal Complete?'),
          content: Text(
            'Confirm the ${r.carTitle} deal with ${r.counterpart.name} is done at $price - payment received and the car handed over. '
            'The listing closes and cannot be reopened.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text(
                'Mark Complete',
                style: TextStyle(color: AppColors.green),
              ),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    final updated = await controller.updateDealStatus(
      r.id,
      status: status,
      agreedAmount: amount,
    );
    if (updated != null) room.value = updated;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final r = room.value;
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBarWidget(
          title: r == null ? 'Deal Room' : 'Deal Room — ${r.carTitle}',
          actions: [
            if (r != null)
              IconButton(
                tooltip: 'Deal status, cancel or dispute',
                icon: const Icon(
                  Icons.report_problem_outlined,
                  color: AppColors.red,
                ),
                onPressed: () async {
                  final updated = await Get.to<DealerDealRoomModel>(
                    () => DealRoomExceptionsPage(room: r),
                  );
                  if (updated != null) room.value = updated;
                },
              ),
          ],
        ),
        body: SafeArea(
          child:
              r == null
                  ? DealerStateView(
                    isLoading: isLoading.value,
                    error:
                        isLoading.value
                            ? ''
                            : 'This Deal Room could not be loaded.',
                    isEmpty: true,
                    emptyMessage: '',
                    onRetry: _load,
                    child: const SizedBox(),
                  )
                  : Column(
                    children: [
                      _partiesHeader(r),
                      _statusBar(r),
                      Expanded(child: _thread()),
                      if (!r.isClosed) _inputBar(r),
                      if (r.nextStatuses.contains('COMPLETED'))
                        _markCompleteBar(r)
                      else if (r.status == 'COMPLETED')
                        _completedBar(),
                    ],
                  ),
        ),
      );
    });
  }

  Widget _partiesHeader(DealerDealRoomModel r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _partyBox(
                'BUYER',
                r.buyer,
                AppColors.green,
                isYou: r.isYouBuyer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _partyBox(
                'SELLER',
                r.seller,
                AppColors.blue,
                isYou: !r.isYouBuyer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _partyBox(
    String role,
    DealerPartyModel party,
    Color color, {
    required bool isYou,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isYou ? '$role · YOU' : role,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            party.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${party.dealerCode} · ${party.city}',
            style: const TextStyle(fontSize: 11, color: AppColors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (!isYou && party.phone.isNotEmpty)
            InkWell(
              onTap: () => _call(party.phone),
              child: Row(
                children: [
                  Icon(Icons.call, size: 12, color: color),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      party.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusBar(DealerDealRoomModel r) {
    final steps =
        r.nextStatuses
            .where((s) => !{'COMPLETED', 'CANCELLED', 'DISPUTED'}.contains(s))
            .toList();
    final color =
        r.status == 'COMPLETED'
            ? AppColors.green
            : r.isClosed
            ? AppColors.red
            : AppColors.blue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          DealerStatusChip(
            label: r.statusLabel.toUpperCase(),
            color: color,
            small: true,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Asking ${GlobalFunctions.formatLakh(r.askingPrice)}${r.agreedAmount > 0 ? ' · Agreed ${GlobalFunctions.formatLakh(r.agreedAmount)}' : ''}',
              style: const TextStyle(fontSize: 11, color: AppColors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (steps.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'Update deal status',
              onSelected: (s) => _moveTo(r, s),
              itemBuilder:
                  (_) => [
                    for (final s in steps)
                      PopupMenuItem(
                        value: s,
                        child: Text('Move to ${DealerDealRoomModel.labels[s]}'),
                      ),
                  ],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'Update ›',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _thread() {
    final c = chat.value;
    if (c == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }
    return Obx(() {
      final items = <Widget>[];
      var shownRevealDivider = false;
      if (c.messages.isNotEmpty && c.messages.first.phase != 'DEAL_ROOM') {
        items.add(
          _divider(
            Icons.visibility_off_outlined,
            'Chat Room history · identities were hidden',
          ),
        );
      }
      for (final m in c.messages) {
        if (!shownRevealDivider && m.phase == 'DEAL_ROOM') {
          items.add(
            _divider(
              Icons.handshake_outlined,
              'Connection accepted · identities revealed',
            ),
          );
          shownRevealDivider = true;
        }
        items.add(
          ChatMessageBubble(
            message: m,
            mine: c.isMine(m),
            onRetry: () => c.retry(m),
          ),
        );
      }
      return NotificationListener<ScrollNotification>(
        onNotification: (s) {
          if (s.metrics.pixels <= 40) c.loadOlder();
          return false;
        },
        child: ListView(
          controller: c.scrollController,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          children: items,
        ),
      );
    });
  }

  Widget _divider(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: AppColors.grey.withValues(alpha: 0.3)),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 14, color: AppColors.grey),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(color: AppColors.grey.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _inputBar(DealerDealRoomModel r) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                hintText: 'Message ${r.counterpart.name}…',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            onPressed: _send,
            icon: const Icon(Icons.send, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _markCompleteBar(DealerDealRoomModel r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: ButtonWidget(
        text: 'Mark Complete',
        isLoading: controller.isActing,
        width: double.infinity,
        height: 44,
        onTap: () => _moveTo(r, 'COMPLETED'),
      ),
    );
  }

  Widget _completedBar() {
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: AppColors.green, size: 18),
          SizedBox(width: 6),
          Text(
            'Deal Completed',
            style: TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
