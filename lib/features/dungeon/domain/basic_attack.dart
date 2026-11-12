import 'dungeon_actor.dart';
import 'grid_position.dart';

abstract final class BasicAttack {
  static const baseDamage = 0;
  static const range = 1;

  static int damageFor(DungeonActor actor) => baseDamage + actor.strength;

  static bool reaches({
    required GridPosition attacker,
    required GridPosition target,
  }) => attacker.isAdjacentTo(target);
}
