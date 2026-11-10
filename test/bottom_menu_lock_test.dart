import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/floors/floor_0.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_controller.dart';

void main() {
  test('Each action must release its own lock before the menu is enabled', () {
    final controller = DungeonController(Dungeon.start(floor0.create()));
    addTearDown(controller.dispose);
    final firstAction = Object();
    final secondAction = Object();
    controller.selectCharacter();
    controller.disableBottomMenu(firstAction);
    controller.disableBottomMenu(firstAction);
    controller.disableBottomMenu(secondAction);
    controller.enableBottomMenu(firstAction);
    expect(controller.isBottomMenuEnabled, isFalse);
    controller.unselect();
    controller.beginDrag();
    controller.preview(DungeonDirection.east);
    expect(controller.isSelected, isTrue);
    expect(controller.plan.path, isEmpty);
    expect(controller.canConfirm, isFalse);
    controller.enableBottomMenu(Object());
    expect(controller.isBottomMenuEnabled, isFalse);
    controller.enableBottomMenu(secondAction);
    expect(controller.isBottomMenuEnabled, isTrue);
    controller.unselect();
    expect(controller.isSelected, isFalse);
  });

  testWidgets('Completing movement releases only its own lock', (tester) async {
    final controller = DungeonController(Dungeon.start(floor0.create()));
    addTearDown(controller.dispose);
    controller.selectCharacter();
    controller.beginDrag();
    controller.preview(DungeonDirection.east, steps: 2);
    controller.endDrag();
    controller.confirm();
    expect(controller.isBottomMenuEnabled, isFalse);
    final otherAction = Object();
    controller.disableBottomMenu(otherAction);
    controller.unselect();
    expect(controller.isSelected, isTrue);
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.dungeon.player, const GridPosition(9, 7));
    expect(controller.isMoving, isFalse);
    expect(controller.isBottomMenuEnabled, isFalse);
    controller.enableBottomMenu(otherAction);
    expect(controller.isBottomMenuEnabled, isTrue);
  });
}
