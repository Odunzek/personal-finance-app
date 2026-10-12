import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_app/core/security/privacy_mode.dart';
import 'package:finance_app/core/widgets/money_text.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  tearDown(() => privacyModeNotifier.value = false);

  testWidgets('amounts show normally when privacy is off', (tester) async {
    await _pump(tester, const MoneyText(181314));
    expect(find.text('\$1,813.14'), findsOneWidget);
    expect(find.text(PrivacyMode.mask), findsNothing);
  });

  testWidgets('switching privacy on masks an amount already on screen', (
    tester,
  ) async {
    await _pump(tester, const MoneyText(181314));
    expect(find.text('\$1,813.14'), findsOneWidget);

    privacyModeNotifier.value = true;
    await tester.pump();

    expect(find.text('\$1,813.14'), findsNothing);
    expect(find.text(PrivacyMode.mask), findsOneWidget);
  });

  testWidgets('the mask is the same whatever the amount', (tester) async {
    // A mask that grew with the number would still give its size away.
    privacyModeNotifier.value = true;
    await _pump(tester, const MoneyText(5));
    final small = tester.widget<Text>(find.byType(Text)).data;

    await _pump(tester, const MoneyText(999999999));
    final large = tester.widget<Text>(find.byType(Text)).data;

    expect(small, large);
  });

  testWidgets('a masked amount gives no sign away', (tester) async {
    privacyModeNotifier.value = true;
    await _pump(tester, const MoneyText(-50000, showSign: true));
    expect(find.textContaining('-'), findsNothing);
    expect(find.text(PrivacyMode.mask), findsOneWidget);
  });

  testWidgets('the hero figure masks too, without counting up', (tester) async {
    privacyModeNotifier.value = true;
    await _pump(tester, const AnimatedMoneyText(181314));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(PrivacyMode.mask), findsOneWidget);
  });

  testWidgets('turning privacy back off restores the amount', (tester) async {
    privacyModeNotifier.value = true;
    await _pump(tester, const MoneyText(181314));
    expect(find.text(PrivacyMode.mask), findsOneWidget);

    privacyModeNotifier.value = false;
    await tester.pump();

    expect(find.text('\$1,813.14'), findsOneWidget);
  });
}
