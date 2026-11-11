import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/app/dungeon_theme.dart';
import 'package:duncrawl/features/shards/presentation/shard_text.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/floors/floor_0.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_controller.dart';
import 'package:duncrawl/features/dungeon/presentation/movement_menu.dart';
import 'package:duncrawl/features/dungeon/presentation/selection_panel.dart';
import 'package:duncrawl/features/dungeon/presentation/selection_stack_tab.dart';

void main() {
  testWidgets(
    'Every other content gets a left-aligned tab with its relative layer',
    (tester) async {
      final rows = List<String>.of(floor0.rows);
      rows[7] = rows[7].replaceRange(5, 6, '1');
      final floor = DungeonFloorTemplate(
        number: 9,
        rows: rows,
        groundObjects: const [
          DungeonGroundObject.grass(GridPosition(5, 7)),
          DungeonGroundObject.shallowWater(GridPosition(5, 7)),
        ],
      ).create();
      final controller = DungeonController(Dungeon.start(floor));
      addTearDown(controller.dispose);
      controller.selectTile(const GridPosition(5, 7));
      await tester.pumpWidget(
        MaterialApp(
          theme: DungeonTheme.dark,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 320,
                height: SelectionStackTab.extent,
                child: ListenableBuilder(
                  listenable: controller,
                  builder: (context, child) =>
                      SelectionStackTab(controller: controller),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(OutlinedButton), findsNWidgets(2));
      expect(find.text('Over: Grass'), findsOneWidget);
      expect(find.text('Over: Shallow Water'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('selection-stack-tab'))).dx,
        0,
      );
      await tester.ensureVisible(find.text('Over: Grass'));
      await tester.pump();
      await tester.tap(find.text('Over: Grass'));
      await tester.pump();
      expect(controller.inspectedTile?.object?.type, GroundObjectType.grass);
      expect(find.text('Below: Bat'), findsOneWidget);
      expect(find.text('Below: Shallow Water'), findsOneWidget);
      await tester.ensureVisible(find.text('Below: Shallow Water'));
      await tester.pump();
      await tester.tap(find.text('Below: Shallow Water'));
      await tester.pump();
      expect(
        controller.inspectedTile?.object?.type,
        GroundObjectType.shallowWater,
      );
      expect(find.text('Below: Bat'), findsOneWidget);
      expect(find.text('Over: Grass'), findsOneWidget);
      final lock = Object();
      controller.disableBottomMenu(lock);
      await tester.pump();
      await tester.ensureVisible(find.text('Below: Bat'));
      await tester.pump();
      await tester.tap(find.text('Below: Bat'));
      await tester.pump();
      expect(
        controller.inspectedTile?.object?.type,
        GroundObjectType.shallowWater,
      );
      controller.enableBottomMenu(lock);
      controller.unselect();
      await tester.pump();
      expect(find.byType(OutlinedButton), findsNothing);
    },
  );

  test(
    'Inspecting below the adventurer cancels the plan and returns to the same actor',
    () {
      final controller = DungeonController(Dungeon.start(_floor()));
      addTearDown(controller.dispose);
      controller.selectCharacter();
      controller.beginDrag();
      controller.preview(DungeonDirection.east);
      expect(controller.canConfirm, isTrue);
      expect(
        controller.alternateSelection?.object?.type,
        GroundObjectType.grass,
      );
      controller.toggleStackSelection();
      expect(controller.selectedPosition, controller.dungeon.player);
      expect(controller.isSelected, isFalse);
      expect(controller.inspectedTile?.object?.type, GroundObjectType.grass);
      expect(controller.alternateSelection?.isAdventurer, isTrue);
      expect(controller.isInspectingBelow, isTrue);
      expect(controller.plan.path, isEmpty);
      controller.beginDrag();
      controller.preview(DungeonDirection.east);
      controller.confirm();
      expect(controller.isMoving, isFalse);
      controller.toggleStackSelection();
      expect(controller.isSelected, isTrue);
      expect(controller.isInspectingBelow, isFalse);
      expect(controller.plan.path, isEmpty);
      controller.unselect();
      expect(controller.alternateSelection, isNull);
      controller.selectTile(const GridPosition(8, 7));
      expect(controller.alternateSelection, isNull);
      controller.toggleStackSelection();
      expect(controller.inspectedTile?.object?.type, GroundObjectType.grass);
    },
  );

  test(
    'Bat and Shallow Water alternate as distinct contents of one position',
    () {
      final controller = DungeonController(Dungeon.start(_floor()));
      addTearDown(controller.dispose);
      controller.selectTile(const GridPosition(5, 7));
      final bat = controller.inspectedTile?.enemy;
      expect(bat, isNotNull);
      expect(
        controller.alternateSelection?.object?.type,
        GroundObjectType.shallowWater,
      );
      controller.toggleStackSelection();
      expect(controller.inspectedTile?.enemy, isNull);
      expect(
        controller.inspectedTile?.object?.type,
        GroundObjectType.shallowWater,
      );
      expect(controller.alternateSelection?.enemy, same(bat));
      expect(controller.dungeon.player, const GridPosition(7, 7));
      controller.toggleStackSelection();
      expect(controller.inspectedTile?.enemy, same(bat));
      controller.selectTile(const GridPosition(3, 3));
      expect(controller.isInspectingBelow, isFalse);
      expect(controller.alternateSelection, isNull);
    },
  );

  testWidgets(
    'Locks prevent layer switching and walking refreshes the contents underfoot',
    (tester) async {
      final controller = DungeonController(Dungeon.start(_floor()));
      addTearDown(controller.dispose);
      controller.selectCharacter();
      final lock = Object();
      controller.disableBottomMenu(lock);
      controller.toggleStackSelection();
      expect(controller.isSelected, isTrue);
      controller.enableBottomMenu(lock);
      controller.pause();
      controller.toggleStackSelection();
      expect(controller.isSelected, isTrue);
      controller.resume();
      controller.beginDrag();
      controller.preview(DungeonDirection.east, steps: 2);
      controller.confirm();
      controller.toggleStackSelection();
      expect(controller.isSelected, isTrue);
      await tester.pump(DungeonController.stepDuration);
      expect(controller.alternateSelection?.position, const GridPosition(8, 7));
      controller.toggleStackSelection();
      expect(controller.isSelected, isTrue);
      await tester.pump(DungeonController.stepDuration);
      expect(controller.selectedPosition, const GridPosition(9, 7));
      expect(controller.alternateSelection, isNull);
    },
  );

  test(
    'Removing a lower object clears the tab without changing the selected Bat',
    () {
      final object = InteractiveDungeonGroundObject(
        type: GroundObjectType.grass,
        position: const GridPosition(5, 7),
        onInteract: (context) => context.updateDungeon(
          context.dungeon.removeGroundObject(context.object),
        ),
      );
      final controller = DungeonController(
        Dungeon.start(_floor(extra: object)),
      );
      addTearDown(controller.dispose);
      controller.selectTile(const GridPosition(5, 7));
      final bat = controller.inspectedTile?.enemy;
      expect(controller.alternateSelection?.object, same(object));
      expect(controller.interactWith(object), isTrue);
      expect(controller.inspectedTile?.enemy, same(bat));
      expect(controller.alternateSelection, isNull);
      expect(controller.pendingFloorChange, isNull);
    },
  );

  testWidgets(
    'All selected contents share portrait/button geometry and layer tabs switch info',
    (tester) async {
      for (final (width, scale) in [(320.0, 1.5), (528.0, 1.0)]) {
        final controller = DungeonController(Dungeon.start(_floor()));
        await tester.pumpWidget(
          MaterialApp(
            theme: DungeonTheme.dark,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: MediaQuery(
                    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                    child: ListenableBuilder(
                      listenable: controller,
                      builder: (context, child) => Column(
                        children: [
                          SizedBox.square(
                            dimension: 240,
                            child: DungeonBoard(
                              floor: controller.dungeon.floor,
                              player: controller.dungeon.player,
                              selectedTile: controller.selectedPosition,
                              isSelected: controller.isSelected,
                            ),
                          ),
                          SizedBox(
                            height: SelectionStackTab.extent,
                            child: SelectionStackTab(controller: controller),
                          ),
                          Expanded(child: MovementMenu(controller: controller)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        controller.selectCharacter();
        await tester.pump();
        final size = _checkSharedPanel(tester);
        expect(find.text('Movement'), findsOneWidget);
        expect(find.text('Confirm'), findsOneWidget);
        expect(find.text('Over: Grass'), findsOneWidget);
        final tab = tester.getRect(
          find.byKey(const ValueKey('selection-stack-tab')),
        );
        expect(
          tab.top,
          greaterThanOrEqualTo(
            tester.getBottomLeft(find.byType(DungeonBoard)).dy,
          ),
        );
        expect(
          tab.bottom,
          lessThanOrEqualTo(
            tester.getTopLeft(find.byKey(const ValueKey('option-menu'))).dy,
          ),
        );
        await tester.tap(find.text('Over: Grass'));
        await tester.pump();
        expect(_checkSharedPanel(tester), size);
        expect(
          tester
              .widget<ShardText>(find.byKey(const ValueKey('selection-name')))
              .text,
          'Grass',
        );
        expect(find.text('Below: Adventurer'), findsOneWidget);
        expect(find.text('Confirm'), findsNothing);
        expect(find.text('Movement'), findsNothing);
        expect(find.byKey(const ValueKey('movement-allowance')), findsNothing);
        await tester.tap(find.text('Below: Adventurer'));
        await tester.pump();
        expect(controller.isSelected, isTrue);
        expect(find.text('Confirm'), findsOneWidget);

        controller.selectTile(const GridPosition(5, 7));
        await tester.pump();
        expect(_checkSharedPanel(tester), size);
        expect(
          tester
              .widget<ShardText>(find.byKey(const ValueKey('selection-name')))
              .text,
          'Bat',
        );
        expect(find.text('Over: Shallow Water'), findsOneWidget);
        expect(find.text('Confirm'), findsNothing);
        expect(find.text('Movement'), findsOneWidget);
        expect(find.text('5(3)'), findsOneWidget);
        await tester.tap(find.text('Over: Shallow Water'));
        await tester.pump();
        expect(_checkSharedPanel(tester), size);
        expect(
          tester
              .widget<ShardText>(find.byKey(const ValueKey('selection-name')))
              .text,
          'Shallow Water',
        );
        expect(find.text('Below: Bat'), findsOneWidget);
        expect(find.text('Movement'), findsNothing);
        expect(
          controller.inspectedTile?.object?.type,
          GroundObjectType.shallowWater,
        );
        await tester.tap(find.text('Below: Bat'));
        await tester.pump();
        expect(controller.inspectedTile?.enemy, isNotNull);
        controller.selectTile(const GridPosition(3, 3));
        await tester.pump();
        expect(_checkSharedPanel(tester), size);
        expect(find.byKey(const ValueKey('selection-stack-tab')), findsNothing);
        await tester.tap(find.text('Unselect'));
        await tester.pump();
        expect(controller.selectedInspection, isNull);
        expect(find.text('Select something to continue'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      }
    },
  );
}

Size _checkSharedPanel(WidgetTester tester) {
  expect(find.byType(SelectionPanel), findsOneWidget);
  final portrait = tester.getRect(
    find.byKey(const ValueKey('selection-portrait')),
  );
  final unselect = tester.getRect(
    find.byKey(const ValueKey('unselect-selection')),
  );
  expect(unselect.height, closeTo(portrait.height, 0.001));
  expect(unselect.top, closeTo(portrait.top, 0.001));
  return portrait.size;
}

DungeonFloor _floor({DungeonGroundObject? extra}) {
  final rows = List<String>.of(floor0.rows);
  rows[7] = rows[7].replaceRange(5, 6, '1');
  return DungeonFloorTemplate(
    number: 9,
    rows: rows,
    terrainOverlay: [
      for (var row = 0; row < 15; row++)
        [
          for (var column = 0; column < 15; column++)
            row == 3 && column == 3 ? 'w' : '.',
        ].join(),
    ],
    groundObjects: [
      const DungeonGroundObject.grass(GridPosition(7, 7)),
      const DungeonGroundObject.grass(GridPosition(8, 7)),
      extra ?? const DungeonGroundObject.shallowWater(GridPosition(5, 7)),
    ],
  ).create();
}
