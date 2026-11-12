import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/presentation/cardinal_drag.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_controller.dart';

import 'support/combat_fixture.dart';

void main() {
  testWidgets(
    'Combat inspection preserves spent resources and clears only previews',
    (tester) async {
      final controller = DungeonController(
        combatFixture(enemies: [const GridPosition(8, 7)]),
      );
      addTearDown(controller.dispose);
      controller.beginAttack();
      controller.aim(DungeonDirection.east);
      controller.confirmAction();
      await tester.pump(DungeonController.stepDuration);
      controller.beginMove();
      controller.beginPadDrag();
      controller.preview(DungeonDirection.west);
      controller.endDrag();
      controller.confirmAction();
      await tester.pump(DungeonController.stepDuration);
      final encounter = controller.encounter;
      expect(encounter?.remainingMovement, 2);
      expect(encounter?.actionAvailable, isFalse);

      controller.beginPadDrag();
      controller.preview(DungeonDirection.west);
      controller.endDrag();
      controller.closeControls();
      expect(controller.controlMode, ControlMode.inspect);
      expect(controller.plan.path, isEmpty);
      expect(controller.encounter, same(encounter));
      expect(controller.plan.remainingMovement, 2);
      controller.selectTile(const GridPosition(8, 7));
      expect(controller.selectedInspection?.enemy, isNotNull);
      controller.beginMove();
      expect(controller.controlMode, ControlMode.move);
      expect(controller.encounter, same(encounter));
      expect(controller.plan.remainingMovement, 2);
      expect(controller.canAttack, isFalse);

      controller.endTurn();
      controller.closeControls();
      expect(controller.controlMode, ControlMode.move);
      expect(controller.isEnemyTurn, isTrue);
      controller.pause();
    },
  );

  test(
    'Separate drags extend a route; a cancelled drag restores its snapshot',
    () {
      final controller = DungeonController(combatFixture(enemies: const []));
      addTearDown(controller.dispose);
      controller.beginMove();
      controller.beginPadDrag();
      controller.preview(DungeonDirection.east);
      controller.endDrag();
      expect(controller.dungeon.player, const GridPosition(7, 7));
      expect(controller.canConfirm, isTrue);

      controller.beginPadDrag();
      controller.preview(DungeonDirection.north);
      controller.endDrag();
      const route = [GridPosition(8, 7), GridPosition(8, 6)];
      expect(controller.plan.path, route);

      controller.beginPadDrag();
      controller.preview(DungeonDirection.south);
      expect(controller.plan.path, [const GridPosition(8, 7)]);
      controller.preview(DungeonDirection.west);
      expect(controller.plan.path, isEmpty);
      controller.cancelPadDrag();
      expect(controller.plan.path, route);
      expect(controller.canConfirm, isTrue);

      controller.beginPadDrag();
      controller.preview(DungeonDirection.north);
      controller.pause();
      expect(controller.plan.path, route);
      controller.resume();
      expect(controller.canConfirm, isTrue);
      controller.cancelAction();
      expect(controller.plan.path, isEmpty);
      expect(controller.controlMode, ControlMode.move);
    },
  );

  test(
    'Control, inspection and aim remain independent and modes clear previews',
    () {
      final controller = DungeonController(
        combatFixture(enemies: [const GridPosition(8, 7)]),
      );
      addTearDown(controller.dispose);
      controller.beginPadDrag();
      controller.preview(DungeonDirection.west);
      controller.endDrag();
      controller.selectTile(const GridPosition(8, 7));
      expect(controller.isSelected, isFalse);
      expect(controller.canConfirm, isTrue);
      expect(controller.controlledActorId, controller.dungeon.adventurer.id);

      controller.beginAttack();
      expect(controller.plan.path, isEmpty);
      final inspected = controller.selectedInspection;
      controller.aim(DungeonDirection.east);
      expect(controller.canStrike, isTrue);
      expect(controller.selectedInspection, inspected);
      controller.selectCharacter();
      expect(controller.aimDirection, DungeonDirection.east);
      expect(controller.canStrike, isTrue);
      controller.aim(DungeonDirection.north);
      expect(controller.canStrike, isFalse);
      expect(controller.aimedPosition, const GridPosition(7, 6));
      controller.confirmAction();
      expect(controller.encounter?.actionAvailable, isTrue);
      expect(controller.dungeon.floor.enemies.single.health, 3);
      controller.aim(null);
      expect(controller.aimedPosition, isNull);
      controller.aim(DungeonDirection.east);
      controller.beginMove();
      expect(controller.attackTargetId, isNull);
      expect(controller.aimedPosition, isNull);
      expect(controller.encounter?.actionAvailable, isTrue);
    },
  );

  test('Aim has a central dead zone and resolves only cardinal directions', () {
    expect(CardinalDrag.directionFor(dx: 0, dy: 0), isNull);
    expect(CardinalDrag.directionFor(dx: 8, dy: 8), isNull);
    expect(CardinalDrag.directionFor(dx: 12, dy: 0), isNull);
    expect(CardinalDrag.directionFor(dx: 20, dy: -15), DungeonDirection.east);
    expect(CardinalDrag.directionFor(dx: -20, dy: 15), DungeonDirection.west);
    expect(CardinalDrag.directionFor(dx: 15, dy: -20), DungeonDirection.north);
    expect(CardinalDrag.directionFor(dx: -15, dy: 20), DungeonDirection.south);
  });
}
