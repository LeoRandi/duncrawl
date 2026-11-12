import 'dungeon_enemy.dart';
import 'dungeon_floor.dart';
import 'grid_position.dart';

abstract final class DungeonVisibility {
  static Set<GridPosition> visibleArea(
    DungeonFloor floor,
    DungeonEnemy enemy,
  ) => Set.unmodifiable({
    for (final position in enemy.visionArea)
      if (floor.contains(position) &&
          hasLineOfSight(floor, from: enemy.position, to: position))
        position,
  });

  static bool detectsPlayer({
    required DungeonFloor floor,
    required DungeonEnemy enemy,
    required GridPosition player,
  }) =>
      !enemy.isDefeated &&
      enemy.visionArea.contains(player) &&
      hasLineOfSight(floor, from: enemy.position, to: player);

  /// La pared de destino se ve; las paredes intermedias y las esquinas cierran la visión.
  static bool hasLineOfSight(
    DungeonFloor floor, {
    required GridPosition from,
    required GridPosition to,
  }) {
    if (!floor.contains(from) || !floor.contains(to)) {
      return false;
    }

    final dx = to.column - from.column;
    final dy = to.row - from.row;
    final width = dx.abs();
    final height = dy.abs();
    final stepX = dx.sign;
    final stepY = dy.sign;
    var column = from.column;
    var row = from.row;
    var crossedX = 0;
    var crossedY = 0;
    while (crossedX < width || crossedY < height) {
      final crossing = (1 + 2 * crossedX) * height - (1 + 2 * crossedY) * width;
      if (crossing == 0) {
        if (_blocksSight(floor, GridPosition(column + stepX, row)) ||
            _blocksSight(floor, GridPosition(column, row + stepY))) {
          return false;
        }
        column += stepX;
        row += stepY;
        crossedX++;
        crossedY++;
      } else if (crossing < 0) {
        column += stepX;
        crossedX++;
      } else {
        row += stepY;
        crossedY++;
      }
      final position = GridPosition(column, row);
      if (position != to && _blocksSight(floor, position)) {
        return false;
      }
    }
    return true;
  }

  static bool _blocksSight(DungeonFloor floor, GridPosition position) =>
      !floor.contains(position) ||
      switch (floor.tileAt(position)) {
        DungeonTile.wall || DungeonTile.voidTile => true,
        DungeonTile.floor || DungeonTile.water => false,
      };
}
