import 'dungeon.dart';
import 'dungeon_floor.dart';
import 'grid_position.dart';
import 'ground_object_interaction_context.dart';

class GroundObjectInteractionRequest {
  final InteractiveDungeonGroundObject object;
  final GroundObjectTrigger trigger;
  final int floorNumber;
  final GridPosition playerPosition;

  const GroundObjectInteractionRequest({
    required this.object,
    required this.trigger,
    required this.floorNumber,
    required this.playerPosition,
  });

  bool isValidFor(Dungeon dungeon) =>
      dungeon.floor.number == floorNumber &&
      dungeon.player == playerPosition &&
      dungeon.floor.groundObjects.contains(object);
}
