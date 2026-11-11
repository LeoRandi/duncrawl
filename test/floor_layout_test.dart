import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/app/dungeon_theme.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/domain/movement_plan.dart';
import 'package:duncrawl/features/dungeon/floors/floor_0.dart';
import 'package:duncrawl/features/dungeon/floors/floor_1.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';

void main() {
  test(
    'Terrain dots preserve structure and water blocks movement and previews',
    () {
      final floor = floor1.create();
      final water = <GridPosition>{};
      for (var row = 0; row < DungeonFloor.size; row++) {
        for (var column = 0; column < DungeonFloor.size; column++) {
          final position = GridPosition(column, row);
          if (floor.tileAt(position) == DungeonTile.water) {
            water.add(position);
            expect(floor.canEnter(position), isFalse);
          }
        }
      }
      expect(water, {
        const GridPosition(5, 6),
        const GridPosition(6, 6),
        const GridPosition(7, 6),
        const GridPosition(5, 7),
        const GridPosition(6, 7),
        const GridPosition(7, 7),
        const GridPosition(8, 7),
        const GridPosition(9, 7),
        const GridPosition(7, 8),
        const GridPosition(8, 8),
        const GridPosition(9, 8),
      });
      expect(floor.tileAt(const GridPosition(4, 1)), DungeonTile.wall);
      expect(floor.spawn, const GridPosition(12, 12));

      var dungeon = Dungeon.start(floor);
      dungeon = dungeon
          .move(DungeonDirection.north)
          .move(DungeonDirection.west, steps: 2)
          .move(DungeonDirection.north, steps: 4);
      final plan = MovementPlan.start(dungeon).extend(DungeonDirection.west);
      expect(plan.path, isEmpty);
      expect(plan.remainingMovement, dungeon.adventurer.movementSpeed);
      expect(dungeon.stepTo(const GridPosition(9, 7)), same(dungeon));
      expect(dungeon.move(DungeonDirection.west, steps: 5), same(dungeon));
      final awayFromWater = plan.extend(DungeonDirection.north);
      expect(awayFromWater.path, [const GridPosition(10, 6)]);
    },
  );

  test(
    'Explicit objects clear drawn grass and water while preserving explicit stacks',
    () {
      const position = GridPosition(7, 7);
      const stairs = DungeonGroundObject(
        type: GroundObjectType.stairsUp,
        position: position,
      );
      const grass = DungeonGroundObject.grass(position);
      final template = DungeonFloorTemplate(
        number: 2,
        rows: floor0.rows,
        terrainOverlay: _mapAt(position, 'w'),
        objectRows: _mapAt(position, 'g'),
        groundObjects: const [stairs, grass],
      );
      final floor = template.create();
      expect(floor.tileAt(position), DungeonTile.floor);
      expect(floor.groundObjects, [stairs, grass]);
      expect(floor.groundObjects.first, same(stairs));
      expect(template.terrainOverlay[7][7], 'w');
      expect(template.objectRows[7][7], 'g');
      expect(template.create().groundObjects, [stairs, grass]);
      expect(() => floor.groundObjects.clear(), throwsUnsupportedError);
    },
  );

  test('Water can also be drawn directly in base rows', () {
    final rows = List<String>.of(floor0.rows);
    rows[7] = rows[7].replaceRange(8, 9, 'w');
    final floor = DungeonFloorTemplate(number: 2, rows: rows).create();
    expect(floor.tileAt(const GridPosition(8, 7)), DungeonTile.water);
    expect(floor.canEnter(const GridPosition(8, 7)), isFalse);
  });

  test(
    'Malformed layer sizes, symbols and blocked placements fail clearly',
    () {
      for (final layout in [
        <String>['.'],
        List.filled(15, '..............'),
      ]) {
        expect(
          () => DungeonFloorTemplate(
            number: 2,
            rows: floor0.rows,
            terrainOverlay: layout,
          ).create(),
          throwsFormatException,
        );
        expect(
          () => DungeonFloorTemplate(
            number: 2,
            rows: floor0.rows,
            objectRows: layout,
          ).create(),
          throwsFormatException,
        );
      }
      for (final symbol in ['?', '@', 'g']) {
        expect(
          () => DungeonFloorTemplate(
            number: 2,
            rows: floor0.rows,
            terrainOverlay: _mapAt(const GridPosition(3, 3), symbol),
          ).create(),
          throwsFormatException,
        );
      }
      expect(
        () => DungeonFloorTemplate(
          number: 2,
          rows: floor0.rows,
          objectRows: _mapAt(const GridPosition(3, 3), 'w'),
        ).create(),
        throwsFormatException,
      );
      expect(
        () => DungeonFloorTemplate(
          number: 2,
          rows: floor0.rows,
          objectRows: _mapAt(const GridPosition(0, 0), 'g'),
        ).create(),
        throwsFormatException,
      );
      expect(
        () => DungeonFloorTemplate(
          number: 2,
          rows: floor0.rows,
          terrainOverlay: _mapAt(const GridPosition(7, 7), '#'),
        ).create(),
        throwsFormatException,
      );
      expect(
        () => DungeonFloorTemplate(
          number: 2,
          rows: floor0.rows,
          terrainOverlay: _mapAt(const GridPosition(7, 7), 'w'),
        ).create(),
        throwsFormatException,
      );
      expect(
        () => DungeonFloorTemplate(
          number: 2,
          rows: floor0.rows,
          groundObjects: const [DungeonGroundObject.grass(GridPosition(-1, 0))],
        ).create(),
        throwsFormatException,
      );
    },
  );

  for (final isShallow in [false, true]) {
    testWidgets(
      '${isShallow ? 'Shallow' : 'Deep'} water groups have continuous outlines and no internal tile borders',
      (tester) async {
        final water = {
          const GridPosition(0, 0),
          const GridPosition(1, 0),
          const GridPosition(0, 1),
          const GridPosition(4, 4),
          const GridPosition(5, 4),
          const GridPosition(4, 5),
          const GridPosition(8, 8),
        };
        final waterRows = [
          for (var row = 0; row < DungeonFloor.size; row++)
            [
              for (var column = 0; column < DungeonFloor.size; column++)
                water.contains(GridPosition(column, row))
                    ? (isShallow ? 's' : 'w')
                    : '.',
            ].join(),
        ];
        final floor = DungeonFloorTemplate(
          number: 2,
          rows: floor0.rows.map((row) => row.replaceAll('#', '.')).toList(),
          terrainOverlay: isShallow
              ? [
                  for (var row = 0; row < DungeonFloor.size; row++)
                    [
                      for (var column = 0; column < DungeonFloor.size; column++)
                        row == 4 && (column == 4 || column == 6) ? 'w' : '.',
                    ].join(),
                ]
              : waterRows,
          objectRows: isShallow ? waterRows : const [],
        ).create();
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox.square(
              dimension: 300,
              child: DungeonBoard(floor: floor, player: floor.spawn),
            ),
          ),
        );
        final painter = tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byKey(const ValueKey(DungeonLayer.floorTiles)),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter;
        if (painter == null) {
          fail('The terrain layer must have a painter.');
        }
        await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          painter.paint(Canvas(recorder), const Size(300, 300));
          final picture = recorder.endRecording();
          final image = picture.toImageSync(300, 300);
          try {
            final data = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            if (data == null) {
              fail('The rendered terrain must provide pixel data.');
            }
            List<int> pixel(int x, int y) {
              final offset = (y * 300 + x) * 4;
              return List.generate(
                4,
                (channel) => data.getUint8(offset + channel),
              );
            }

            const interior = [48, 48, 48, 255];
            for (final (x, y) in [(100, 90), (90, 100), (20, 10), (10, 20)]) {
              expect(
                pixel(x, y),
                interior,
                reason: 'No shared edge at ($x, $y).',
              );
            }
            final outline = isShallow
                ? [176, 176, 176, 255]
                : [255, 255, 255, 255];
            for (final (x, y) in [
              (90, 80),
              (80, 90),
              (90, 120),
              (100, 110),
              (110, 100),
              (170, 160),
              (160, 170),
              (180, 170),
              (170, 180),
              (0, 10),
              (10, 0),
            ]) {
              expect(pixel(x, y), outline, reason: 'Exposed edge at ($x, $y).');
            }
            // El límite con agua profunda conserva su borde blanco.
            expect(pixel(120, 90), [255, 255, 255, 255]);
            if (isShallow) {
              expect(pixel(140, 90), [255, 255, 255, 255]);
            }
            expect(pixel(140, 130), [0, 0, 0, 255]);
          } finally {
            image.dispose();
            picture.dispose();
          }
        });
      },
    );
  }

  testWidgets('Water glyphs occupy the terrain layer below objects', (
    tester,
  ) async {
    final floor = floor1.create();
    await tester.pumpWidget(
      MaterialApp(
        theme: DungeonTheme.dark,
        home: Center(
          child: SizedBox.square(
            dimension: 300,
            child: DungeonBoard(floor: floor, player: floor.spawn),
          ),
        ),
      ),
    );
    final glyphs = find.descendant(
      of: find.byKey(const ValueKey(DungeonLayer.floorTiles)),
      matching: find.text('w'),
    );
    expect(glyphs, findsNWidgets(11));
    for (final glyph in tester.widgetList<Text>(glyphs)) {
      expect(glyph.style?.color, DungeonColors.water);
      expect(glyph.semanticsLabel, 'Water');
      expect(glyph.textScaler, TextScaler.noScaling);
    }
    expect(
      find.descendant(
        of: find.byKey(const ValueKey(DungeonLayer.groundObjects)),
        matching: find.text('w'),
      ),
      findsNothing,
    );
    final origin = tester.getTopLeft(find.byType(DungeonBoard));
    expect(
      tester.getCenter(
        find.byKey(const ValueKey(('water', GridPosition(5, 6)))),
      ),
      origin + const Offset(110, 130),
    );
  });
}

List<String> _mapAt(GridPosition position, String symbol) => [
  for (var row = 0; row < DungeonFloor.size; row++)
    [
      for (var column = 0; column < DungeonFloor.size; column++)
        GridPosition(column, row) == position ? symbol : '.',
    ].join(),
];
