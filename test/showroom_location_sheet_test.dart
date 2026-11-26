import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:otobix/Widgets/Dealer%20Membership/showroom_location_widgets.dart';

// A dealer with no showroom location must set one: the sheet Dealer Home opens
// has no Later and ignores tapping outside, swiping down and Back.
void main() {
  tearDown(Get.reset);

  testWidgets('the sheet the app opens cannot be closed without a location', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => askForShowroomLocation(),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final title = find.text('Add your showroom location');
    expect(title, findsOneWidget);
    expect(find.text('Later'), findsNothing);
    expect(find.textContaining('needed to continue'), findsOneWidget);
    // Both ways to set it are there.
    expect(find.text('Search your showroom name or address'), findsOneWidget);
    expect(
      find.text("Use my current location (I'm at the showroom)"),
      findsOneWidget,
    );

    // Tapping outside, above the sheet.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(title, findsOneWidget);

    // Swiping it down.
    await tester.drag(title, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(title, findsOneWidget);

    // Android Back.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(title, findsOneWidget);
  });
}
