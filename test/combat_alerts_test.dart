import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/adventurer.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_enemy.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_visibility.dart';
import 'package:duncrawl/features/dungeon/domain/game_command.dart';
import 'package:duncrawl/features/dungeon/domain/game_event.dart';
import 'package:duncrawl/features/dungeon/domain/game_rules.dart';
import 'package:duncrawl/features/dungeon/domain/game_state.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';

import 'support/combat_fixture.dart';

void main() {
  const rules = GameRules();

  test(
    'Alert range defaults to twice vision and explicit overrides survive copies',
    () {
      const bat = DungeonEnemy.bat(GridPosition(8, 7), id: 'bat');
      expect(bat.alertRadius, 4);
      expect(bat.copyWith(visionRadius: 3).alertRadius, 6);
      final custom = bat.copyWith(alertRadius: 7);
      expect(custom.copyWith(visionRadius: 1, health: 2).alertRadius, 7);
      expect(
        custom.copyWith(position: const GridPosition(9, 7)).alertRadius,
        7,
      );
      expect(bat.copyWith(alertRadius: 0).alertRadius, 0);
      expect(bat.isWithinAlertRange(const GridPosition(10, 9)), isTrue);
      expect(bat.isWithinAlertRange(const GridPosition(11, 9)), isFalse);
    },
  );

  test('Being inside alert range alone does not start combat', () {
    final dungeon = combatFixture(enemies: [const GridPosition(11, 7)]);
    final bat = dungeon.floor.enemies.single;
    expect(bat.isWithinAlertRange(dungeon.player), isTrue);
    expect(bat.visionArea, isNot(contains(dungeon.player)));
    final transition = rules.refresh(GameState(dungeon: dungeon));
    expect(transition.state.mode, GameMode.exploration);
    expect(transition.events, isEmpty);
  });

  test('An engaged player alerts an enemy beyond its vision', () {
    final dungeon = combatFixture(
      enemies: [const GridPosition(8, 7), const GridPosition(11, 7)],
    );
    final distant = dungeon.floor.enemies.last;
    expect(distant.visionArea, isNot(contains(dungeon.player)));
    final state = rules.refresh(GameState(dungeon: dungeon)).state;
    expect(
      state.encounter?.enemyIds.toSet(),
      dungeon.floor.enemies.map((enemy) => enemy.id).toSet(),
    );
    expect(state.isPlayerTurn, isTrue);
    expect(state.encounter?.round, 1);
    expect(state.encounter?.remainingMovement, 3);
  });

  test(
    'Enemies can hear a fighting creature even when the player is out of alert range',
    () {
      final dungeon = combatFixture(
        enemies: [const GridPosition(8, 7), const GridPosition(12, 7)],
      );
      final distant = dungeon.floor.enemies.last;
      expect(distant.isWithinAlertRange(dungeon.player), isFalse);
      expect(
        distant.isWithinAlertRange(dungeon.floor.enemies.first.position),
        isTrue,
      );
      final state = rules.refresh(GameState(dungeon: dungeon)).state;
      expect(state.encounter?.enemyIds, contains(distant.id));
    },
  );

  test('Hearing works through walls while direct sight remains blocked', () {
    final dungeon = combatFixture(
      enemies: [const GridPosition(8, 7), const GridPosition(12, 7)],
      walls: {const GridPosition(10, 7)},
    );
    final first = dungeon.floor.enemies.first;
    final distant = dungeon.floor.enemies.last;
    expect(
      DungeonVisibility.hasLineOfSight(
        dungeon.floor,
        from: distant.position,
        to: first.position,
      ),
      isFalse,
    );
    expect(distant.isWithinAlertRange(dungeon.player), isFalse);
    expect(
      rules.refresh(GameState(dungeon: dungeon)).state.encounter?.enemyIds,
      contains(distant.id),
    );
  });

  test(
    'Alert propagation follows chains without cycles or dependence on enemy order',
    () {
      final dungeon = combatFixture(
        enemies: [
          const GridPosition(8, 7),
          const GridPosition(12, 7),
          const GridPosition(13, 10),
        ],
      );
      final farthest = dungeon.floor.enemies.last;
      expect(farthest.isWithinAlertRange(dungeon.player), isFalse);
      expect(
        farthest.isWithinAlertRange(dungeon.floor.enemies.first.position),
        isFalse,
      );
      final state = rules.refresh(GameState(dungeon: dungeon)).state;
      expect(
        state.encounter?.enemyIds.toSet(),
        dungeon.floor.enemies.map((enemy) => enemy.id).toSet(),
      );
      expect(state.encounter?.enemyIds, hasLength(3));
      var reversed = dungeon;
      for (final enemy in dungeon.floor.enemies) {
        reversed = reversed.removeEnemy(enemy.id);
      }
      for (final enemy in dungeon.floor.enemies.reversed) {
        reversed = reversed.addEnemy(enemy);
      }
      expect(
        rules
            .refresh(GameState(dungeon: reversed))
            .state
            .encounter
            ?.enemyIds
            .toSet(),
        state.encounter?.enemyIds.toSet(),
      );
      expect(rules.refresh(state).events, isEmpty);
    },
  );

  test(
    'Per-enemy overrides and the inclusive range boundary are respected',
    () {
      for (final (column, joins) in [(12, true), (13, false)]) {
        final dungeon = combatFixture(
          enemies: [const GridPosition(8, 7), GridPosition(column, 7)],
        );
        final distant = dungeon.floor.enemies.last;
        final state = rules.refresh(GameState(dungeon: dungeon)).state;
        expect(state.encounter?.enemyIds.contains(distant.id), joins);
      }
      final dungeon = combatFixture(
        enemies: [const GridPosition(8, 7), const GridPosition(12, 7)],
      );
      final quiet = dungeon.floor.enemies.last.copyWith(alertRadius: 0);
      final state = rules
          .refresh(GameState(dungeon: dungeon.withEnemy(quiet)))
          .state;
      expect(state.encounter?.enemyIds, isNot(contains(quiet.id)));
    },
  );

  test('An initial lethal attack is heard before the victim is removed', () {
    var dungeon = combatFixture(
      adventurer: const Adventurer(strength: 3),
      enemies: [const GridPosition(8, 7), const GridPosition(12, 7)],
      visionRadius: 0,
    );
    final victim = dungeon.floor.enemies.first;
    final listener = dungeon.floor.enemies.last.copyWith(alertRadius: 4);
    dungeon = dungeon.withEnemy(listener);
    final initial = rules.refresh(GameState(dungeon: dungeon)).state;
    expect(initial.mode, GameMode.exploration);
    final attack = rules.resolve(
      initial,
      AttackActor(actorId: dungeon.adventurer.id, targetId: victim.id),
    );
    expect(attack.state.dungeon.actorById(victim.id), isNull);
    expect(attack.state.encounter?.enemyIds, [listener.id]);
    expect(attack.state.encounter?.actionAvailable, isFalse);
    expect(attack.events.whereType<EncounterStarted>(), hasLength(1));
    expect(attack.events.whereType<EncounterWon>(), isEmpty);
  });

  test('Defeated creatures cannot relay alerts', () {
    var dungeon = combatFixture(
      enemies: [
        const GridPosition(8, 7),
        const GridPosition(12, 7),
        const GridPosition(13, 10),
      ],
    );
    final relay = dungeon.floor.enemies[1];
    final distant = dungeon.floor.enemies.last;
    dungeon = dungeon.withEnemy(relay.copyWith(health: 0));
    final state = rules.refresh(GameState(dungeon: dungeon)).state;
    expect(state.dungeon.actorById(relay.id), isNull);
    expect(state.encounter?.enemyIds, [dungeon.floor.enemies.first.id]);
    expect(state.encounter?.enemyIds, isNot(contains(distant.id)));
  });
}
