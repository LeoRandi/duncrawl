import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/adventurer.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/domain/movement_plan.dart';
import 'package:duncrawl/features/dungeon/floors/floor_0.dart';

void main() {
  test('Uses the character speed and never moves the actual character', () {
    final dungeon = Dungeon.start(
      floor0.create(),
      adventurer: const Adventurer(movementSpeed: 2),
    );
    final plan = MovementPlan.start(
      dungeon,
    ).extend(DungeonDirection.east, steps: 10);
    expect(plan.path, [const GridPosition(8, 7), const GridPosition(9, 7)]);
    expect(plan.remainingMovement, 0);
    expect(dungeon.player, const GridPosition(7, 7));
    expect(plan.extend(DungeonDirection.north), same(plan));
  });

  test(
    'Retracing steps at the limit restores the allowance for a new direction',
    () {
      final dungeon = Dungeon.start(floor0.create());
      final fullPlan = MovementPlan.start(dungeon)
          .extend(DungeonDirection.north, steps: 2)
          .extend(DungeonDirection.east, steps: 2)
          .extend(DungeonDirection.north);
      expect(fullPlan.remainingMovement, 0);
      final shortened = fullPlan.extend(DungeonDirection.south);
      expect(shortened.remainingMovement, 1);
      expect(shortened.destination, const GridPosition(9, 5));
      final rerouted = shortened.extend(DungeonDirection.east);
      expect(rerouted.path, [
        const GridPosition(7, 6),
        const GridPosition(7, 5),
        const GridPosition(8, 5),
        const GridPosition(9, 5),
        const GridPosition(10, 5),
      ]);
      expect(fullPlan.destination, const GridPosition(9, 4));
    },
  );

  test('Can undo the complete route and use the full allowance again', () {
    final plan = MovementPlan.start(Dungeon.start(floor0.create()))
        .extend(DungeonDirection.east, steps: 5)
        .extend(DungeonDirection.west, steps: 5);
    expect(plan.path, isEmpty);
    expect(plan.remainingMovement, 5);
    expect(plan.destination, const GridPosition(7, 7));
    expect(plan.extend(DungeonDirection.north, steps: 5).path.length, 5);
  });

  test('Cannot preview through a wall or over the edge', () {
    final rows = [...floor0.rows]..[7] = '.......@.#.....';
    final floor = DungeonFloorTemplate(number: 1, rows: rows).create();
    final dungeon = Dungeon.start(
      floor,
      adventurer: const Adventurer(movementSpeed: 20),
    );
    final plan = MovementPlan.start(dungeon);
    final east = plan.extend(DungeonDirection.east, steps: 100);
    expect(east.path, [const GridPosition(8, 7)]);
    expect(east.remainingMovement, 19);
    expect(east.extend(DungeonDirection.east), same(east));
    final north = plan.extend(DungeonDirection.north, steps: 100);
    expect(north.path.length, 6);
    expect(north.destination, const GridPosition(7, 1));
    expect(north.remainingMovement, 14);
  });

  test(
    'Zero speed cannot create a route; diagonal or distant execution is rejected',
    () {
      final dungeon = Dungeon.start(
        floor0.create(),
        adventurer: const Adventurer(movementSpeed: 0),
      );
      final plan = MovementPlan.start(dungeon);
      expect(plan.extend(DungeonDirection.east), same(plan));
      expect(dungeon.stepTo(const GridPosition(8, 8)), same(dungeon));
      expect(dungeon.stepTo(const GridPosition(9, 7)), same(dungeon));
    },
  );
}
