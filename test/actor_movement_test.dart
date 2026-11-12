import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/adventurer.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/domain/movement_plan.dart';
import 'package:duncrawl/features/dungeon/floors/floor_0.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_controller.dart';

void main() {
  test('Preview and execution stop before an enemy on walkable terrain', () {
    final dungeon = Dungeon.start(_floor());
    const freeTile = GridPosition(8, 7);
    const occupiedTile = GridPosition(9, 7);
    final plan = MovementPlan.start(
      dungeon,
    ).extend(DungeonDirection.east, steps: 5);

    expect(dungeon.floor.canEnter(occupiedTile), isTrue);
    expect(dungeon.actorAt(occupiedTile)?.id, dungeon.floor.enemies.first.id);
    expect(plan.path, [freeTile]);
    final moved = dungeon.move(DungeonDirection.east, steps: 5);
    expect(moved.player, plan.destination);
    expect(moved.stepTo(occupiedTile), same(moved));
    expect(dungeon.player, const GridPosition(7, 7));
  });

  test('Enemies share terrain, adjacency and actor occupancy rules', () {
    final dungeon = Dungeon.start(_floor());
    final bat = dungeon.floor.enemies.first;
    final besidePlayer = dungeon.stepActorTo(
      actorId: bat.id,
      destination: const GridPosition(8, 7),
    );
    expect(besidePlayer.positionOf(bat.id), const GridPosition(8, 7));
    expect(
      besidePlayer.stepActorTo(actorId: bat.id, destination: dungeon.player),
      same(besidePlayer),
    );

    for (final target in [
      const GridPosition(10, 7), // Otro enemigo.
      const GridPosition(9, 6), // Pared.
      const GridPosition(9, 8), // Agua profunda.
      const GridPosition(10, 8), // Diagonal.
      const GridPosition(12, 7), // Salto.
      const GridPosition(-1, 7),
    ]) {
      expect(
        dungeon.stepActorTo(actorId: bat.id, destination: target),
        same(dungeon),
      );
    }
    expect(
      dungeon.stepActorTo(
        actorId: 'missing',
        destination: const GridPosition(8, 7),
      ),
      same(dungeon),
    );
  });

  test('Immutable updates reject overlapping actors and invalid terrain', () {
    final dungeon = Dungeon.start(_floor());
    final bat = dungeon.floor.enemies.first;
    for (final position in [
      dungeon.player,
      const GridPosition(10, 7),
      const GridPosition(9, 6),
      const GridPosition(9, 8),
      const GridPosition(15, 7),
    ]) {
      expect(
        dungeon.withEnemy(bat.copyWith(position: position)),
        same(dungeon),
      );
    }
  });

  test('A projected route can loop through its own starting tile', () {
    final dungeon = Dungeon.start(_floor());
    final plan = MovementPlan.start(dungeon)
        .extend(DungeonDirection.north)
        .extend(DungeonDirection.west)
        .extend(DungeonDirection.south)
        .extend(DungeonDirection.east);
    expect(plan.path, hasLength(4));
    expect(plan.destination, dungeon.player);
    var moved = dungeon;
    for (final step in plan.path) {
      final next = moved.stepTo(step);
      expect(next, isNot(same(moved)));
      moved = next;
    }
    expect(moved.player, dungeon.player);
  });

  test(
    'An explicit plan budget survives extension and undo without spending state',
    () {
      final dungeon = Dungeon.start(_floor());
      final plan = MovementPlan.start(
        dungeon,
        movementBudget: 2,
      ).extend(DungeonDirection.west, steps: 5);
      expect(plan.path, hasLength(2));
      expect(plan.remainingMovement, 0);
      final undone = plan.extend(DungeonDirection.east);
      expect(undone.remainingMovement, 1);
      final rerouted = undone.extend(DungeonDirection.north);
      expect(rerouted.movementBudget, 2);
      expect(rerouted.remainingMovement, 0);
      expect(dungeon.adventurer.movementSpeed, 5);
      expect(dungeon.player, const GridPosition(7, 7));
      expect(
        MovementPlan.start(
          dungeon,
          movementBudget: 0,
        ).extend(DungeonDirection.west).path,
        isEmpty,
      );
    },
  );

  test('Defeated actors cannot preview or execute movement', () {
    final dungeon = Dungeon.start(
      _floor(),
      adventurer: const Adventurer(health: 0),
    );
    expect(dungeon.stepTo(const GridPosition(8, 7)), same(dungeon));
    expect(
      MovementPlan.start(dungeon).extend(DungeonDirection.west).path,
      isEmpty,
    );
    final bat = dungeon.floor.enemies.first;
    final defeated = dungeon.withEnemy(bat.copyWith(health: 0));
    expect(
      defeated.stepActorTo(
        actorId: bat.id,
        destination: const GridPosition(8, 7),
      ),
      same(defeated),
    );
  });

  testWidgets(
    'A route blocked after confirmation stops without retriggering entry effects',
    (tester) async {
      var entries = 0;
      final blocker = InteractiveDungeonGroundObject(
        type: GroundObjectType.grass,
        position: const GridPosition(8, 7),
        onInteract: (context) {
          entries++;
          final bat = context.dungeon.floor.enemies.first;
          context.updateDungeon(
            context.dungeon.withEnemy(
              bat.copyWith(position: const GridPosition(9, 7)),
            ),
          );
        },
      );
      final rows = [...floor0.rows]..[7] = '#......@..1...#';
      final initialFloor = DungeonFloorTemplate(
        number: 9,
        rows: rows,
        groundObjects: [blocker],
      ).create();
      final floor = initialFloor.withEnemy(
        initialFloor.enemies.single.copyWith(visionRadius: 0),
      );
      final controller = DungeonController(Dungeon.start(floor));
      addTearDown(controller.dispose);
      controller.selectCharacter();
      controller.beginDrag();
      controller.preview(DungeonDirection.east, steps: 2);
      expect(controller.plan.path, hasLength(2));
      controller.confirm();
      await tester.pump(DungeonController.stepDuration);
      expect(controller.dungeon.player, const GridPosition(8, 7));
      expect(controller.isMoving, isTrue);
      await tester.pump(DungeonController.stepDuration);
      expect(controller.dungeon.player, const GridPosition(8, 7));
      expect(entries, 1);
      expect(controller.isMoving, isFalse);
      expect(controller.isBottomMenuEnabled, isTrue);
      expect(controller.remainingPath, isEmpty);
      expect(controller.selectedPosition, controller.dungeon.player);
      await tester.pump(DungeonController.stepDuration * 3);
      expect(entries, 1);
    },
  );
}

DungeonFloor _floor() {
  final rows = [...floor0.rows]..[7] = '#......@.12...#';
  rows[6] = rows[6].replaceRange(9, 10, '#');
  rows[8] = rows[8].replaceRange(9, 10, 'w');
  return DungeonFloorTemplate(number: 9, rows: rows).create();
}
