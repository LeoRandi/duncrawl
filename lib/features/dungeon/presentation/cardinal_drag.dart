import '../domain/dungeon.dart';

/// Convierte el arrastre en pasos sin depender de coordenadas o widgets Flutter.
class CardinalDrag {
  double _horizontal = 0;
  double _vertical = 0;

  void reset() {
    _horizontal = 0;
    _vertical = 0;
  }

  /// Consume el desplazamiento del eje dominante; nunca devuelve una diagonal.
  /// Devuelve null hasta acumular la distancia de un paso.
  ({DungeonDirection direction, int steps})? add({
    required double dx,
    required double dy,
    required double stepDistance,
  }) {
    assert(stepDistance > 0);
    _horizontal += dx;
    _vertical += dy;

    final isHorizontal = _horizontal.abs() >= _vertical.abs();
    final distance = isHorizontal ? _horizontal : _vertical;
    final steps = (distance.abs() / stepDistance).floor();
    if (steps == 0) {
      return null;
    }

    final DungeonDirection direction;
    if (isHorizontal) {
      direction = distance > 0 ? DungeonDirection.east : DungeonDirection.west;
    } else {
      direction = distance > 0
          ? DungeonDirection.south
          : DungeonDirection.north;
    }

    // Se descarta el eje menor para que un gesto diagonal no genere dos movimientos.
    final remainder = distance - distance.sign * steps * stepDistance;
    _horizontal = isHorizontal ? remainder : 0;
    _vertical = isHorizontal ? 0 : remainder;
    return (direction: direction, steps: steps);
  }
}
