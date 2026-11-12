import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/adventurer.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_enemy.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/game_event.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_controller.dart';

import 'support/combat_fixture.dart';

void main() {
  testWidgets(
    'Detection interrupts a confirmed route at the first visible tile',
    (tester) async {
      final controller = DungeonController(
        combatFixture(enemies: [const GridPosition(11, 7)]),
      );
      addTearDown(controller.dispose);
      expect(controller.isInCombat, isFalse);
      controller.selectCharacter();
      controller.beginDrag();
      controller.preview(DungeonDirection.east, steps: 5);
      expect(controller.plan.path, hasLength(3));
      controller.confirm();
      await tester.pump(DungeonController.stepDuration);
      expect(controller.dungeon.player, const GridPosition(8, 7));
      expect(controller.isInCombat, isFalse);
      await tester.pump(DungeonController.stepDuration);
      expect(controller.dungeon.player, const GridPosition(9, 7));
      expect(controller.isMoving, isFalse);
      expect(controller.isPlayerTurn, isTrue);
      expect(controller.encounter?.remainingMovement, 3);
      expect(controller.remainingPath, isEmpty);
      await tester.pump(DungeonController.stepDuration * 3);
      expect(controller.dungeon.player, const GridPosition(9, 7));
    },
  );

  testWidgets(
    'Split routes, cancellation and selection cannot restore spent movement',
    (tester) async {
      final controller = DungeonController(combatFixture());
      addTearDown(controller.dispose);
      controller.beginDrag();
      controller.preview(DungeonDirection.west);
      controller.confirm();
      await tester.pump(DungeonController.stepDuration);
      expect(controller.encounter?.remainingMovement, 2);
      controller.beginDrag();
      controller.preview(DungeonDirection.west, steps: 5);
      expect(controller.plan.path, hasLength(2));
      controller.cancelPreview();
      controller.unselect();
      controller.selectCharacter();
      expect(controller.plan.remainingMovement, 2);
      expect(controller.encounter?.remainingMovement, 2);
    },
  );

  testWidgets(
    'Targeting and cancelling are free; a strike spends exactly one action',
    (tester) async {
      final controller = DungeonController(
        combatFixture(enemies: [const GridPosition(8, 7)]),
      );
      addTearDown(controller.dispose);
      controller.beginAttack();
      controller.selectTile(const GridPosition(8, 8));
      expect(controller.canStrike, isFalse);
      expect(controller.encounter?.actionAvailable, isTrue);
      controller.cancelAttack();
      expect(controller.encounter?.actionAvailable, isTrue);
      controller.beginAttack();
      controller.aim(DungeonDirection.east);
      expect(controller.canStrike, isTrue);
      expect(controller.canEndTurn, isTrue);
      controller.strike();
      controller.strike();
      controller.endTurn();
      expect(controller.dungeon.floor.enemies.single.health, 1);
      expect(controller.encounter?.actionAvailable, isFalse);
      expect(controller.isPlayerTurn, isTrue);
      expect(controller.isBottomMenuEnabled, isFalse);
      await tester.pump(DungeonController.stepDuration);
      expect(controller.isBottomMenuEnabled, isTrue);
      expect(controller.canAttack, isFalse);
      expect(controller.canEndTurn, isTrue);
      expect(controller.lastCombatEvent, isA<AttackResolved>());
    },
  );

  testWidgets(
    'Combat takes precedence over stairs, which resume after victory on their tile',
    (tester) async {
      var climbs = 0;
      final stairs = InteractiveDungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: const GridPosition(8, 7),
        stopsMovement: true,
        interactionKind: GroundObjectInteractionKind.stairs,
        onInteract: (context) {
          climbs++;
          context.requestFloorChange(100);
        },
      );
      final controller = DungeonController(
        combatFixture(
          enemies: [const GridPosition(9, 7)],
          visionRadius: 1,
          enemyHealth: 1,
          objects: [stairs],
        ),
      );
      addTearDown(controller.dispose);
      controller.selectCharacter();
      controller.beginDrag();
      controller.preview(DungeonDirection.east);
      controller.confirm();
      await tester.pump(DungeonController.stepDuration);
      expect(controller.isInCombat, isTrue);
      expect(controller.pendingFloorChange, isNull);
      expect(climbs, 0);
      controller.beginAttack();
      controller.aim(DungeonDirection.east);
      controller.strike();
      expect(controller.isInCombat, isFalse);
      expect(climbs, 0);
      await tester.pump(DungeonController.stepDuration);
      expect(climbs, 1);
      expect(controller.pendingFloorChange?.floorNumber, 100);
      expect(controller.dungeon.floor.enemies, isEmpty);
    },
  );

  testWidgets(
    'Lethal automatic effects resolve before detection and optional interactions',
    (tester) async {
      var climbs = 0;
      final stairs = InteractiveDungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: const GridPosition(8, 7),
        interactionKind: GroundObjectInteractionKind.stairs,
        onInteract: (_) => climbs++,
      );
      final trap = InteractiveDungeonGroundObject(
        type: GroundObjectType.grass,
        position: const GridPosition(8, 7),
        interactionKind: GroundObjectInteractionKind.automatic,
        onInteract: (context) => context.updateDungeon(
          context.dungeon.withAdventurer(
            context.dungeon.adventurer.copyWith(health: 0),
          ),
        ),
      );
      final controller = DungeonController(
        combatFixture(
          enemies: [const GridPosition(10, 7)],
          objects: [stairs, trap],
        ),
      );
      addTearDown(controller.dispose);
      controller.selectCharacter();
      controller.beginDrag();
      controller.preview(DungeonDirection.east);
      controller.confirm();
      await tester.pump(DungeonController.stepDuration);
      expect(controller.isDefeated, isTrue);
      expect(controller.encounter, isNull);
      expect(controller.isMoving, isFalse);
      expect(climbs, 0);
    },
  );

  for (final interval in [
    const Duration(milliseconds: 50),
    const Duration(milliseconds: 300),
  ]) {
    testWidgets(
      'Enemy turns pause and resume with identical outcomes at $interval',
      (tester) async {
        final controller = DungeonController(
          combatFixture(enemies: [const GridPosition(8, 7)]),
          playerMovementInterval: () => interval,
        );
        addTearDown(controller.dispose);
        controller.endTurn();
        expect(controller.isEnemyTurn, isTrue);
        controller.pause();
        await tester.pump(interval * 10);
        expect(controller.dungeon.adventurer.health, 10);
        controller.resume();
        await tester.pump(EnemyType.bat.stepInterval);
        expect(controller.dungeon.adventurer.health, 9);
        await tester.pump(EnemyType.bat.stepInterval);
        expect(controller.isPlayerTurn, isTrue);
        expect(controller.encounter?.round, 2);
        expect(controller.encounter?.remainingMovement, 3);
      },
    );
  }

  testWidgets(
    'Defeat stops enemy processing and disposal cancels pending turns',
    (tester) async {
      final defeated = DungeonController(
        combatFixture(
          adventurer: const Adventurer(health: 1),
          enemies: [const GridPosition(8, 7)],
        ),
      );
      defeated.endTurn();
      await tester.pump(DungeonController.stepDuration);
      expect(defeated.isDefeated, isTrue);
      final snapshot = defeated.dungeon;
      await tester.pump(DungeonController.stepDuration * 10);
      expect(defeated.dungeon, same(snapshot));
      defeated.dispose();

      final disposed = DungeonController(
        combatFixture(enemies: [const GridPosition(8, 7)]),
      );
      disposed.endTurn();
      disposed.dispose();
      await tester.pump(DungeonController.stepDuration * 10);
      expect(disposed.dungeon.adventurer.health, 10);
      expect(tester.takeException(), isNull);
    },
  );
}
