import 'dungeon_floor.dart';
import 'dungeon_enemy.dart';
import 'grid_position.dart';

/// Contenido visible de una casilla, sin ejecutar sus interacciones.
class TileInspection {
  final GridPosition position;
  final DungeonTile tile;
  final DungeonGroundObject? object;
  final DungeonEnemy? enemy;

  const TileInspection({
    required this.position,
    required this.tile,
    this.object,
    this.enemy,
  });
}
