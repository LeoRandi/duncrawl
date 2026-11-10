import 'dungeon.dart';
import 'grid_position.dart';

/// Ruta de un turno que aún no modifica la posición real del personaje.
class MovementPlan {
  final Dungeon dungeon;
  final List<GridPosition> path;
  final bool Function(GridPosition position)? additionalStop;

  const MovementPlan.start(this.dungeon, {this.additionalStop})
    : path = const [];

  const MovementPlan._({
    required this.dungeon,
    required this.path,
    this.additionalStop,
  });

  GridPosition get destination => path.isEmpty ? dungeon.player : path.last;

  int get remainingMovement => dungeon.adventurer.movementSpeed - path.length;

  /// Registra pasos válidos y deshace el último al volver sobre él.
  /// Los pasos bloqueados o que superan el presupuesto no alteran la ruta.
  MovementPlan extend(DungeonDirection direction, {int steps = 1}) {
    final updatedPath = [...path];
    for (var step = 0; step < steps; step++) {
      final current = updatedPath.isEmpty ? dungeon.player : updatedPath.last;
      final next = direction.stepFrom(current);
      final previous = updatedPath.length < 2
          ? dungeon.player
          : updatedPath[updatedPath.length - 2];
      if (updatedPath.isNotEmpty && next == previous) {
        updatedPath.removeLast();
        continue;
      }
      // Tras rechazar una interacción, se permite abandonar la casilla de origen.
      if (updatedPath.length >= dungeon.adventurer.movementSpeed ||
          (updatedPath.isNotEmpty &&
              (dungeon.floor.stopsMovementAt(current) ||
                  (additionalStop?.call(current) ?? false))) ||
          !dungeon.floor.canEnter(next)) {
        break;
      }
      updatedPath.add(next);
    }
    if (updatedPath.length == path.length &&
        (updatedPath.isEmpty || updatedPath.last == path.last)) {
      return this;
    }

    return MovementPlan._(
      dungeon: dungeon,
      path: List.unmodifiable(updatedPath),
      additionalStop: additionalStop,
    );
  }
}
