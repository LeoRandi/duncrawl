import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/domain/ground_object_interaction_request.dart';
import 'package:duncrawl/features/dungeon/floors/floor_0.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_controller.dart';

void main() {
  testWidgets(
    'Automatic stairs keep triggering after arrival without a prompt',
    (tester) async {
      var climbed = 0;
      final stairs = InteractiveDungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: const GridPosition(8, 7),
        stopsMovement: true,
        interactionKind: GroundObjectInteractionKind.stairs,
        onInteract: (context) {
          climbed++;
          context.requestFloorChange(100);
        },
      );
      final controller = DungeonController(Dungeon.start(_floor([stairs])));
      addTearDown(controller.dispose);
      controller.selectCharacter();
      controller.beginDrag();
      controller.preview(DungeonDirection.east, steps: 3);
      expect(controller.plan.path, [const GridPosition(8, 7)]);
      expect(climbed, 0);
      controller.endDrag();
      controller.confirm();
      await tester.pump(DungeonController.stepDuration);
      expect(climbed, 1);
      expect(controller.pendingInteraction, isNull);
      expect(controller.pendingFloorChange?.floorNumber, 100);
      expect(controller.isMoving, isFalse);
    },
  );

  testWidgets('A stairs callback is deferred until Yes and is applied once', (
    tester,
  ) async {
    var climbed = 0;
    final stairs = InteractiveDungeonGroundObject(
      type: GroundObjectType.stairsUp,
      position: const GridPosition(8, 7),
      stopsMovement: true,
      interactionKind: GroundObjectInteractionKind.stairs,
      onInteract: (context) {
        climbed++;
        context.requestFloorChange(100);
      },
    );
    final controller = DungeonController(
      Dungeon.start(_floor([stairs])),
      requiresConfirmation: (object) =>
          object.interactionKind == GroundObjectInteractionKind.stairs,
    );
    addTearDown(controller.dispose);
    controller.selectCharacter();
    await _walk(tester, controller, DungeonDirection.east, steps: 3);
    expect(controller.dungeon.player, const GridPosition(8, 7));
    expect(controller.pendingInteraction?.object, same(stairs));
    expect(controller.pendingFloorChange, isNull);
    expect(controller.isBottomMenuEnabled, isFalse);
    expect(climbed, 0);
    final request = _pending(controller);
    controller.pause();
    expect(
      controller.respondToInteraction(request: request, accept: true),
      isTrue,
    );
    expect(
      controller.respondToInteraction(request: request, accept: true),
      isFalse,
    );
    expect(climbed, 1);
    expect(controller.pendingInteraction, isNull);
    expect(controller.pendingFloorChange?.floorNumber, 100);
    expect(controller.completeFloorChange(_floor([], number: 100)), isTrue);
    controller.resume();
    expect(controller.dungeon.floor.number, 100);
    expect(controller.pendingInteraction, isNull);
  });

  testWidgets(
    'No leaves the player in place and asks again only after leaving and re-entering',
    (tester) async {
      var climbed = 0;
      final stairs = InteractiveDungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: const GridPosition(8, 7),
        stopsMovement: true,
        interactionKind: GroundObjectInteractionKind.stairs,
        onInteract: (_) => climbed++,
      );
      final controller = DungeonController(
        Dungeon.start(_floor([stairs])),
        requiresConfirmation: (object) =>
            object.interactionKind == GroundObjectInteractionKind.stairs,
      );
      addTearDown(controller.dispose);
      controller.selectCharacter();
      await _walk(tester, controller, DungeonDirection.east);
      expect(controller.pendingInteraction?.object, same(stairs));
      final declinedRequest = _pending(controller);
      expect(
        controller.respondToInteraction(
          request: declinedRequest,
          accept: false,
        ),
        isTrue,
      );
      expect(controller.dungeon.player, const GridPosition(8, 7));
      expect(controller.pendingFloorChange, isNull);
      expect(climbed, 0);
      controller.pause();
      controller.resume();
      controller.unselect();
      controller.selectCharacter();
      controller.beginDrag();
      controller.cancelDrag();
      await tester.pump(const Duration(seconds: 1));
      expect(controller.pendingInteraction, isNull);
      controller.beginDrag();
      controller.preview(DungeonDirection.east);
      expect(controller.plan.path, [const GridPosition(9, 7)]);
      controller.endDrag();
      controller.confirm();
      await tester.pump(DungeonController.stepDuration);
      expect(controller.dungeon.player, const GridPosition(9, 7));
      expect(controller.pendingInteraction, isNull);
      await _walk(tester, controller, DungeonDirection.west);
      expect(controller.dungeon.player, const GridPosition(8, 7));
      expect(controller.pendingInteraction?.object, same(stairs));
      expect(climbed, 0);
      final revisitedRequest = _pending(controller);
      expect(
        controller.respondToInteraction(request: declinedRequest, accept: true),
        isFalse,
      );
      expect(controller.pendingInteraction, same(revisitedRequest));
      controller.respondToInteraction(request: revisitedRequest, accept: false);
    },
  );

  for (final autoPickup in [true, false]) {
    testWidgets(
      'Auto-pickup $autoPickup keeps generic effects automatic and only consumes approved items',
      (tester) async {
        var pickups = 0;
        var genericEffects = 0;
        final generic = InteractiveDungeonGroundObject(
          type: GroundObjectType.stairsUp,
          position: const GridPosition(8, 7),
          onInteract: (context) {
            genericEffects++;
            final adventurer = context.dungeon.adventurer;
            context.updateDungeon(
              context.dungeon.withAdventurer(
                adventurer.copyWith(health: adventurer.health - 1),
              ),
            );
          },
        );
        final pickup = InteractiveDungeonGroundObject(
          type: GroundObjectType.stairsUp,
          position: const GridPosition(8, 7),
          interactionKind: GroundObjectInteractionKind.pickup,
          onInteract: (context) {
            pickups++;
            context.updateDungeon(
              context.dungeon.removeGroundObject(context.object),
            );
          },
        );
        final controller = DungeonController(
          Dungeon.start(_floor([generic, pickup])),
          requiresConfirmation: (object) =>
              !autoPickup &&
              object.interactionKind == GroundObjectInteractionKind.pickup,
        );
        addTearDown(controller.dispose);
        controller.selectCharacter();
        await _walk(tester, controller, DungeonDirection.east, steps: 2);
        expect(genericEffects, 1);
        expect(controller.dungeon.adventurer.health, 9);
        if (autoPickup) {
          expect(controller.dungeon.player, const GridPosition(9, 7));
          expect(controller.pendingInteraction, isNull);
        } else {
          expect(controller.dungeon.player, const GridPosition(8, 7));
          expect(pickups, 0);
          expect(controller.pendingInteraction?.object, same(pickup));
          final pickupRequest = _pending(controller);
          controller.respondToInteraction(request: pickupRequest, accept: true);
          await _walk(tester, controller, DungeonDirection.east);
        }
        expect(pickups, 1);
        expect(controller.dungeon.floor.groundObjects, isNot(contains(pickup)));
        expect(controller.pendingFloorChange, isNull);
        await _walk(tester, controller, DungeonDirection.west);
        expect(pickups, 1);
        expect(genericEffects, 2);
        expect(controller.dungeon.adventurer.health, 8);
        expect(controller.pendingInteraction, isNull);
      },
    );
  }

  testWidgets(
    'Co-located choices stay ordered, No consumes one request and removed entries are skipped',
    (tester) async {
      final activations = <String>[];
      final first = InteractiveDungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: const GridPosition(8, 7),
        interactionKind: GroundObjectInteractionKind.pickup,
        onInteract: (_) => activations.add('first'),
      );
      final removed = InteractiveDungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: const GridPosition(8, 7),
        interactionKind: GroundObjectInteractionKind.pickup,
        onInteract: (_) => activations.add('removed'),
      );
      final second = InteractiveDungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: const GridPosition(8, 7),
        interactionKind: GroundObjectInteractionKind.pickup,
        onInteract: (context) {
          activations.add('second');
          context.updateDungeon(context.dungeon.removeGroundObject(removed));
        },
      );
      final last = InteractiveDungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: const GridPosition(8, 7),
        interactionKind: GroundObjectInteractionKind.pickup,
        onInteract: (_) => activations.add('last'),
      );
      final generic = InteractiveDungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: const GridPosition(8, 7),
        onInteract: (_) => activations.add('generic'),
      );
      final controller = DungeonController(
        Dungeon.start(_floor([first, second, removed, last, generic])),
        requiresConfirmation: (object) =>
            object.interactionKind == GroundObjectInteractionKind.pickup,
      );
      addTearDown(controller.dispose);
      controller.selectCharacter();
      await _walk(tester, controller, DungeonDirection.east);
      expect(controller.pendingInteraction?.object, same(first));
      expect(activations, isEmpty);
      final firstRequest = _pending(controller);
      controller.respondToInteraction(request: firstRequest, accept: false);
      expect(controller.pendingInteraction?.object, same(second));
      final secondRequest = _pending(controller);
      expect(
        controller.respondToInteraction(request: firstRequest, accept: true),
        isFalse,
      );
      expect(controller.pendingInteraction, same(secondRequest));
      expect(activations, isEmpty);
      controller.respondToInteraction(request: secondRequest, accept: true);
      expect(controller.pendingInteraction?.object, same(last));
      final lastRequest = _pending(controller);
      expect(activations, ['second']);
      expect(
        controller.respondToInteraction(request: secondRequest, accept: true),
        isFalse,
      );
      expect(controller.pendingInteraction, same(lastRequest));
      controller.respondToInteraction(request: lastRequest, accept: true);
      expect(controller.pendingInteraction, isNull);
      expect(activations, ['second', 'last', 'generic']);
      expect(controller.interactWith(removed), isFalse);
      expect(controller.isBottomMenuEnabled, isTrue);
    },
  );
}

GroundObjectInteractionRequest _pending(DungeonController controller) {
  final request = controller.pendingInteraction;
  if (request == null) {
    fail('An unanswered interaction must be pending.');
  }
  return request;
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
