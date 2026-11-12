import 'adventurer.dart';
import 'dungeon_actor.dart';
import 'dungeon_enemy.dart';
import 'dungeon_floor.dart';
import 'grid_position.dart';
import 'tile_inspection.dart';

enum DungeonDirection {
  north(0, -1),
  east(1, 0),
  south(0, 1),
  west(-1, 0);

  final int columnOffset;
  final int rowOffset;

  const DungeonDirection(this.columnOffset, this.rowOffset);

  GridPosition stepFrom(GridPosition position) =>
      GridPosition(position.column + columnOffset, position.row + rowOffset);
}

class Dungeon {
  final DungeonFloor floor;
  final GridPosition player;
  final Adventurer adventurer;

  Dungeon.start(this.floor, {this.adventurer = const Adventurer()})
    : player = floor.spawn {
    if (floor.enemyById(adventurer.id) != null ||
        floor.enemyAt(player) != null) {
      throw ArgumentError(
        'The adventurer must have a unique ID and spawn tile.',
      );
    }
  }

  const Dungeon._({
    required this.floor,
    required this.player,
    required this.adventurer,
  });

  Dungeon enterFloor(DungeonFloor destination) =>
      Dungeon.start(destination, adventurer: adventurer);

  DungeonActor? actorById(String id) =>
      id == adventurer.id ? adventurer : floor.enemyById(id);

  GridPosition? positionOf(String actorId) =>
      actorId == adventurer.id ? player : floor.enemyById(actorId)?.position;

  DungeonActor? actorAt(GridPosition position) =>
      position == player ? adventurer : floor.enemyAt(position);

  /// Un actor conserva su casilla hasta que se retire del estado del mundo.
  bool canOccupy(GridPosition position, {required String actorId}) {
    if (actorById(actorId) == null || !floor.canEnter(position)) {
      return false;
    }

    final occupant = actorAt(position);
    return occupant == null || occupant.id == actorId;
  }

  /// [from] puede ser una posición proyectada al previsualizar una ruta.
  /// La ejecución usa siempre la posición actual del actor.
  bool canStepFrom({
    required String actorId,
    required GridPosition from,
    required GridPosition destination,
  }) {
    final actor = actorById(actorId);
    if (actor == null || actor.isDefeated) {
      return false;
    }

    return floor.contains(from) &&
        from.isAdjacentTo(destination) &&
        canOccupy(destination, actorId: actorId);
  }

  List<TileInspection> selectionStackAt(GridPosition position) {
    if (!floor.contains(position)) {
      return const [];
    }
    return List.unmodifiable([
      if (position == player)
        TileInspection(
          position: position,
          tile: floor.tileAt(position),
          adventurerId: adventurer.id,
        ),
      ...floor.inspectTileStack(position),
    ]);
  }

  Dungeon withAdventurer(Adventurer adventurer) {
    if (adventurer.id != this.adventurer.id) {
      throw ArgumentError('Updating the adventurer must preserve its ID.');
    }

    return Dungeon._(floor: floor, player: player, adventurer: adventurer);
  }

  /// Actualiza un enemigo sin permitir que ocupe la casilla del aventurero.
  /// Un ID desconocido o un destino bloqueado no cambian el estado.
  Dungeon withEnemy(DungeonEnemy enemy) {
    if (enemy.position == player) {
      return this;
    }

    final updatedFloor = floor.withEnemy(enemy);
    if (identical(updatedFloor, floor)) {
      return this;
    }

    return Dungeon._(
      floor: updatedFloor,
      player: player,
      adventurer: adventurer,
    );
  }

  Dungeon addEnemy(DungeonEnemy enemy) {
    if (actorById(enemy.id) != null || enemy.position == player) {
      return this;
    }
    final updatedFloor = floor.addEnemy(enemy);
    if (identical(updatedFloor, floor)) {
      return this;
    }
    return Dungeon._(
      floor: updatedFloor,
      player: player,
      adventurer: adventurer,
    );
  }

  Dungeon removeEnemy(String id) {
    final updatedFloor = floor.removeEnemy(id);
    if (identical(updatedFloor, floor)) {
      return this;
    }

    return Dungeon._(
      floor: updatedFloor,
      player: player,
      adventurer: adventurer,
    );
  }

  Dungeon removeGroundObject(DungeonGroundObject object) => Dungeon._(
    floor: floor.removeGroundObject(object),
    player: player,
    adventurer: adventurer,
  );

  /// Avanza por un único eje hasta completar los pasos, una pared o el borde.
  /// Los pasos nulos o negativos no cambian la posición.
  Dungeon move(DungeonDirection direction, {int steps = 1}) {
    var dungeon = this;
    for (var step = 0; step < steps; step++) {
      final next = dungeon.stepTo(direction.stepFrom(dungeon.player));
      if (identical(next, dungeon)) {
        break;
      }
      dungeon = next;
    }

    return dungeon;
  }

  /// Ejecuta un paso adyacente transitable; un destino inválido no cambia el estado.
  Dungeon stepTo(GridPosition destination) =>
      stepActorTo(actorId: adventurer.id, destination: destination);

  /// Comparte la validación entre el aventurero y los enemigos.
  Dungeon stepActorTo({
    required String actorId,
    required GridPosition destination,
  }) {
    final from = positionOf(actorId);
    if (from == null ||
        !canStepFrom(actorId: actorId, from: from, destination: destination)) {
      return this;
    }

    if (actorId == adventurer.id) {
      return Dungeon._(
        floor: floor,
        player: destination,
        adventurer: adventurer,
      );
    }

    final enemy = floor.enemyById(actorId);
    if (enemy == null) {
      return this;
    }

    return withEnemy(enemy.copyWith(position: destination));
  }
}
