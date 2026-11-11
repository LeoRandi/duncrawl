import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/settings/domain/text_speed.dart';
import 'package:duncrawl/features/dialogue/presentation/dialogue_window.dart';
import 'package:duncrawl/features/dungeon/presentation/floor_one_tutorial.dart';
import 'package:duncrawl/features/dungeon/presentation/opening_tutorial.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_page.dart';

Future<void> completeOpeningTutorial(WidgetTester tester) async {
  await completeOpeningDialogue(tester);
  await completeGuidedTutorial(tester);
}

Future<void> completeFloorOneTutorial(WidgetTester tester) async {
  if (find.byType(DialogueWindow).evaluate().isEmpty) {
    await tester.pump(FloorOneTutorial.delay);
  }
  await tester.pump(const Duration(milliseconds: 250));
  for (final _ in FloorOneTutorial.dialogue.lines) {
    await tester.tap(find.byKey(const ValueKey('dialogue-box')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('dialogue-advance')));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  final board = tester.getRect(find.byType(DungeonBoard));
  final tileSize = board.width / DungeonFloor.size;
  await tester.tapAt(board.topLeft + Offset(5.5 * tileSize, 6.5 * tileSize));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('close-tutorial')));
  await tester.pump();
  expect(find.byType(DialogueWindow), findsNothing);
  expect(find.byKey(const ValueKey('tutorial-spotlight')), findsNothing);
}

Future<void> completeOpeningDialogue(WidgetTester tester) async {
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

Future<void> completeGuidedTutorial(WidgetTester tester) async {
  await tester.pump(OpeningTutorial.stepDelay);
  await tester.tap(find.byKey(const ValueKey('player-portrait')));
  await tester.pump();
  await tester.pump(OpeningTutorial.stepDelay);
  final board = find.byType(DungeonBoard);
  final settings = tester
      .widget<DungeonPage>(find.byType(DungeonPage))
      .settings
      .value;
  final stepDistance =
      math.max(tester.getSize(board).width / DungeonFloor.size, 16) *
      settings.dragDistanceMultiplier;
  await tester.drag(board, Offset(stepDistance * 1.1, 0));
  await tester.pump();
  await tester.tap(find.text('Confirm'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.byKey(const ValueKey('close-tutorial')));
  await tester.pump();
  expect(find.byKey(const ValueKey('tutorial-spotlight')), findsNothing);

  // Las pruebas de juego posteriores parten de la misma casilla y sin selección.
  await tester.drag(board, Offset(-stepDistance * 1.1, 0));
  await tester.pump();
  await tester.tap(find.text('Confirm'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text('Unselect'));
  await tester.pump();
}
