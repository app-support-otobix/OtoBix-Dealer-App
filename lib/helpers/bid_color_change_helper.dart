import 'package:flutter/material.dart';
import 'package:otobix/Utils/app_colors.dart';

enum BidRole { hasNotBidYet, isHighestBidder, isNotHighestBidder }

class BidColorChangeHelper {
  // ===== Plain-English booleans =====
  static bool hasNotBidYet(bool hasUserBid) => !hasUserBid;

  static bool isHighestBidder({
    required String? currentUserId,
    required String? highestBidderUserId,
  }) {
    return currentUserId != null && currentUserId == highestBidderUserId;
  }

  static bool isNotHighestBidder({
    required String? currentUserId,
    required String? highestBidderUserId,
    required bool hasUserBid,
  }) {
    return hasUserBid &&
        !isHighestBidder(
          currentUserId: currentUserId,
          highestBidderUserId: highestBidderUserId,
        );
  }

  // ===== Role (optional, but nice) =====
  static BidRole getBidRole({
    required String? currentUserId,
    required String? highestBidderUserId,
    required bool hasUserBid,
  }) {
    if (hasNotBidYet(hasUserBid)) return BidRole.hasNotBidYet;
    if (isHighestBidder(
      currentUserId: currentUserId,
      highestBidderUserId: highestBidderUserId,
    )) {
      return BidRole.isHighestBidder;
    }
    return BidRole.isNotHighestBidder;
  }

  // ===== Colors =====
  static Color colorForBidRole(
    BidRole role, {
    required Color neutralColor, // not bid yet
    required Color winningColor, // is highest
    required Color losingColor, // bid but not highest
  }) {
    switch (role) {
      case BidRole.hasNotBidYet:
        return neutralColor;
      case BidRole.isHighestBidder:
        return winningColor;
      case BidRole.isNotHighestBidder:
        return losingColor;
    }
  }

  // Most convenient: directly get a color
  static Color getHighestBidColor({
    required String? currentUserId,
    required String? highestBidderUserId,
    required bool hasUserBid,
    Color neutralColor = AppColors.black,
    Color winningColor = AppColors.green,
    Color losingColor = AppColors.red,
  }) {
    final role = getBidRole(
      currentUserId: currentUserId,
      highestBidderUserId: highestBidderUserId,
      hasUserBid: hasUserBid,
    );
    return colorForBidRole(
      role,
      neutralColor: neutralColor,
      winningColor: winningColor,
      losingColor: losingColor,
    );
  }

  /// Deal price should be visible ONLY to dealers who have bid on that car
  /// and only if customerExpectedPrice is available (> 0).
  static bool shouldShowExpectedPrice({
    required bool hasUserBidOnCar,
    required double customerExpectedPrice,
  }) {
    return hasUserBidOnCar && customerExpectedPrice > 0;
  }
}
