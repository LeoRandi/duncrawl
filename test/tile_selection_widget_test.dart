import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/app/dungeon_theme.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/floors/floor_1.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_controller.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_page.dart';
import 'package:duncrawl/features/dungeon/presentation/movement_menu.dart';
import 'package:duncrawl/features/settings/domain/game_settings.dart';

void main() {
  testWidgets(
    'Tile taps inspect objects, clear on empty ground and restore character controls',
    (tester) async {
      final settings = ValueNotifier(const GameSettings(skipTutorials: true));
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: DungeonTheme.dark,
          home: DungeonPage(settings: settings),
        ),
      );
      await tester.pumpAndSettle();
      final panel = find.byKey(const ValueKey('option-menu'));
      await _tapTile(tester, const GridPosition(7, 1));
      expect(_board(tester).selectedTile, const GridPosition(7, 1));
      expect(_board(tester).isSelected, isFalse);
      expect(
        find.descendant(of: panel, matching: find.byIcon(Icons.stairs_rounded)),
        findsOneWidget,
      );
      expect(find.text('Confirm'), findsNothing);
      expect(_board(tester).floor.number, 0);

      await _tapTile(tester, const GridPosition(6, 6));
      expect(_board(tester).selectedTile, isNull);
      expect(find.text('Select something to continue'), findsOneWidget);
      await _tapTile(tester, const GridPosition(7, 7));
      expect(_board(tester).isSelected, isTrue);
      final distance = tester.getSize(find.byType(DungeonBoard)).width / 15 * 2;
      await tester.drag(find.byType(DungeonBoard), Offset(distance * 1.2, 0));
      await tester.pump();
      expect(_board(tester).movementPath, isNotEmpty);
      await _tapTile(tester, const GridPosition(0, 7));
      expect(_board(tester).isSelected, isFalse);
      expect(_board(tester).movementPath, isEmpty);
      expect(
        find.descendant(of: panel, matching: find.text('Wall')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey(('selected-tile', GridPosition(0, 7)))),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('player-portrait')));
      await tester.pump();
      expect(_board(tester).isSelected, isTrue);
      expect(find.text('Confirm'), findsOneWidget);
      await _tapTile(tester, const GridPosition(6, 6));
      expect(_board(tester).isSelected, isFalse);
      expect(find.text('Select something to continue'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('player-portrait')));
      await tester.pump();
      await tester.drag(find.byType(DungeonBoard), Offset(distance * 2.2, 0));
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      await _tapTile(tester, const GridPosition(7, 1));
      expect(_board(tester).isSelected, isTrue);
      await tester.pump(const Duration(milliseconds: 600));
      expect(_board(tester).player, const GridPosition(9, 7));
      expect(_board(tester).selectedTile, _board(tester).player);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Water and grass show their tile glyphs, names and descriptions',
    (tester) async {
      final floor = floor1.create();
      final controller = DungeonController(Dungeon.start(floor));
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
      final panel = find.byKey(const ValueKey('option-menu'));
      for (final (position, name, glyph) in [
        (const GridPosition(5, 6), 'Water', 'w'),
        (const GridPosition(1, 1), 'Grass', 'g'),
      ]) {
        await _tapTile(tester, position);
        expect(_board(tester).selectedTile, position);
        expect(
          find.descendant(of: panel, matching: find.text(name)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: panel, matching: find.text(glyph)),
          findsOneWidget,
        );
        expect(find.text('Confirm'), findsNothing);
        await tester.drag(find.byType(DungeonBoard), const Offset(80, 0));
        await tester.pump();
        expect(controller.dungeon.player, floor.spawn);
        expect(controller.selectedPosition, position);
      }
      await tester.tap(find.text('Unselect'));
      await tester.pump();
      expect(controller.selectedPosition, isNull);
      expect(find.text('Select something to continue'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

DungeonBoard _board(WidgetTester tester) =>
    tester.widget<DungeonBoard>(find.byType(DungeonBoard));

Future<void> _tapTile(WidgetTester tester, GridPosition position) async {
  final grid = tester.getRect(find.byType(DungeonBoard));
  final tileSize = grid.width / 15;
  await tester.tapAt(
    grid.topLeft +
        Offset(
          (position.column + 0.5) * tileSize,
          (position.row + 0.5) * tileSize,
        ),
  );
  await tester.pump();
}
