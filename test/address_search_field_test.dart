import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otobix/Models/place_model.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Network/places_api.dart';
import 'package:otobix/Widgets/address_search_field.dart';

/// Records what the field sends to the backend and answers like it would.
class _FakeBackend {
  final calls = <(String, Map<String, dynamic>)>[];
  bool failSuggestions = false;
  bool noSuggestions = false;
  String formattedAddress =
      'Plot 12, Sector V, Bidhannagar, Kolkata, West Bengal 700091, India';

  Future<dynamic> post(String url, Map<String, dynamic> body) async {
    calls.add((url, body));
    if (url.endsWith('places/autocomplete')) {
      if (failSuggestions) {
        throw const DealerApiException('Address suggestions are not available');
      }
      if (noSuggestions) return {'suggestions': []};
      return {
        'suggestions': [
          {
            'placeId': 'ChIJshowroom1',
            'title': 'Maruti Suzuki Arena',
            'subtitle': 'Sector V, Kolkata, West Bengal, India',
          },
          {
            'placeId': 'ChIJstreet2',
            'title': 'Park Street',
            'subtitle': 'Kolkata, West Bengal, India',
          },
        ],
      };
    }
    return {
      'place': {
        'placeId': body['placeId'],
        'address': formattedAddress,
        'latitude': 22.5726,
        'longitude': 88.4321,
        'city': 'Bidhannagar',
        'state': 'West Bengal',
        'pincode': '700091',
      },
    };
  }

  List<Map<String, dynamic>> callsTo(String path) =>
      calls.where((c) => c.$1.endsWith(path)).map((c) => c.$2).toList();
}

void main() {
  late _FakeBackend backend;
  late TextEditingController controller;
  PlaceDetailsModel? picked;
  var cleared = 0;

  setUp(() {
    backend = _FakeBackend();
    PlacesApi.post = backend.post;
    controller = TextEditingController();
    picked = null;
    cleared = 0;
  });

  Future<void> pumpField(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AddressSearchField(
            controller: controller,
            otpVerificationToken: 'otp-token',
            onPicked: (p) => picked = p,
            onCleared: () => cleared++,
          ),
        ),
      ),
    ),
  );

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextFormField), text);
    await tester.pump();
  }

  testWidgets('under 3 characters asks nothing', (tester) async {
    await pumpField(tester);
    await type(tester, 'ma');
    await tester.pump(const Duration(seconds: 1));
    expect(backend.calls, isEmpty);
  });

  testWidgets('searches once typing pauses, with the OTP and a session token', (
    tester,
  ) async {
    await pumpField(tester);
    await type(tester, 'mar');
    await tester.pump(const Duration(milliseconds: 100));
    await type(tester, 'maruti salt lake');
    await tester.pump(const Duration(milliseconds: 349));
    expect(backend.calls, isEmpty);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump();

    final searches = backend.callsTo('places/autocomplete');
    expect(searches, hasLength(1));
    expect(searches.single['input'], 'maruti salt lake');
    expect(searches.single['otpVerificationToken'], 'otp-token');
    expect(searches.single['sessionToken'], matches(r'^[A-Za-z0-9_-]{32}$'));
    expect(find.text('Maruti Suzuki Arena'), findsOneWidget);
    expect(find.text('Park Street'), findsOneWidget);
    expect(find.text('Google Maps'), findsOneWidget);
  });

  testWidgets(
    'picking fills in the full address, reports the position, then starts a new session',
    (tester) async {
      await pumpField(tester);
      await type(tester, 'maruti salt lake');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      await tester.tap(find.text('Maruti Suzuki Arena'));
      await tester.pumpAndSettle();

      final search = backend.callsTo('places/autocomplete').single;
      final details = backend.callsTo('places/details').single;
      expect(details['placeId'], 'ChIJshowroom1');
      expect(details['sessionToken'], search['sessionToken']);
      // The showroom's name leads Google's address, which lacks it.
      expect(
        controller.text,
        'Maruti Suzuki Arena, Plot 12, Sector V, Bidhannagar, Kolkata, West Bengal 700091, India',
      );
      expect(picked?.latitude, 22.5726);
      expect(picked?.longitude, 88.4321);
      expect(find.text('Park Street'), findsNothing); // list closed
      expect(find.byIcon(Icons.where_to_vote), findsOneWidget);
      // The picked address is not searched again.
      await tester.pump(const Duration(seconds: 1));
      expect(backend.callsTo('places/autocomplete'), hasLength(1));

      // The next search is a new session.
      await type(tester, 'park street kolkata');
      await tester.pump(const Duration(milliseconds: 400));
      final next = backend.callsTo('places/autocomplete').last;
      expect(next['sessionToken'], isNot(search['sessionToken']));
    },
  );

  testWidgets('an address that already names the place is kept as is', (
    tester,
  ) async {
    backend.formattedAddress = 'Maruti Suzuki Arena, Sector V, Kolkata 700091';
    await pumpField(tester);
    await type(tester, 'maruti salt lake');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.tap(find.text('Maruti Suzuki Arena'));
    await tester.pumpAndSettle();
    expect(controller.text, 'Maruti Suzuki Arena, Sector V, Kolkata 700091');
  });

  testWidgets('emptying the field drops the picked position', (tester) async {
    await pumpField(tester);
    await type(tester, 'maruti salt lake');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.tap(find.text('Maruti Suzuki Arena'));
    await tester.pumpAndSettle();
    expect(cleared, 0);

    await type(tester, '');
    expect(cleared, 1);
    expect(find.byIcon(Icons.where_to_vote), findsNothing);
  });

  testWidgets('when suggestions fail, the dealer can still type the address', (
    tester,
  ) async {
    backend.failSuggestions = true;
    await pumpField(tester);
    await type(tester, '12 Park Street, Kolkata');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byType(ListTile), findsNothing);
    expect(controller.text, '12 Park Street, Kolkata');
    expect(picked, isNull);
    // The dealer is told why, not left with an empty field.
    expect(find.text('Address suggestions are not available'), findsOneWidget);
  });

  testWidgets('nothing found says so, and typing again clears it', (
    tester,
  ) async {
    backend.noSuggestions = true;
    await pumpField(tester);
    await type(tester, 'Unknown Motors');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byType(ListTile), findsNothing);
    expect(find.textContaining('No matching places'), findsOneWidget);
    await type(tester, 'Unknown Motors Kolkata');
    expect(find.textContaining('No matching places'), findsNothing);
  });
}
