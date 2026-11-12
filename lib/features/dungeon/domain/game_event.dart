import 'grid_position.dart';

sealed class GameEvent {
  const GameEvent();
}

class ActorMoved extends GameEvent {
  final String actorId;
  final GridPosition from;
  final GridPosition to;

  const ActorMoved({
    required this.actorId,
    required this.from,
    required this.to,
  });
}

class AttackResolved extends GameEvent {
  final String actorId;
  final String targetId;
  final int damage;
  final int remainingHealth;
  final GridPosition targetPosition;

  const AttackResolved({
    required this.actorId,
    required this.targetId,
    required this.damage,
    required this.remainingHealth,
    required this.targetPosition,
  });
}

class ActorDefeated extends GameEvent {
  final String actorId;

  const ActorDefeated(this.actorId);
}

class EncounterStarted extends GameEvent {
  const EncounterStarted();
}

class EncounterWon extends GameEvent {
  const EncounterWon();
}

class ActorTurnStarted extends GameEvent {
  final String actorId;

  const ActorTurnStarted(this.actorId);
}
