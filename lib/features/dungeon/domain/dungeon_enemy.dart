import 'dungeon_actor.dart';
import 'grid_position.dart';

enum EnemyType {
  bat(stepInterval: Duration(milliseconds: 150));

  /// Cadencia propia de la especie, independiente del ajuste del jugador.
  final Duration stepInterval;

  const EnemyType({required this.stepInterval});
}

class DungeonEnemy extends DungeonActor {
  final EnemyType type;
  final GridPosition position;
  final int visionRadius;
  final int? _alertRadius;

  const DungeonEnemy({
    required super.id,
    required this.type,
    required this.position,
    super.level = 1,
    super.health = 3,
    super.maximumHealth = 3,
    super.movementSpeed = 4,
    super.strength = 1,
    super.dexterity = 1,
    super.special = 1,
    this.visionRadius = 2,
    int? alertRadius,
  }) : _alertRadius = alertRadius,
       assert(visionRadius >= 0),
       assert(alertRadius == null || alertRadius >= 0);

  const DungeonEnemy.bat(GridPosition position, {required String id})
    : this(id: id, type: EnemyType.bat, position: position);

  DungeonEnemy copyWith({
    GridPosition? position,
    int? level,
    int? health,
    int? maximumHealth,
    int? movementSpeed,
    int? strength,
    int? dexterity,
    int? special,
    int? visionRadius,
    int? alertRadius,
  }) => DungeonEnemy(
    id: id,
    type: type,
    position: position ?? this.position,
    level: level ?? this.level,
    health: health ?? this.health,
    maximumHealth: maximumHealth ?? this.maximumHealth,
    movementSpeed: movementSpeed ?? this.movementSpeed,
    strength: strength ?? this.strength,
    dexterity: dexterity ?? this.dexterity,
    special: special ?? this.special,
    visionRadius: visionRadius ?? this.visionRadius,
    alertRadius: alertRadius ?? _alertRadius,
  );

  /// Sin un valor específico, el oído sigue siendo el doble de la visión actual.
  int get alertRadius => _alertRadius ?? visionRadius * 2;

  bool isWithinAlertRange(GridPosition source) =>
      position.distanceTo(source) <= alertRadius;

  /// Distancia ortogonal: las diagonales consumen dos pasos del radio.
  Set<GridPosition> get visionArea => position.areaWithin(visionRadius);

  Set<GridPosition> get alertArea => position.areaWithin(alertRadius);

  /// Anticipa el alcance máximo del turno, sin descontar terreno ni movimiento gastado.
  Set<GridPosition> get movementArea =>
      position.areaWithin(combatMovementSpeed);
}
