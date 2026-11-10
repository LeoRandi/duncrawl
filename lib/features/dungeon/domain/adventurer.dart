class Adventurer {
  final int level;
  final int health;
  final int maximumHealth;
  final int movementSpeed;

  const Adventurer({
    this.level = 1,
    this.health = 10,
    this.maximumHealth = 10,
    this.movementSpeed = 5,
  }) : assert(movementSpeed >= 0);

  Adventurer copyWith({
    int? level,
    int? health,
    int? maximumHealth,
    int? movementSpeed,
  }) => Adventurer(
    level: level ?? this.level,
    health: health ?? this.health,
    maximumHealth: maximumHealth ?? this.maximumHealth,
    movementSpeed: movementSpeed ?? this.movementSpeed,
  );
}
