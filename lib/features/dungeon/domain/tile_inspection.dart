import 'dungeon_floor.dart';
import 'dungeon_enemy.dart';
import 'grid_position.dart';

/// Contenido visible de una casilla, sin ejecutar sus interacciones.
class TileInspection {
  final GridPosition position;
  final DungeonTile tile;
  final DungeonGroundObject? object;
  final DungeonEnemy? enemy;
  final String? adventurerId;

  const TileInspection({
    required this.position,
    required this.tile,
    this.object,
    this.enemy,
    this.adventurerId,
  }) : assert(enemy == null || adventurerId == null);

  bool get isAdventurer => adventurerId != null;

  String? get actorId => adventurerId ?? enemy?.id;

  bool hasSameTarget(TileInspection other) {
    final id = actorId;
    if (id != null) {
      return id == other.actorId;
    }

    return other.actorId == null &&
        position == other.position &&
        identical(object, other.object) &&
        tile == other.tile;
  }
}
