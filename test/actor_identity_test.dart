import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/adventurer.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_enemy.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/floors/floor_0.dart';
import 'package:duncrawl/features/dungeon/floors/floor_2.dart';

void main() {
  test('Map actors have distinct repeatable IDs scoped to their floor', () {
    final floor = floor2.create();
    final rebuilt = floor2.create();
    final ids = floor.enemies.map((enemy) => enemy.id).toList();
    expect(ids.toSet(), hasLength(floor.enemies.length));
    expect(rebuilt.enemies.map((enemy) => enemy.id), ids);
    expect(ids, isNot(contains(const Adventurer().id)));
  });

  test(
    'Damage and movement preserve identity and previous world snapshots',
    () {
      final original = Dungeon.start(floor2.create());
      final bat = original.floor.enemies.first;
      final damaged = original.withEnemy(bat.copyWith(health: 1));
      final moved = damaged.stepActorTo(
        actorId: bat.id,
        destination: const GridPosition(10, 1),
      );

      expect(original.actorById(bat.id), same(bat));
      expect(original.actorById(bat.id)?.health, 3);
      expect(original.positionOf(bat.id), const GridPosition(10, 2));
      expect(damaged.actorById(bat.id)?.health, 1);
      expect(damaged.positionOf(bat.id), const GridPosition(10, 2));
      expect(moved.actorById(bat.id)?.id, bat.id);
      expect(moved.actorById(bat.id)?.health, 1);
      expect(moved.positionOf(bat.id), const GridPosition(10, 1));
      expect(moved.player, original.player);
      expect(moved.floor.groundObjects, same(original.floor.groundObjects));
      expect(() => moved.floor.enemies.clear(), throwsUnsupportedError);
    },
  );

  test(
    'The adventurer retains its ID through stat updates and floor changes',
    () {
      const adventurer = Adventurer(id: 'hero', health: 7);
      final dungeon = Dungeon.start(floor0.create(), adventurer: adventurer);
      final updated = dungeon.withAdventurer(adventurer.copyWith(health: 4));
      final arrived = updated.enterFloor(floor2.create());

      expect(arrived.actorById('hero'), same(updated.adventurer));
      expect(arrived.actorById('hero')?.health, 4);
      expect(arrived.positionOf('hero'), arrived.floor.spawn);
      expect(dungeon.adventurer.health, 7);
      expect(
        () => dungeon.withAdventurer(const Adventurer(id: 'someone-else')),
        throwsArgumentError,
      );
    },
  );

  test('A new dungeon rejects a shared actor ID or occupied spawn', () {
    final floor = floor2.create();
    final bat = floor.enemies.first;
    expect(
      () => Dungeon.start(floor, adventurer: Adventurer(id: bat.id)),
      throwsArgumentError,
    );
    final occupiedSpawn = floor.withEnemy(bat.copyWith(position: floor.spawn));
    expect(() => Dungeon.start(occupiedSpawn), throwsArgumentError);
  });

  test(
    'Unknown actor updates cannot create enemies and removal releases a tile',
    () {
      final dungeon = Dungeon.start(floor2.create());
      const unknown = DungeonEnemy.bat(GridPosition(3, 12), id: 'unknown');
      expect(dungeon.withEnemy(unknown), same(dungeon));
      expect(dungeon.removeEnemy('unknown'), same(dungeon));
      expect(dungeon.actorById('unknown'), isNull);
      expect(dungeon.positionOf('unknown'), isNull);

      final bat = dungeon.floor.enemies.first;
      final removed = dungeon.removeEnemy(bat.id);
      expect(removed.actorById(bat.id), isNull);
      expect(removed.actorAt(bat.position), isNull);
      expect(
        removed.canOccupy(bat.position, actorId: removed.adventurer.id),
        isTrue,
      );
      expect(dungeon.actorAt(bat.position), same(bat));
    },
  );

  test('Both actor types clamp the shared combat movement penalty at zero', () {
    for (final (speed, combatSpeed) in [
      (0, 0),
      (1, 0),
      (2, 0),
      (3, 1),
      (5, 3),
    ]) {
      final adventurer = Adventurer(movementSpeed: speed);
      final bat = DungeonEnemy(
        id: 'bat',
        type: EnemyType.bat,
        position: const GridPosition(1, 1),
        movementSpeed: speed,
      );
      expect(adventurer.combatMovementSpeed, combatSpeed);
      expect(bat.combatMovementSpeed, combatSpeed);
    }
  });
}
