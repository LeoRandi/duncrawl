import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_page.dart';
import 'package:duncrawl/features/dungeon/presentation/movement_preview.dart';
import 'package:duncrawl/features/dungeon/presentation/selection_frame.dart';
import 'package:duncrawl/features/dungeon/floors/floor_0.dart';
import 'package:duncrawl/main.dart';

import 'helpers/dialogue_helpers.dart';

void main() {
  testWidgets(
    'Confirm updates during dragging and can commit before finger release',
    (tester) async {
      await _startGame(tester);
      final distance = _stepDistance(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DungeonBoard)),
        pointer: 1,
      );
      await gesture.moveBy(Offset(distance * 1.2, 0));
      await tester.pump();
      expect(find.text('4/5'), findsOneWidget);
      expect(_confirmEnabled(tester), isTrue);

      await gesture.moveBy(Offset(-distance * 1.4, 0));
      await tester.pump();
      expect(find.text('5/5'), findsOneWidget);
      expect(_confirmEnabled(tester), isFalse);

      await gesture.moveBy(Offset(distance * 1.4, 0));
      await tester.pump();
      expect(find.text('4/5'), findsOneWidget);
      expect(_confirmEnabled(tester), isTrue);
      await tester.tap(find.text('Confirm'), pointer: 2);
      await tester.pump();
      expect(_confirmEnabled(tester), isFalse);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_board(tester).player, const GridPosition(8, 7));
      await gesture.up();
      await tester.pump();
      expect(_board(tester).movementPath, isEmpty);
    },
  );

  testWidgets(
    'The menu changes from a prompt to character details and live movement controls',
    (tester) async {
      await _startGame(tester, select: false);
      final prompt = find.text('Select something to continue');
      expect(prompt, findsOneWidget);
      expect(
        tester.getCenter(prompt),
        tester.getCenter(find.byKey(const ValueKey('option-menu'))),
      );
      expect(tester.widget<Text>(prompt).style?.color, const Color(0xFF808080));
      await tester.tap(find.byKey(const ValueKey('player-portrait')));
      await tester.pump();
      expect(prompt, findsNothing);
      expect(find.text('Movement'), findsOneWidget);
      expect(find.text('5/5'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(_confirmEnabled(tester), isFalse);
      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('confirm-movement')),
      );
      expect(
        button.style?.foregroundColor?.resolve({WidgetState.disabled}),
        const Color(0xFF808080),
      );
      final infoRect = tester.getRect(
        find.byKey(const ValueKey('selected-character-info')),
      );
      final unselectRect = tester.getRect(find.text('Unselect'));
      final movementRect = tester.getRect(find.text('Movement'));
      final confirmRect = tester.getRect(find.text('Confirm'));
      expect(infoRect.left, lessThan(unselectRect.left));
      expect(infoRect.bottom, lessThan(movementRect.top));
      expect(unselectRect.bottom, lessThan(confirmRect.top));
      expect(movementRect.left, lessThan(confirmRect.left));
      await tester.tap(find.text('Confirm'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_board(tester).player, const GridPosition(7, 7));

      final distance = _stepDistance(tester) + 0.01;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DungeonBoard)),
      );
      await gesture.moveBy(Offset(distance * 2, 0));
      await tester.pump();
      expect(find.text('3/5'), findsOneWidget);
      expect(_confirmEnabled(tester), isTrue);
      await gesture.moveBy(Offset(-distance * 1.1, 0));
      await tester.pump();
      expect(find.text('4/5'), findsOneWidget);
      await gesture.up();
      await tester.pump();
      expect(_confirmEnabled(tester), isTrue);
      await tester.tap(find.text('Movement'));
      await tester.pump();
      expect(find.text('5/5'), findsOneWidget);
      expect(_confirmEnabled(tester), isFalse);
      expect(_board(tester).movementPath, isEmpty);
    },
  );

  testWidgets(
    'Unselected mode ignores drags and taps outside selection targets',
    (tester) async {
      await _startGame(tester, select: false);
      expect(_board(tester).isSelected, isFalse);
      expect(find.text('Unselect'), findsNothing);
      await tester.drag(find.byType(DungeonBoard), const Offset(150, -80));
      await tester.pump();
      await tester.drag(
        find.byKey(const ValueKey('option-menu')),
        const Offset(-100, 0),
      );
      await tester.pump();
      await tester.drag(
        find.byKey(const ValueKey('player-portrait')),
        const Offset(100, 0),
      );
      await tester.tapAt(
        tester.getTopLeft(find.byType(DungeonBoard)) + const Offset(5, 5),
      );
      await tester.pump();
      expect(_board(tester).player, const GridPosition(7, 7));
      expect(_board(tester).movementPath, isEmpty);
      expect(_board(tester).isSelected, isFalse);
      expect(find.text('Confirm'), findsNothing);
    },
  );

  testWidgets('Both selection targets work and selection borders pulse', (
    tester,
  ) async {
    await _startGame(tester, select: false);
    await tester.tap(find.byKey(const ValueKey('player')));
    await tester.pump();
    expect(_board(tester).isSelected, isTrue);
    expect(find.text('Unselect'), findsOneWidget);
    expect(
      tester
          .widgetList<SelectionFrame>(find.byType(SelectionFrame))
          .where((frame) => frame.selected)
          .length,
      2,
    );
    final border = find.byKey(const ValueKey('selection-border')).first;
    final initialWidth = tester.getSize(border).width;
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.getSize(border).width - initialWidth, closeTo(3, 0.1));
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.getSize(border).width, closeTo(initialWidth, 0.1));
    await tester.tap(find.text('Unselect'));
    await tester.pump();
    expect(_board(tester).isSelected, isFalse);
    expect(find.byKey(const ValueKey('selection-border')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('player-portrait')));
    await tester.pump();
    expect(_board(tester).isSelected, isTrue);
  });

  testWidgets(
    'Unselect clears previews but the whole menu is locked during a confirmed walk',
    (tester) async {
      await _startGame(tester);
      await tester.drag(
        find.byType(DungeonBoard),
        Offset(_stepDistance(tester) * 2.2, 0),
      );
      await tester.pump();
      expect(find.text('Confirm'), findsOneWidget);
      await tester.tap(find.text('Unselect'));
      await tester.pump();
      expect(_board(tester).isSelected, isFalse);
      expect(_board(tester).movementPath, isEmpty);
      expect(find.text('Confirm'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('player')));
      await tester.pump();
      await tester.drag(
        find.byType(DungeonBoard),
        Offset(_stepDistance(tester) * 2.2, 0),
      );
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_board(tester).player, const GridPosition(8, 7));
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Unselect'),
            )
            .onPressed,
        isNull,
      );
      expect(_confirmEnabled(tester), isFalse);
      await tester.tapAt(tester.getCenter(find.text('Unselect')));
      await tester.pump();
      expect(_board(tester).player, const GridPosition(8, 7));
      expect(_board(tester).isSelected, isTrue);
      await tester.dragFrom(
        tester.getCenter(find.text('Movement')),
        const Offset(-100, 0),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(_board(tester).player, const GridPosition(9, 7));
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Unselect'),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Unselect'));
      await tester.pump();
      expect(_board(tester).isSelected, isFalse);
      expect(_board(tester).movementPath, isEmpty);
      await tester.drag(find.byType(DungeonBoard), const Offset(150, 0));
      await tester.pump();
      expect(_board(tester).movementPath, isEmpty);
    },
  );

  testWidgets('The floating menu blocks play and opens bestiary and settings', (
    tester,
  ) async {
    await _startGame(tester, select: false);
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    for (final label in ['Continue', 'Bestiary', 'Settings', 'Main menu']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.dragFrom(const Offset(5, 250), const Offset(100, 0));
    await tester.pumpAndSettle();
    expect(_board(tester).movementPath, isEmpty);
    expect(_board(tester).isSelected, isFalse);
    await tester.tap(find.text('Bestiary'));
    await tester.pumpAndSettle();
    expect(find.text('No creatures discovered yet.'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNWidgets(2));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsNothing);
    expect(_board(tester).isSelected, isFalse);
  });

  testWidgets('Menu pauses a confirmed walk and Continue resumes it', (
    tester,
  ) async {
    await _startGame(tester);
    await tester.drag(
      find.byType(DungeonBoard),
      Offset(_stepDistance(tester) * 3.2, 0),
    );
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_board(tester).player, const GridPosition(8, 7));
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(_board(tester).player, const GridPosition(8, 7));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 299));
    expect(_board(tester).player, const GridPosition(8, 7));
    await tester.pump(const Duration(milliseconds: 1));
    expect(_board(tester).player, const GridPosition(9, 7));
    expect(_board(tester).isSelected, isTrue);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Unselect'));
    await tester.pump();
  });

  testWidgets(
    'Composes six layers with objects and characters above the floor',
    (tester) async {
      const position = GridPosition(7, 7);
      final floor = DungeonFloorTemplate(
        number: 1,
        rows: floor0.rows,
        groundObjects: const [
          DungeonGroundObject(
            type: GroundObjectType.stairsUp,
            position: position,
          ),
        ],
      ).create();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 300,
                child: DungeonBoard(
                  floor: floor,
                  player: position,
                  movementPath: const [
                    GridPosition(8, 7),
                    GridPosition(8, 6),
                    GridPosition(7, 6),
                    position,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final layers = tester.widgetList<Positioned>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Positioned && widget.key is ValueKey<DungeonLayer>,
        ),
      );
      expect(
        layers.map((layer) => (layer.key as ValueKey<DungeonLayer>).value),
        DungeonLayer.values,
      );
      final background = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byKey(const ValueKey(DungeonLayer.background)),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(background.color, const Color(0xFF000000));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey(DungeonLayer.floorTiles)),
          matching: find.byKey(const ValueKey('movement-destination')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey(DungeonLayer.groundObjects)),
          matching: find.byIcon(Icons.stairs_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey(DungeonLayer.characters)),
          matching: find.byKey(const ValueKey('player')),
        ),
        findsOneWidget,
      );
      expect(
        tester.getRect(find.byIcon(Icons.stairs_rounded)),
        tester.getRect(find.byKey(const ValueKey('player'))),
      );
    },
  );

  testWidgets('Launches in the main menu and Start opens the dungeon', (
    tester,
  ) async {
    await tester.pumpWidget(const DungeonCrawlerApp());
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(find.byType(DungeonBoard), findsNothing);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.byType(DungeonBoard), findsOneWidget);

    await completeOpeningTutorial(tester);
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main menu'));
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
    expect(find.byType(DungeonBoard), findsNothing);
  });

  testWidgets('Settings apply the chosen movement sensitivity to the game', (
    tester,
  ) async {
    await tester.pumpWidget(const DungeonCrawlerApp());
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('movement-sensitivity-slider')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<DungeonPage>(find.byType(DungeonPage))
          .settings
          .value
          .dragDistanceMultiplier,
      5,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Close requests the native application to close', (tester) async {
    final platformCalls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(const DungeonCrawlerApp());
    await tester.tap(find.text('Close'));
    await tester.pump();
    expect(platformCalls, contains('SystemNavigator.pop'));
  });

  testWidgets('Starts alone at the center with stairs and an empty menu', (
    tester,
  ) async {
    await _startGame(tester);

    final board = tester.widget<DungeonBoard>(find.byType(DungeonBoard));
    expect(board.player, const GridPosition(7, 7));
    expect(board.floor.number, 0);
    expect(find.byIcon(Icons.stairs_rounded), findsOneWidget);
    expect(find.byKey(const ValueKey('option-menu')), findsOneWidget);
    expect(find.text('Tower – Floor 0'), findsOneWidget);
    expect(find.text('Lv. 1'), findsNWidgets(2));
    expect(find.text('HP 10/10'), findsNWidgets(2));
    expect(find.text('Adventurer'), findsNothing);

    final portrait = tester.getRect(
      find.byKey(const ValueKey('player-portrait')),
    );
    final floor = tester.getRect(find.text('Tower – Floor 0'));
    final level = tester.getRect(find.text('Lv. 1').first);
    final health = tester.getRect(find.text('HP 10/10').first);
    expect(floor.bottom, lessThan(portrait.top));
    expect(level.center.dy, greaterThanOrEqualTo(portrait.top));
    expect(health.center.dy, lessThanOrEqualTo(portrait.bottom));

    final boardRect = tester.getRect(find.byType(DungeonBoard));
    final playerRect = tester.getRect(find.byKey(const ValueKey('player')));
    expect(boardRect.width, closeTo(boardRect.height, 0.01));
    expect(playerRect.center.dx, closeTo(boardRect.center.dx, 0.01));
    expect(playerRect.center.dy, closeTo(boardRect.center.dy, 0.01));
  });

  testWidgets(
    'Diagonal drags preview a single axis without moving the player',
    (tester) async {
      await _startGame(tester);
      final boardRect = tester.getRect(find.byType(DungeonBoard));
      final tileSize = boardRect.width / DungeonFloor.size;

      await tester.dragFrom(
        boardRect.center,
        Offset(tileSize * 5, tileSize * 1.2),
      );
      await tester.pump();
      var board = _board(tester);
      expect(board.player, const GridPosition(7, 7));
      expect(board.movementPath, isNotEmpty);
      expect(board.movementPath.every((position) => position.row == 7), isTrue);
      expect(find.text('Confirm'), findsOneWidget);

      await tester.dragFrom(boardRect.center, const Offset(-1000, 0));
      await tester.pump();
      board = _board(tester);
      expect(board.player, const GridPosition(7, 7));
      expect(board.movementPath.length, 5);
      expect(board.movementPath.last, const GridPosition(2, 7));
    },
  );

  testWidgets('The empty lower panel also accepts drag movement', (
    tester,
  ) async {
    await _startGame(tester);
    final menu = find.byKey(const ValueKey('option-menu'));

    await tester.drag(menu, const Offset(0, -100));
    await tester.pump();

    final board = tester.widget<DungeonBoard>(find.byType(DungeonBoard));
    expect(board.player.column, 7);
    expect(board.player.row, 7);
    expect(board.movementPath.last.row, lessThan(7));
  });

  testWidgets('Default movement needs two tile widths of dragging per step', (
    tester,
  ) async {
    await _startGame(tester);
    final boardRect = tester.getRect(find.byType(DungeonBoard));
    final tileSize = boardRect.width / DungeonFloor.size;

    await tester.dragFrom(boardRect.center, Offset(tileSize * 1.5, 0));
    await tester.pump();
    expect(
      tester.widget<DungeonBoard>(find.byType(DungeonBoard)).player,
      const GridPosition(7, 7),
    );

    await tester.dragFrom(boardRect.center, Offset(tileSize * 3.5, 0));
    await tester.pump();
    expect(
      tester.widget<DungeonBoard>(find.byType(DungeonBoard)).player,
      const GridPosition(7, 7),
    );
    expect(_board(tester).movementPath, [const GridPosition(8, 7)]);
  });

  testWidgets(
    'Records the turning and backtracking example, then walks at 0.3s per tile',
    (tester) async {
      await _startGame(tester);
      final distance = _stepDistance(tester) + 0.01;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DungeonBoard)),
      );
      await gesture.moveBy(Offset(0, -distance * 2));
      await tester.pump();
      await gesture.moveBy(Offset(distance * 2, 0));
      await tester.pump();
      await gesture.moveBy(Offset(0, -distance));
      await tester.pump();
      expect(_board(tester).movementPath.last, const GridPosition(9, 4));
      await gesture.moveBy(Offset(0, distance));
      await tester.pump();
      expect(_board(tester).movementPath.length, 4);
      await gesture.moveBy(Offset(distance, 0));
      await tester.pump();

      const path = [
        GridPosition(7, 6),
        GridPosition(7, 5),
        GridPosition(8, 5),
        GridPosition(9, 5),
        GridPosition(10, 5),
      ];
      expect(_board(tester).movementPath, path);
      expect(_board(tester).player, const GridPosition(7, 7));
      expect(_confirmEnabled(tester), isTrue);
      await gesture.up();
      await tester.pump();
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.byTooltip('Destination: column 11, row 6'), findsOneWidget);
      expect(_confirmEnabled(tester), isTrue);
      expect(
        find.descendant(
          of: find.byType(MovementPreview),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('movement-destination')),
        findsOneWidget,
      );

      await tester.tap(find.text('Confirm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 299));
      expect(_board(tester).player, const GridPosition(7, 7));
      await tester.pump(const Duration(milliseconds: 1));
      expect(_board(tester).player, path.first);
      expect(_board(tester).movementPath, path.skip(1).toList());
      // Los gestos durante la ejecución no alteran la ruta confirmada.
      await tester.drag(find.byType(DungeonBoard), const Offset(-100, 0));
      await tester.pump();
      for (final (index, position) in path.indexed.skip(1)) {
        await tester.pump(const Duration(milliseconds: 300));
        expect(_board(tester).player, position);
        expect(_board(tester).movementPath, path.skip(index + 1).toList());
        if (index < path.length - 1) {
          final preview = tester.widget<MovementPreview>(
            find.byType(MovementPreview),
          );
          expect(preview.origin, position);
          expect(preview.path.last, path.last);
        }
      }
      expect(_board(tester).movementPath, isEmpty);
      expect(find.byType(MovementPreview), findsNothing);
      expect(_confirmEnabled(tester), isFalse);
      expect(find.text('Moving…'), findsNothing);

      await tester.drag(find.byType(DungeonBoard), Offset(distance, 0));
      await tester.pump();
      expect(_board(tester).movementPath, [const GridPosition(11, 5)]);
      expect(_board(tester).player, path.last);
    },
  );

  testWidgets('Any tap outside Confirm cancels the preview without moving', (
    tester,
  ) async {
    await _startGame(tester);
    final targets = [
      tester.getCenter(find.byType(DungeonBoard)),
      tester.getTopLeft(find.byKey(const ValueKey('option-menu'))) +
          const Offset(5, 5),
      tester.getCenter(find.text('Tower – Floor 0')),
      const Offset(5, 250),
    ];
    for (final target in targets) {
      await tester.drag(
        find.byType(DungeonBoard),
        Offset(_stepDistance(tester) * 1.2, 0),
      );
      await tester.pump();
      expect(find.text('Confirm'), findsOneWidget);
      await tester.tapAt(target);
      await tester.pump();
      expect(_confirmEnabled(tester), isFalse);
      expect(_board(tester).movementPath, isEmpty);
      expect(_board(tester).player, const GridPosition(7, 7));
    }
  });

  testWidgets('Cancelling a pointer gesture discards its preview', (
    tester,
  ) async {
    await _startGame(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(DungeonBoard)),
    );
    await gesture.moveBy(Offset(_stepDistance(tester) * 1.2, 0));
    await tester.pump();
    expect(_board(tester).movementPath, isNotEmpty);
    await gesture.cancel();
    await tester.pump();
    expect(_board(tester).movementPath, isEmpty);
    expect(_confirmEnabled(tester), isFalse);
  });

  testWidgets('Leaving during a confirmed walk cancels its timer', (
    tester,
  ) async {
    await _startGame(tester);
    await tester.drag(
      find.byType(DungeonBoard),
      Offset(_stepDistance(tester) * 3.2, 0),
    );
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main menu'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('Fits compact portrait and landscape screens with larger text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final size in [const Size(320, 568), const Size(844, 390)]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(size);
      await _startGame(tester);
      await tester.pump();
      expect(tester.takeException(), isNull);
      final boardRect = tester.getRect(find.byType(DungeonBoard));
      expect(boardRect.width, closeTo(boardRect.height, 0.01));
      expect(boardRect.width, greaterThan(0));
      expect(
        MediaQuery.textScalerOf(
          tester.element(find.byType(DungeonBoard)),
        ).scale(10),
        15,
      );
      await tester.drag(find.byType(DungeonBoard), const Offset(70, 0));
      await tester.pump();
      expect(find.text('Confirm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

DungeonBoard _board(WidgetTester tester) =>
    tester.widget<DungeonBoard>(find.byType(DungeonBoard));

bool _confirmEnabled(WidgetTester tester) =>
    tester
        .widget<FilledButton>(find.byKey(const ValueKey('confirm-movement')))
        .onPressed !=
    null;

double _stepDistance(WidgetTester tester) =>
    math.max(
      tester.getSize(find.byType(DungeonBoard)).width / DungeonFloor.size,
      16,
    ) *
    tester
        .widget<DungeonPage>(find.byType(DungeonPage))
        .settings
        .value
        .dragDistanceMultiplier;

Future<void> _startGame(WidgetTester tester, {bool select = true}) async {
  await tester.pumpWidget(const DungeonCrawlerApp());
  await tester.tap(find.text('Start'));
  await tester.pumpAndSettle();
  await completeOpeningTutorial(tester);
  if (select) {
    await tester.tap(find.byKey(const ValueKey('player-portrait')));
    await tester.pump();
  }
}
