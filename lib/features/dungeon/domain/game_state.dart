import 'dungeon.dart';
import 'encounter_state.dart';

enum GameMode { exploration, combat, defeated }

class GameState {
  final Dungeon dungeon;
  final EncounterState? encounter;

  const GameState({required this.dungeon, this.encounter});

  GameMode get mode {
    if (dungeon.adventurer.isDefeated) {
      return GameMode.defeated;
    }
    return encounter == null ? GameMode.exploration : GameMode.combat;
  }

  bool get isPlayerTurn =>
      mode == GameMode.combat &&
      encounter?.activeActorId == dungeon.adventurer.id;

  GameState withDungeon(Dungeon dungeon) =>
      GameState(dungeon: dungeon, encounter: encounter);

  GameState withEncounter(EncounterState? encounter) =>
      GameState(dungeon: dungeon, encounter: encounter);
}
