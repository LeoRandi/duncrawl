abstract class DungeonActor {
  static const combatMovementPenalty = 2;

  final String id;
  final int level;
  final int health;
  final int maximumHealth;
  final int movementSpeed;
  final int strength;
  final int dexterity;
  final int special;

  const DungeonActor({
    required this.id,
    required this.level,
    required this.health,
    required this.maximumHealth,
    required this.movementSpeed,
    required this.strength,
    required this.dexterity,
    required this.special,
  }) : assert(id != ''),
       assert(movementSpeed >= 0),
       assert(strength >= 0),
       assert(dexterity >= 0),
       assert(special >= 0);

  bool get isDefeated => health <= 0;

  int get combatMovementSpeed => movementSpeed > combatMovementPenalty
      ? movementSpeed - combatMovementPenalty
      : 0;
}
