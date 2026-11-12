import '../domain/dungeon.dart';
import '../domain/dungeon_enemy.dart';
import '../domain/grid_position.dart';

abstract final class FloorZeroTestBats {
  static const ids = ['floor:0:test-bat:0', 'floor:0:test-bat:1'];
  static const _positions = [
    GridPosition(11, 12),
    GridPosition(12, 12),
    GridPosition(13, 12),
    GridPosition(11, 13),
    GridPosition(12, 13),
    GridPosition(13, 13),
  ];

  static Dungeon apply(Dungeon dungeon, {required bool enabled}) {
    if (dungeon.floor.number != 0) {
      return dungeon;
    }
    var updated = dungeon;
    for (final id in ids) {
      if (!enabled) {
        updated = updated.removeEnemy(id);
        continue;
      }
      if (updated.actorById(id) != null) {
        continue;
      }
      final position = _positions
          .where(
            (position) =>
                updated.floor.canEnter(position) &&
                updated.actorAt(position) == null,
          )
          .firstOrNull;
      if (position != null) {
        updated = updated.addEnemy(DungeonEnemy.bat(position, id: id));
      }
    }
    return updated;
  }
}
