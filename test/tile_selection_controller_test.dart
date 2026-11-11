import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/floors/floor_0.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_controller.dart';

void main() {
  test(
    'Inspection returns the top object or solid terrain without invoking it',
    () {
      var interactions = 0;
      const position = GridPosition(6, 6);
      const grass = DungeonGroundObject.grass(position);
      final stairs = InteractiveDungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: position,
        onInteract: (_) => interactions++,
      );
      final floor = _floor(objects: [grass, stairs]);
      final inspection = floor.inspectTile(position);
      expect(inspection?.position, position);
      expect(inspection?.tile, DungeonTile.floor);
      expect(inspection?.object, same(stairs));
      expect(
        floor.inspectTile(const GridPosition(5, 5))?.tile,
        DungeonTile.water,
      );
      expect(
        floor.inspectTile(const GridPosition(0, 0))?.tile,
        DungeonTile.wall,
      );
      expect(floor.inspectTile(const GridPosition(4, 4)), isNull);
      expect(floor.inspectTile(const GridPosition(8, 8)), isNull);
      expect(floor.inspectTile(const GridPosition(-1, 0)), isNull);
      expect(floor.inspectTile(const GridPosition(15, 0)), isNull);
      expect(interactions, 0);
    },
  );

  test(
    'Tile selection clears the route and switching back restores character control',
    () {
      const grass = DungeonGroundObject.grass(GridPosition(6, 6));
      final controller = DungeonController(
        Dungeon.start(_floor(objects: [grass])),
      );
      addTearDown(controller.dispose);
      controller.selectCharacter();
      controller.beginDrag();
      controller.preview(DungeonDirection.east);
      expect(controller.canConfirm, isTrue);
      controller.selectTile(const GridPosition(5, 5));
      expect(controller.selectedPosition, const GridPosition(5, 5));
      expect(controller.inspectedTile?.tile, DungeonTile.water);
      expect(controller.isSelected, isFalse);
      expect(controller.plan.path, isEmpty);
      expect(controller.phase, MovementPhase.idle);
      controller.beginDrag();
      controller.preview(DungeonDirection.east);
      controller.confirm();
      expect(controller.isMoving, isFalse);
      expect(controller.canConfirm, isFalse);

      controller.selectTile(const GridPosition(6, 6));
      expect(controller.inspectedTile?.object, same(grass));
      controller.selectCharacter();
      expect(controller.selectedPosition, controller.dungeon.player);
      expect(controller.isSelected, isTrue);
      expect(controller.inspectedTile, isNull);
      controller.beginDrag();
      controller.preview(DungeonDirection.east);
      expect(controller.canConfirm, isTrue);
    },
  );

  test(
    'Empty tiles clear any selection while outside coordinates are ignored',
    () {
      final controller = DungeonController(Dungeon.start(_floor()));
      addTearDown(controller.dispose);
      controller.selectCharacter();
      controller.selectTile(const GridPosition(8, 8));
      expect(controller.selectedPosition, isNull);
      expect(controller.isSelected, isFalse);
      controller.selectTile(const GridPosition(5, 5));
      controller.selectTile(const GridPosition(-1, 5));
      expect(controller.selectedPosition, const GridPosition(5, 5));
      controller.selectTile(const GridPosition(4, 4));
      expect(controller.selectedPosition, isNull);
      controller.selectTile(const GridPosition(5, 5));
      controller.unselect();
      expect(controller.inspectedTile, isNull);
      expect(controller.selectedPosition, isNull);
    },
  );

  test(
    'The character takes priority over an object under the occupied tile',
    () {
      const stairs = DungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: GridPosition(7, 7),
      );
      final controller = DungeonController(
        Dungeon.start(_floor(objects: [stairs])),
      );
      addTearDown(controller.dispose);
      controller.selectTile(const GridPosition(7, 7));
      expect(controller.isSelected, isTrue);
      expect(controller.inspectedTile, isNull);
      controller.beginDrag();
      controller.preview(DungeonDirection.east);
      expect(controller.canConfirm, isTrue);
    },
  );

  testWidgets(
    'Movement keeps character selection and blocks switching or unselecting',
    (tester) async {
      final controller = DungeonController(Dungeon.start(_floor()));
      addTearDown(controller.dispose);
      controller.selectCharacter();
      controller.beginDrag();
      controller.preview(DungeonDirection.east, steps: 2);
      controller.confirm();
      controller.selectTile(const GridPosition(5, 5));
      controller.selectTile(const GridPosition(8, 8));
      controller.unselect();
      expect(controller.isSelected, isTrue);
      await tester.pump(DungeonController.stepDuration);
      expect(controller.dungeon.player, const GridPosition(8, 7));
      expect(controller.selectedPosition, const GridPosition(8, 7));
      expect(controller.isSelected, isTrue);
      await tester.pump(DungeonController.stepDuration);
      expect(controller.selectedPosition, const GridPosition(9, 7));
      expect(controller.isSelected, isTrue);
      controller.selectTile(const GridPosition(5, 5));
      expect(controller.inspectedTile?.tile, DungeonTile.water);
    },
  );

  test('Pause and shared menu locks preserve the current selection', () {
    final controller = DungeonController(Dungeon.start(_floor()));
    addTearDown(controller.dispose);
    controller.selectTile(const GridPosition(5, 5));
    final reason = Object();
    controller.disableBottomMenu(reason);
    controller.selectCharacter();
    controller.selectTile(const GridPosition(8, 8));
    controller.unselect();
    expect(controller.selectedPosition, const GridPosition(5, 5));
    controller.enableBottomMenu(reason);
    controller.pause();
    controller.selectCharacter();
    controller.selectTile(const GridPosition(0, 0));
    controller.unselect();
    expect(controller.selectedPosition, const GridPosition(5, 5));
    controller.resume();
    controller.selectCharacter();
    expect(controller.isSelected, isTrue);
  });

  test(
    'Inspecting stairs is passive and changing floors clears the inspection',
    () {
      final stairs = InteractiveDungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: const GridPosition(8, 7),
        onInteract: (context) => context.requestFloorChange(2),
      );
      final controller = DungeonController(
        Dungeon.start(_floor(objects: [stairs])),
      );
      addTearDown(controller.dispose);
      controller.selectTile(stairs.position);
      expect(controller.inspectedTile?.object, same(stairs));
      expect(controller.pendingFloorChange, isNull);
      expect(controller.interactWith(stairs), isTrue);
      controller.selectCharacter();
      controller.selectTile(const GridPosition(8, 8));
      expect(controller.inspectedTile?.object, same(stairs));
      expect(controller.completeFloorChange(_floor(number: 2)), isTrue);
      expect(controller.inspectedTile, isNull);
      expect(controller.selectedPosition, isNull);
      expect(controller.isSelected, isFalse);
    },
  );

  test(
    'Removing the inspected object clears selection if its tile becomes empty',
    () {
      final item = InteractiveDungeonGroundObject(
        type: GroundObjectType.grass,
        position: const GridPosition(6, 6),
        onInteract: (context) => context.updateDungeon(
          context.dungeon.removeGroundObject(context.object),
        ),
      );
      final controller = DungeonController(
        Dungeon.start(_floor(objects: [item])),
      );
      addTearDown(controller.dispose);
      controller.selectTile(item.position);
      expect(controller.interactWith(item), isTrue);
      expect(controller.selectedPosition, isNull);
      expect(controller.inspectedTile, isNull);
    },
  );
}

DungeonFloor _floor({
  List<DungeonGroundObject> objects = const [],
  int number = 1,
}) => DungeonFloorTemplate(
  number: number,
  rows: floor0.rows,
  terrainOverlay: [
    for (var row = 0; row < DungeonFloor.size; row++)
      [
        for (var column = 0; column < DungeonFloor.size; column++)
          if (row == 5 && column == 5)
            'w'
          else if (row == 4 && column == 4)
            '_'
          else
            '.',
      ].join(),
  ],
  groundObjects: objects,
).create();
