import '../domain/dungeon_floor.dart';
import '../domain/grid_position.dart';
import '../domain/ground_object_interaction_context.dart';

const floor1 = DungeonFloorTemplate(
  number: 1,
  rows: [
    '###############',
    '#...#.....#...#',
    '#...#.....#...#',
    '#.............#',
    '###.........###',
    '#.............#',
    '#.............#',
    '#.............#',
    '#.............#',
    '#.............#',
    '###.........###',
    '#.............#',
    '#...#.....#.@.#',
    '#...#.....#...#',
    '###############',
  ],
  terrainOverlay: [
    '...............',
    '...............',
    '...............',
    '...............',
    '...............',
    '...............',
    '.....www.......',
    '.....wwwww.....',
    '.......www.....',
    '...............',
    '...............',
    '...............',
    '...............',
    '...............',
    '...............',
  ],
  objectRows: [
    '...............',
    '.ggg...........',
    '.ggg...........',
    '.ggg...........',
    '...gg..........',
    '....ggg........',
    '....g..........',
    '....g..........',
    '....ggg........',
    '....gg.........',
    '...ggg.....g...',
    '..gggg......gg.',
    '...g.....g.....',
    '........gg.....',
    '...............',
  ],
  groundObjects: [
    InteractiveDungeonGroundObject(
      type: GroundObjectType.stairsUp,
      position: GridPosition(2, 2),
      stopsMovement: true,
      interactionKind: GroundObjectInteractionKind.stairs,
      onInteract: _goUpstairs,
    ),
  ],
);

void _goUpstairs(GroundObjectInteractionContext context) {
  context.requestFloorChange(2);
}
