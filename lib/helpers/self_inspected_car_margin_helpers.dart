class SelfInspectedCarMarginHelpers {
  SelfInspectedCarMarginHelpers._();

  static const double fixedMargin = 2.0;

  // Convert price discovery to lacs
  static double toLacs(num? priceDiscovery) {
    final n = (priceDiscovery ?? 0).toDouble();
    if (!n.isFinite || n <= 0) return 0;
    return n > 1000 ? n / 100000 : n;
  }

  // Get car margins using price discovery
  static ({double fixed, double variable}) getSelfInspectedCarMargins(
    num? priceDiscovery,
  ) {
    final lacs = toLacs(priceDiscovery);

    double variable = 0;
    if (lacs > 0 && lacs <= 1) {
      variable = 8;
    } else if (lacs <= 3) {
      variable = 6;
    } else if (lacs <= 5) {
      variable = 4;
    } else if (lacs <= 10) {
      variable = 2;
    } else if (lacs <= 25) {
      variable = 2;
    } else if (lacs > 25) {
      variable = 2;
    }

    return (fixed: fixedMargin, variable: variable);
  }

  /// Round off to the next thousand
  static double roundOffToNext1000(num value) {
    return ((value.toDouble() / 1000).ceil() * 1000).toDouble();
  }

  /// Round off to the previous thousand
  static double roundOffToPrevious1000(num value) {
    return ((value.toDouble() / 1000).floor() * 1000).toDouble();
  }

  // Increase margin
  static double increaseMargin({
    required num amount,
    required double fixedMargin,
    required double variableMargin,
  }) {
    final originalAmount = amount.toDouble();
    final totalMargin = fixedMargin + variableMargin;
    final totalMarginInDecimal = totalMargin / 100.0;
    final marginAmount = originalAmount * totalMarginInDecimal;
    return roundOffToNext1000(originalAmount + marginAmount);
  }

  // Decrease margin
  static double decreaseMargin({
    required num amount,
    required double fixedMargin,
    required double variableMargin,
  }) {
    final originalAmount = amount.toDouble();
    final totalMargin = fixedMargin + variableMargin;
    final totalMarginInDecimal = totalMargin / 100.0;
    final reverseMargin = totalMarginInDecimal / (1 + totalMarginInDecimal);
    return roundOffToPrevious1000(originalAmount * (1 - reverseMargin));
  }

  // Get final margin adjusted amount
  // If fixedMargin and variableMargin are null or 0 then it will use PD slab to get the margins
  static double getMarginAdjustedAmount({
    required num originalPrice,
    required num? priceDiscovery,
    double? fixedMargin,
    double? variableMargin,
    bool shouldIncreaseMargin = true,
  }) {
    final pdMargins = getSelfInspectedCarMargins(priceDiscovery);

    // If fixedMargin not provided (null or 0) => use default fixed (2.0)
    final usedFixed =
        (fixedMargin == null || fixedMargin == 0)
            ? pdMargins.fixed
            : fixedMargin;

    // If variableMargin not provided (null or 0) => use slab-based variable
    final usedVariable =
        (variableMargin == null || variableMargin == 0)
            ? pdMargins.variable
            : variableMargin;

    final net =
        shouldIncreaseMargin
            ? increaseMargin(
              amount: originalPrice,
              fixedMargin: usedFixed,
              variableMargin: usedVariable,
            )
            : decreaseMargin(
              amount: originalPrice,
              fixedMargin: usedFixed,
              variableMargin: usedVariable,
            );

    return net;
  }
}
