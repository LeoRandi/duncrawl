import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/floors/floor_0.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_controller.dart';
import 'package:duncrawl/features/settings/domain/movement_speed.dart';

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
        movementInterval: () => speed.stepInterval,
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
  }

  testWidgets(
    'Resuming movement reads an updated speed without losing the route',
    (tester) async {
      var speed = MovementSpeed.slow;
      final controller = DungeonController(
        Dungeon.start(floor0.create()),
        movementInterval: () => speed.stepInterval,
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
