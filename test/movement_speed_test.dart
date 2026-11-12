import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_enemy.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/floors/floor_0.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_controller.dart';
import 'package:duncrawl/features/settings/domain/movement_speed.dart';

import 'support/combat_fixture.dart';

void main() {
  for (final (speed, milliseconds) in [
    (MovementSpeed.slow, 500),
    (MovementSpeed.medium, 300),
    (MovementSpeed.fast, 150),
    (MovementSpeed.ultraFast, 50),
  ]) {
    testWidgets('$speed moves each tile at the selected interval', (
      tester,
    ) async {
      final controller = DungeonController(
        Dungeon.start(floor0.create()),
        playerMovementInterval: () => speed.stepInterval,
      );
      addTearDown(controller.dispose);
      controller.selectCharacter();
      controller.beginDrag();
      controller.preview(DungeonDirection.east, steps: 2);
      controller.endDrag();
      controller.confirm();
      expect(controller.isBottomMenuEnabled, isFalse);
      await tester.pump(Duration(milliseconds: milliseconds - 1));
      expect(controller.dungeon.player, const GridPosition(7, 7));
      await tester.pump(const Duration(milliseconds: 1));
      expect(controller.dungeon.player, const GridPosition(8, 7));
      expect(controller.remainingPath, [const GridPosition(9, 7)]);
      await tester.pump(Duration(milliseconds: milliseconds));
      expect(controller.dungeon.player, const GridPosition(9, 7));
      expect(controller.isMoving, isFalse);
      expect(controller.isBottomMenuEnabled, isTrue);
    });

    testWidgets('Bats keep their own pace with player speed $speed', (
      tester,
    ) async {
      final controller = DungeonController(
        combatFixture(),
        playerMovementInterval: () => speed.stepInterval,
      );
      addTearDown(controller.dispose);
      final bat = controller.dungeon.floor.enemies.single;
      final interval = bat.type.stepInterval;
      const lastMillisecond = Duration(milliseconds: 1);
      controller.endTurn();
      await tester.pump(interval - lastMillisecond);
      expect(controller.dungeon.floor.enemies.single.position, bat.position);
      await tester.pump(lastMillisecond);
      expect(
        controller.dungeon.floor.enemies.single.position,
        const GridPosition(8, 7),
      );
      expect(controller.encounter?.remainingMovement, 1);

      await tester.pump(interval - lastMillisecond);
      expect(controller.dungeon.adventurer.health, 10);
      await tester.pump(lastMillisecond);
      expect(controller.dungeon.adventurer.health, 9);
      expect(controller.isEnemyTurn, isTrue);
      await tester.pump(interval);
      expect(controller.isPlayerTurn, isTrue);
      expect(controller.encounter?.round, 2);
    });
  }

  testWidgets('Changing player speed while paused preserves enemy pacing', (
    tester,
  ) async {
    var speed = MovementSpeed.slow;
    final controller = DungeonController(
      combatFixture(),
      playerMovementInterval: () => speed.stepInterval,
    );
    addTearDown(controller.dispose);
    final interval = EnemyType.bat.stepInterval;
    controller.endTurn();
    await tester.pump(interval);
    expect(
      controller.dungeon.floor.enemies.single.position,
      const GridPosition(8, 7),
    );
    controller.pause();
    speed = MovementSpeed.ultraFast;
    await tester.pump(const Duration(seconds: 2));
    expect(controller.dungeon.adventurer.health, 10);
    controller.resume();
    await tester.pump(interval - const Duration(milliseconds: 1));
    expect(controller.dungeon.adventurer.health, 10);
    await tester.pump(const Duration(milliseconds: 1));
    expect(controller.dungeon.adventurer.health, 9);
    await tester.pump(interval);
    expect(controller.isPlayerTurn, isTrue);
  });

  testWidgets(
    'Each enemy gets its type interval when the active actor changes',
    (tester) async {
      final controller = DungeonController(
        combatFixture(
          enemies: [const GridPosition(9, 7), const GridPosition(7, 9)],
        ),
      );
      addTearDown(controller.dispose);
      final interval = EnemyType.bat.stepInterval;
      controller.endTurn();
      await tester.pump(interval * 3);
      expect(controller.dungeon.adventurer.health, 9);
      expect(controller.isEnemyTurn, isTrue);
      expect(
        controller.dungeon.floor.enemies.last.position,
        const GridPosition(7, 9),
      );
      await tester.pump(interval - const Duration(milliseconds: 1));
      expect(
        controller.dungeon.floor.enemies.last.position,
        const GridPosition(7, 9),
      );
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        controller.dungeon.floor.enemies.last.position,
        const GridPosition(7, 8),
      );
      await tester.pump(interval * 2);
      expect(controller.dungeon.adventurer.health, 8);
      expect(controller.isPlayerTurn, isTrue);
    },
  );

  testWidgets(
    'Resuming movement reads an updated speed without losing the route',
    (tester) async {
      var speed = MovementSpeed.slow;
      final controller = DungeonController(
        Dungeon.start(floor0.create()),
        playerMovementInterval: () => speed.stepInterval,
      );
      addTearDown(controller.dispose);
      controller.selectCharacter();
      controller.beginDrag();
      controller.preview(DungeonDirection.east, steps: 2);
      controller.confirm();
      await tester.pump(const Duration(milliseconds: 500));
      controller.pause();
      await tester.pump(const Duration(seconds: 1));
      expect(controller.dungeon.player, const GridPosition(8, 7));
      speed = MovementSpeed.ultraFast;
      controller.resume();
      await tester.pump(const Duration(milliseconds: 49));
      expect(controller.dungeon.player, const GridPosition(8, 7));
      await tester.pump(const Duration(milliseconds: 1));
      expect(controller.dungeon.player, const GridPosition(9, 7));
    },
  );
}
