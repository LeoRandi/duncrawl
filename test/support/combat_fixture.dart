import 'package:duncrawl/features/dungeon/domain/adventurer.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';

Dungeon combatFixture({
  Adventurer adventurer = const Adventurer(),
  List<GridPosition> enemies = const [GridPosition(9, 7)],
  Set<GridPosition> walls = const {},
  Set<GridPosition> water = const {},
  List<DungeonGroundObject> objects = const [],
  int visionRadius = 2,
  int enemyHealth = 3,
}) {
  var floor = DungeonFloorTemplate(
    number: 99,
    rows: [
      for (var row = 0; row < DungeonFloor.size; row++)
        [
          for (var column = 0; column < DungeonFloor.size; column++)
            if (column == 0 || row == 0 || column == 14 || row == 14)
              '#'
            else if (column == 7 && row == 7)
              '@'
            else if (enemies.contains(GridPosition(column, row)))
              '1'
            else if (walls.contains(GridPosition(column, row)))
              '#'
            else if (water.contains(GridPosition(column, row)))
              'w'
            else
              '.',
        ].join(),
    ],
    groundObjects: objects,
  ).create();
  for (final enemy in floor.enemies) {
    floor = floor.withEnemy(
      enemy.copyWith(
        visionRadius: visionRadius,
        health: enemyHealth,
        maximumHealth: enemyHealth,
      ),
    );
  }
  return Dungeon.start(floor, adventurer: adventurer);
}
