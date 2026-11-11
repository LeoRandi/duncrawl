import 'dungeon_floor.dart';
import 'grid_position.dart';

/// Contenido visible de una casilla, sin ejecutar sus interacciones.
class TileInspection {
  final GridPosition position;
  final DungeonTile tile;
  final DungeonGroundObject? object;

  const TileInspection({
    required this.position,
    required this.tile,
    this.object,
  });
}
