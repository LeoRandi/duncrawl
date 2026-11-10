import 'adventurer.dart';
import 'dungeon_floor.dart';
import 'grid_position.dart';

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
    : player = floor.spawn;

  const Dungeon._({
    required this.floor,
    required this.player,
    required this.adventurer,
  });

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
  Dungeon stepTo(GridPosition destination) {
    if (!player.isAdjacentTo(destination) || !floor.canEnter(destination)) {
      return this;
    }

    return Dungeon._(floor: floor, player: destination, adventurer: adventurer);
  }
}
