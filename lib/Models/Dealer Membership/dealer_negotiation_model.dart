import 'package:otobix/Utils/global_functions.dart';

String _str(dynamic v) => GlobalFunctions.parse<String>(v) ?? '';
int _int(dynamic v) => GlobalFunctions.parse<int>(v) ?? 0;
DateTime? _date(dynamic v) => GlobalFunctions.parse<DateTime>(v);

class DealerPartyModel {
  final String dealerCode;
  final String dealerType;
  final String city;
  final String name;
  final String phone;

  bool get isRevealed => name.isNotEmpty;

  DealerPartyModel.fromJson(Map<String, dynamic>? j)
    : dealerCode = _str(j?['dealerCode']),
      dealerType = _str(j?['dealerType']),
      city = _str(j?['city']),
      name = _str(j?['name']),
      phone = _str(j?['phone']);
}

class DealerNegotiationModel {
  final String id;
  final String negotiationCode;
  final String role;
  final String carId;
  final String carTitle;
  final String carImage;
  final int askingPrice;
  final bool isCustomerCar;
  final DealerPartyModel counterpart;
  final String status;
  final String displayStatus;
  final int? lastOfferAmount;
  final bool lastOfferByMe;
  final bool lastOfferIsCounter;
  final int buyerOffer;
  final int sellerOffer;
  final int agreedAmount;
  final int offerCount;
  final int questionCount;
  final int unread;
  final DateTime? lastMessageAt;
  final String lastMessagePreview;
  final String connectionId;
  final String connectionStatus;
  final bool connectionInitiatedByMe;
  final DateTime? connectionExpiresAt;
  final String dealRoomId;

  bool get isBuyer => role == 'BUYER';
  bool get awaitsMyReply => displayStatus == 'ACTION NEEDED';
  bool get hasPendingConnection => connectionStatus == 'PENDING';

  DealerNegotiationModel.fromJson(Map<String, dynamic> j)
    : id = _str(j['id']),
      negotiationCode = _str(j['negotiationCode']),
      role = _str(j['role']),
      carId = _str(j['car']?['id']),
      carTitle = _str(j['car']?['title']),
      carImage = _str(j['car']?['image']),
      askingPrice = _int(j['car']?['exchangePrice']),
      isCustomerCar = j['car']?['isCustomerCar'] == true,
      counterpart = DealerPartyModel.fromJson(
        j['counterpart'] is Map
            ? Map<String, dynamic>.from(j['counterpart'])
            : null,
      ),
      status = _str(j['status']),
      displayStatus = _str(j['displayStatus']),
      lastOfferAmount =
          j['lastOffer'] is Map ? _int(j['lastOffer']['amount']) : null,
      lastOfferByMe = j['lastOffer']?['byMe'] == true,
      lastOfferIsCounter = j['lastOffer']?['isCounter'] == true,
      buyerOffer = _int(j['buyerOffer']),
      sellerOffer = _int(j['sellerOffer']),
      agreedAmount = _int(j['agreedAmount']),
      offerCount = _int(j['offerCount']),
      questionCount = _int(j['questionCount']),
      unread = _int(j['unread']),
      lastMessageAt = _date(j['lastMessageAt']),
      lastMessagePreview = _str(j['lastMessagePreview']),
      connectionId = _str(j['connection']?['id']),
      connectionStatus = _str(j['connection']?['status']),
      connectionInitiatedByMe = j['connection']?['initiatedByMe'] == true,
      connectionExpiresAt = _date(j['connection']?['expiresAt']),
      dealRoomId = _str(j['dealRoomId']);
}

class DealerPriceDiscoveryModel {
  final int count;
  final int min;
  final int max;
  final int average;

  DealerPriceDiscoveryModel.fromJson(Map<String, dynamic>? j)
    : count = _int(j?['count']),
      min = _int(j?['min']),
      max = _int(j?['max']),
      average = _int(j?['average']);
}

enum DealerMessageState { sent, sending, failed }

class DealerMessageModel {
  final String id;
  final String senderRole;
  final String kind;
  final String text;
  final int amount;
  final String offerLabel;
  final String answerTo;
  final String phase;
  final String clientMessageId;
  final DateTime createdAt;
  final DealerMessageState state;

  DealerMessageModel({
    required this.id,
    required this.senderRole,
    required this.kind,
    required this.text,
    required this.phase,
    required this.clientMessageId,
    required this.createdAt,
    this.amount = 0,
    this.offerLabel = '',
    this.answerTo = '',
    this.state = DealerMessageState.sent,
  });

  DealerMessageModel.fromJson(Map<String, dynamic> j)
    : id = _str(j['id']),
      senderRole = _str(j['senderRole']),
      kind = _str(j['kind']),
      text = _str(j['text']),
      amount = _int(j['amount']),
      offerLabel = _str(j['offerLabel']),
      answerTo = _str(j['answerTo']),
      phase = _str(j['phase']),
      clientMessageId = _str(j['clientMessageId']),
      createdAt = _date(j['createdAt']) ?? DateTime.now(),
      state = DealerMessageState.sent;

  DealerMessageModel copyWith({DealerMessageState? state}) =>
      DealerMessageModel(
        id: id,
        senderRole: senderRole,
        kind: kind,
        text: text,
        amount: amount,
        offerLabel: offerLabel,
        answerTo: answerTo,
        phase: phase,
        clientMessageId: clientMessageId,
        createdAt: createdAt,
        state: state ?? this.state,
      );
}
