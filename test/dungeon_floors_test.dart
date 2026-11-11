import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dialogue/presentation/dialogue_window.dart';
import 'package:duncrawl/features/dialogue/presentation/wobbly_word.dart';
import 'package:duncrawl/features/dungeon/domain/adventurer.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/domain/movement_plan.dart';
import 'package:duncrawl/features/dungeon/floors/dungeon_floors.dart';
import 'package:duncrawl/features/dungeon/floors/floor_0.dart';
import 'package:duncrawl/features/dungeon/floors/floor_1.dart';
import 'package:duncrawl/features/dungeon/floors/floor_2.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_controller.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_page.dart';
import 'package:duncrawl/features/dungeon/presentation/game_menu_dialog.dart';
import 'package:duncrawl/features/dungeon/presentation/floor_two_tutorial.dart';
import 'package:duncrawl/features/dungeon/presentation/opening_tutorial.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_strings.dart';
import 'package:duncrawl/features/tutorial/presentation/tutorial_spotlight.dart';
import 'package:duncrawl/main.dart';
import 'package:duncrawl/features/shards/domain/shard_progress.dart';
import 'package:duncrawl/features/shards/presentation/shard_scope.dart';
import 'package:duncrawl/features/shards/presentation/shard_colors.dart';
import 'package:duncrawl/features/shards/presentation/shard_reveal.dart';
import 'package:duncrawl/features/dungeon/presentation/tile_glyph.dart';
import 'package:duncrawl/features/dungeon/presentation/tile_area_outline.dart';
import 'package:duncrawl/widgets/iris_transition.dart';

import 'helpers/dialogue_helpers.dart';

void main() {
  for (final template in dungeonFloors.values) {
    test(
      'Floor ${template.number} has an impassable outer ring and any stairs are reachable',
      () {
        final floor = template.create();
        for (var row = 0; row < DungeonFloor.size; row++) {
          for (var column = 0; column < DungeonFloor.size; column++) {
            final position = GridPosition(column, row);
            final isEdge = row == 0 || column == 0 || row == 14 || column == 14;
            if (isEdge) {
              expect(floor.tileAt(position), DungeonTile.wall);
              expect(floor.canEnter(position), isFalse);
            }
          }
        }
        final dungeon = Dungeon.start(floor);
        for (final direction in DungeonDirection.values) {
          final end = dungeon.move(direction, steps: 100).player;
          expect(end.column, inInclusiveRange(1, 13));
          expect(end.row, inInclusiveRange(1, 13));
        }
        for (final stairs in floor.groundObjects.where(
          (object) => object.type == GroundObjectType.stairsUp,
        )) {
          expect(_routeTo(floor, stairs.position), isNotEmpty);
        }
      },
    );
  }

  test(
    'Floor 1 spawns bottom-right with stairs top-left and all linked destinations registered',
    () {
      final floor = floor1.create();
      expect(floor.spawn.column, greaterThan(7));
      expect(floor.spawn.row, greaterThan(7));
      expect(_stairs(floor).position.column, lessThan(7));
      expect(_stairs(floor).position.row, lessThan(7));
      for (final template in dungeonFloors.values) {
        final source = template.create();
        for (final object
            in source.groundObjects
                .whereType<InteractiveDungeonGroundObject>()) {
          var atObject = Dungeon.start(source);
          for (final step in _routeTo(source, object.position)) {
            atObject = atObject.stepTo(step);
          }
          final controller = DungeonController(atObject);
          final request = controller.pendingFloorChange;
          if (request != null) {
            expect(dungeonFloors.containsKey(request.floorNumber), isTrue);
          }
          controller.dispose();
        }
      }
    },
  );

  test(
    'Floor changes require an interaction request and preserve all character statistics',
    () {
      const adventurer = Adventurer(
        level: 4,
        health: 7,
        maximumHealth: 12,
        movementSpeed: 8,
      );
      final start = Dungeon.start(floor0.create(), adventurer: adventurer);
      final destination = floor1.create();
      final noInteraction = DungeonController(start);
      addTearDown(noInteraction.dispose);
      expect(noInteraction.completeFloorChange(destination), isFalse);
      final atStairs = start.move(DungeonDirection.north, steps: 6);
      final controller = DungeonController(atStairs);
      addTearDown(controller.dispose);
      expect(controller.completeFloorChange(floor0.create()), isFalse);
      expect(controller.completeFloorChange(destination), isTrue);
      final arrived = controller.dungeon;
      expect(arrived.floor.number, 1);
      expect(arrived.player, destination.spawn);
      expect(arrived.adventurer, same(adventurer));
      var atNextStairs = arrived;
      for (final step in _routeTo(destination, _stairs(destination).position)) {
        atNextStairs = atNextStairs.stepTo(step);
      }
      expect(atNextStairs.player, _stairs(destination).position);
      final nextController = DungeonController(atNextStairs);
      addTearDown(nextController.dispose);
      expect(nextController.pendingFloorChange?.floorNumber, 2);
      expect(nextController.completeFloorChange(floor0.create()), isFalse);
      final nextFloor = floor2.create();
      expect(nextController.completeFloorChange(nextFloor), isTrue);
      expect(nextController.dungeon.player, nextFloor.spawn);
      expect(nextController.dungeon.floor.number, 2);
      expect(nextController.dungeon.adventurer, same(adventurer));
    },
  );

  test(
    'Preview stops at linked stairs and can be retraced before confirming',
    () {
      final dungeon = Dungeon.start(
        floor0.create(),
      ).move(DungeonDirection.north, steps: 5);
      final plan = MovementPlan.start(
        dungeon,
      ).extend(DungeonDirection.north, steps: 5);
      expect(plan.path, [const GridPosition(7, 1)]);
      expect(plan.extend(DungeonDirection.east), same(plan));
      final retraced = plan.extend(DungeonDirection.south);
      expect(retraced.path, isEmpty);
      expect(
        retraced.extend(DungeonDirection.east).destination,
        const GridPosition(8, 2),
      );
    },
  );

  testWidgets(
    'Changing floors resets movement and selection while retaining unrelated locks',
    (tester) async {
      final controller = DungeonController(
        Dungeon.start(floor0.create()).move(DungeonDirection.north, steps: 5),
      );
      addTearDown(controller.dispose);
      final otherLock = Object();
      controller.selectCharacter();
      controller.beginDrag();
      controller.preview(DungeonDirection.north, steps: 5);
      controller.endDrag();
      controller.confirm();
      controller.disableBottomMenu(otherLock);
      expect(controller.completeFloorChange(floor1.create()), isFalse);
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.pendingFloorChange?.floorNumber, 1);
      controller.pause();
      expect(controller.completeFloorChange(floor1.create()), isTrue);
      expect(controller.plan.path, isEmpty);
      expect(controller.isSelected, isFalse);
      expect(controller.dungeon.player, floor1.create().spawn);
      expect(controller.alternateSelection, isNull);
      expect(controller.isInspectingBelow, isFalse);
      controller.resume();
      expect(controller.isBottomMenuEnabled, isFalse);
      controller.enableBottomMenu(otherLock);
      expect(controller.isBottomMenuEnabled, isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(controller.dungeon.player, floor1.create().spawn);
    },
  );

  testWidgets(
    'Adjacent wall tiles have no dividing lines in either direction',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.square(
              dimension: 300,
              child: DungeonBoard(
                floor: floor0.create(),
                player: const GridPosition(7, 7),
              ),
            ),
          ),
        ),
      );
      final paintWidget = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(const ValueKey(DungeonLayer.floorTiles)),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = paintWidget.painter;
      if (painter == null) {
        fail('The grid must have a painter.');
      }
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        painter.paint(Canvas(recorder), const Size(300, 300));
        final picture = recorder.endRecording();
        final image = picture.toImageSync(300, 300);
        try {
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          if (data == null) {
            fail('The rendered grid must provide pixel data.');
          }
          List<int> pixel(int x, int y) {
            final offset = (y * 300 + x) * 4;
            return List.generate(
              4,
              (channel) => data.getUint8(offset + channel),
            );
          }

          const wall = [96, 96, 96, 255];
          for (var edge = 20; edge < 300; edge += 20) {
            expect(pixel(edge, 10), wall);
            expect(pixel(edge, 290), wall);
            expect(pixel(10, edge), wall);
            expect(pixel(290, edge), wall);
          }
          expect(pixel(30, 30), [48, 48, 48, 255]);
          expect([
            pixel(39, 50),
            pixel(40, 50),
          ], contains(equals([0, 0, 0, 255])));
        } finally {
          image.dispose();
          picture.dispose();
        }
      });
    },
  );

  testWidgets('Stairs reach Floors 1 and 2 with their own arrival dialogues', (
    tester,
  ) async {
    await _reachStairs(tester);
    final center = tester.getCenter(find.byKey(const ValueKey('player')));
    expect(_board(tester).floor.number, 0);
    expect(_mask(tester).center, center);
    await tester.tapAt(tester.getCenter(find.byTooltip('Menu')));
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('player-portrait'))),
    );
    await tester.pump(const Duration(milliseconds: 1499));
    expect(_board(tester).floor.number, 0);
    expect(find.byType(GameMenuDialog), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(_board(tester).floor.number, 1);
    expect(_board(tester).player, floor1.create().spawn);
    expect(_mask(tester).aperture, closeTo(0, 0.001));
    expect(
      _mask(tester).center,
      tester.getCenter(find.byKey(const ValueKey('player'))),
    );
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('player-portrait'))),
    );
    await tester.pump();
    expect(_board(tester).isSelected, isFalse);
    await tester.pump(IrisTransition.phaseDuration);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.byType(IrisMask), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(DialogueWindow), findsOneWidget);
    await completeFloorOneTutorial(tester);
    final grid = tester.getRect(find.byType(DungeonBoard));
    final tile = grid.width / DungeonFloor.size;
    final stairs = _stairs(_board(tester).floor).position;
    expect(
      (tester.getCenter(find.byIcon(Icons.stairs_rounded)) -
              (grid.topLeft +
                  Offset(
                    tile * (stairs.column + 0.5),
                    tile * (stairs.row + 0.5),
                  )))
          .distance,
      lessThan(0.001),
    );
    await tester.tap(find.byKey(const ValueKey('player-portrait')));
    await tester.pump();
    await tester.drag(
      find.byType(DungeonBoard),
      Offset(_stepDistance(tester) * 3, 0),
    );
    await tester.pump();
    expect(
      _board(tester).movementPath.every(_board(tester).floor.canEnter),
      isTrue,
    );
    expect(_board(tester).movementPath.last.column, lessThan(14));
    final direction = DungeonDirection.values.firstWhere(
      (direction) => _board(
        tester,
      ).floor.canEnter(direction.stepFrom(_board(tester).player)),
    );
    await tester.drag(
      find.byType(DungeonBoard),
      Offset(
        direction.columnOffset * _stepDistance(tester) * 1.1,
        direction.rowOffset * _stepDistance(tester) * 1.1,
      ),
    );
    await tester.pump();
    expect(_board(tester).movementPath, [
      direction.stepFrom(_board(tester).player),
    ]);
    await _walkRoute(tester, _routeTo(_board(tester).floor, stairs));
    await tester.pumpAndSettle();
    expect(_board(tester).floor.number, 2);
    expect(_board(tester).player, floor2.create().spawn);
    expect(find.byType(DialogueWindow), findsNothing);
    await tester.tapAt(tester.getCenter(find.byTooltip('Menu')));
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('player-portrait'))),
    );
    await tester.pump();
    expect(_board(tester).isSelected, isFalse);
    expect(find.byType(GameMenuDialog), findsNothing);
    await tester.pump(FloorTwoTutorial.delay);
    expect(find.byType(DialogueWindow), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 250));
    final expectedLines = [
      'You are almost there, just one more floor...',
      '...Wait are those Bats? They keep getting into this floor, im not sure how.',
      '...Are you colorblind or something? Why is everything so gray?',
      "Hurry up, and don't get eaten!",
    ];
    for (var index = 0; index < expectedLines.length; index++) {
      await tester.tap(find.byKey(const ValueKey('dialogue-box')));
      await tester.pump();
      expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('dialogue-text')))
            .properties
            .label,
        expectedLines[index],
      );
      final animatedWord = switch (index) {
        1 => 'Bats',
        3 => 'eaten',
        _ => null,
      };
      if (animatedWord == null) {
        expect(find.byType(WobblyWord), findsNothing);
      } else {
        expect(
          tester.widget<WobblyWord>(find.byType(WobblyWord)).letters.join(),
          animatedWord,
        );
      }
      await tester.tap(find.byKey(const ValueKey('dialogue-advance')));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.byType(DialogueWindow), findsNothing);
    expect(find.byType(TutorialSpotlight), findsNothing);
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('player-portrait'))),
    );
    await tester.pump(const Duration(milliseconds: 499));
    expect(_board(tester).isSelected, isFalse);
    expect(find.byType(TutorialSpotlight), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    final batSpotlight = tester.widget<TutorialSpotlight>(
      find.byType(TutorialSpotlight),
    );
    expect(
      batSpotlight.specification.highlights.single.target,
      DungeonTutorialTarget.bat,
    );
    final batTarget = batSpotlight.anchors[DungeonTutorialTarget.bat];
    expect(batTarget, isNotNull);
    final batGrid = tester.getRect(find.byType(DungeonBoard));
    await tester.tapAt(batGrid.topLeft + const Offset(1, 1));
    await tester.pump();
    expect(_board(tester).selectedTile, isNull);
    await tester.tapAt(tester.getCenter(find.byKey(batTarget!)));
    await tester.pump();
    expect(
      tester
          .widget<TutorialSpotlight>(find.byType(TutorialSpotlight))
          .specification
          .highlights
          .single
          .target,
      DungeonTutorialTarget.menu,
    );
    expect(find.text('Bat'), findsOneWidget);
    expect(find.text(DungeonStrings.batDescription), findsOneWidget);
    expect(find.text('Lv. 1'), findsOneWidget);
    expect(find.text('HP 3/3'), findsOneWidget);
    expect(find.text('5(3)'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
    final selectedBat = _board(tester).selectedTile;
    await tester.tap(find.byKey(const ValueKey('movement-stat-info')));
    await tester.pump();
    expect(find.text(DungeonStrings.movementHelp), findsOneWidget);
    final popup = tester.getRect(find.byKey(const ValueKey('stat-info-popup')));
    expect(
      popup.bottom,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('movement-stat-info'))).dy,
      ),
    );
    await tester.tapAt(const Offset(4, 4));
    await tester.pump();
    expect(find.byKey(const ValueKey('stat-info-popup')), findsNothing);
    expect(_board(tester).selectedTile, selectedBat);
    expect(find.byType(TutorialSpotlight), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close-tutorial')));
    await tester.pump();
    expect(find.byType(TutorialSpotlight), findsNothing);
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('player-portrait'))),
    );
    await tester.pump(const Duration(milliseconds: 499));
    expect(_board(tester).isSelected, isFalse);
    expect(find.byType(DialogueWindow), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final shardLines = [
      'Gods, i really cannot see if those Bats are angry at you or not...',
      'Let me see if i can find this...',
      '...',
      "...Ah! Here it is, let's see if this works...",
    ];
    for (var index = 0; index < shardLines.length; index++) {
      await tester.tap(find.byKey(const ValueKey('dialogue-box')));
      await tester.pump();
      expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('dialogue-text')))
            .properties
            .label,
        shardLines[index],
      );
      if (index == 3) {
        expect(
          tester.widget<WobblyWord>(find.byType(WobblyWord)).letters.join(),
          'this',
        );
      }
      await tester.tap(find.byKey(const ValueKey('dialogue-advance')));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.byType(DialogueWindow), findsNothing);
    final shards = ShardScope.controllerOf(
      tester.element(find.byType(DungeonPage)),
    )!;
    expect(shards.value.unlocked, isEmpty);
    await tester.pump(const Duration(milliseconds: 99));
    expect(find.byType(ShardReveal), findsNothing);
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('player-portrait'))),
    );
    expect(_board(tester).isSelected, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.byType(ShardReveal), findsOneWidget);
    expect(
      tester.getCenter(find.byKey(const ValueKey('shard-reveal'))),
      tester.getSize(find.byType(Scaffold).first).center(Offset.zero),
    );
    expect(find.byIcon(Icons.star), findsOneWidget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 999));
    expect(shards.value.unlocked, isEmpty);
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('player-portrait'))),
    );
    expect(_board(tester).isSelected, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    await tester.pump();
    expect(find.byType(ShardReveal), findsNothing);
    expect(shards.value.unlocked, {ColorShard.red});
    final batGlyphs = tester
        .widgetList<TileGlyph>(find.byType(TileGlyph))
        .where((glyph) => glyph.symbol == 'B');
    expect(
      batGlyphs.every((glyph) => glyph.color == ShardColors.bat.unlocked),
      isTrue,
    );
    expect(
      tester.widget<TileAreaOutline>(find.byType(TileAreaOutline)).color,
      ShardColors.vision.unlocked,
    );
    await tester.tap(find.byKey(const ValueKey('player-portrait')));
    await tester.pump();
    expect(_board(tester).isSelected, isTrue);
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    final menuButton = find.widgetWithText(OutlinedButton, 'Main menu');
    final button = tester.widget<OutlinedButton>(menuButton);
    expect(
      button.style?.foregroundColor?.resolve({}),
      ShardColors.mainMenu.unlocked,
    );
    await tester.tap(menuButton);
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
    expect(shards.value.unlocked, {ColorShard.red});
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Disposal during a floor transition cancels its animation safely',
    (tester) async {
      await _reachStairs(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _reachStairs(WidgetTester tester) async {
  await tester.pumpWidget(const DungeonCrawlerApp());
  await tester.tap(find.text('Start'));
  await tester.pumpAndSettle();
  await completeOpeningTutorial(tester);
  await tester.tap(find.byKey(const ValueKey('player-portrait')));
  await tester.pump();
  await tester.drag(
    find.byType(DungeonBoard),
    Offset(0, -_stepDistance(tester) * 5.1),
  );
  await tester.pump();
  await tester.tap(find.text('Confirm'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1500));
  expect(_board(tester).player, const GridPosition(7, 2));
  await tester.drag(
    find.byType(DungeonBoard),
    Offset(0, -_stepDistance(tester) * 4),
  );
  await tester.pump();
  expect(_board(tester).movementPath, [const GridPosition(7, 1)]);
  await tester.tap(find.text('Confirm'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
  expect(find.byType(IrisMask), findsOneWidget);
}

DungeonBoard _board(WidgetTester tester) =>
    tester.widget<DungeonBoard>(find.byType(DungeonBoard));

Future<void> _walkRoute(WidgetTester tester, List<GridPosition> route) async {
  for (final next in route) {
    final current = _board(tester).player;
    await tester.drag(
      find.byType(DungeonBoard),
      Offset(
        (next.column - current.column) * _stepDistance(tester) * 1.1,
        (next.row - current.row) * _stepDistance(tester) * 1.1,
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }
}

DungeonGroundObject _stairs(DungeonFloor floor) => floor.groundObjects
    .singleWhere((object) => object.type == GroundObjectType.stairsUp);

List<GridPosition> _routeTo(DungeonFloor floor, GridPosition target) {
  final paths = <GridPosition, List<GridPosition>>{floor.spawn: []};
  final queue = [floor.spawn];
  for (var index = 0; index < queue.length; index++) {
    final current = queue[index];
    final path = paths[current] ?? [];
    if (current == target) {
      return path;
    }
    for (final direction in DungeonDirection.values) {
      final next = direction.stepFrom(current);
      if (floor.canEnter(next) && !paths.containsKey(next)) {
        paths[next] = [...path, next];
        queue.add(next);
      }
    }
  }
  fail('Every staircase must be reachable from the floor spawn.');
}

IrisMask _mask(WidgetTester tester) =>
    tester.widget<IrisMask>(find.byType(IrisMask));
double _stepDistance(WidgetTester tester) =>
    math.max(
      tester.getSize(find.byType(DungeonBoard)).width / DungeonFloor.size,
      16,
    ) *
    tester
        .widget<DungeonPage>(find.byType(DungeonPage))
        .settings
        .value
        .dragDistanceMultiplier;
