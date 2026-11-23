// The Dealer Home voice assistant: one chat message, the cars and buttons an
// answer carries, and the three languages it speaks.

/// A language the assistant listens and speaks in. Speech recognition and
/// read-aloud both run on the phone, so they cost nothing per question.
class AssistantLanguage {
  final String code; // what the backend calls it
  final String label; // what the dealer sees
  final String speechLocale; // speech_to_text locale id
  final String ttsLocale; // flutter_tts language

  const AssistantLanguage._(
    this.code,
    this.label,
    this.speechLocale,
    this.ttsLocale,
  );

  static const english = AssistantLanguage._('en', 'English', 'en_IN', 'en-IN');
  static const hindi = AssistantLanguage._('hi', 'हिन्दी', 'hi_IN', 'hi-IN');
  static const bengali = AssistantLanguage._('bn', 'বাংলা', 'bn_IN', 'bn-IN');

  static const all = [english, hindi, bengali];

  static AssistantLanguage of(String? code) =>
      all.firstWhere((l) => l.code == code, orElse: () => english);
}

/// A car in an answer. [source] is `auction`, `dealer` or `customer`.
class AssistantCar {
  final String source;
  final String id;
  final String title;
  final String variant;
  final String image;
  final int year;
  final int kms;
  final String fuelType;
  final String transmission;
  final String city;
  final int price; // 0 for auction cars: the car page shows their price
  final String auctionStatus; // live | upcoming | otobuy (auction cars only)
  final Map<String, dynamic>?
  listing; // dealer and customer cars, as the Buy screens get them

  AssistantCar.fromJson(Map<String, dynamic> j)
    : source = _str(j['source']),
      id = _str(j['id']),
      title = _str(j['title']),
      variant = _str(j['variant']),
      image = _str(j['image']),
      year = _int(j['year']),
      kms = _int(j['kms']),
      fuelType = _str(j['fuelType']),
      transmission = _str(j['transmission']),
      city = _str(j['city']),
      price = _int(j['price']),
      auctionStatus = _str(j['auctionStatus']),
      listing =
          j['listing'] is Map
              ? Map<String, dynamic>.from(j['listing'] as Map)
              : null;

  bool get isAuction => source == 'auction';
}

/// A button under an answer, e.g. "Open Membership".
class AssistantAction {
  final String type; // OPEN_MEMBERSHIP | OPEN_SELL | OPEN_LEADS
  final String label;

  AssistantAction.fromJson(Map<String, dynamic> j)
    : type = _str(j['type']),
      label = _str(j['label']);
}

class AssistantMessage {
  final bool fromDealer;
  final String text;
  final AssistantLanguage language;
  final List<AssistantCar> cars;
  final List<AssistantAction> actions;

  /// What the backend understood so far (filters etc.). Sent back with the
  /// next question so a follow-up like "only diesel" keeps the earlier search.
  final Map<String, dynamic>? state;

  /// Errors are shown in the chat but never sent back as conversation.
  final bool isError;

  const AssistantMessage({
    required this.fromDealer,
    required this.text,
    required this.language,
    this.cars = const [],
    this.actions = const [],
    this.state,
    this.isError = false,
  });

  factory AssistantMessage.answer(Map<String, dynamic> data) {
    List<Map<String, dynamic>> maps(dynamic v) =>
        v is List
            ? v
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList()
            : const [];
    return AssistantMessage(
      fromDealer: false,
      text: _str(data['reply']),
      language: AssistantLanguage.of(_str(data['language'])),
      cars: maps(data['cars']).map(AssistantCar.fromJson).toList(),
      actions: maps(data['actions']).map(AssistantAction.fromJson).toList(),
      state:
          data['state'] is Map
              ? Map<String, dynamic>.from(data['state'] as Map)
              : null,
    );
  }

  /// The shape the backend reads: { role, text, state? }.
  Map<String, dynamic> toHistory() => {
    'role': fromDealer ? 'user' : 'assistant',
    'text': text,
    if (state != null) 'state': state,
  };
}

String _str(dynamic v) => v == null ? '' : v.toString();
int _int(dynamic v) => v is num ? v.round() : int.tryParse('${v ?? ''}') ?? 0;
