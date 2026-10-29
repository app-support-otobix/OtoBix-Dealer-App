import 'package:otobix/Models/Dealer%20Membership/dealer_negotiation_model.dart';
import 'package:otobix/Utils/global_functions.dart';

String _str(dynamic v) => GlobalFunctions.parse<String>(v) ?? '';
int _int(dynamic v) => GlobalFunctions.parse<int>(v) ?? 0;
DateTime? _date(dynamic v) => GlobalFunctions.parse<DateTime>(v);

class DealerConnectionModel {
  final String id;
  final String connectionCode;
  final String negotiationId;
  final String carId;
  final String carTitle;
  final String carImage;
  final String myRole;
  final bool initiatedByMe;
  final String initiatorRole;
  final DealerPartyModel counterpart;
  final String status;
  final int pointsPerSide;
  // Premium Listing: paid once the car owner accepts (no points).
  final int priceRupees;
  final DateTime? requestedAt;
  final DateTime? expiresAt;
  final String dealRoomId;

  bool get isPending => status == 'PENDING';
  bool get isPremiumListing => priceRupees > 0;
  bool get isPaymentDue => status == 'PAYMENT_DUE';

  DealerConnectionModel.fromJson(Map<String, dynamic> j)
    : id = _str(j['id']),
      priceRupees = _int(j['priceRupees']),
      connectionCode = _str(j['connectionCode']),
      negotiationId = _str(j['negotiationId']),
      carId = _str(j['car']?['id']),
      carTitle = _str(j['car']?['title']),
      carImage = _str(j['car']?['image']),
      myRole = _str(j['myRole']),
      initiatedByMe = j['initiatedByMe'] == true,
      initiatorRole = _str(j['initiatorRole']),
      counterpart = DealerPartyModel.fromJson(
        j['counterpart'] is Map
            ? Map<String, dynamic>.from(j['counterpart'])
            : null,
      ),
      status = _str(j['status']),
      pointsPerSide = _int(j['pointsPerSide']),
      requestedAt = _date(j['requestedAt']),
      expiresAt = _date(j['expiresAt']),
      dealRoomId = _str(j['dealRoomId']);
}

class DealerConnectionPrecheckModel {
  final bool membershipActive;
  final String planName;
  final int availablePoints;
  final int cost;
  final int priceRupees; // Premium Listing: paid once the owner accepts
  final int expiryHours;
  final bool listingActive;
  final int pendingByMe;
  final int maxPending;
  final int pendingOnListing;
  final int maxPendingPerListing;
  final bool canRequest;
  final String reason;

  DealerConnectionPrecheckModel.fromJson(Map<String, dynamic> j)
    : membershipActive = j['membershipActive'] == true,
      planName = _str(j['planName']),
      availablePoints = _int(j['availablePoints']),
      cost = _int(j['cost']),
      priceRupees = _int(j['priceRupees']),
      expiryHours = _int(j['expiryHours']),
      listingActive = j['listingActive'] == true,
      pendingByMe = _int(j['pendingByMe']),
      maxPending = _int(j['maxPending']),
      pendingOnListing = _int(j['pendingOnListing']),
      maxPendingPerListing = _int(j['maxPendingPerListing']),
      canRequest = j['canRequest'] == true,
      reason = _str(j['reason']);
}

class DealerConnectionCandidateModel {
  final String dealerCode; // masked, e.g. DLR-•••••
  // Names this buyer for this car only, when the seller requests a connection.
  final String buyerRef;
  final String dealerType;
  final String city;
  final int matchPercent;
  final String reason;
  final String connectionStatus;

  DealerConnectionCandidateModel.fromJson(Map<String, dynamic> j)
    : dealerCode = _str(j['dealerCode']),
      buyerRef = _str(j['buyerRef']),
      dealerType = _str(j['dealerType']),
      city = _str(j['city']),
      matchPercent = _int(j['matchPercent']),
      reason = _str(j['reason']),
      connectionStatus = _str(j['connectionStatus']);
}
