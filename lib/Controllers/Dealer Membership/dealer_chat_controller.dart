import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_negotiations_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_negotiation_model.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Network/socket_service.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Utils/socket_events.dart';

class DealerChatController extends GetxController {
  final String negotiationId;
  DealerChatController(this.negotiationId);

  // Chats on screen now (once per open page), so a push for one of them is
  // not shown on top of the message already arriving in it.
  static final openChats = <String>[];

  final negotiation = Rxn<DealerNegotiationModel>();
  final messages = <DealerMessageModel>[].obs;
  final isLoading = false.obs;
  final isLoadingOlder = false.obs;
  final hasOlder = true.obs;
  final error = ''.obs;
  final scrollController = ScrollController();

  final _random = Random();

  String get myRole => negotiation.value?.role ?? '';
  bool isMine(DealerMessageModel m) => m.senderRole == myRole;

  @override
  void onInit() {
    super.onInit();
    openChats.add(negotiationId);
    SocketService.instance.on(SocketEvents.dealerMessageCreated, _onMessage);
    SocketService.instance.on(
      SocketEvents.dealerNegotiationUpdated,
      _onUpdated,
    );
    load();
  }

  @override
  void onClose() {
    openChats.remove(negotiationId);
    SocketService.instance.off(SocketEvents.dealerMessageCreated, _onMessage);
    SocketService.instance.off(
      SocketEvents.dealerNegotiationUpdated,
      _onUpdated,
    );
    scrollController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      await refreshNegotiation();
      final page = await _fetch();
      messages.assignAll(page);
      _scrollToEnd();
    } on DealerApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshNegotiation() async {
    final n = await DealerNegotiationsController.to.get(negotiationId);
    if (n != null) negotiation.value = n;
  }

  Future<void> loadOlder() async {
    if (isLoadingOlder.value || !hasOlder.value || messages.isEmpty) return;
    isLoadingOlder.value = true;
    try {
      final older = await _fetch(before: messages.first.createdAt);
      messages.insertAll(0, older);
    } on DealerApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoadingOlder.value = false;
    }
  }

  Future<List<DealerMessageModel>> _fetch({DateTime? before}) async {
    final data = Map<String, dynamic>.from(
      await DealerMembershipApi.get(
        AppUrls.dealerNegotiationMessages(
          negotiationId,
          before: before?.toUtc().toIso8601String() ?? '',
        ),
      ),
    );
    hasOlder.value = data['hasMore'] == true;
    return (data['items'] as List? ?? [])
        .map((e) => DealerMessageModel.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        .reversed
        .toList();
  }

  Future<void> send(String text, {String answerTo = ''}) async {
    final clientId =
        '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 30)}';
    messages.add(
      DealerMessageModel(
        id: '',
        senderRole: myRole,
        kind: answerTo.isEmpty ? 'QUICK' : 'ANSWER',
        text: text,
        answerTo: answerTo,
        phase: '',
        clientMessageId: clientId,
        createdAt: DateTime.now(),
        state: DealerMessageState.sending,
      ),
    );
    _scrollToEnd();
    await _deliver(clientId, text, answerTo);
  }

  Future<void> retry(DealerMessageModel failed) async {
    _replace(
      failed.clientMessageId,
      failed.copyWith(state: DealerMessageState.sending),
    );
    await _deliver(failed.clientMessageId, failed.text, failed.answerTo);
  }

  Future<void> _deliver(String clientId, String text, String answerTo) async {
    try {
      final data = await DealerMembershipApi.post(
        AppUrls.dealerNegotiationSend(negotiationId),
        {
          'text': text,
          'clientMessageId': clientId,
          if (answerTo.isNotEmpty) ...{'kind': 'ANSWER', 'answerTo': answerTo},
        },
      );
      _upsert(DealerMessageModel.fromJson(Map<String, dynamic>.from(data)));
    } on DealerApiException catch (e) {
      final pending = messages.firstWhereOrNull(
        (m) => m.clientMessageId == clientId,
      );
      if (pending != null) {
        _replace(clientId, pending.copyWith(state: DealerMessageState.failed));
      }
      if (e.statusCode >= 400 && e.statusCode < 500) {
        messages.removeWhere((m) => m.clientMessageId == clientId);
        DealerMembershipController.to.handleError(e, title: 'Message not sent');
      }
    }
  }

  Future<void> makeOffer(int amount) async {
    final updated = await DealerNegotiationsController.to.makeOffer(
      negotiationId,
      amount,
    );
    if (updated != null) negotiation.value = updated;
  }

  Future<void> respond({required bool accept}) async {
    final updated = await DealerNegotiationsController.to.respond(
      negotiationId,
      accept: accept,
    );
    if (updated != null) negotiation.value = updated;
  }

  void _onMessage(dynamic data) {
    if (data is! Map || data['negotiationId'] != negotiationId) return;
    final message = DealerMessageModel.fromJson(
      Map<String, dynamic>.from(data['message'] ?? {}),
    );
    _upsert(message);
    if (message.kind == 'SYSTEM' || message.kind == 'OFFER') {
      refreshNegotiation();
    }
  }

  void _onUpdated(dynamic data) {
    if (data is Map && data['negotiationId'] == negotiationId) {
      refreshNegotiation();
    }
  }

  void _upsert(DealerMessageModel message) {
    if (message.id.isNotEmpty && messages.any((m) => m.id == message.id)) {
      return;
    }
    final i =
        message.clientMessageId.isEmpty
            ? -1
            : messages.indexWhere(
              (m) => m.clientMessageId == message.clientMessageId,
            );
    if (i >= 0) {
      messages[i] = message;
    } else {
      messages.add(message);
      _scrollToEnd();
    }
  }

  void _replace(String clientId, DealerMessageModel message) {
    final i = messages.indexWhere((m) => m.clientMessageId == clientId);
    if (i >= 0) messages[i] = message;
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }
}
