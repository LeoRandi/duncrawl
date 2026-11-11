import '../domain/dungeon_floor.dart';
import '../domain/grid_position.dart';
import '../domain/ground_object_interaction_context.dart';

const floor2 = DungeonFloorTemplate(
  number: 2,
  rows: [
    '###############',
    '#.............#',
    '#.............#',
    '#.............#',
    '#....##########',
    '#.............#',
    '#.............#',
    '#.............#',
    '#.............#',
    '#.............#',
    '##########....#',
    '#.............#',
    '#.@...........#',
    '#.............#',
    '###############',
  ],
  terrainOverlay: [
    '...............',
    '...............',
    '...............',
    '...............',
    '...............',
    '...2...........',
    '.w...........w.',
    '.ww..1......ww.',
    '.w...........w.',
    '...............',
    '...............',
    '...............',
    '...............',
    '...............',
    '...............',
  ],
  objectRows: [
    '...............',
    '...............',
    '...............',
    '..gg...........',
    '..gg...........',
    '..g............',
    '.....gggssggg..',
    '...ggssssssg...',
    '....ggssssg....',
    '...............',
    '...............',
    '..........ssg..',
    '...........gg..',
    '...........gg..',
    '...............',
  ],
  groundObjects: [
    InteractiveDungeonGroundObject(
      type: GroundObjectType.stairsUp,
      position: GridPosition(13, 3),
      stopsMovement: true,
      interactionKind: GroundObjectInteractionKind.stairs,
      onInteract: _goUpstairs,
    ),
  ],
);

void _goUpstairs(GroundObjectInteractionContext context) {
  return;
}
