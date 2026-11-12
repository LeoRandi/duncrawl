import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dialogue/presentation/dialogue_window.dart';
import 'package:duncrawl/features/dialogue/presentation/wobbly_letter.dart';
import 'package:duncrawl/features/dialogue/presentation/wobbly_word.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_page.dart';
import 'package:duncrawl/features/dungeon/presentation/floor_one_tutorial.dart';
import 'package:duncrawl/features/dungeon/presentation/game_menu_dialog.dart';
import 'package:duncrawl/features/dungeon/presentation/opening_tutorial.dart';
import 'package:duncrawl/features/settings/domain/text_speed.dart';
import 'package:duncrawl/features/tutorial/presentation/tutorial_spotlight.dart';
import 'package:duncrawl/main.dart';
import 'package:duncrawl/widgets/iris_transition.dart';

import 'helpers/dialogue_helpers.dart';

void main() {
  testWidgets(
    'Floor 1 blocks its delays, shows the voice and teaches tile details',
    (tester) async {
      await _arriveOnFloorOne(tester);
      final spawn = _board(tester).player;
      expect(find.byType(DialogueWindow), findsNothing);
      await _tryBlockedControls(tester);
      await tester.pump(const Duration(milliseconds: 498));
      expect(find.byType(DialogueWindow), findsNothing);
      await tester.pump(const Duration(milliseconds: 2));
      expect(find.byType(DialogueWindow), findsOneWidget);
      expect(find.text('Misteryous voice'), findsOneWidget);
      expect(
        _visibleText(tester),
        'Great, just a couple more floors, you are almost here!',
      );
      await tester.pump(const Duration(milliseconds: 250));
      await _tryBlockedControls(tester);
      expect(_board(tester).player, spawn);
      expect(_board(tester).selectedTile, isNull);
      await tester.tap(find.byKey(const ValueKey('dialogue-advance')));
      await tester.pump();
      expect(
        _visibleText(tester),
        '...Wait, why are there letters on the floor?',
      );
      final words = tester.widgetList<WobblyWord>(find.byType(WobblyWord));
      expect(
        words.map((word) => word.letters.join()).join(' '),
        'letters on the floor',
      );
      final letters = tester
          .widgetList<WobblyLetter>(find.byType(WobblyLetter))
          .toList();
      expect(
        letters.map((letter) => letter.phaseOffset).toSet().length,
        letters.length,
      );
      expect(
        FloorOneTutorial.dialogue.lines.last.fragments
            .where((fragment) => fragment.wobbly)
            .single
            .text,
        'letters on the floor',
      );

      await tester.tap(find.byKey(const ValueKey('dialogue-advance')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(find.byType(DialogueWindow), findsNothing);
      await _tryBlockedControls(tester);
      await tester.pump(const Duration(milliseconds: 498));
      expect(find.byType(TutorialSpotlight), findsNothing);
      await tester.pump(const Duration(milliseconds: 2));
      expect(
        _spotlight(tester).specification.highlights.single.target,
        DungeonTutorialTarget.grid,
      );
      await _tapTile(tester, const GridPosition(6, 10));
      expect(_board(tester).selectedTile, isNull);
      expect(
        _spotlight(tester).specification.highlights.single.target,
        DungeonTutorialTarget.grid,
      );
      await _tapTile(tester, const GridPosition(5, 6));
      expect(_board(tester).selectedTile, const GridPosition(5, 6));
      expect(
        _spotlight(tester).specification.highlights.single.target,
        DungeonTutorialTarget.menu,
      );
      expect(find.byKey(const ValueKey('selection-name')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('selection-description')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('selection-portrait')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('close-tutorial')));
      await tester.pump();
      expect(find.byType(TutorialSpotlight), findsNothing);
      await _tapTile(tester, const GridPosition(6, 10));
      expect(_board(tester).selectedTile, isNull);
      await tester.tap(find.byKey(const ValueKey('player-portrait')));
      await tester.pump();
      expect(_board(tester).isSelected, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Skip tutorials bypasses the Floor 1 dialogue and spotlights', (
    tester,
  ) async {
    await _arriveOnFloorOne(tester, skipTutorials: true);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(DialogueWindow), findsNothing);
    expect(find.byType(TutorialSpotlight), findsNothing);
    await tester.tap(find.byKey(const ValueKey('player-portrait')));
    await tester.pump();
    expect(_board(tester).isSelected, isTrue);
    await _tapTile(tester, const GridPosition(5, 6));
    expect(_board(tester).selectedTile, const GridPosition(5, 6));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Disposal during the Floor 1 dialogue delay cancels pending work',
    (tester) async {
      await _arriveOnFloorOne(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Floor 1 dialogue and detail hints fit portrait and landscape with larger text',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final size in [const Size(320, 568), const Size(844, 390)]) {
        await tester.binding.setSurfaceSize(size);
        await _arriveOnFloorOne(tester);
        await tester.pump(FloorOneTutorial.delay);
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.byKey(const ValueKey('dialogue-advance')));
        await tester.pump();
        expect(find.byType(WobblyWord), findsNWidgets(4));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('dialogue-advance')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();
        await tester.pump(FloorOneTutorial.stepDelay);
        await _tapTile(tester, const GridPosition(5, 6));
        final hint = tester.getRect(
          find.byKey(const ValueKey('tutorial-hint')),
        );
        final panel = tester.getRect(find.byKey(const ValueKey('option-menu')));
        expect(hint.overlaps(panel), isFalse);
        expect(
          find.byKey(const ValueKey('selection-description')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('close-tutorial')));
        await tester.pump();
        expect(find.byType(TutorialSpotlight), findsNothing);
        await _tapTile(tester, const GridPosition(6, 10));
        expect(_board(tester).selectedTile, isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
}

Future<void> _arriveOnFloorOne(
  WidgetTester tester, {
  bool skipTutorials = false,
}) async {
  await tester.pumpWidget(const DungeonCrawlerApp());
  await tester.tap(find.text('Start'));
  await tester.pumpAndSettle();
  await completeOpeningTutorial(tester);
  final settings = tester
      .widget<DungeonPage>(find.byType(DungeonPage))
      .settings;
  settings.value = settings.value.copyWith(
    textSpeed: TextSpeed.instant,
    skipTutorials: skipTutorials,
  );
  await tester.tap(find.byKey(const ValueKey('player-portrait')));
  await tester.pump();
  await _walkNorth(tester, 5);
  await _walkNorth(tester, 1);
  expect(find.byType(IrisMask), findsOneWidget);
  await tester.pump(IrisTransition.phaseDuration);
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump();
  await tester.pump(IrisTransition.phaseDuration);
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump();
  expect(find.byType(IrisMask), findsNothing);
  expect(_board(tester).floor.number, 1);
}

Future<void> _walkNorth(WidgetTester tester, int steps) async {
  final board = find.byType(DungeonBoard);
  final tileSize = math.max(
    tester.getSize(board).width / DungeonFloor.size,
    16,
  );
  final settings = tester
      .widget<DungeonPage>(find.byType(DungeonPage))
      .settings
      .value;
  await tester.drag(
    await movementPad(tester),
    Offset(0, -tileSize * settings.dragDistanceMultiplier * (steps + 0.1)),
  );
  await tester.pump();
  await tester.tap(find.text('Confirm'));
  await tester.pump();
  await tester.pump(settings.movementSpeed.stepInterval * steps);
  await tester.pump();
}

Future<void> _tryBlockedControls(WidgetTester tester) async {
  await tester.tapAt(
    tester.getCenter(find.byKey(const ValueKey('player-portrait'))),
  );
  await tester.tapAt(tester.getCenter(find.byTooltip('Menu')));
  await _tapTile(tester, const GridPosition(5, 6));
  await tester.binding.handlePopRoute();
  await tester.pump();
  expect(_board(tester).isSelected, isFalse);
  expect(_board(tester).selectedTile, isNull);
  expect(_board(tester).movementPath, isEmpty);
  expect(find.byType(GameMenuDialog), findsNothing);
  expect(find.byType(IrisMask), findsNothing);
}

Future<void> _tapTile(WidgetTester tester, GridPosition position) async {
  final grid = tester.getRect(find.byType(DungeonBoard));
  final tileSize = grid.width / DungeonFloor.size;
  await tester.tapAt(
    grid.topLeft +
        Offset(
          (position.column + 0.5) * tileSize,
          (position.row + 0.5) * tileSize,
        ),
  );
  await tester.pump();
}

DungeonBoard _board(WidgetTester tester) =>
    tester.widget<DungeonBoard>(find.byType(DungeonBoard));
TutorialSpotlight _spotlight(WidgetTester tester) =>
    tester.widget<TutorialSpotlight>(find.byType(TutorialSpotlight));
String _visibleText(WidgetTester tester) => tester
    .widget<Semantics>(find.byKey(const ValueKey('dialogue-text')))
    .properties
    .label!;
