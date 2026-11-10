import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/app/dungeon_theme.dart';
import 'package:duncrawl/features/dialogue/presentation/dialogue_sequence.dart';
import 'package:duncrawl/features/dialogue/presentation/dialogue_window.dart';
import 'package:duncrawl/features/dialogue/presentation/wobbly_letter.dart';
import 'package:duncrawl/features/dialogue/presentation/wobbly_word.dart';
import 'package:duncrawl/features/settings/domain/text_speed.dart';

const _sequence = DialogueSequence(
  speaker: 'Voice',
  lines: [
    DialogueLine([
      DialogueFragment('A'),
      DialogueFragment('xy', wobbly: true),
      DialogueFragment('B'),
    ]),
    DialogueLine([DialogueFragment('Next')]),
  ],
);

void main() {
  for (final speed in [TextSpeed.slow, TextSpeed.medium, TextSpeed.fast]) {
    testWidgets(
      '${speed.name} slows only animated letters and then restores its speed',
      (tester) async {
        await _mount(tester, speed: speed);
        final interval = speed.letterInterval;
        const oneMillisecond = Duration(milliseconds: 1);
        await tester.pump(interval - oneMillisecond);
        expect(_visibleText(tester), '');
        await tester.pump(oneMillisecond);
        expect(_visibleText(tester), 'A');
        await tester.pump(const Duration(milliseconds: 99));
        expect(_visibleText(tester), 'A');
        await tester.pump(oneMillisecond);
        expect(_visibleText(tester), 'Ax');
        expect(find.byType(WobblyLetter), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 99));
        expect(_visibleText(tester), 'Ax');
        await tester.pump(oneMillisecond);
        expect(_visibleText(tester), 'Axy');
        expect(find.byType(WobblyLetter), findsNWidgets(2));
        await tester.pump(interval - oneMillisecond);
        expect(_visibleText(tester), 'Axy');
        await tester.pump(oneMillisecond);
        expect(_visibleText(tester), 'AxyB');
        expect(find.text('Continue'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'Instant reveals the entire line including animated words immediately',
    (tester) async {
      await _mount(tester, speed: TextSpeed.instant);
      expect(_visibleText(tester), 'AxyB');
      expect(find.byType(WobblyLetter), findsNWidgets(2));
      expect(find.text('Continue'), findsOneWidget);
      expect(
        _letterOffset(tester, 0),
        isNot(closeTo(_letterOffset(tester, 1), 0.001)),
      );
      await tester.pump(const Duration(milliseconds: 225));
      expect(
        _letterOffset(tester, 0),
        isNot(closeTo(_letterOffset(tester, 1), 0.001)),
      );
      await tester.tap(find.byKey(const ValueKey('dialogue-advance')));
      await tester.pump();
      expect(_visibleText(tester), 'Next');
      expect(find.text('Close'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Tapping mid-line reveals the rest without advancing or leaving a timer',
    (tester) async {
      var closeCalls = 0;
      await _mount(tester, onClose: () => closeCalls++);
      await tester.pump(const Duration(milliseconds: 50));
      expect(_visibleText(tester), 'A');
      await _tapBox(tester);
      expect(_visibleText(tester), 'AxyB');
      expect(find.byType(WobblyLetter), findsNWidgets(2));
      await _tapBox(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(_visibleText(tester), 'AxyB');
      expect(closeCalls, 0);
      await tester.tap(find.byKey(const ValueKey('dialogue-advance')));
      await tester.pump();
      expect(_visibleText(tester), '');
      await tester.pump(const Duration(milliseconds: 49));
      expect(_visibleText(tester), '');
      await tester.pump(const Duration(milliseconds: 1));
      expect(_visibleText(tester), 'N');
      await _tapBox(tester);
      expect(_visibleText(tester), 'Next');
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dialogue-advance')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('dialogue-advance')));
      await tester.pump();
      expect(closeCalls, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Tapping before the first letter also reveals the whole line', (
    tester,
  ) async {
    await _mount(tester);
    expect(_visibleText(tester), '');
    await _tapBox(tester);
    expect(_visibleText(tester), 'AxyB');
    expect(find.text('Continue'), findsOneWidget);
    expect(
      _letterOffset(tester, 0),
      isNot(closeTo(_letterOffset(tester, 1), 0.001)),
    );
    await tester.pump(const Duration(milliseconds: 225));
    expect(
      _letterOffset(tester, 0),
      isNot(closeTo(_letterOffset(tester, 1), 0.001)),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Revealing mid-word preserves its clock and staggers the new letters',
    (tester) async {
      await _mount(tester);
      await tester.pump(const Duration(milliseconds: 150));
      expect(_visibleText(tester), 'Ax');
      final wordState = tester.state(find.byType(WobblyWord));
      await tester.pump(const Duration(milliseconds: 50));
      final before = _letterOffset(tester, 0);
      await _tapBox(tester);
      expect(_visibleText(tester), 'AxyB');
      expect(tester.state(find.byType(WobblyWord)), same(wordState));
      expect(_letterOffset(tester, 0), closeTo(before, 0.000001));
      expect(
        _letterOffset(tester, 0),
        isNot(closeTo(_letterOffset(tester, 1), 0.001)),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        _letterOffset(tester, 0),
        isNot(closeTo(_letterOffset(tester, 1), 0.001)),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

double _letterOffset(WidgetTester tester, int index) => tester
    .widget<Transform>(
      find.descendant(
        of: find.byType(WobblyLetter).at(index),
        matching: find.byType(Transform),
      ),
    )
    .transform
    .storage[13];

Future<void> _mount(
  WidgetTester tester, {
  TextSpeed speed = TextSpeed.defaultSpeed,
  VoidCallback? onClose,
}) => tester.pumpWidget(
  MaterialApp(
    theme: DungeonTheme.dark,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          height: 200,
          child: DialogueWindow(
            sequence: _sequence,
            textSpeed: speed,
            onClose: onClose ?? () {},
          ),
        ),
      ),
    ),
  ),
);

Future<void> _tapBox(WidgetTester tester) async {
  await tester.tapAt(
    tester.getTopLeft(find.byKey(const ValueKey('dialogue-box'))) +
        const Offset(24, 24),
  );
  await tester.pump();
}

String _visibleText(WidgetTester tester) => tester
    .widget<Semantics>(find.byKey(const ValueKey('dialogue-text')))
    .properties
    .label!;
