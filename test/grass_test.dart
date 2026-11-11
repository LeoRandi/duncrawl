import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/app/dungeon_theme.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/domain/movement_plan.dart';
import 'package:duncrawl/features/dungeon/floors/floor_1.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_strings.dart';

void main() {
  test('Floor 1 uses the drawn grass map with stairs taking priority', () {
    final floor = floor1.create();
    final grass = _grass(floor);
    final positions = grass.map((object) => object.position).toSet();
    final expected = <GridPosition>{
      for (var row = 0; row < floor1.objectRows.length; row++)
        for (var column = 0; column < DungeonFloor.size; column++)
          if (floor1.objectRows[row][column] == 'g' &&
              const GridPosition(2, 2) != GridPosition(column, row))
            GridPosition(column, row),
    };
    expect(positions, expected);
    expect(positions.length, 34);
    expect(positions.length, grass.length);
    expect(positions.every(floor.canEnter), isTrue);
    expect(positions, isNot(contains(floor.spawn)));
    for (final stairs in floor.groundObjects.where(
      (object) => object.type == GroundObjectType.stairsUp,
    )) {
      expect(positions, isNot(contains(stairs.position)));
    }

    expect(grass.whereType<InteractiveDungeonGroundObject>(), isEmpty);
  });

  test(
    'Grass remains ordinary walkable ground when planning and executing movement',
    () {
      final floor = floor1.create();
      final grass = _grass(
        floor,
      ).firstWhere((object) => object.position.isAdjacentTo(floor.spawn));
      final direction = DungeonDirection.values.firstWhere(
        (direction) => direction.stepFrom(floor.spawn) == grass.position,
      );
      final dungeon = Dungeon.start(floor);
      final plan = MovementPlan.start(dungeon).extend(direction);
      expect(plan.path, [grass.position]);
      expect(dungeon.stepTo(grass.position).player, grass.position);
      expect(floor.interactiveObjectsAt(grass.position), isEmpty);
    },
  );

  testWidgets(
    'Grass renders as light-grey g glyphs in the ground-object layer',
    (tester) async {
      final floor = floor1.create();
      await tester.pumpWidget(
        MaterialApp(
          theme: DungeonTheme.dark,
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 300,
                child: MediaQuery(
                  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: DungeonBoard(floor: floor, player: floor.spawn),
                ),
              ),
            ),
          ),
        ),
      );

      final glyphs = find.descendant(
        of: find.byKey(const ValueKey(DungeonLayer.groundObjects)),
        matching: find.text('g'),
      );
      expect(glyphs, findsNWidgets(_grass(floor).length));
      for (final glyph in tester.widgetList<Text>(glyphs)) {
        expect(glyph.style?.color, DungeonColors.grass);
        expect(glyph.style?.fontFamily, 'monospace');
        expect(glyph.semanticsLabel, DungeonStrings.grass);
        expect(glyph.textScaler, TextScaler.noScaling);
      }
      final centerGlyph = find.byKey(
        const ValueKey(('grass', GridPosition(4, 7))),
      );
      expect(
        (tester.getCenter(centerGlyph) -
                (tester.getCenter(find.byType(DungeonBoard)) -
                    const Offset(60, 0)))
            .distance,
        lessThan(0.001),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey(DungeonLayer.characters)),
          matching: find.text('g'),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

List<DungeonGroundObject> _grass(DungeonFloor floor) => floor.groundObjects
    .where((object) => object.type == GroundObjectType.grass)
    .toList();
