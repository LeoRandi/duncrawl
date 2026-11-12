import 'dart:math' as math;

import 'basic_attack.dart';
import 'dungeon_enemy.dart';
import 'encounter_detection.dart';
import 'encounter_state.dart';
import 'game_command.dart';
import 'game_event.dart';
import 'game_state.dart';
import 'game_transition.dart';

class GameRules {
  const GameRules();

  /// Tras mover, el coordinador aplica efectos del suelo y llama a [refresh]
  /// antes de publicar el estado. Así una trampa se resuelve antes de detectar.
  GameTransition resolve(GameState state, GameCommand command) {
    if (state.mode == GameMode.defeated || !_canAct(state, command.actorId)) {
      return GameTransition.rejected(state);
    }

    return switch (command) {
      MoveActor() => _move(state, command),
      AttackActor() => _attack(state, command),
      EndActorTurn() =>
        state.encounter == null
            ? GameTransition.rejected(state)
            : _advanceTurn(state),
    };
  }

  bool canAttack(
    GameState state, {
    required String actorId,
    required String targetId,
  }) {
    if (state.mode == GameMode.defeated ||
        !_canAct(state, actorId) ||
        state.encounter?.actionAvailable == false) {
      return false;
    }

    final dungeon = state.dungeon;
    final attacker = dungeon.actorById(actorId);
    final target = dungeon.actorById(targetId);
    final from = dungeon.positionOf(actorId);
    final to = dungeon.positionOf(targetId);
    final playerId = dungeon.adventurer.id;
    final opposingSides = (actorId == playerId) != (targetId == playerId);
    if (attacker == null ||
        target == null ||
        attacker.isDefeated ||
        target.isDefeated ||
        from == null ||
        to == null ||
        !opposingSides) {
      return false;
    }
    return BasicAttack.reaches(attacker: from, target: to);
  }

  /// Revalida muertes y detección tras los cambios del mundo, sin depender de Flutter.
  GameTransition refresh(GameState state) {
    var dungeon = state.dungeon;
    final events = <GameEvent>[];
    for (final enemy in dungeon.floor.enemies) {
      if (enemy.isDefeated) {
        dungeon = dungeon.removeEnemy(enemy.id);
        events.add(ActorDefeated(enemy.id));
      }
    }
    var updated = identical(dungeon, state.dungeon)
        ? state
        : state.withDungeon(dungeon);
    if (dungeon.adventurer.isDefeated) {
      return GameTransition(updated.withEncounter(null), events);
    }

    final previous = updated.encounter;
    final ids = EncounterDetection.enemyIds(dungeon, encounter: previous);
    if (ids.isEmpty) {
      if (previous != null) {
        updated = updated.withEncounter(null);
        events.add(const EncounterWon());
      }
      return GameTransition(updated, events);
    }
    if (previous == null) {
      updated = updated.withEncounter(
        EncounterState(
          enemyIds: ids,
          activeActorId: dungeon.adventurer.id,
          remainingMovement: dungeon.adventurer.combatMovementSpeed,
        ),
      );
      events.add(const EncounterStarted());
      return GameTransition(updated, events);
    }

    final membershipChanged =
        ids.length != previous.enemyIds.length ||
        !ids.containsAll(previous.enemyIds);
    if (membershipChanged) {
      updated = updated.withEncounter(previous.copyWith(enemyIds: ids));
    }
    if (dungeon.actorById(previous.activeActorId) == null) {
      final next = _advanceTurn(updated);
      updated = next.state;
      events.addAll(next.events);
    }
    return GameTransition(updated, events);
  }

  bool _canAct(GameState state, String actorId) => state.encounter == null
      ? actorId == state.dungeon.adventurer.id
      : actorId == state.encounter?.activeActorId;

  GameTransition _move(GameState state, MoveActor command) {
    final encounter = state.encounter;
    if (encounter != null && encounter.remainingMovement == 0) {
      return GameTransition.rejected(state);
    }
    final from = state.dungeon.positionOf(command.actorId);
    final dungeon = state.dungeon.stepActorTo(
      actorId: command.actorId,
      destination: command.destination,
    );
    if (from == null || identical(dungeon, state.dungeon)) {
      return GameTransition.rejected(state);
    }

    var updated = state.withDungeon(dungeon);
    if (encounter != null) {
      updated = updated.withEncounter(
        encounter.copyWith(remainingMovement: encounter.remainingMovement - 1),
      );
    }
    return GameTransition(updated, [
      ActorMoved(actorId: command.actorId, from: from, to: command.destination),
    ]);
  }

  GameTransition _attack(GameState state, AttackActor command) {
    if (!canAttack(
      state,
      actorId: command.actorId,
      targetId: command.targetId,
    )) {
      return GameTransition.rejected(state);
    }
    final actor = state.dungeon.actorById(command.actorId);
    final target = state.dungeon.actorById(command.targetId);
    final targetPosition = state.dungeon.positionOf(command.targetId);
    if (actor == null || target == null || targetPosition == null) {
      return GameTransition.rejected(state);
    }

    var updated = state;
    final events = <GameEvent>[];
    if (updated.encounter == null) {
      updated = updated.withEncounter(
        EncounterState(
          enemyIds: [command.targetId],
          activeActorId: actor.id,
          remainingMovement: actor.combatMovementSpeed,
        ),
      );
      events.add(const EncounterStarted());
    }
    final currentEncounter = updated.encounter;
    if (target is DungeonEnemy &&
        currentEncounter != null &&
        !currentEncounter.enemyIds.contains(target.id)) {
      updated = updated.withEncounter(
        currentEncounter.copyWith(
          enemyIds: [...currentEncounter.enemyIds, target.id],
        ),
      );
    }
    // También se oye un primer golpe letal: la alerta precede a retirar al objetivo.
    final alerted = refresh(updated);
    updated = alerted.state;
    events.addAll(alerted.events);
    final damage = BasicAttack.damageFor(actor);
    final health = math.max(0, target.health - damage);
    final dungeon = target is DungeonEnemy
        ? updated.dungeon.withEnemy(target.copyWith(health: health))
        : updated.dungeon.withAdventurer(
            updated.dungeon.adventurer.copyWith(health: health),
          );
    updated = updated.withDungeon(dungeon);
    final encounter = updated.encounter;
    if (encounter != null) {
      updated = updated.withEncounter(
        encounter.copyWith(actionAvailable: false),
      );
    }
    events.add(
      AttackResolved(
        actorId: actor.id,
        targetId: target.id,
        damage: damage,
        remainingHealth: health,
        targetPosition: targetPosition,
      ),
    );
    if (target.id == dungeon.adventurer.id && health == 0) {
      events.add(ActorDefeated(target.id));
    }
    final settled = refresh(updated);
    return GameTransition(settled.state, [...events, ...settled.events]);
  }

  GameTransition _advanceTurn(GameState state) {
    final encounter = state.encounter;
    if (encounter == null) {
      return GameTransition.rejected(state);
    }
    final dungeon = state.dungeon;
    final order = state.isPlayerTurn
        ? encounter.enemyIds
        : encounter.enemyTurnOrder;
    final nextIndex = state.isPlayerTurn
        ? 0
        : order.indexOf(encounter.activeActorId) + 1;
    for (var index = nextIndex; index < order.length; index++) {
      final enemy = dungeon.floor.enemyById(order[index]);
      if (enemy == null || enemy.isDefeated) {
        continue;
      }
      return GameTransition(
        state.withEncounter(
          encounter.copyWith(
            enemyTurnOrder: order,
            activeActorId: enemy.id,
            remainingMovement: enemy.combatMovementSpeed,
            actionAvailable: true,
          ),
        ),
        [ActorTurnStarted(enemy.id)],
      );
    }

    return GameTransition(
      state.withEncounter(
        encounter.copyWith(
          enemyTurnOrder: const [],
          activeActorId: dungeon.adventurer.id,
          round: encounter.round + 1,
          remainingMovement: dungeon.adventurer.combatMovementSpeed,
          actionAvailable: true,
        ),
      ),
      [ActorTurnStarted(dungeon.adventurer.id)],
    );
  }
}
