import 'dungeon_actor.dart';

class Adventurer extends DungeonActor {
  const Adventurer({
    super.id = 'adventurer',
    super.level = 1,
    super.health = 10,
    super.maximumHealth = 10,
    super.movementSpeed = 5,
    super.strength = 2,
    super.dexterity = 1,
    super.special = 1,
  });

  Adventurer copyWith({
    int? level,
    int? health,
    int? maximumHealth,
    int? movementSpeed,
    int? strength,
    int? dexterity,
    int? special,
  }) => Adventurer(
    id: id,
    level: level ?? this.level,
    health: health ?? this.health,
    maximumHealth: maximumHealth ?? this.maximumHealth,
    movementSpeed: movementSpeed ?? this.movementSpeed,
    strength: strength ?? this.strength,
    dexterity: dexterity ?? this.dexterity,
    special: special ?? this.special,
  );
}
