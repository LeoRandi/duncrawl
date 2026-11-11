import 'dungeon_floor.dart';
import 'dungeon_enemy.dart';
import 'grid_position.dart';

/// Contenido visible de una casilla, sin ejecutar sus interacciones.
class TileInspection {
  final GridPosition position;
  final DungeonTile tile;
  final DungeonGroundObject? object;
  final DungeonEnemy? enemy;
  final bool isAdventurer;

  const TileInspection({
    required this.position,
    required this.tile,
    this.object,
    this.enemy,
    this.isAdventurer = false,
  });

  bool hasSameTarget(TileInspection other) =>
      position == other.position &&
      isAdventurer == other.isAdventurer &&
      identical(enemy, other.enemy) &&
      identical(object, other.object) &&
      tile == other.tile;
}
