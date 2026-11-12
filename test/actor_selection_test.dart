import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/domain/tile_inspection.dart';
import 'package:duncrawl/features/dungeon/floors/floor_0.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_controller.dart';
import 'package:duncrawl/features/dungeon/presentation/movement_menu.dart';
import 'package:duncrawl/features/dungeon/presentation/tile_inspection_view.dart';

void main() {
  test(
    'Inspection identity follows an actor across stat, tile and position changes',
    () {
      final dungeon = Dungeon.start(_floor());
      final bat = dungeon.floor.enemies.first;
      final before = dungeon.floor.inspectTile(bat.position);
      final after = TileInspection(
        position: const GridPosition(4, 7),
        tile: DungeonTile.water,
        enemy: bat.copyWith(position: const GridPosition(4, 7), health: 1),
      );
      expect(before?.hasSameTarget(after), isTrue);
      expect(
        after.hasSameTarget(dungeon.selectionStackAt(dungeon.player).single),
        isFalse,
      );
      expect(
        after.hasSameTarget(
          TileInspection(
            position: after.position,
            tile: after.tile,
            enemy: dungeon.floor.enemies.last.copyWith(
              position: after.position,
            ),
          ),
        ),
        isFalse,
      );
    },
  );

  test(
    'A selected enemy follows its ID and refreshes the contents beneath it',
    () {
      final effect = InteractiveDungeonGroundObject(
        type: GroundObjectType.grass,
        position: const GridPosition(5, 7),
        onInteract: (context) {
          final bat = context.dungeon.floor.enemies.first;
          context.updateDungeon(
            context.dungeon.withEnemy(
              bat.copyWith(position: const GridPosition(4, 7), health: 1),
            ),
          );
        },
      );
      final controller = DungeonController(
        Dungeon.start(_floor(effect: effect)),
      );
      addTearDown(controller.dispose);
      controller.selectTile(const GridPosition(5, 7));
      final batId = controller.inspectedTile?.actorId;
      expect(controller.alternateSelection?.object, same(effect));

      expect(controller.interactWith(effect), isTrue);
      expect(controller.inspectedTile?.actorId, batId);
      expect(controller.inspectedTile?.enemy?.health, 1);
      expect(controller.selectedPosition, const GridPosition(4, 7));
      expect(controller.selectionStack, hasLength(1));
      expect(controller.alternateSelections, isEmpty);
      expect(controller.isInspectingBelow, isFalse);
    },
  );

  test(
    'Removing a selected actor clears selection even if another takes its tile',
    () {
      final effect = InteractiveDungeonGroundObject(
        type: GroundObjectType.grass,
        position: const GridPosition(5, 7),
        onInteract: (context) {
          final enemies = context.dungeon.floor.enemies;
          context.updateDungeon(
            context.dungeon
                .removeEnemy(enemies.first.id)
                .withEnemy(
                  enemies.last.copyWith(position: enemies.first.position),
                ),
          );
        },
      );
      final controller = DungeonController(
        Dungeon.start(_floor(effect: effect)),
      );
      addTearDown(controller.dispose);
      controller.selectTile(const GridPosition(5, 7));
      expect(controller.interactWith(effect), isTrue);
      expect(controller.selectedInspection, isNull);
      expect(controller.selectionStack, isEmpty);
      expect(controller.alternateSelections, isEmpty);
      expect(controller.dungeon.actorAt(const GridPosition(5, 7)), isNotNull);
    },
  );

  testWidgets(
    'Updating a selected enemy refreshes stats without replacing its panel',
    (tester) async {
      final effect = InteractiveDungeonGroundObject(
        type: GroundObjectType.grass,
        position: const GridPosition(5, 7),
        onInteract: (context) {
          final bat = context.dungeon.floor.enemies.first;
          context.updateDungeon(
            context.dungeon.withEnemy(bat.copyWith(health: 1)),
          );
        },
      );
      final controller = DungeonController(
        Dungeon.start(_floor(effect: effect)),
      );
      addTearDown(controller.dispose);
      controller.selectTile(const GridPosition(5, 7));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, child) => MovementMenu(controller: controller),
            ),
          ),
        ),
      );
      final panel = tester.element(find.byType(TileInspectionView));
      expect(find.text('HP 3/3'), findsOneWidget);
      controller.interactWith(effect);
      await tester.pump();
      expect(find.text('HP 1/3'), findsOneWidget);
      expect(tester.element(find.byType(TileInspectionView)), same(panel));
    },
  );

  for (final useAnchor in [false, true]) {
    testWidgets(
      'Enemy widget identity survives movement (tutorial anchor: $useAnchor)',
      (tester) async {
        final initial = Dungeon.start(_floor());
        final bat = initial.floor.enemies.first;
        final selection = initial.floor.inspectTile(bat.position);
        final state = ValueNotifier(initial);
        addTearDown(state.dispose);
        final anchor = GlobalKey();
        final Key key = useAnchor ? anchor : ValueKey(('enemy', bat.id));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox.square(
                dimension: 300,
                child: ValueListenableBuilder<Dungeon>(
                  valueListenable: state,
                  builder: (context, dungeon, child) => DungeonBoard(
                    floor: dungeon.floor,
                    player: dungeon.player,
                    selectedInspection: selection,
                    enemyAnchorKeys: {if (useAnchor) bat.id: anchor},
                  ),
                ),
              ),
            ),
          ),
        );
        final element = tester.element(find.byKey(key));
        final before = tester.getTopLeft(find.byKey(key));
        state.value = initial.stepActorTo(
          actorId: bat.id,
          destination: const GridPosition(4, 7),
        );
        await tester.pump();
        expect(tester.element(find.byKey(key)), same(element));
        expect(tester.getTopLeft(find.byKey(key)).dx, lessThan(before.dx));
        final semantics = tester.widget<Semantics>(
          find
              .descendant(of: find.byKey(key), matching: find.byType(Semantics))
              .first,
        );
        expect(semantics.properties.selected, isTrue);
      },
    );
  }
}

DungeonFloor _floor({DungeonGroundObject? effect}) {
  final rows = [...floor0.rows]..[7] = '#....1.@..2...#';
  var floor = DungeonFloorTemplate(
    number: 9,
    rows: rows,
    groundObjects: [if (effect != null) effect],
  ).create();
  for (final enemy in floor.enemies) {
    floor = floor.withEnemy(enemy.copyWith(visionRadius: 0));
  }
  return floor;
}
