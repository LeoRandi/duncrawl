import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/settings/domain/text_speed.dart';
import 'package:duncrawl/features/dungeon/presentation/opening_tutorial.dart';

Future<void> completeOpeningTutorial(WidgetTester tester) async {
  await tester.pump(OpeningTutorial.delay);
  await tester.pump(const Duration(milliseconds: 250));
  for (final line in OpeningTutorial.dialogue.lines) {
    await tester.pump(
      TextSpeed.slow.letterInterval * line.text.characters.length,
    );
    await tester.tap(find.byKey(const ValueKey('dialogue-advance')));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump();
}
