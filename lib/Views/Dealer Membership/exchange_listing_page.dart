import 'package:flutter/material.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_exchange_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/Dealer%20Membership/exchange_listing_card.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';

class ExchangeListingPage extends StatelessWidget {
  final DealerExchangeListingModel listing;
  const ExchangeListingPage({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(title: listing.title),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [ExchangeListingCard(listing: listing)],
        ),
      ),
    );
  }
}
