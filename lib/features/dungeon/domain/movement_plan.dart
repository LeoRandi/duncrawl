import 'dungeon.dart';
import 'grid_position.dart';

/// Ruta de un turno que aún no modifica la posición real del personaje.
class MovementPlan {
  final Dungeon dungeon;
  final List<GridPosition> path;
  final int? _movementBudget;
  final bool Function(GridPosition position)? additionalStop;

  const MovementPlan.start(
    this.dungeon, {
    int? movementBudget,
    this.additionalStop,
  }) : assert(movementBudget == null || movementBudget >= 0),
       _movementBudget = movementBudget,
       path = const [];

  const MovementPlan._({
    required this.dungeon,
    required this.path,
    required int? movementBudget,
    this.additionalStop,
  }) : _movementBudget = movementBudget;

  GridPosition get destination => path.isEmpty ? dungeon.player : path.last;

  /// En combate, el llamador aporta el saldo del turno, no la velocidad completa.
  int get movementBudget => _movementBudget ?? dungeon.adventurer.movementSpeed;

  int get remainingMovement => movementBudget - path.length;

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
      if (updatedPath.length >= movementBudget ||
          (updatedPath.isNotEmpty &&
              (dungeon.floor.stopsMovementAt(current) ||
                  (additionalStop?.call(current) ?? false))) ||
          !dungeon.canStepFrom(
            actorId: dungeon.adventurer.id,
            from: current,
            destination: next,
          )) {
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
      movementBudget: _movementBudget,
      additionalStop: additionalStop,
    );
  }
}
