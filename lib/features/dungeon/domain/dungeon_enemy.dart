import 'grid_position.dart';

enum EnemyType { bat }

class DungeonEnemy {
  static const combatMovementPenalty = 2;

  final EnemyType type;
  final GridPosition position;
  final int level;
  final int health;
  final int maximumHealth;
  final int movementSpeed;
  final int visionRadius;

  const DungeonEnemy({
    required this.type,
    required this.position,
    this.level = 1,
    this.health = 3,
    this.maximumHealth = 3,
    this.movementSpeed = 5,
    this.visionRadius = 2,
  }) : assert(movementSpeed >= 0),
       assert(visionRadius >= 0);

  const DungeonEnemy.bat(GridPosition position)
    : this(type: EnemyType.bat, position: position);

  int get combatMovementSpeed => movementSpeed > combatMovementPenalty
      ? movementSpeed - combatMovementPenalty
      : 0;

  /// Distancia ortogonal: las diagonales consumen dos pasos del radio.
  Set<GridPosition> get visionArea => Set.unmodifiable({
    for (var dy = -visionRadius; dy <= visionRadius; dy++)
      for (var dx = -visionRadius; dx <= visionRadius; dx++)
        if (dx.abs() + dy.abs() <= visionRadius)
          GridPosition(position.column + dx, position.row + dy),
  });
}
