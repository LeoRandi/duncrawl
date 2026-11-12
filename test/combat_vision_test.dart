import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/adventurer.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_visibility.dart';
import 'package:duncrawl/features/dungeon/domain/game_command.dart';
import 'package:duncrawl/features/dungeon/domain/game_rules.dart';
import 'package:duncrawl/features/dungeon/domain/game_state.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/domain/tile_inspection.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/tile_area_outline.dart';
import 'package:duncrawl/features/shards/presentation/shard_colors.dart';

import 'support/combat_fixture.dart';

void main() {
  const rules = GameRules();

  testWidgets(
    'Every combatant has a red sight outline without selecting it or unlocking red',
    (tester) async {
      final dungeon = combatFixture(
        enemies: [const GridPosition(8, 7), const GridPosition(12, 7)],
      );
      final state = rules.refresh(GameState(dungeon: dungeon)).state;
      await tester.pumpWidget(_VisionBoard(state: state));
      expect(find.byType(TileAreaOutline), findsNWidgets(2));
      for (final enemy in dungeon.floor.enemies) {
        final outline = tester.widget<TileAreaOutline>(
          find.byKey(ValueKey(('combat-vision', enemy.id))),
        );
        expect(outline.color, ShardColors.vision.unlocked);
        expect(
          outline.tiles,
          DungeonVisibility.visibleArea(dungeon.floor, enemy),
        );
        expect(outline.pulseDuration, const Duration(seconds: 6));
      }
      final first = dungeon.floor.enemies.first;
      final key = ValueKey(('combat-vision', first.id));
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
    },
  );

  testWidgets('Combat sight has a slow twelve-second breathing cycle', (
    tester,
  ) async {
    final state = rules.refresh(GameState(dungeon: combatFixture())).state;
    await tester.pumpWidget(_VisionBoard(state: state));
    final outline = find.byKey(
      ValueKey(('combat-vision', state.encounter!.enemyIds.single)),
    );
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
      findsOneWidget,
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
      final survivorKey = ValueKey(('combat-vision', survivor.id));
      final survivorElement = tester.element(find.byKey(survivorKey));
      state = rules
          .resolve(
            state,
            AttackActor(actorId: dungeon.adventurer.id, targetId: victim.id),
          )
          .state;
      await tester.pumpWidget(_VisionBoard(state: state));
      expect(find.byKey(ValueKey(('combat-vision', victim.id))), findsNothing);
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
        DungeonVisibility.visibleArea(state.dungeon.floor, moved),
      );
      state = rules
          .refresh(state.withDungeon(state.dungeon.removeEnemy(survivor.id)))
          .state;
      await tester.pumpWidget(_VisionBoard(state: state));
      expect(find.byType(TileAreaOutline), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

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
