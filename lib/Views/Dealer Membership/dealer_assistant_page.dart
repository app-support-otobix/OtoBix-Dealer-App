import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_assistant_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_assistant_model.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_exchange_model.dart';
import 'package:otobix/Services/notification_router.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_membership_navigator.dart';
import 'package:otobix/Views/Dealer%20Membership/exchange_listing_page.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';

/// Dealer Home -> mic. A conversation: the dealer speaks (or types), the
/// assistant answers in text with car cards, and reads the answer aloud on tap.
class DealerAssistantPage extends StatefulWidget {
  /// Start listening as soon as the page opens (the Home mic does this).
  final bool listenOnOpen;

  const DealerAssistantPage({super.key, this.listenOnOpen = true});

  @override
  State<DealerAssistantPage> createState() => _DealerAssistantPageState();
}

class _DealerAssistantPageState extends State<DealerAssistantPage> {
  late final DealerAssistantController c;
  final _input = TextEditingController();
  final _typing = false.obs;

  @override
  void initState() {
    super.initState();
    c = Get.put(DealerAssistantController());
    if (widget.listenOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => c.startListening());
    }
  }

  @override
  void dispose() {
    _input.dispose();
    Get.delete<DealerAssistantController>();
    super.dispose();
  }

  void _sendTyped() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    _typing.value = false;
    FocusScope.of(context).unfocus();
    c.send(text);
  }

  // Each part has its own Obx, so the mic level (many updates a second)
  // rebuilds the input bar only, not the conversation.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() => _appBar(context)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Obx(_languageBar),
            Expanded(
              child: Obx(
                () => c.messages.isEmpty ? _emptyState() : _conversation(),
              ),
            ),
            Obx(_inputBar),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    return AppBarWidget(
      title: c.t('title'),
      actions: [
        IconButton(
          tooltip: c.t(c.autoRead.value ? 'autoReadOn' : 'autoReadOff'),
          icon: Icon(
            c.autoRead.value
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            color: c.autoRead.value ? AppColors.green : AppColors.grey,
          ),
          onPressed: () {
            c.toggleAutoRead();
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  content: Text(
                    c.t(c.autoRead.value ? 'autoReadOn' : 'autoReadOff'),
                  ),
                ),
              );
          },
        ),
        if (c.messages.isNotEmpty)
          IconButton(
            tooltip: c.t('newChat'),
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey),
            onPressed: c.clearConversation,
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------

  Widget _languageBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          for (final l in AssistantLanguage.all) ...[
            ChoiceChip(
              label: Text(l.label),
              selected: c.language.value == l,
              selectedColor: AppColors.green.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    c.language.value == l ? AppColors.green : AppColors.black,
              ),
              side: BorderSide(
                color:
                    c.language.value == l
                        ? AppColors.green
                        : AppColors.grayWithOpacity1,
              ),
              showCheckmark: false,
              onSelected: c.isListening.value ? null : (_) => c.setLanguage(l),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        const Icon(Icons.mic_rounded, size: 56, color: AppColors.green),
        const SizedBox(height: 12),
        Text(
          c.t('tapToSpeak'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 28),
        Text(
          c.t('tryAsking'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.grey, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final example in c.examples)
              ActionChip(
                label: Text(example, style: const TextStyle(fontSize: 13)),
                backgroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.grayWithOpacity1),
                onPressed: () => c.send(example),
              ),
          ],
        ),
      ],
    );
  }

  Widget _conversation() {
    final count = c.messages.length + (c.isSending.value ? 1 : 0);
    return ListView.builder(
      controller: c.scrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: count,
      itemBuilder: (context, i) {
        if (i >= c.messages.length) return _thinkingBubble();
        final m = c.messages[i];
        return m.fromDealer ? _dealerBubble(m) : _answer(m, i);
      },
    );
  }

  Widget _dealerBubble(AssistantMessage m) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 10, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.green,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          m.text,
          style: const TextStyle(color: AppColors.white, fontSize: 14),
        ),
      ),
    );
  }

  Widget _answer(AssistantMessage m, int index) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 4),
              decoration: BoxDecoration(
                color:
                    m.isError
                        ? AppColors.red.withValues(alpha: 0.08)
                        : const Color(0xFFF2F4F3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: m.isError ? AppColors.red : AppColors.black,
                      ),
                    ),
                  ),
                  // Its own Obx: list items are built outside the list's Obx.
                  if (!m.isError) Obx(() => _readAloudButton(index)),
                ],
              ),
            ),
            for (final car in m.cars) _carCard(car),
            if (m.actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final a in m.actions)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          side: const BorderSide(color: AppColors.green),
                        ),
                        onPressed: () => _runAction(a),
                        child: Text(a.label),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _readAloudButton(int index) {
    final speaking = c.speakingIndex.value == index;
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.green,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        visualDensity: VisualDensity.compact,
      ),
      onPressed: () => c.toggleSpeaking(index),
      icon: Icon(
        speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
        size: 18,
      ),
      label: Text(
        c.t(speaking ? 'stop' : 'readAloud'),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _thinkingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              c.t('searching'),
              style: const TextStyle(color: AppColors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Car cards
  // ---------------------------------------------------------------------------

  static final _number = NumberFormat.decimalPattern('en_IN');

  (String, Color) _sourceLabel(AssistantCar car) => switch (car.source) {
    'auction' => switch (car.auctionStatus) {
      'live' => ('Live auction', AppColors.red),
      'otobuy' => ('OtoBuy', AppColors.blue),
      _ => ('Upcoming auction', AppColors.deepOrange),
    },
    'customer' => ('Premium Listing', const Color(0xFF8E44AD)),
    _ => ('Dealer stock', AppColors.green),
  };

  Widget _carCard(AssistantCar car) {
    final (label, color) = _sourceLabel(car);
    final facts = [
      if (car.fuelType.isNotEmpty) car.fuelType,
      if (car.transmission.isNotEmpty) car.transmission,
      if (car.kms > 0) '${_number.format(car.kms)} km',
    ].join(' · ');
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayWithOpacity1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openCar(car),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 96,
                  height: 72,
                  child:
                      car.image.isEmpty
                          ? _imagePlaceholder()
                          : CachedNetworkImage(
                            imageUrl: car.image,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _imagePlaceholder(),
                            errorWidget: (_, __, ___) => _imagePlaceholder(),
                          ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      car.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (car.variant.isNotEmpty)
                      Text(
                        car.variant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    if (facts.isNotEmpty)
                      Text(
                        facts,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    Row(
                      children: [
                        if (car.city.isNotEmpty)
                          Expanded(
                            child: Text(
                              car.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grey,
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        if (car.price > 0)
                          Text(
                            '₹${_number.format(car.price)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: const Color(0xFFF2F4F3),
    child: const Icon(Icons.directions_car_rounded, color: AppColors.grey),
  );

  /// Opens a car on the screen the app already uses for it.
  void _openCar(AssistantCar car) {
    c.stopSpeaking();
    switch (car.source) {
      case 'auction':
        // The push-notification route: checks the car is still in that
        // auction and starts its timer, as a notification tap does.
        NotificationRouter.go({
          'navigateToScreen': switch (car.auctionStatus) {
            'live' => NotificationRoutes.carAddedInLive,
            'otobuy' => NotificationRoutes.carAddedInOtobuy,
            _ => NotificationRoutes.carAddedInUpcoming,
          },
          'parametersForScreen': {'carId': car.id},
        });
      case 'customer':
        final listing = car.listing;
        if (listing != null) {
          Get.to(
            () => ExchangeListingPage(
              listing: DealerExchangeListingModel.fromJson(listing),
            ),
          );
        }
      default:
        DealerMembershipNavigator.openExchangeListing(car.id);
    }
  }

  void _runAction(AssistantAction a) {
    c.stopSpeaking();
    switch (a.type) {
      case 'OPEN_SELL':
        DealerMembershipNavigator.openSell();
      case 'OPEN_LEADS':
        DealerMembershipNavigator.openLeads();
      default:
        DealerMembershipNavigator.openMembership();
    }
  }

  // ---------------------------------------------------------------------------
  // Mic and text box
  // ---------------------------------------------------------------------------

  Widget _inputBar() {
    final listening = c.isListening.value;
    final status =
        listening
            ? (c.heardText.value.isEmpty ? c.t('listening') : c.heardText.value)
            : c.hint.value;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: listening ? AppColors.black : AppColors.grey,
                  fontStyle: listening ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  enabled: !listening,
                  minLines: 1,
                  maxLines: 3,
                  maxLength: 500,
                  textInputAction: TextInputAction.send,
                  onChanged: (v) => _typing.value = v.trim().isNotEmpty,
                  onSubmitted: (_) => _sendTyped(),
                  decoration: InputDecoration(
                    counterText: '',
                    isDense: true,
                    hintText: c.t('typeHere'),
                    hintStyle: TextStyle(
                      color: AppColors.grey.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: AppColors.grayWithOpacity1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.green),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _typing.value ? _sendButton() : _micButton(listening),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sendButton() => SizedBox(
    width: 56,
    height: 56,
    child: IconButton.filled(
      style: IconButton.styleFrom(backgroundColor: AppColors.green),
      onPressed: c.isSending.value ? null : _sendTyped,
      icon: const Icon(Icons.send_rounded, color: AppColors.white),
    ),
  );

  Widget _micButton(bool listening) {
    // The ring grows with the voice it hears (Android reports about -2..10 dB).
    final level = ((c.soundLevel.value + 2) / 12).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: c.isSending.value ? null : c.toggleListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              c.isSending.value
                  ? AppColors.grayWithOpacity1
                  : listening
                  ? AppColors.red
                  : AppColors.green,
          boxShadow:
              listening
                  ? [
                    BoxShadow(
                      color: AppColors.red.withValues(alpha: 0.35),
                      blurRadius: 4 + 14 * level,
                      spreadRadius: 2 + 8 * level,
                    ),
                  ]
                  : null,
        ),
        child: Icon(
          listening ? Icons.stop_rounded : Icons.mic_rounded,
          color: AppColors.white,
          size: 28,
        ),
      ),
    );
  }
}
