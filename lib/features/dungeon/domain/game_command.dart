import 'grid_position.dart';

sealed class GameCommand {
  final String actorId;

  const GameCommand(this.actorId);
}

class MoveActor extends GameCommand {
  final GridPosition destination;

  const MoveActor({required String actorId, required this.destination})
    : super(actorId);
}

class AttackActor extends GameCommand {
  final String targetId;

  const AttackActor({required String actorId, required this.targetId})
    : super(actorId);
}

class EndActorTurn extends GameCommand {
  const EndActorTurn(super.actorId);
}
