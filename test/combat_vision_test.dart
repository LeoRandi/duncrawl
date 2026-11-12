import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/adventurer.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_visibility.dart';
import 'package:duncrawl/features/dungeon/domain/game_command.dart';
import 'package:duncrawl/features/dungeon/domain/game_rules.dart';
import 'package:duncrawl/features/dungeon/domain/game_state.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_enemy.dart';
import 'package:duncrawl/features/dungeon/domain/tile_inspection.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/tile_area_outline.dart';
import 'package:duncrawl/features/shards/presentation/shard_colors.dart';
import 'package:duncrawl/features/shards/domain/shard_progress.dart';
import 'package:duncrawl/features/shards/presentation/shard_scope.dart';

import 'support/combat_fixture.dart';

void main() {
  const rules = GameRules();

  testWidgets('Combatants share one movement outline and one alert outline', (
    tester,
  ) async {
    final dungeon = combatFixture(
      enemies: [const GridPosition(8, 7), const GridPosition(12, 7)],
    );
    final state = rules.refresh(GameState(dungeon: dungeon)).state;
    await tester.pumpWidget(_VisionBoard(state: state));
    expect(find.byType(TileAreaOutline), findsNWidgets(2));
    final outline = _outline(tester, 'combat-movement');
    final movement = {
      for (final enemy in dungeon.floor.enemies)
        ...enemy.movementArea.where(dungeon.floor.contains),
    };
    expect(outline.tiles, movement);
    expect(outline.color, ShardColors.vision.unlocked);
    expect(outline.pulseDuration, const Duration(seconds: 6));
    expect(_outline(tester, 'enemy-alert').tiles, {
      for (final enemy in dungeon.floor.enemies)
        ...enemy.alertArea.where(dungeon.floor.contains),
    });
    await tester.runAsync(() async {
      for (final range in ['combat-movement', 'enemy-alert']) {
        final painter = tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byKey(ValueKey(range)),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!;
        final recorder = ui.PictureRecorder();
        painter.paint(Canvas(recorder), const Size(300, 300));
        final picture = recorder.endRecording();
        final image = await picture.toImage(300, 300);
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        // El borde del primer enemigo cae dentro del área del segundo.
        final insideX = range == 'combat-movement' ? 220 : 260;
        final outsideY = range == 'combat-movement' ? 100 : 60;
        expect(pixels.getUint8((150 * 300 + insideX) * 4 + 3), 0);
        expect(pixels.getUint8((outsideY * 300 + 170) * 4 + 3), greaterThan(0));
        image.dispose();
        picture.dispose();
      }
    });
    final first = dungeon.floor.enemies.first;
    const key = ValueKey('combat-movement');
    final element = tester.element(find.byKey(key));
    await tester.pumpWidget(
      _VisionBoard(
        state: state,
        selection: dungeon.floor.inspectTile(first.position),
      ),
    );
    expect(find.byType(TileAreaOutline), findsNWidgets(2));
    expect(find.byKey(const ValueKey('enemy-vision')), findsNothing);
    expect(tester.element(find.byKey(key)), same(element));
    await tester.pumpWidget(_VisionBoard(state: state));
    expect(find.byType(TileAreaOutline), findsNWidgets(2));
    expect(tester.element(find.byKey(key)), same(element));
  });

  testWidgets('Combat movement has a slow twelve-second breathing cycle', (
    tester,
  ) async {
    final state = rules.refresh(GameState(dungeon: combatFixture())).state;
    await tester.pumpWidget(_VisionBoard(state: state));
    final outline = find.byKey(const ValueKey('combat-movement'));
    final painter =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: outline,
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as TileAreaOutlinePainter;
    expect(painter.pulse.value, 0);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(painter.pulse.value, closeTo(0.25, 0.01));
    await tester.pump(const Duration(milliseconds: 4500));
    expect(painter.pulse.value, closeTo(1, 0.01));
    await tester.pump(const Duration(seconds: 6));
    expect(painter.pulse.value, closeTo(0, 0.01));
    expect(
      find.byWidgetPredicate((widget) => widget is TileAreaOutline),
      findsNWidgets(2),
    );
  });

  testWidgets(
    'Outlines follow living participants and disappear when combat ends',
    (tester) async {
      final dungeon = combatFixture(
        adventurer: const Adventurer(strength: 3),
        enemies: [const GridPosition(8, 7), const GridPosition(12, 7)],
      );
      var state = rules.refresh(GameState(dungeon: dungeon)).state;
      await tester.pumpWidget(_VisionBoard(state: state));
      final victim = dungeon.floor.enemies.first;
      final survivor = dungeon.floor.enemies.last;
      const survivorKey = ValueKey('combat-movement');
      final survivorElement = tester.element(find.byKey(survivorKey));
      state = rules
          .resolve(
            state,
            AttackActor(actorId: dungeon.adventurer.id, targetId: victim.id),
          )
          .state;
      await tester.pumpWidget(_VisionBoard(state: state));
      expect(
        _outline(tester, 'combat-movement').tiles,
        survivor.movementArea.where(state.dungeon.floor.contains).toSet(),
      );
      expect(tester.element(find.byKey(survivorKey)), same(survivorElement));
      state = rules
          .refresh(
            state.withDungeon(
              state.dungeon.withEnemy(
                survivor.copyWith(position: const GridPosition(12, 6)),
              ),
            ),
          )
          .state;
      await tester.pumpWidget(_VisionBoard(state: state));
      expect(tester.element(find.byKey(survivorKey)), same(survivorElement));
      final moved = state.dungeon.floor.enemies.single;
      expect(
        tester.widget<TileAreaOutline>(find.byKey(survivorKey)).tiles,
        moved.movementArea.where(state.dungeon.floor.contains).toSet(),
      );
      state = rules
          .refresh(state.withDungeon(state.dungeon.removeEnemy(survivor.id)))
          .state;
      await tester.pumpWidget(_VisionBoard(state: state));
      expect(find.byType(TileAreaOutline), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Movement preview ignores terrain and uses full combat speed', (
    tester,
  ) async {
    final dungeon = combatFixture(
      enemies: [const GridPosition(8, 7)],
      walls: {const GridPosition(9, 7)},
      water: {const GridPosition(8, 8)},
    );
    var state = rules.refresh(GameState(dungeon: dungeon)).state;
    await tester.pumpWidget(_VisionBoard(state: state));
    final tiles = _outline(tester, 'combat-movement').tiles;
    expect(
      tiles,
      containsAll([
        const GridPosition(9, 7),
        const GridPosition(10, 7),
        const GridPosition(8, 8),
      ]),
    );
    expect(tiles, isNot(contains(const GridPosition(11, 7))));
    state = rules
        .resolve(
          state,
          MoveActor(
            actorId: dungeon.adventurer.id,
            destination: const GridPosition(6, 7),
          ),
        )
        .state;
    await tester.pumpWidget(_VisionBoard(state: state));
    expect(_outline(tester, 'combat-movement').tiles, tiles);
  });

  testWidgets(
    'Alert uses its own orange shard and selection controls exploration ranges',
    (tester) async {
      final shards = ShardController();
      addTearDown(shards.dispose);
      final dungeon = combatFixture(enemies: [const GridPosition(12, 7)]);
      final enemy = dungeon.floor.enemies.single;
      final state = GameState(dungeon: dungeon);
      final selection = dungeon.floor.inspectTile(enemy.position);
      await tester.pumpWidget(
        ShardScope(
          controller: shards,
          child: _VisionBoard(state: state, selection: selection),
        ),
      );
      expect(_outline(tester, 'enemy-alert').color, ShardColors.alert.grey);
      expect(
        _outline(tester, 'enemy-alert').tiles,
        enemy.alertArea.where(dungeon.floor.contains).toSet(),
      );
      expect(
        _outline(tester, 'enemy-vision').tiles,
        DungeonVisibility.visibleArea(dungeon.floor, enemy),
      );
      expect(find.byKey(const ValueKey('combat-movement')), findsNothing);
      shards.unlock(ColorShard.red);
      await tester.pump();
      expect(_outline(tester, 'enemy-alert').color, ShardColors.alert.grey);
      expect(
        _outline(tester, 'enemy-vision').color,
        ShardColors.vision.unlocked,
      );
      shards.unlock(ColorShard.orange);
      await tester.pump();
      expect(_outline(tester, 'enemy-alert').color, ShardColors.alert.unlocked);
      await tester.pumpWidget(
        ShardScope(
          controller: shards,
          child: _VisionBoard(state: state),
        ),
      );
      expect(find.byType(TileAreaOutline), findsNothing);
    },
  );

  test(
    'Range radii follow stats, including zero speed and explicit alerts',
    () {
      const enemy = DungeonEnemy.bat(GridPosition(1, 1), id: 'bat');
      expect(enemy.alertArea, hasLength(41));
      expect(enemy.movementSpeed, 4);
      expect(enemy.combatMovementSpeed, 2);
      expect(enemy.movementArea, hasLength(13));
      expect(
        enemy.copyWith(visionRadius: 3).alertArea,
        contains(const GridPosition(7, 1)),
      );
      expect(enemy.copyWith(alertRadius: 1).alertArea, hasLength(5));
      expect(enemy.copyWith(movementSpeed: 0).movementArea, {enemy.position});
      expect(
        enemy.copyWith(movementSpeed: 6).movementArea,
        contains(const GridPosition(5, 1)),
      );
    },
  );
}

TileAreaOutline _outline(WidgetTester tester, String key) =>
    tester.widget<TileAreaOutline>(find.byKey(ValueKey(key)));

class _VisionBoard extends StatelessWidget {
  final GameState state;
  final TileInspection? selection;

  const _VisionBoard({required this.state, this.selection});

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: SizedBox.square(
        dimension: 300,
        child: DungeonBoard(
          floor: state.dungeon.floor,
          player: state.dungeon.player,
          selectedInspection: selection,
          engagedEnemyIds: state.encounter?.enemyIds.toSet() ?? const {},
        ),
      ),
    ),
  );
}
