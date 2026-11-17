import 'package:otobix/Utils/global_functions.dart';

int _int(dynamic v) => GlobalFunctions.parse<int>(v) ?? 0;
String _rupees(int v) => GlobalFunctions.formatRupees(v);

/// A price as the server sends it: `priceRupees` is what the dealer pays, 18%
/// GST included, and `basePriceRupees` / `gstRupees` / `gstPercent` break it
/// down. A server without GST sends none of them, so the price stands alone.
class DealerPriceModel {
  final int totalRupees;
  final int baseRupees;
  final int gstRupees;
  final int gstPercent;

  bool get hasGst => gstRupees > 0;

  /// "₹5,000 + GST", or the price alone.
  String get listText =>
      hasGst ? '${_rupees(baseRupees)} + GST' : _rupees(totalRupees);

  /// "₹2,360 (₹2,000 + 18% GST)", or the price alone.
  String get fullText => hasGst
      ? '${_rupees(totalRupees)} (${_rupees(baseRupees)} + $gstPercent% GST)'
      : _rupees(totalRupees);

  /// "₹5,000 + ₹900 GST (18%)" for under a Pay button; '' without GST.
  String get breakdownText => hasGst
      ? '${_rupees(baseRupees)} + ${_rupees(gstRupees)} GST ($gstPercent%)'
      : '';

  /// Reads the price fields of [j] (a plan, a top-up, a connection, or a
  /// thread's connection); null gives no price.
  DealerPriceModel.fromJson(dynamic j)
    : totalRupees = j is Map ? _int(j['priceRupees']) : 0,
      gstRupees = j is Map ? _int(j['gstRupees']) : 0,
      gstPercent = j is Map ? _int(j['gstPercent']) : 0,
      baseRupees = j is Map
          ? (j['basePriceRupees'] != null
                ? _int(j['basePriceRupees'])
                : _int(j['priceRupees']))
          : 0;
}
