import '../domain/dungeon_floor.dart';
import '../domain/grid_position.dart';

// Duplica este fichero, cambia el número y edita las 15 filas de 15 símbolos.
// . suelo libre | _ vacío negro | # pared | @ aparición (una por planta).
// Los objetos sobre el suelo se colocan por separado en groundObjects.
const floor0 = DungeonFloorTemplate(
  number: 0,
  rows: [
    '...............',
    '...............',
    '...............',
    '...............',
    '...............',
    '...............',
    '...............',
    '.......@.......',
    '...............',
    '...............',
    '...............',
    '...............',
    '...............',
    '...............',
    '...............',
  ],
  groundObjects: [
    DungeonGroundObject(
      type: GroundObjectType.stairsUp,
      position: GridPosition(7, 1),
    ),
  ],
);
