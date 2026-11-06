import 'package:otobix/Models/Dealer%20Membership/dealer_negotiation_model.dart';
import 'package:otobix/Utils/global_functions.dart';

String _str(dynamic v) => GlobalFunctions.parse<String>(v) ?? '';
int _int(dynamic v) => GlobalFunctions.parse<int>(v) ?? 0;

class DealerDealStatusEntryModel {
  final String status;
  final String label;
  final String note;
  final DateTime? at;
  final bool byMe;

  DealerDealStatusEntryModel.fromJson(Map<String, dynamic> j)
    : status = _str(j['status']),
      label = _str(j['label']),
      note = _str(j['note']),
      at = GlobalFunctions.parse<DateTime>(j['at']),
      byMe = j['byMe'] == true;
}

class DealerDealRoomModel {
  static const terminal = {'COMPLETED', 'CANCELLED', 'DISPUTED'};
  static const labels = {
    'OPEN': 'Open',
    'NEGOTIATING': 'Negotiating',
    'AGREED': 'Agreed',
    'DOCUMENTATION': 'Documentation',
    'PAYMENT_PENDING': 'Payment pending',
    'COMPLETED': 'Completed',
    'CANCELLED': 'Cancelled',
    'DISPUTED': 'Disputed',
  };

  final String id;
  final String dealRoomCode;
  final String negotiationId;
  final String myRole;
  final String carId;
  final String carTitle;
  final String carImage;
  final String registrationNumber;
  final int askingPrice;
  final DealerPartyModel buyer;
  final DealerPartyModel seller;
  final String status;
  final List<DealerDealStatusEntryModel> statusHistory;
  final int agreedAmount;
  final List<String> nextStatuses;
  final String disputeReason;
  final String cancelReason;

  bool get isYouBuyer => myRole == 'BUYER';
  bool get isClosed => terminal.contains(status);
  DealerPartyModel get counterpart => isYouBuyer ? seller : buyer;
  String get statusLabel => labels[status] ?? status;

  DealerDealRoomModel.fromJson(Map<String, dynamic> j)
    : id = _str(j['id']),
      dealRoomCode = _str(j['dealRoomCode']),
      negotiationId = _str(j['negotiationId']),
      myRole = _str(j['myRole']),
      carId = _str(j['car']?['id']),
      carTitle = _str(j['car']?['title']),
      carImage = _str(j['car']?['image']),
      registrationNumber = _str(j['car']?['registrationNumber']),
      askingPrice = _int(j['car']?['askingPrice']),
      buyer = DealerPartyModel.fromJson(
        j['buyer'] is Map ? Map<String, dynamic>.from(j['buyer']) : null,
      ),
      seller = DealerPartyModel.fromJson(
        j['seller'] is Map ? Map<String, dynamic>.from(j['seller']) : null,
      ),
      status = _str(j['status']),
      statusHistory =
          (j['statusHistory'] as List? ?? [])
              .map(
                (e) => DealerDealStatusEntryModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(),
      agreedAmount = _int(j['agreedAmount']),
      nextStatuses =
          (j['nextStatuses'] as List? ?? []).map((e) => e.toString()).toList(),
      disputeReason = _str(j['disputeReason']),
      cancelReason = _str(j['cancelReason']);
}
