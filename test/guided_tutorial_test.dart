import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/app/dungeon_theme.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_page.dart';
import 'package:duncrawl/features/dungeon/presentation/game_menu_dialog.dart';
import 'package:duncrawl/features/dungeon/presentation/opening_tutorial.dart';
import 'package:duncrawl/features/dungeon/presentation/selection_frame.dart';
import 'package:duncrawl/features/tutorial/presentation/tutorial_spotlight.dart';
import 'package:duncrawl/main.dart';

import 'helpers/dialogue_helpers.dart';

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets(
    'Main-menu background uses floor grey and the dungeon stays black',
    (tester) async {
      await tester.pumpWidget(const DungeonCrawlerApp());
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        DungeonColors.floorTile,
      );
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(
          tester.element(find.byType(DungeonBoard)),
        ).scaffoldBackgroundColor,
        DungeonColors.background,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Selection highlights reveal only the player and portrait', (
    tester,
  ) async {
    await _finishDialogue(tester);
    expect(find.byType(TutorialSpotlight), findsNothing);
    await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('player'))));
    await tester.tapAt(tester.getCenter(find.byTooltip('Menu')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_board(tester).isSelected, isFalse);
    expect(find.byType(TutorialSpotlight), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    final spotlight = _spotlight(tester);
    final player = _targetRect(tester, DungeonTutorialTarget.character);
    final portrait = _targetRect(tester, DungeonTutorialTarget.portrait);
    final path = _shade(tester);
    expect(path.contains(player.center), isFalse);
    expect(path.contains(portrait.center), isFalse);
    expect(path.contains(tester.getCenter(find.byTooltip('Menu'))), isTrue);
    expect(spotlight.specification.shadeOpacity, 0.5);
    expect(
      find.text('Select your character to allow movement'),
      findsOneWidget,
    );
    final hint = tester.getRect(find.byKey(const ValueKey('tutorial-hint')));
    expect(hint.center.dy, closeTo((portrait.bottom + player.top) / 2, 0.01));

    await tester.dragFrom(
      _gridRect(tester).topLeft + const Offset(10, 10),
      const Offset(80, 0),
    );
    await tester.tapAt(tester.getCenter(find.byTooltip('Menu')));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(_board(tester).isSelected, isFalse);
    expect(_board(tester).movementPath, isEmpty);
    expect(find.byType(GameMenuDialog), findsNothing);
    await tester.tap(find.byKey(const ValueKey('player-portrait')));
    await tester.pump();
    expect(_board(tester).isSelected, isTrue);
    expect(find.byType(TutorialSpotlight), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Grid selection, drag, pulsing Confirm, completed walk and stairs form one guide',
    (tester) async {
      await _finishDialogue(tester);
      await tester.pump(OpeningTutorial.stepDelay);
      await tester.tap(find.byKey(const ValueKey('player')));
      await tester.pump();
      expect(_board(tester).isSelected, isTrue);
      await tester.dragFrom(_gridRect(tester).center, const Offset(150, 0));
      await tester.tapAt(tester.getCenter(find.byTooltip('Menu')));
      await tester.pump(const Duration(milliseconds: 499));
      expect(_board(tester).movementPath, isEmpty);
      expect(find.byType(TutorialSpotlight), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        find.text('Now try dragging around to move the character'),
        findsOneWidget,
      );
      expect(
        _shade(tester).contains(_gridRect(tester).topLeft + const Offset(1, 1)),
        isFalse,
      );
      expect(
        _shade(tester).contains(
          tester.getCenter(find.byKey(const ValueKey('player-portrait'))),
        ),
        isTrue,
      );
      await tester.dragFrom(
        tester.getCenter(find.byKey(const ValueKey('option-menu'))),
        const Offset(100, 0),
      );
      await tester.pump();
      expect(_board(tester).movementPath, isEmpty);

      final stepDistance = _stepDistance(tester);
      final gesture = await tester.startGesture(_gridRect(tester).center);
      await gesture.moveBy(Offset(stepDistance * 2.01, 0));
      await tester.pump();
      expect(find.byType(TutorialSpotlight), findsNothing);
      expect(_board(tester).movementPath.length, 2);
      expect(_pulse(tester).selected, isTrue);
      final pulseBorder = find.descendant(
        of: find.byKey(const ValueKey('tutorial-confirm-pulse')),
        matching: find.byKey(const ValueKey('selection-border')),
      );
      final initialWidth = tester.getSize(pulseBorder).width;
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.getSize(pulseBorder).width, greaterThan(initialWidth));
      await gesture.moveBy(Offset(-stepDistance * 2.01, 0));
      await tester.pump();
      expect(_pulse(tester).selected, isFalse);
      await gesture.moveBy(Offset(stepDistance * 2.01, 0));
      await gesture.up();
      await tester.pump();
      expect(_pulse(tester).selected, isTrue);
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      expect(_pulse(tester).selected, isFalse);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_board(tester).player, const GridPosition(8, 7));
      expect(find.byType(TutorialSpotlight), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_board(tester).player, const GridPosition(9, 7));
      expect(find.text('Use the stairs to exit this floor'), findsOneWidget);
      expect(
        _shade(
          tester,
        ).contains(_targetRect(tester, DungeonTutorialTarget.stairs).center),
        isFalse,
      );
      expect(
        _shade(
          tester,
        ).contains(tester.getCenter(find.byKey(const ValueKey('player')))),
        isTrue,
      );
      await tester.tapAt(tester.getCenter(find.byTooltip('Menu')));
      await tester.pump();
      expect(find.byType(GameMenuDialog), findsNothing);
      await tester.tap(find.byKey(const ValueKey('close-tutorial')));
      await tester.pump();
      expect(find.byType(TutorialSpotlight), findsNothing);

      await tester.drag(
        find.byType(DungeonBoard),
        Offset(-stepDistance * 1.1, 0),
      );
      await tester.pump();
      expect(_pulse(tester).selected, isFalse);
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TutorialSpotlight), findsNothing);
      await tester.tap(find.byIcon(Icons.stairs_rounded));
      await tester.pump();
      expect(_board(tester).selectedTile, const GridPosition(7, 1));
      expect(_board(tester).isSelected, isFalse);
      expect(find.text('Upstairs'), findsOneWidget);
      expect(find.text('Stairs leading to a higher floor.'), findsOneWidget);
      expect(_board(tester).floor.number, 0);
      await tester.tap(find.byKey(const ValueKey('player-portrait')));
      await tester.pump();
      await tester.tap(find.byTooltip('Menu'));
      await tester.pump();
      expect(find.byType(GameMenuDialog), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Spotlights follow targets on rotation and hints fit with larger text',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await _finishDialogue(tester);
      await tester.pump(OpeningTutorial.stepDelay);
      for (final size in [const Size(320, 568), const Size(844, 390)]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pump();
        await tester.pump();
        expect(
          _shade(
            tester,
          ).contains(tester.getCenter(find.byKey(const ValueKey('player')))),
          isFalse,
        );
        expect(
          _shade(tester).contains(
            tester.getCenter(find.byKey(const ValueKey('player-portrait'))),
          ),
          isFalse,
        );
        final hint = tester.getRect(
          find.byKey(const ValueKey('tutorial-hint')),
        );
        expect(hint.top, greaterThanOrEqualTo(0));
        expect(hint.bottom, lessThanOrEqualTo(size.height));
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byKey(const ValueKey('player')));
      await tester.pump();
      await tester.pump(OpeningTutorial.stepDelay);
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pump();
      await tester.pump();
      expect(_shade(tester).contains(_gridRect(tester).center), isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

Future<void> _finishDialogue(WidgetTester tester) async {
  await tester.pumpWidget(const DungeonCrawlerApp());
  await tester.tap(find.text('Start'));
  await tester.pumpAndSettle();
  await completeOpeningDialogue(tester);
}

DungeonBoard _board(WidgetTester tester) =>
    tester.widget<DungeonBoard>(find.byType(DungeonBoard));
TutorialSpotlight _spotlight(WidgetTester tester) =>
    tester.widget<TutorialSpotlight>(find.byType(TutorialSpotlight));
Rect _gridRect(WidgetTester tester) =>
    tester.getRect(find.byType(DungeonBoard));

Rect _targetRect(WidgetTester tester, DungeonTutorialTarget target) =>
    tester.getRect(find.byKey(_spotlight(tester).anchors[target]!));

Path _shade(WidgetTester tester) =>
    (tester
                .widget<ClipPath>(find.byKey(const ValueKey('tutorial-shade')))
                .clipper
            as SpotlightClipper)
        .getClip(tester.getSize(find.byType(TutorialSpotlight)));

SelectionFrame _pulse(WidgetTester tester) => tester.widget<SelectionFrame>(
  find.byKey(const ValueKey('tutorial-confirm-pulse')),
);

double _stepDistance(WidgetTester tester) =>
    math.max(_gridRect(tester).width / DungeonFloor.size, 16) *
    tester
        .widget<DungeonPage>(find.byType(DungeonPage))
        .settings
        .value
        .dragDistanceMultiplier;
