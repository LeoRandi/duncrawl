import 'dart:collection';

import 'dungeon.dart';
import 'game_command.dart';
import 'game_rules.dart';
import 'game_state.dart';
import 'grid_position.dart';

class EnemyTactics {
  final GameRules rules;

  const EnemyTactics({this.rules = const GameRules()});

  GameCommand? nextCommand(GameState state) {
    final encounter = state.encounter;
    if (state.mode != GameMode.combat ||
        encounter == null ||
        state.isPlayerTurn) {
      return null;
    }
    final actorId = encounter.activeActorId;
    if (rules.canAttack(
      state,
      actorId: actorId,
      targetId: state.dungeon.adventurer.id,
    )) {
      return AttackActor(
        actorId: actorId,
        targetId: state.dungeon.adventurer.id,
      );
    }
    if (encounter.actionAvailable && encounter.remainingMovement > 0) {
      final destination = _stepTowardPlayer(state, actorId);
      if (destination != null) {
        return MoveActor(actorId: actorId, destination: destination);
      }
    }
    return EndActorTurn(actorId);
  }

  GridPosition? _stepTowardPlayer(GameState state, String actorId) {
    final dungeon = state.dungeon;
    final origin = dungeon.positionOf(actorId);
    if (origin == null) {
      return null;
    }
    final frontier = Queue<GridPosition>()..add(origin);
    final previous = <GridPosition, GridPosition>{};
    final visited = {origin};
    while (frontier.isNotEmpty) {
      final current = frontier.removeFirst();
      if (current.isAdjacentTo(dungeon.player)) {
        var step = current;
        while (true) {
          final parent = previous[step];
          if (parent == null || parent == origin) {
            break;
          }
          step = parent;
        }
        return step == origin ? null : step;
      }
      for (final direction in DungeonDirection.values) {
        final next = direction.stepFrom(current);
        if (visited.contains(next) ||
            !dungeon.canStepFrom(
              actorId: actorId,
              from: current,
              destination: next,
            )) {
          continue;
        }
        visited.add(next);
        previous[next] = current;
        frontier.add(next);
      }
    }
    return null;
  }
}
