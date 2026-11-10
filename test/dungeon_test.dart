import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/floors/floor_0.dart';
import 'package:duncrawl/features/dungeon/presentation/cardinal_drag.dart';

void main() {
  group('Dungeon movement', () {
    test('Moves one tile in each cardinal direction', () {
      final dungeon = Dungeon.start(floor0.create());
      const destinations = {
        DungeonDirection.north: GridPosition(7, 6),
        DungeonDirection.east: GridPosition(8, 7),
        DungeonDirection.south: GridPosition(7, 8),
        DungeonDirection.west: GridPosition(6, 7),
      };
      for (final entry in destinations.entries) {
        expect(dungeon.move(entry.key).player, entry.value);
      }
      expect(dungeon.player, const GridPosition(7, 7));
    });

    test('Clamps long movements at every boundary', () {
      final dungeon = Dungeon.start(floor0.create());
      const destinations = {
        DungeonDirection.north: GridPosition(7, 0),
        DungeonDirection.east: GridPosition(14, 7),
        DungeonDirection.south: GridPosition(7, 14),
        DungeonDirection.west: GridPosition(0, 7),
      };
      for (final entry in destinations.entries) {
        final atEdge = dungeon.move(entry.key, steps: 100);
        expect(atEdge.player, entry.value);
        expect(atEdge.move(entry.key), same(atEdge));
      }
    });

    test('Stops at walls instead of jumping over them during a long drag', () {
      final rows = [...floor0.rows];
      rows[7] = '.......@.#.....';
      final floor = DungeonFloorTemplate(number: 1, rows: rows).create();
      final dungeon = Dungeon.start(floor);
      expect(
        dungeon.move(DungeonDirection.east, steps: 100).player,
        const GridPosition(8, 7),
      );
    });

    test('Nonpositive steps do not change the dungeon', () {
      final dungeon = Dungeon.start(floor0.create());
      expect(dungeon.move(DungeonDirection.north, steps: 0), same(dungeon));
      expect(dungeon.move(DungeonDirection.north, steps: -1), same(dungeon));
    });
  });

  group('Floor templates', () {
    test(
      'Void blocks movement while stairs remain on ordinary walkable floor',
      () {
        final rows = [...floor0.rows]..[7] = '.......@_......';
        final floor = DungeonFloorTemplate(
          number: 1,
          rows: rows,
          groundObjects: const [
            DungeonGroundObject(
              type: GroundObjectType.stairsUp,
              position: GridPosition(7, 6),
            ),
          ],
        ).create();
        final dungeon = Dungeon.start(floor);

        expect(floor.tileAt(const GridPosition(8, 7)), DungeonTile.voidTile);
        expect(dungeon.move(DungeonDirection.east), same(dungeon));
        expect(floor.tileAt(const GridPosition(7, 6)), DungeonTile.floor);
        expect(
          dungeon.move(DungeonDirection.north).player,
          const GridPosition(7, 6),
        );
      },
    );

    test('Rejects ground objects on void, walls or outside the map', () {
      final rows = [...floor0.rows]
        ..[0] = '#..............'
        ..[7] = '.......@_......';
      for (final position in [
        const GridPosition(0, 0),
        const GridPosition(8, 7),
        const GridPosition(-1, 0),
        const GridPosition(15, 0),
        const GridPosition(0, 15),
      ]) {
        expect(
          () => DungeonFloorTemplate(
            number: 1,
            rows: rows,
            groundObjects: [
              DungeonGroundObject(
                type: GroundObjectType.stairsUp,
                position: position,
              ),
            ],
          ).create(),
          throwsFormatException,
        );
      }
    });

    test('Floor 0 is empty apart from the upper stairs', () {
      final floor = floor0.create();
      expect(floor.number, 0);
      expect(floor.spawn, const GridPosition(7, 7));
      expect(floor.groundObjects, hasLength(1));
      expect(floor.groundObjects.single.type, GroundObjectType.stairsUp);
      expect(floor.groundObjects.single.position, const GridPosition(7, 1));
      expect(floor.tileAt(const GridPosition(7, 1)), DungeonTile.floor);
      var emptyTiles = 0;
      for (var row = 0; row < DungeonFloor.size; row++) {
        for (var column = 0; column < DungeonFloor.size; column++) {
          if (floor.tileAt(GridPosition(column, row)) == DungeonTile.floor) {
            emptyTiles++;
          }
        }
      }
      expect(emptyTiles, 225);
    });

    test(
      'Rejects invalid size, unknown symbols, and missing or duplicate spawns',
      () {
        final wrongWidth = [...floor0.rows]..[0] = '.';
        final unknownSymbol = [...floor0.rows]..[0] = 'X..............';
        final missingSpawn = [...floor0.rows]..[7] = '...............';
        final duplicateSpawn = [...floor0.rows]..[0] = '@..............';
        for (final rows in [
          floor0.rows.sublist(1),
          wrongWidth,
          unknownSymbol,
          missingSpawn,
          duplicateSpawn,
        ]) {
          expect(
            () => DungeonFloorTemplate(number: 1, rows: rows).create(),
            throwsFormatException,
          );
        }
      },
    );
  });

  group('Cardinal dragging', () {
    test('Accumulates small movements until they reach one tile', () {
      final drag = CardinalDrag();
      expect(drag.add(dx: 9, dy: 0, stepDistance: 20), isNull);
      expect(drag.add(dx: 10, dy: 0, stepDistance: 20), isNull);
      expect(drag.add(dx: 1, dy: 0, stepDistance: 20), (
        direction: DungeonDirection.east,
        steps: 1,
      ));
    });

    test('Consumes only the dominant axis of a diagonal gesture', () {
      final drag = CardinalDrag();
      expect(drag.add(dx: -45, dy: 30, stepDistance: 20), (
        direction: DungeonDirection.west,
        steps: 2,
      ));
      expect(drag.add(dx: 0, dy: 0, stepDistance: 20), isNull);
    });

    test('Can change direction during a gesture', () {
      final drag = CardinalDrag();
      expect(drag.add(dx: 20, dy: 0, stepDistance: 20), (
        direction: DungeonDirection.east,
        steps: 1,
      ));
      expect(drag.add(dx: 0, dy: -40, stepDistance: 20), (
        direction: DungeonDirection.north,
        steps: 2,
      ));
    });

    test('A new gesture does not inherit previous movement', () {
      final drag = CardinalDrag();
      drag.add(dx: 19, dy: 0, stepDistance: 20);
      drag.reset();
      expect(drag.add(dx: 1, dy: 0, stepDistance: 20), isNull);
    });
  });
}
