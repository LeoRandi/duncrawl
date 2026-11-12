import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/app/dungeon_theme.dart';
import 'package:duncrawl/features/dialogue/presentation/dialogue_sequence.dart';
import 'package:duncrawl/features/dialogue/presentation/dialogue_window.dart';
import 'package:duncrawl/features/dialogue/presentation/wobbly_letter.dart';
import 'package:duncrawl/features/dialogue/presentation/wobbly_word.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/game_menu_dialog.dart';
import 'package:duncrawl/features/dungeon/presentation/opening_tutorial.dart';
import 'package:duncrawl/main.dart';
import 'package:duncrawl/features/settings/domain/text_speed.dart';
import 'package:duncrawl/widgets/iris_transition.dart';

import 'helpers/dialogue_helpers.dart';

void main() {
  testWidgets(
    'Tutorial waits for the iris and one second, then types and blocks input',
    (tester) async {
      await _enterGame(tester);
      expect(find.byType(IrisMask), findsNothing);
      expect(find.byType(DialogueWindow), findsNothing);
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('player-portrait'))),
      );
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('player'))),
      );
      await tester.tapAt(tester.getCenter(find.byTooltip('Menu')));
      await tester.dragFrom(
        tester.getCenter(find.byType(DungeonBoard)),
        const Offset(200, 0),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(_board(tester).isSelected, isFalse);
      expect(_board(tester).movementPath, isEmpty);
      expect(_board(tester).player, const GridPosition(7, 7));
      expect(find.byType(GameMenuDialog), findsNothing);
      expect(find.byType(IrisMask), findsNothing);
      await tester.pump(const Duration(milliseconds: 999));
      expect(find.byType(DialogueWindow), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byType(DialogueWindow), findsOneWidget);
      expect(find.text('Misteryous voice'), findsOneWidget);
      expect(_visibleText(tester), '');
      expect(find.byKey(const ValueKey('dialogue-advance')), findsNothing);
      final menuRect = tester.getRect(
        find.byKey(const ValueKey('option-menu')),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('dialogue-box'))),
        menuRect,
      );
      expect(
        tester.getRect(find.text('Misteryous voice')).bottom,
        lessThan(menuRect.top),
      );

      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('player-portrait'))),
      );
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('player'))),
      );
      await tester.tapAt(tester.getCenter(find.byTooltip('Menu')));
      await tester.dragFrom(
        tester.getCenter(find.byType(DungeonBoard)),
        const Offset(200, 0),
      );
      await tester.binding.handlePopRoute();
      expect(_board(tester).isSelected, isFalse);
      expect(_board(tester).movementPath, isEmpty);
      expect(find.byType(DialogueWindow), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 49));
      expect(_visibleText(tester), '');
      expect(
        _dialogueOpacity(tester),
        closeTo(Curves.easeIn.transform(49 / 250), 0.000001),
      );
      await tester.pump(const Duration(milliseconds: 1));
      expect(_visibleText(tester), '.');
      await tester.pump(const Duration(milliseconds: 50));
      expect(_visibleText(tester), '..');
      await tester.pump(const Duration(milliseconds: 50));
      expect(_visibleText(tester), '...');
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.text('Close'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'All five texts advance in order and drag starts wobbling letter by letter',
    (tester) async {
      await _enterGame(tester);
      await tester.pump(OpeningTutorial.delay);
      await tester.pump(const Duration(milliseconds: 250));
      for (final line in OpeningTutorial.dialogue.lines.take(4)) {
        await _finishLine(tester, line);
        expect(_visibleText(tester), line.text);
        expect(find.text('Continue'), findsOneWidget);
        expect(find.text('Close'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('dialogue-advance')));
        await tester.pump();
        expect(_visibleText(tester), '');
      }

      final lastLine = OpeningTutorial.dialogue.lines.last;
      final prefix = lastLine.fragments.first.text;
      await tester.pump(
        TextSpeed.medium.letterInterval * prefix.characters.length,
      );
      expect(_visibleText(tester), prefix);
      expect(find.byType(WobblyLetter), findsNothing);
      await tester.pump(TextSpeed.slow.letterInterval);
      expect(find.byType(WobblyLetter), findsOneWidget);
      final wordState = tester.state(find.byType(WobblyWord));
      await tester.pump(TextSpeed.slow.letterInterval);
      expect(find.byType(WobblyLetter), findsNWidgets(2));
      expect(tester.state(find.byType(WobblyWord)), same(wordState));
      expect(_letterOffset(tester), isNot(0));
      await _finishLine(tester, lastLine);
      expect(_visibleText(tester), lastLine.text);
      expect(find.byType(WobblyLetter), findsNWidgets(4));
      expect(find.text('Continue'), findsNothing);
      expect(find.text('Close'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      final before = _letterOffset(tester);
      await tester.pump(const Duration(milliseconds: 225));
      expect(_letterOffset(tester), isNot(closeTo(before, 0.001)));

      await tester.tap(find.byKey(const ValueKey('dialogue-advance')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 125));
      expect(
        _dialogueOpacity(tester),
        closeTo(Curves.easeOut.transform(0.5), 0.000001),
      );
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('player-portrait'))),
      );
      expect(_board(tester).isSelected, isFalse);
      await tester.pump(const Duration(milliseconds: 125));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(find.byType(DialogueWindow), findsNothing);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const ValueKey('player-portrait')));
      await tester.pump();
      expect(_board(tester).isSelected, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Dialogue follows the menu when rotating and supports larger text',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await _enterGame(tester);
      await tester.pump(OpeningTutorial.delay);
      await tester.pump(const Duration(milliseconds: 250));
      for (final size in [const Size(320, 568), const Size(844, 390)]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pump();
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.byKey(const ValueKey('dialogue-box'))),
          tester.getRect(find.byKey(const ValueKey('option-menu'))),
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'A drag held through tutorial arrival is ignored and play unlocks after closing',
    (tester) async {
      await _enterGame(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DungeonBoard)),
      );
      await gesture.moveBy(const Offset(400, 0));
      await tester.pump(OpeningTutorial.delay);
      expect(find.byType(DialogueWindow), findsOneWidget);
      await gesture.moveBy(const Offset(-400, 0));
      await gesture.up();
      await tester.pump(const Duration(seconds: 2));
      expect(_board(tester).player, const GridPosition(7, 7));
      expect(_board(tester).movementPath, isEmpty);
      expect(_board(tester).isSelected, isFalse);
      await completeOpeningTutorial(tester);
      await tester.tap(find.byKey(const ValueKey('player')));
      await tester.pump();
      expect(_board(tester).isSelected, isTrue);
      await tester.drag(await movementPad(tester), const Offset(400, 0));
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(_board(tester).player.column, greaterThan(7));
      await tester.tap(find.byTooltip('Menu'));
      await tester.pump();
      expect(find.byType(GameMenuDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Disposing mid-sentence cancels both typing and wobbling', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DungeonTheme.dark,
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: DialogueWindow(
              sequence: const DialogueSequence(
                speaker: 'Voice',
                lines: [
                  DialogueLine([DialogueFragment('drag', wobbly: true)]),
                ],
              ),
              onClose: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(TextSpeed.slow.letterInterval);
    expect(find.byType(WobblyLetter), findsOneWidget);
    expect(find.text('Close'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Typewriter reveals whole Unicode characters and disposes its timer',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DungeonTheme.dark,
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: DialogueWindow(
                sequence: const DialogueSequence(
                  speaker: 'Voice',
                  lines: [
                    DialogueLine([DialogueFragment('A👋🏽é')]),
                  ],
                ),
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(TextSpeed.medium.letterInterval);
      expect(_visibleText(tester), 'A');
      await tester.pump(TextSpeed.medium.letterInterval);
      expect(_visibleText(tester), 'A👋🏽');
      expect(find.text('Close'), findsNothing);
      await tester.pump(TextSpeed.medium.letterInterval);
      expect(_visibleText(tester), 'A👋🏽é');
      expect(find.text('Close'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _enterGame(WidgetTester tester) async {
  await tester.pumpWidget(const DungeonCrawlerApp());
  await tester.tap(find.text('Start'));
  await tester.pump();
  while (find.byType(IrisMask).evaluate().isNotEmpty) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  await tester.pump();
}

Future<void> _finishLine(WidgetTester tester, DialogueLine line) =>
    tester.pump(TextSpeed.slow.letterInterval * line.text.characters.length);

String _visibleText(WidgetTester tester) => tester
    .widget<Semantics>(find.byKey(const ValueKey('dialogue-text')))
    .properties
    .label!;

DungeonBoard _board(WidgetTester tester) =>
    tester.widget<DungeonBoard>(find.byType(DungeonBoard));

double _letterOffset(WidgetTester tester) => tester
    .widget<Transform>(
      find.descendant(
        of: find.byType(WobblyLetter).first,
        matching: find.byType(Transform),
      ),
    )
    .transform
    .storage[13];

double _dialogueOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find
          .ancestor(
            of: find.byType(DialogueWindow),
            matching: find.byType(FadeTransition),
          )
          .first,
    )
    .opacity
    .value;
