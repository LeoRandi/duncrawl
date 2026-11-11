import 'grid_position.dart';
import 'ground_object_interaction_context.dart';
import 'tile_inspection.dart';
import 'dungeon_enemy.dart';

enum DungeonTile { voidTile, floor, wall, water }

enum GroundObjectType { stairsUp, grass, shallowWater }

enum GroundObjectInteractionKind { generic, stairs, pickup }

class DungeonGroundObject {
  final GroundObjectType type;
  final GridPosition position;

  const DungeonGroundObject({required this.type, required this.position});

  const DungeonGroundObject.grass(this.position)
    : type = GroundObjectType.grass;

  const DungeonGroundObject.shallowWater(this.position)
    : type = GroundObjectType.shallowWater;
}

class InteractiveDungeonGroundObject extends DungeonGroundObject {
  final void Function(GroundObjectInteractionContext context) onInteract;
  final bool stopsMovement;
  final GroundObjectInteractionKind interactionKind;

  const InteractiveDungeonGroundObject({
    required super.type,
    required super.position,
    required this.onInteract,
    this.stopsMovement = false,
    this.interactionKind = GroundObjectInteractionKind.generic,
  });
}

class DungeonFloorTemplate {
  final int number;
  final List<String> rows;

  /// Mapa opcional de terreno: el punto conserva la estructura de [rows].
  final List<String> terrainOverlay;

  /// Mapa opcional: g coloca hierba, s agua poco profunda y el punto no añade objetos.
  final List<String> objectRows;

  /// Sustituyen lo dibujado en su posición; admiten varios objetos explícitos juntos.
  final List<DungeonGroundObject> groundObjects;

  const DungeonFloorTemplate({
    required this.number,
    required this.rows,
    this.terrainOverlay = const [],
    this.objectRows = const [],
    this.groundObjects = const [],
  });

  /// Valida el mapa y exige un único punto de aparición.
  /// Lanza FormatException si el mapa, la aparición o los objetos son inválidos.
  DungeonFloor create() {
    _validateRows(rows, 'rows');
    if (terrainOverlay.isNotEmpty) {
      _validateRows(terrainOverlay, 'terrainOverlay');
    }
    if (objectRows.isNotEmpty) {
      _validateRows(objectRows, 'objectRows');
    }

    final (spawn, baseTiles, enemies) = _readBaseMap();
    final explicitPositions = groundObjects
        .map((object) => object.position)
        .toSet();
    final floor = DungeonFloor._(
      number: number,
      spawn: spawn,
      tiles: List.unmodifiable(_composeTerrain(baseTiles, explicitPositions)),
      groundObjects: List.unmodifiable(_composeObjects(explicitPositions)),
      enemies: List.unmodifiable(enemies),
    );
    if (!floor.canEnter(spawn)) {
      throw const FormatException('The spawn must be on walkable terrain.');
    }
    for (final object in floor.groundObjects) {
      if (!floor.canEnter(object.position)) {
        throw const FormatException(
          'Ground objects must be placed on floor tiles.',
        );
      }
    }
    for (final enemy in enemies) {
      if (!floor.canEnter(enemy.position)) {
        throw const FormatException(
          'Enemies must be placed on walkable terrain.',
        );
      }
    }

    return floor;
  }

  (GridPosition, List<DungeonTile>, List<DungeonEnemy>) _readBaseMap() {
    GridPosition? spawn;
    final tiles = <DungeonTile>[];
    final enemies = <DungeonEnemy>[];
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
        final enemy = switch (symbol) {
          '1' || '2' || '3' => DungeonEnemy.bat(position),
          _ => null,
        };
        if (enemy != null) {
          enemies.add(enemy);
        }
        final tile = symbol == '@' || enemy != null
            ? DungeonTile.floor
            : _parseTile(symbol);
        tiles.add(tile);
      }
    }
    if (spawn == null) {
      throw const FormatException('A floor must have exactly one spawn.');
    }
    return (spawn, tiles, enemies);
  }

  List<DungeonTile> _composeTerrain(
    List<DungeonTile> baseTiles,
    Set<GridPosition> explicitPositions,
  ) {
    final tiles = List<DungeonTile>.of(baseTiles);
    for (var row = 0; row < terrainOverlay.length; row++) {
      for (var column = 0; column < DungeonFloor.size; column++) {
        final symbol = terrainOverlay[row][column];
        if (symbol != '.') {
          tiles[row * DungeonFloor.size + column] = _parseTile(symbol);
        }
      }
    }

    for (final position in explicitPositions) {
      if (!_contains(position)) {
        throw const FormatException('Ground objects must be inside the floor.');
      }
      final index = position.row * DungeonFloor.size + position.column;
      // Los objetos explícitos despejan lo dibujado, conservando la estructura base.
      tiles[index] = baseTiles[index] == DungeonTile.water
          ? DungeonTile.floor
          : baseTiles[index];
    }
    return tiles;
  }

  List<DungeonGroundObject> _composeObjects(
    Set<GridPosition> explicitPositions,
  ) {
    final composedObjects = <DungeonGroundObject>[];
    for (var row = 0; row < objectRows.length; row++) {
      for (var column = 0; column < DungeonFloor.size; column++) {
        final position = GridPosition(column, row);
        final symbol = objectRows[row][column];
        final object = switch (symbol) {
          '.' => null,
          'g' => DungeonGroundObject.grass(position),
          's' => DungeonGroundObject.shallowWater(position),
          _ => throw FormatException('Unknown object symbol: $symbol'),
        };
        if (object != null && !explicitPositions.contains(position)) {
          composedObjects.add(object);
        }
      }
    }
    composedObjects.addAll(groundObjects);
    return composedObjects;
  }

  static void _validateRows(List<String> layout, String layer) {
    if (layout.length != DungeonFloor.size ||
        layout.any((row) => row.length != DungeonFloor.size)) {
      throw FormatException('$layer must contain 15 rows of 15 tiles.');
    }
  }

  static DungeonTile _parseTile(String symbol) => switch (symbol) {
    '.' => DungeonTile.floor,
    '_' => DungeonTile.voidTile,
    '#' => DungeonTile.wall,
    'w' => DungeonTile.water,
    _ => throw FormatException('Unknown floor symbol: $symbol'),
  };
}

bool _contains(GridPosition position) =>
    position.column >= 0 &&
    position.column < DungeonFloor.size &&
    position.row >= 0 &&
    position.row < DungeonFloor.size;

class DungeonFloor {
  static const size = 15;

  final int number;
  final GridPosition spawn;
  final List<DungeonTile> _tiles;
  final List<DungeonGroundObject> groundObjects;
  final List<DungeonEnemy> enemies;

  const DungeonFloor._({
    required this.number,
    required this.spawn,
    required List<DungeonTile> tiles,
    required this.groundObjects,
    required this.enemies,
  }) : _tiles = tiles;

  DungeonTile tileAt(GridPosition position) =>
      _tiles[position.row * size + position.column];

  bool contains(GridPosition position) => _contains(position);

  TileInspection? inspectTile(GridPosition position) =>
      inspectTileStack(position).firstOrNull;

  /// Orden visual, de arriba abajo; el suelo vacío no añade una selección.
  List<TileInspection> inspectTileStack(GridPosition position) {
    if (!contains(position)) {
      return const [];
    }
    final tile = tileAt(position);
    final contents = <TileInspection>[
      for (final enemy in enemies.reversed)
        if (enemy.position == position)
          TileInspection(position: position, tile: tile, enemy: enemy),
    ];
    for (final object in groundObjects.reversed) {
      if (object.position == position) {
        contents.add(
          TileInspection(position: position, tile: tile, object: object),
        );
      }
    }
    if (tile == DungeonTile.water || tile == DungeonTile.wall) {
      contents.add(TileInspection(position: position, tile: tile));
    }
    return List.unmodifiable(contents);
  }

  Iterable<InteractiveDungeonGroundObject> interactiveObjectsAt(
    GridPosition position,
  ) sync* {
    for (final object in groundObjects) {
      if (object is InteractiveDungeonGroundObject &&
          object.position == position) {
        yield object;
      }
    }
  }

  bool stopsMovementAt(GridPosition position) =>
      interactiveObjectsAt(position).any((object) => object.stopsMovement);

  DungeonFloor removeGroundObject(DungeonGroundObject object) {
    if (!groundObjects.contains(object)) {
      return this;
    }

    return DungeonFloor._(
      number: number,
      spawn: spawn,
      tiles: _tiles,
      groundObjects: List.unmodifiable(
        groundObjects.where((other) => other != object),
      ),
      enemies: enemies,
    );
  }

  bool canEnter(GridPosition position) {
    if (!_contains(position)) {
      return false;
    }

    return switch (tileAt(position)) {
      DungeonTile.floor => true,
      DungeonTile.water => hasShallowWaterAt(position),
      DungeonTile.voidTile || DungeonTile.wall => false,
    };
  }

  bool hasShallowWaterAt(GridPosition position) => groundObjects.any(
    (object) =>
        object.position == position &&
        object.type == GroundObjectType.shallowWater,
  );
}
