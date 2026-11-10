import 'grid_position.dart';

enum DungeonTile { voidTile, floor, wall }

enum GroundObjectType { stairsUp }

class DungeonGroundObject {
  final GroundObjectType type;
  final GridPosition position;

  const DungeonGroundObject({required this.type, required this.position});
}

class DungeonFloorTemplate {
  final int number;
  final List<String> rows;
  final List<DungeonGroundObject> groundObjects;

  const DungeonFloorTemplate({
    required this.number,
    required this.rows,
    this.groundObjects = const [],
  });

  /// Valida el mapa y exige un único punto de aparición.
  /// Lanza FormatException si el mapa, la aparición o los objetos son inválidos.
  DungeonFloor create() {
    if (rows.length != DungeonFloor.size ||
        rows.any((row) => row.length != DungeonFloor.size)) {
      throw const FormatException('A floor must contain 15 rows of 15 tiles.');
    }

    GridPosition? spawn;
    final tiles = <DungeonTile>[];
    for (var row = 0; row < DungeonFloor.size; row++) {
      for (var column = 0; column < DungeonFloor.size; column++) {
        final symbol = rows[row][column];
        final position = GridPosition(column, row);
        if (symbol == '@') {
          if (spawn != null) {
            throw const FormatException('A floor must have exactly one spawn.');
          }
          spawn = position;
        }
        final tile = switch (symbol) {
          '.' || '@' => DungeonTile.floor,
          '_' => DungeonTile.voidTile,
          '#' => DungeonTile.wall,
          _ => throw FormatException('Unknown floor symbol: $symbol'),
        };
        tiles.add(tile);
      }
    }
    if (spawn == null) {
      throw const FormatException('A floor must have exactly one spawn.');
    }

    final floor = DungeonFloor._(
      number: number,
      spawn: spawn,
      tiles: List.unmodifiable(tiles),
      groundObjects: List.unmodifiable(groundObjects),
    );
    for (final object in groundObjects) {
      if (!floor.canEnter(object.position)) {
        throw const FormatException(
          'Ground objects must be placed on floor tiles.',
        );
      }
    }

    return floor;
  }
}

class DungeonFloor {
  static const size = 15;

  final int number;
  final GridPosition spawn;
  final List<DungeonTile> _tiles;
  final List<DungeonGroundObject> groundObjects;

  const DungeonFloor._({
    required this.number,
    required this.spawn,
    required List<DungeonTile> tiles,
    required this.groundObjects,
  }) : _tiles = tiles;

  DungeonTile tileAt(GridPosition position) =>
      _tiles[position.row * size + position.column];

  bool canEnter(GridPosition position) {
    if (position.column < 0 ||
        position.column >= size ||
        position.row < 0 ||
        position.row >= size) {
      return false;
    }

    return tileAt(position) == DungeonTile.floor;
  }
}
