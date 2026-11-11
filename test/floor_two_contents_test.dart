import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/app/dungeon_theme.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_enemy.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/domain/movement_plan.dart';
import 'package:duncrawl/features/dungeon/floors/floor_0.dart';
import 'package:duncrawl/features/dungeon/floors/floor_2.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_controller.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_strings.dart';
import 'package:duncrawl/features/dungeon/presentation/movement_menu.dart';

void main() {
  test(
    'Floor 2 keeps its drawn objects and parses numbered Bat placeholders',
    () {
      final floor = floor2.create();
      final markers = _positions(floor2.rows, {'1', '2', '3'});
      expect(floor.enemies.map((enemy) => enemy.position).toSet(), markers);
      expect(floor.enemies, hasLength(3));
      for (final enemy in floor.enemies) {
        expect(enemy.type, EnemyType.bat);
        expect(floor.tileAt(enemy.position), DungeonTile.floor);
        expect(floor.inspectTile(enemy.position)?.enemy, same(enemy));
      }
      final shallow = floor.groundObjects.where(
        (object) => object.type == GroundObjectType.shallowWater,
      );
      expect(
        shallow.map((object) => object.position).toSet(),
        _positions(floor2.objectRows, {'s'}),
      );
      expect(shallow, hasLength(14));
      for (final object in shallow) {
        expect(floor.canEnter(object.position), isTrue);
        expect(floor.interactiveObjectsAt(object.position), isEmpty);
      }
      final underBat = floor.enemies.firstWhere(
        (enemy) => floor.hasShallowWaterAt(enemy.position),
      );
      final inspection = floor.inspectTile(underBat.position);
      expect(inspection?.enemy, same(underBat));
      expect(inspection?.object?.type, GroundObjectType.shallowWater);
      final withoutObject = floor.removeGroundObject(shallow.first);
      expect(withoutObject.enemies, same(floor.enemies));
      expect(() => floor.enemies.clear(), throwsUnsupportedError);
    },
  );

  test(
    'Shallow Water is walkable over water, while an adjacent deep pool blocks the route',
    () {
      const shallowPosition = GridPosition(8, 7);
      const deepPosition = GridPosition(9, 7);
      final floor = DungeonFloorTemplate(
        number: 9,
        rows: floor0.rows,
        terrainOverlay: _draw({shallowPosition: 'w', deepPosition: 'w'}),
        objectRows: _draw({shallowPosition: 's'}),
      ).create();
      final dungeon = Dungeon.start(floor);
      final plan = MovementPlan.start(
        dungeon,
      ).extend(DungeonDirection.east, steps: 5);
      expect(plan.path, [shallowPosition]);
      final moved = dungeon.stepTo(shallowPosition);
      expect(moved.player, shallowPosition);
      expect(moved.stepTo(deepPosition), same(moved));
      expect(floor.canEnter(deepPosition), isFalse);
      final drained = floor.removeGroundObject(floor.groundObjects.single);
      expect(drained.canEnter(shallowPosition), isFalse);
    },
  );

  testWidgets(
    'Shallow Water uses two colours and Bat selection shows only its name and portrait',
    (tester) async {
      final controller = DungeonController(Dungeon.start(floor2.create()));
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: DungeonTheme.dark,
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, child) => Column(
                children: [
                  SizedBox.square(
                    dimension: 300,
                    child: DungeonBoard(
                      floor: controller.dungeon.floor,
                      player: controller.dungeon.player,
                      selectedTile: controller.selectedPosition,
                      isSelected: controller.isSelected,
                      onSelectTile: controller.selectTile,
                      onSelectPlayer: controller.selectCharacter,
                    ),
                  ),
                  Expanded(child: MovementMenu(controller: controller)),
                ],
              ),
            ),
          ),
        ),
      );
      final characterLayer = find.byKey(
        const ValueKey(DungeonLayer.characters),
      );
      expect(
        find.descendant(of: characterLayer, matching: find.text('B')),
        findsNWidgets(3),
      );
      for (final text in tester.widgetList<Text>(
        find.descendant(of: characterLayer, matching: find.text('B')),
      )) {
        expect(text.style?.color, DungeonColors.enemy);
      }
      final groundLayer = find.byKey(
        const ValueKey(DungeonLayer.groundObjects),
      );
      final shallowSymbols = find.descendant(
        of: groundLayer,
        matching: find.text('sw'),
      );
      expect(shallowSymbols, findsNWidgets(14));
      for (final text in tester.widgetList<Text>(shallowSymbols)) {
        _expectShallowColours(text);
      }
      final shallow = controller.dungeon.floor.groundObjects.firstWhere(
        (object) => object.type == GroundObjectType.shallowWater,
      );
      await _tapTile(tester, shallow.position);
      expect(find.text('Shallow Water'), findsOneWidget);
      expect(find.text(DungeonStrings.waterDescription), findsOneWidget);
      final note = find.text('Shallow: This pool of liquid is walkable');
      expect(note, findsOneWidget);
      expect(
        tester.getTopLeft(note).dy,
        greaterThan(
          tester.getBottomLeft(find.text(DungeonStrings.waterDescription)).dy,
        ),
      );
      final portrait = find.byKey(const ValueKey('tile-inspection-portrait'));
      _expectShallowColours(
        tester.widget<Text>(
          find.descendant(of: portrait, matching: find.text('sw')),
        ),
      );
      final glyph = find.descendant(of: portrait, matching: find.text('sw'));
      expect(
        tester.getRect(portrait).contains(tester.getTopLeft(glyph)),
        isTrue,
      );
      expect(
        tester.getRect(portrait).contains(tester.getBottomRight(glyph)),
        isTrue,
      );

      for (final enemy in controller.dungeon.floor.enemies) {
        await _tapTile(tester, enemy.position);
        expect(find.text('Bat'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('tile-inspection-portrait')),
            matching: find.text('B'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('tile-inspection-description')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('tile-inspection-note')),
          findsNothing,
        );
        expect(find.text('Confirm'), findsNothing);
        expect(controller.isSelected, isFalse);
        expect(controller.inspectedTile?.enemy, same(enemy));
        expect(controller.dungeon.player, controller.dungeon.floor.spawn);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

void _expectShallowColours(Text text) {
  final span = text.textSpan as TextSpan;
  expect(span.toPlainText(), 'sw');
  expect((span.children!.first as TextSpan).text, 's');
  expect(
    (span.children!.first as TextSpan).style?.color,
    DungeonColors.shallowWaterPrefix,
  );
  expect(text.style?.color, DungeonColors.water);
}

Set<GridPosition> _positions(List<String> rows, Set<String> symbols) => {
  for (var row = 0; row < rows.length; row++)
    for (var column = 0; column < rows[row].length; column++)
      if (symbols.contains(rows[row][column])) GridPosition(column, row),
};

List<String> _draw(Map<GridPosition, String> symbols) => [
  for (var row = 0; row < DungeonFloor.size; row++)
    [
      for (var column = 0; column < DungeonFloor.size; column++)
        symbols[GridPosition(column, row)] ?? '.',
    ].join(),
];

Future<void> _tapTile(WidgetTester tester, GridPosition position) async {
  final grid = tester.getRect(find.byType(DungeonBoard));
  final tileSize = grid.width / DungeonFloor.size;
  await tester.tapAt(
    grid.topLeft +
        Offset(
          (position.column + 0.5) * tileSize,
          (position.row + 0.5) * tileSize,
        ),
  );
  await tester.pump();
}
