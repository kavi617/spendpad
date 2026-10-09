import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendpad/screen/startup_screen.dart';

void main() {
  testWidgets('reduced-motion intro completes without starting an animation', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: StartupScreen(onComplete: () => completions++),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('SpendPad'), findsOneWidget);
    expect(find.text('Your Money, Made Clear'), findsOneWidget);
    expect(completions, 1);
  });

  testWidgets('intro completion callback fires once after the transition', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(home: StartupScreen(onComplete: () => completions++)),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(completions, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(completions, 1);
  });
}
