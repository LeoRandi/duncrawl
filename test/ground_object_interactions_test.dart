import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/domain/ground_object_interaction_context.dart';
import 'package:duncrawl/features/dungeon/floors/floor_0.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_controller.dart';

void main() {
  testWidgets(
    'Preview never runs callbacks; entry and explicit activation share the interaction',
    (tester) async {
      final triggers = <GroundObjectTrigger>[];
      final positions = <GridPosition>[];
      final sources = <DungeonGroundObject>[];
      final object = InteractiveDungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: const GridPosition(8, 7),
        onInteract: (context) {
          triggers.add(context.trigger);
          positions.add(context.dungeon.player);
          sources.add(context.object);
        },
      );
      final controller = DungeonController(Dungeon.start(_floor([object])));
      addTearDown(controller.dispose);
      controller.selectCharacter();
      controller.beginDrag();
      controller.preview(DungeonDirection.east, steps: 2);
      expect(triggers, isEmpty);
      controller.endDrag();
      controller.confirm();
      await tester.pump(const Duration(milliseconds: 299));
      expect(triggers, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(triggers, [GroundObjectTrigger.enteredTile]);
      expect(positions.single, const GridPosition(8, 7));
      expect(sources.single, same(object));
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.dungeon.player, const GridPosition(9, 7));
      controller.beginDrag();
      controller.preview(DungeonDirection.west);
      controller.endDrag();
      controller.confirm();
      await tester.pump(const Duration(milliseconds: 300));
      expect(triggers, [
        GroundObjectTrigger.enteredTile,
        GroundObjectTrigger.enteredTile,
      ]);
      expect(controller.interactWith(object), isTrue);
      expect(triggers.last, GroundObjectTrigger.activated);
      controller.pause();
      expect(controller.interactWith(object), isFalse);
      controller.resume();
      controller.cancelPreview();
      expect(triggers, hasLength(3));
    },
  );

  testWidgets(
    'Co-located callbacks can consume an object and update health without changing floors',
    (tester) async {
      var collected = 0;
      var activated = 0;
      final pickupWasPresent = <bool>[];
      final pickup = InteractiveDungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: const GridPosition(8, 7),
        onInteract: (context) {
          collected++;
          context.updateDungeon(
            context.dungeon.removeGroundObject(context.object),
          );
        },
      );
      final effect = InteractiveDungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: const GridPosition(8, 7),
        onInteract: (context) {
          activated++;
          pickupWasPresent.add(
            context.dungeon.floor.groundObjects.contains(pickup),
          );
          final adventurer = context.dungeon.adventurer;
          context.updateDungeon(
            context.dungeon.withAdventurer(
              adventurer.copyWith(health: adventurer.health - 3),
            ),
          );
        },
      );
      final template = _floor([pickup, effect]);
      final controller = DungeonController(Dungeon.start(template));
      addTearDown(controller.dispose);
      controller.selectCharacter();
      await _walk(tester, controller, DungeonDirection.east, steps: 2);
      expect(controller.dungeon.player, const GridPosition(9, 7));
      expect(controller.dungeon.adventurer.health, 7);
      expect(controller.pendingFloorChange, isNull);
      expect(controller.interactWith(pickup), isFalse);
      await _walk(tester, controller, DungeonDirection.west);
      expect(collected, 1);
      expect(activated, 2);
      expect(pickupWasPresent, [false, false]);
      expect(controller.dungeon.adventurer.health, 4);
      expect(controller.dungeon.adventurer.maximumHealth, 10);
      expect(controller.dungeon.adventurer.movementSpeed, 5);
      expect(template.groundObjects, contains(pickup));
      expect(controller.dungeon.floor.groundObjects, isNot(contains(pickup)));
    },
  );

  testWidgets(
    'Stopping is object metadata, independent of appearance or callback outcome',
    (tester) async {
      var interactions = 0;
      final object = InteractiveDungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: const GridPosition(8, 7),
        stopsMovement: true,
        onInteract: (_) => interactions++,
      );
      final controller = DungeonController(Dungeon.start(_floor([object])));
      addTearDown(controller.dispose);
      controller.selectCharacter();
      controller.beginDrag();
      controller.preview(DungeonDirection.east, steps: 3);
      expect(controller.plan.path, [const GridPosition(8, 7)]);
      expect(interactions, 0);
      controller.endDrag();
      controller.confirm();
      await tester.pump(const Duration(milliseconds: 300));
      expect(interactions, 1);
      expect(controller.isMoving, isFalse);
      expect(controller.isBottomMenuEnabled, isTrue);
      expect(controller.pendingFloorChange, isNull);
    },
  );

  testWidgets(
    'Entering a floor activates spawn objects once and queues scene changes',
    (tester) async {
      var arrivals = 0;
      final source = _floor([
        InteractiveDungeonGroundObject(
          type: GroundObjectType.stairsUp,
          position: const GridPosition(7, 7),
          onInteract: (context) => context.requestFloorChange(100),
        ),
      ]);
      final destination = _floor([
        InteractiveDungeonGroundObject(
          type: GroundObjectType.stairsUp,
          position: const GridPosition(7, 7),
          onInteract: (context) {
            arrivals++;
            expect(context.trigger, GroundObjectTrigger.enteredTile);
            expect(context.dungeon.floor.number, 100);
            context.updateDungeon(
              context.dungeon.withAdventurer(
                context.dungeon.adventurer.copyWith(health: 6),
              ),
            );
          },
        ),
      ], number: 100);
      final controller = DungeonController(Dungeon.start(source));
      addTearDown(controller.dispose);
      expect(controller.pendingFloorChange?.floorNumber, 100);
      expect(controller.dungeon.floor.number, 99);
      expect(controller.isBottomMenuEnabled, isFalse);
      expect(controller.completeFloorChange(source), isFalse);
      controller.pause();
      expect(controller.completeFloorChange(destination), isTrue);
      expect(controller.dungeon.floor.number, 100);
      expect(controller.dungeon.adventurer.health, 6);
      controller.resume();
      controller.selectCharacter();
      controller.cancelPreview();
      expect(arrivals, 1);
      expect(controller.pendingFloorChange, isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(arrivals, 1);
    },
  );

  testWidgets(
    'Callbacks skip objects removed earlier in the same tile-entry batch',
    (tester) async {
      var skippedCalls = 0;
      final removed = InteractiveDungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: const GridPosition(8, 7),
        onInteract: (_) => skippedCalls++,
      );
      final remover = InteractiveDungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: const GridPosition(8, 7),
        onInteract: (context) =>
            context.updateDungeon(context.dungeon.removeGroundObject(removed)),
      );
      final controller = DungeonController(
        Dungeon.start(_floor([remover, removed])),
      );
      addTearDown(controller.dispose);
      controller.selectCharacter();
      await _walk(tester, controller, DungeonDirection.east);
      expect(skippedCalls, 0);
      expect(controller.interactWith(removed), isFalse);
    },
  );
}

DungeonFloor _floor(List<DungeonGroundObject> objects, {int number = 99}) =>
    DungeonFloorTemplate(
      number: number,
      rows: floor0.rows,
      groundObjects: objects,
    ).create();

Future<void> _walk(
  WidgetTester tester,
  DungeonController controller,
  DungeonDirection direction, {
  int steps = 1,
}) async {
  controller.beginDrag();
  controller.preview(direction, steps: steps);
  controller.endDrag();
  controller.confirm();
  await tester.pump(DungeonController.stepDuration * steps);
}
