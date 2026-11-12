import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/adventurer.dart';
import 'package:duncrawl/features/dungeon/domain/basic_attack.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_visibility.dart';
import 'package:duncrawl/features/dungeon/domain/enemy_tactics.dart';
import 'package:duncrawl/features/dungeon/domain/game_command.dart';
import 'package:duncrawl/features/dungeon/domain/game_event.dart';
import 'package:duncrawl/features/dungeon/domain/game_rules.dart';
import 'package:duncrawl/features/dungeon/domain/game_state.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/domain/movement_plan.dart';

import 'support/combat_fixture.dart';

void main() {
  const rules = GameRules();

  test('New stats survive copies, movement and floor changes', () {
    const hero = Adventurer(strength: 5, dexterity: 4, special: 3);
    final dungeon = combatFixture(adventurer: hero);
    final bat = dungeon.floor.enemies.first.copyWith(
      strength: 3,
      dexterity: 2,
      special: 4,
    );
    final updated = dungeon
        .withEnemy(bat)
        .stepActorTo(actorId: bat.id, destination: const GridPosition(9, 6));
    expect(updated.actorById(bat.id)?.strength, 3);
    expect(updated.actorById(bat.id)?.dexterity, 2);
    expect(updated.actorById(bat.id)?.special, 4);
    final arrived = updated
        .withAdventurer(hero.copyWith(health: 4))
        .enterFloor(combatFixture(enemies: const []).floor);
    expect(arrived.adventurer.strength, 5);
    expect(arrived.adventurer.dexterity, 4);
    expect(arrived.adventurer.special, 3);
  });

  test(
    'Detection and the displayed sight area obey walls and closed corners',
    () {
      final blocked = combatFixture(walls: {const GridPosition(8, 7)});
      final bat = blocked.floor.enemies.single;
      final area = DungeonVisibility.visibleArea(blocked.floor, bat);
      expect(bat.visionArea, contains(blocked.player));
      expect(area, isNot(contains(blocked.player)));
      expect(area, contains(const GridPosition(8, 7)));
      expect(
        rules.refresh(GameState(dungeon: blocked)).state.mode,
        GameMode.exploration,
      );
      final corner = combatFixture(
        enemies: [const GridPosition(8, 8)],
        walls: {const GridPosition(8, 7)},
      );
      expect(
        rules.refresh(GameState(dungeon: corner)).state.mode,
        GameMode.exploration,
      );
      final pool = combatFixture(water: {const GridPosition(8, 7)});
      expect(
        rules.refresh(GameState(dungeon: pool)).state.mode,
        GameMode.combat,
      );
    },
  );

  test(
    'Detection starts a player turn with a fresh reduced movement budget',
    () {
      final transition = rules.refresh(GameState(dungeon: combatFixture()));
      expect(transition.events.whereType<EncounterStarted>(), hasLength(1));
      expect(transition.state.isPlayerTurn, isTrue);
      expect(transition.state.encounter?.remainingMovement, 3);
      expect(transition.state.encounter?.actionAvailable, isTrue);
      expect(transition.state.encounter?.round, 1);
    },
  );

  test('A basic attack reaches only the four adjacent tiles', () {
    const origin = GridPosition(7, 7);
    for (final tile in [
      const GridPosition(6, 7),
      const GridPosition(8, 7),
      const GridPosition(7, 6),
      const GridPosition(7, 8),
    ]) {
      expect(BasicAttack.reaches(attacker: origin, target: tile), isTrue);
    }
    for (final tile in [
      origin,
      const GridPosition(8, 8),
      const GridPosition(9, 7),
    ]) {
      expect(BasicAttack.reaches(attacker: origin, target: tile), isFalse);
    }
  });

  test('Damage is exactly zero plus STR, including zero Strength', () {
    for (final strength in [0, 1, 4]) {
      final dungeon = combatFixture(
        adventurer: Adventurer(strength: strength),
        enemies: [const GridPosition(8, 7)],
        enemyHealth: 10,
      );
      final initial = rules.refresh(GameState(dungeon: dungeon)).state;
      final bat = dungeon.floor.enemies.single;
      final hit = rules.resolve(
        initial,
        AttackActor(actorId: dungeon.adventurer.id, targetId: bat.id),
      );
      expect(hit.accepted, isTrue);
      expect(hit.state.dungeon.actorById(bat.id)?.health, 10 - strength);
      expect(hit.events.whereType<AttackResolved>().single.damage, strength);
      expect(hit.state.encounter?.actionAvailable, isFalse);
      expect(hit.state.encounter?.remainingMovement, 3);
      expect(
        rules
            .resolve(
              hit.state,
              AttackActor(actorId: dungeon.adventurer.id, targetId: bat.id),
            )
            .accepted,
        isFalse,
      );
      expect(initial.dungeon.actorById(bat.id)?.health, 10);
    }
  });

  test(
    'Killing the last bat resumes the same dungeon without restoring HP',
    () {
      final dungeon = combatFixture(
        adventurer: const Adventurer(strength: 8, health: 6),
        enemies: [const GridPosition(8, 7)],
      );
      final initial = rules.refresh(GameState(dungeon: dungeon)).state;
      final bat = dungeon.floor.enemies.single;
      final won = rules.resolve(
        initial,
        AttackActor(actorId: dungeon.adventurer.id, targetId: bat.id),
      );
      expect(won.state.mode, GameMode.exploration);
      expect(won.state.dungeon.floor.enemies, isEmpty);
      expect(won.state.dungeon.player, dungeon.player);
      expect(won.state.dungeon.adventurer.health, 6);
      expect(won.events.whereType<ActorDefeated>(), hasLength(1));
      expect(won.events.whereType<EncounterWon>(), hasLength(1));
      expect(
        rules.refresh(won.state).events.whereType<EncounterWon>(),
        isEmpty,
      );
      expect(dungeon.floor.enemies, hasLength(1));
    },
  );

  test(
    'Invalid targets, nonadjacent attacks and commands out of turn spend nothing',
    () {
      final state = rules.refresh(GameState(dungeon: combatFixture())).state;
      final heroId = state.dungeon.adventurer.id;
      final batId = state.dungeon.floor.enemies.single.id;
      for (final command in <GameCommand>[
        AttackActor(actorId: heroId, targetId: batId),
        AttackActor(actorId: heroId, targetId: heroId),
        AttackActor(actorId: heroId, targetId: 'missing'),
        MoveActor(actorId: batId, destination: const GridPosition(8, 7)),
        EndActorTurn(batId),
      ]) {
        final rejected = rules.resolve(state, command);
        expect(rejected.accepted, isFalse);
        expect(rejected.state, same(state));
      }
    },
  );

  test(
    'Movement remains spent across separate plans and refreshes only next turn',
    () {
      var state = rules.refresh(GameState(dungeon: combatFixture())).state;
      final heroId = state.dungeon.adventurer.id;
      state = rules
          .resolve(
            state,
            MoveActor(actorId: heroId, destination: const GridPosition(6, 7)),
          )
          .state;
      final plan = MovementPlan.start(
        state.dungeon,
        movementBudget: state.encounter?.remainingMovement,
      );
      expect(plan.movementBudget, 2);
      expect(plan.extend(DungeonDirection.west, steps: 5).path, hasLength(2));
      state = rules
          .resolve(
            state,
            MoveActor(actorId: heroId, destination: const GridPosition(5, 7)),
          )
          .state;
      state = rules
          .resolve(
            state,
            MoveActor(actorId: heroId, destination: const GridPosition(4, 7)),
          )
          .state;
      expect(
        rules
            .resolve(
              state,
              MoveActor(actorId: heroId, destination: const GridPosition(3, 7)),
            )
            .accepted,
        isFalse,
      );
      state = rules.resolve(state, EndActorTurn(heroId)).state;
      final enemyId = state.encounter!.activeActorId;
      state = rules.resolve(state, EndActorTurn(enemyId)).state;
      expect(state.encounter?.remainingMovement, 3);
      expect(state.encounter?.round, 2);
      expect(state.encounter?.actionAvailable, isTrue);
    },
  );

  test('Newly alerted enemies wait for the next enemy phase', () {
    final dungeon = combatFixture(
      enemies: [const GridPosition(8, 7), const GridPosition(13, 7)],
    );
    var state = rules.refresh(GameState(dungeon: dungeon)).state;
    final heroId = dungeon.adventurer.id;
    final first = dungeon.floor.enemies.first;
    final reinforcement = dungeon.floor.enemies.last;
    state = rules.resolve(state, EndActorTurn(heroId)).state;
    state = rules
        .refresh(
          state.withDungeon(
            state.dungeon.withEnemy(
              reinforcement.copyWith(position: const GridPosition(9, 7)),
            ),
          ),
        )
        .state;
    expect(state.encounter?.enemyIds, contains(reinforcement.id));
    expect(state.encounter?.enemyTurnOrder, [first.id]);
    state = rules.resolve(state, EndActorTurn(first.id)).state;
    expect(state.isPlayerTurn, isTrue);
    state = rules.resolve(state, EndActorTurn(heroId)).state;
    expect(state.encounter?.enemyTurnOrder, [first.id, reinforcement.id]);
  });

  test(
    'Enemy tactics navigate around blocking terrain and never spend player resources',
    () {
      var state = rules
          .refresh(
            GameState(
              dungeon: combatFixture(
                enemies: [const GridPosition(9, 7)],
                water: {const GridPosition(8, 7)},
              ),
            ),
          )
          .state;
      final heroId = state.dungeon.adventurer.id;
      state = rules.resolve(state, EndActorTurn(heroId)).state;
      const tactics = EnemyTactics();
      final first = tactics.nextCommand(state);
      expect(first, isA<MoveActor>());
      expect((first as MoveActor).destination, isNot(const GridPosition(8, 7)));
      for (var step = 0; step < 8 && !state.isPlayerTurn; step++) {
        final command = tactics.nextCommand(state);
        expect(command, isNotNull);
        state = rules.refresh(rules.resolve(state, command!).state).state;
      }
      expect(state.isPlayerTurn, isTrue);
      expect(state.encounter?.remainingMovement, 3);
      expect(state.encounter?.actionAvailable, isTrue);
    },
  );

  test(
    'A lethal bat attack clamps HP at zero and prevents further commands',
    () {
      var state = rules
          .refresh(
            GameState(
              dungeon: combatFixture(
                adventurer: const Adventurer(health: 1),
                enemies: [const GridPosition(8, 7)],
              ),
            ),
          )
          .state;
      state = rules
          .resolve(state, EndActorTurn(state.dungeon.adventurer.id))
          .state;
      final hit = rules.resolve(
        state,
        AttackActor(
          actorId: state.encounter!.activeActorId,
          targetId: state.dungeon.adventurer.id,
        ),
      );
      expect(hit.state.mode, GameMode.defeated);
      expect(hit.state.dungeon.adventurer.health, 0);
      expect(hit.state.encounter, isNull);
      expect(hit.events.whereType<ActorDefeated>(), hasLength(1));
      expect(
        rules
            .resolve(hit.state, EndActorTurn(hit.state.dungeon.adventurer.id))
            .accepted,
        isFalse,
      );
    },
  );

  test(
    'A removed active enemy is skipped without executing its queued turn',
    () {
      final dungeon = combatFixture(
        enemies: [const GridPosition(8, 7), const GridPosition(7, 8)],
      );
      var state = rules.refresh(GameState(dungeon: dungeon)).state;
      state = rules.resolve(state, EndActorTurn(dungeon.adventurer.id)).state;
      final removedId = state.encounter!.activeActorId;
      final settled = rules.refresh(
        state.withDungeon(state.dungeon.removeEnemy(removedId)),
      );
      state = settled.state;
      expect(state.encounter?.activeActorId, isNot(removedId));
      expect(state.encounter?.enemyIds, isNot(contains(removedId)));
      expect(
        const EnemyTactics().nextCommand(state)?.actorId,
        isNot(removedId),
      );
      expect(state.dungeon.adventurer.health, 10);
    },
  );

  test(
    'Losing sight does not reset combat and an unreachable enemy ends its turn',
    () {
      var state = rules.refresh(GameState(dungeon: combatFixture())).state;
      final enclosed = combatFixture(
        walls: {
          const GridPosition(6, 7),
          const GridPosition(8, 7),
          const GridPosition(7, 6),
          const GridPosition(7, 8),
        },
      );
      state = rules.refresh(state.withDungeon(enclosed)).state;
      expect(state.mode, GameMode.combat);
      state = rules.resolve(state, EndActorTurn(enclosed.adventurer.id)).state;
      final command = const EnemyTactics().nextCommand(state);
      expect(command, isA<EndActorTurn>());
      state = rules.resolve(state, command!).state;
      expect(state.isPlayerTurn, isTrue);
      expect(state.encounter?.round, 2);
      expect(state.dungeon.adventurer.health, 10);
    },
  );
}
