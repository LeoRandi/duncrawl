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
  test(
    'Floor 1 grass connects its center to four corners without covering walls or actors',
    () {
      final floor = floor1.create();
      final grass = _grass(floor);
      final positions = grass.map((object) => object.position).toSet();
      const center = GridPosition(7, 7);
      expect(
        positions,
        containsAll([
          center,
          const GridPosition(1, 1),
          const GridPosition(13, 1),
          const GridPosition(1, 13),
          const GridPosition(13, 13),
        ]),
      );
      expect(positions.length, grass.length);
      expect(positions.every(floor.canEnter), isTrue);
      expect(positions, isNot(contains(floor.spawn)));
      for (final stairs in floor.groundObjects.where(
        (object) => object.type == GroundObjectType.stairsUp,
      )) {
        expect(positions, isNot(contains(stairs.position)));
      }

      final connected = <GridPosition>{center};
      final frontier = [center];
      for (var index = 0; index < frontier.length; index++) {
        for (final direction in DungeonDirection.values) {
          final next = direction.stepFrom(frontier[index]);
          if (positions.contains(next) && connected.add(next)) {
            frontier.add(next);
          }
        }
      }
      expect(connected, positions);
      expect(grass.whereType<InteractiveDungeonGroundObject>(), isEmpty);
    },
  );

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
        const ValueKey(('grass', GridPosition(7, 7))),
      );
      expect(
        (tester.getCenter(centerGlyph) -
                tester.getCenter(find.byType(DungeonBoard)))
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
