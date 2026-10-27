import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:otobix/Widgets/button_widget.dart';

Widget _host(Widget child) => GetMaterialApp(home: Scaffold(body: child));

void main() {
  setUp(() => Get.testMode = true);

  testWidgets('ButtonWidget ignores taps while loading (no double submit)', (
    tester,
  ) async {
    final isLoading = false.obs;
    var taps = 0;
    await tester.pumpWidget(
      _host(
        ButtonWidget(
          text: 'Send offer',
          isLoading: isLoading,
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('Send offer'));
    expect(taps, 1);

    isLoading.value = true;
    await tester.pump();
    await tester.tap(find.byType(ButtonWidget));
    expect(taps, 1, reason: 'taps while loading must be ignored');

    isLoading.value = false;
    await tester.pump();
    await tester.tap(find.text('Send offer'));
    expect(taps, 2);
  });
}
