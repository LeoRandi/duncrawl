import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/app/dungeon_theme.dart';
import 'package:duncrawl/features/dungeon/domain/adventurer.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_enemy.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_controller.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_page.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_strings.dart';
import 'package:duncrawl/features/dungeon/presentation/actor_stats_view.dart';
import 'package:duncrawl/features/dungeon/presentation/character_stats_view.dart';
import 'package:duncrawl/features/dungeon/presentation/movement_menu.dart';
import 'package:duncrawl/features/dungeon/presentation/selection_frame.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/settings/domain/game_settings.dart';

import 'support/combat_fixture.dart';

void main() {
  for (final attackFirst in [true, false]) {
    testWidgets(
      'Spent actions grey out and End Turn pulses (attack first: $attackFirst)',
      (tester) async {
        final settings = ValueNotifier(const GameSettings(skipTutorials: true));
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: DungeonTheme.dark,
            home: DungeonPage(
              settings: settings,
              initialDungeon: combatFixture(
                adventurer: const Adventurer(movementSpeed: 4),
                enemies: [const GridPosition(8, 7)],
                enemyHealth: 9,
              ),
            ),
          ),
        );
        await tester.pump();
        final controller = tester
            .widget<MovementMenu>(find.byType(MovementMenu))
            .controller;
        final pulse = find.byKey(const ValueKey('end-turn-pulse'));
        final geometry = [
          find.byType(DungeonBoard),
          find.byKey(const ValueKey('option-menu')),
          find.byKey(const ValueKey('end-turn')),
        ];
        final initialRects = geometry.map(tester.getRect).toList();
        expect(tester.widget<SelectionFrame>(pulse).selected, isFalse);
        expect(_actionColor(tester, 'move-mode'), DungeonColors.textPrimary);
        expect(_actionColor(tester, 'strike-mode'), DungeonColors.textPrimary);

        Future<void> attack() async {
          await tester.tap(find.byKey(const ValueKey('strike-mode')));
          controller.aim(
            attackFirst ? DungeonDirection.east : DungeonDirection.south,
          );
          await tester.pump();
          await tester.tap(find.byKey(const ValueKey('confirm-action')));
          await tester.pump();
          expect(tester.widget<SelectionFrame>(pulse).selected, isFalse);
          await tester.pump(DungeonController.stepDuration);
          expect(
            _actionColor(tester, 'strike-mode'),
            DungeonColors.textDisabled,
          );
        }

        Future<void> move() async {
          controller.beginMove();
          controller.beginPadDrag();
          controller.preview(DungeonDirection.north);
          controller.preview(DungeonDirection.east);
          controller.endDrag();
          await tester.pump();
          expect(controller.plan.remainingMovement, 0);
          expect(_actionColor(tester, 'move-mode'), DungeonColors.textPrimary);
          expect(tester.widget<SelectionFrame>(pulse).selected, isFalse);
          await tester.tap(find.byKey(const ValueKey('confirm-action')));
          await tester.pump();
          await tester.pump(DungeonController.stepDuration * 2);
          expect(_actionColor(tester, 'move-mode'), DungeonColors.textDisabled);
        }

        if (attackFirst) {
          await attack();
          expect(_actionColor(tester, 'move-mode'), DungeonColors.textPrimary);
          expect(tester.widget<SelectionFrame>(pulse).selected, isFalse);
          await move();
        } else {
          await move();
          expect(
            _actionColor(tester, 'strike-mode'),
            DungeonColors.textPrimary,
          );
          expect(tester.widget<SelectionFrame>(pulse).selected, isFalse);
          await attack();
        }
        expect(tester.widget<SelectionFrame>(pulse).selected, isTrue);
        final border = find.descendant(
          of: pulse,
          matching: find.byKey(const ValueKey('selection-border')),
        );
        final width = tester.getSize(border).width;
        await tester.pump(const Duration(milliseconds: 700));
        expect(tester.getSize(border).width - width, closeTo(3, 0.1));
        expect(geometry.map(tester.getRect), initialRects);

        await tester.tap(find.byKey(const ValueKey('end-turn')));
        await tester.pump();
        expect(tester.widget<SelectionFrame>(pulse).selected, isFalse);
        await tester.pump(EnemyType.bat.stepInterval * 2);
        expect(controller.isPlayerTurn, isTrue);
        expect(tester.widget<SelectionFrame>(pulse).selected, isFalse);
        expect(_actionColor(tester, 'move-mode'), DungeonColors.textPrimary);
        expect(_actionColor(tester, 'strike-mode'), DungeonColors.textPrimary);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'Pad aiming preserves inspection and cancelled drags restore aim',
    (tester) async {
      final settings = ValueNotifier(const GameSettings(skipTutorials: true));
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: DungeonTheme.dark,
          home: DungeonPage(
            settings: settings,
            initialDungeon: combatFixture(enemies: [const GridPosition(8, 7)]),
          ),
        ),
      );
      await tester.pump();
      final controller = tester
          .widget<MovementMenu>(find.byType(MovementMenu))
          .controller;
      final buttons = [
        for (final key in ['cancel-action', 'confirm-action', 'end-turn'])
          find.byKey(ValueKey(key)),
      ];
      final positions = buttons.map(tester.getRect).toList();
      await tester.tap(find.byKey(const ValueKey('strike-mode')));
      await tester.pump();
      expect(buttons.map(tester.getRect), positions);
      final pad = find.byKey(const ValueKey('action-pad'));
      final padRect = tester.getRect(pad);
      await tester.tapAt(padRect.centerRight - const Offset(9, 0));
      await tester.pump();
      expect(controller.aimDirection, DungeonDirection.east);
      expect(controller.canStrike, isTrue);
      expect(controller.selectedPosition, controller.dungeon.player);

      final boardRect = tester.getRect(find.byType(DungeonBoard));
      await tester.tapAt(
        boardRect.topLeft +
            Offset(boardRect.width / 15 * 8.5, boardRect.height / 15 * 7.5),
      );
      await tester.pump();
      expect(controller.selectedPosition, const GridPosition(8, 7));
      expect(controller.aimDirection, DungeonDirection.east);
      expect(controller.canStrike, isTrue);

      final gesture = await tester.startGesture(padRect.center);
      await gesture.moveBy(const Offset(0, -40));
      await tester.pump();
      expect(controller.aimDirection, DungeonDirection.north);
      expect(controller.canStrike, isFalse);
      await gesture.cancel();
      await tester.pump();
      expect(controller.aimDirection, DungeonDirection.east);
      expect(controller.canStrike, isTrue);
      expect(controller.dungeon.floor.enemies.single.health, 3);
      await tester.tap(find.byKey(const ValueKey('cancel-action')));
      await tester.pump();
      expect(controller.aimDirection, isNull);
      expect(controller.controlMode, ControlMode.strike);
      expect(controller.encounter?.actionAvailable, isTrue);
      expect(buttons.map(tester.getRect), positions);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Battle controls target a tile, spend an action and finish an encounter',
    (tester) async {
      final settings = ValueNotifier(const GameSettings(skipTutorials: true));
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: DungeonTheme.dark,
          home: DungeonPage(
            settings: settings,
            initialDungeon: combatFixture(enemies: [const GridPosition(8, 7)]),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Round 1 · Your turn'), findsOneWidget);
      expect(find.byType(ActorStatsView), findsNothing);
      expect(find.byType(CharacterStatsView), findsNothing);
      expect(find.text('Vision range'), findsNothing);
      expect(find.byKey(const ValueKey('selection-description')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('strike-mode')));
      await tester.pump();
      expect(find.byKey(const ValueKey('attack-range')), findsOneWidget);
      expect(find.text('0 + STR 2 = 2 damage'), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey('action-pad')),
        const Offset(40, 0),
      );
      await tester.pump();
      expect(
        tester
            .widget<OutlinedButton>(
              find.descendant(
                of: find.byKey(const ValueKey('end-turn')),
                matching: find.byType(OutlinedButton),
              ),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const ValueKey('confirm-action')));
      await tester.pump();
      expect(_board(tester).floor.enemies.single.health, 1);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('end-turn')));
      await tester.pump();
      expect(find.text('Round 1 · Enemy turn'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('-1'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Round 2 · Your turn'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('strike-mode')));
      await tester.pump();
      await tester.drag(
        find.byKey(const ValueKey('action-pad')),
        const Offset(40, 0),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('confirm-action')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_board(tester).floor.enemies, isEmpty);
      expect(_board(tester).player, const GridPosition(7, 7));
      expect(find.text('Victory — exploration resumed'), findsNothing);
      expect(find.text('Enemies spotted you'), findsNothing);
      expect(find.byKey(const ValueKey('combat-turn-tab')), findsNothing);
      expect(find.byKey(const ValueKey('end-turn')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('Combat inspection and controls fit $size with large text', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(size);
      final settings = ValueNotifier(const GameSettings(skipTutorials: true));
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: DungeonTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: DungeonPage(
            settings: settings,
            initialDungeon: combatFixture(enemies: [const GridPosition(8, 7)]),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      for (final key in ['move-mode', 'strike-mode', 'end-turn']) {
        final rect = tester.getRect(find.byKey(ValueKey(key)));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      await tester.tap(find.byKey(const ValueKey('strike-mode')));
      await tester.pump();
      await tester.drag(
        find.byKey(const ValueKey('action-pad')),
        const Offset(40, 0),
      );
      await tester.pump();
      expect(_board(tester).selectedTile, _board(tester).player);
      expect(find.byKey(const ValueKey('aim-reticle')), findsOneWidget);
      expect(find.text(DungeonStrings.batDescription), findsNothing);
      expect(find.byKey(const ValueKey('selection-description')), findsNothing);
      expect(find.byType(ActorStatsView), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('cancel-action')));
      await tester.pump();
      final boardRect = tester.getRect(find.byType(DungeonBoard));
      final menuRect = tester.getRect(
        find.byKey(const ValueKey('option-menu')),
      );
      final controller = tester
          .widget<MovementMenu>(find.byType(MovementMenu))
          .controller;
      await tester.tap(find.byKey(const ValueKey('inspect-action')));
      await tester.pump();
      expect(find.byType(ActorStatsView), findsOneWidget);
      expect(find.byKey(const ValueKey('action-pad')), findsNothing);
      expect(find.byKey(const ValueKey('combat-turn-tab')), findsOneWidget);
      controller.selectTile(const GridPosition(8, 7));
      await tester.pump();
      expect(find.text('Bat'), findsOneWidget);
      expect(find.text('4(2)'), findsOneWidget);
      await tester.tap(find.text('Unselect'));
      await tester.pump();
      expect(find.text('Select something to continue'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('return-to-actions')));
      await tester.pump();
      expect(find.byKey(const ValueKey('action-pad')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('inspect-action')));
      await tester.pump();
      expect(controller.isSelected, isTrue);
      expect(find.byType(ActorStatsView), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('return-to-actions')));
      await tester.pump();
      expect(find.byType(ActorStatsView), findsNothing);
      expect(tester.getRect(find.byType(DungeonBoard)), boardRect);
      expect(
        tester.getRect(find.byKey(const ValueKey('option-menu'))),
        menuRect,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('Combat preserves exploration geometry at $size', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(size);
      final settings = ValueNotifier(const GameSettings(skipTutorials: true));
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: DungeonTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: DungeonPage(
            settings: settings,
            initialDungeon: combatFixture(
              enemies: [const GridPosition(10, 7)],
              visionRadius: 1,
              enemyHealth: 1,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      final controller = tester
          .widget<MovementMenu>(find.byType(MovementMenu))
          .controller;
      final targets = [
        find.byType(DungeonBoard),
        find.byKey(const ValueKey('option-menu')),
        find.byKey(const ValueKey('player-portrait')),
      ];
      final exploration = targets.map(tester.getRect).toList();
      controller.selectCharacter();
      controller.beginDrag();
      controller.preview(DungeonDirection.east, steps: 2);
      controller.confirm();
      await tester.pump(const Duration(milliseconds: 600));
      expect(controller.isInCombat, isTrue);
      expect(targets.map(tester.getRect), orderedEquals(exploration));
      expect(find.byType(ActorStatsView), findsNothing);
      expect(find.byType(CharacterStatsView), findsNothing);
      final tab = tester.getRect(find.byKey(const ValueKey('combat-turn-tab')));
      expect(tab.bottom, lessThanOrEqualTo(exploration[1].top));
      controller.endTurn();
      await tester.pump();
      expect(controller.isEnemyTurn, isTrue);
      expect(targets.map(tester.getRect), orderedEquals(exploration));
      await tester.pump(const Duration(milliseconds: 600));
      expect(controller.isPlayerTurn, isTrue);
      expect(targets.map(tester.getRect), orderedEquals(exploration));
      controller.beginAttack();
      controller.aim(DungeonDirection.east);
      await tester.pump();
      expect(targets.map(tester.getRect), orderedEquals(exploration));
      controller.strike();
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.isInCombat, isFalse);
      expect(targets.map(tester.getRect), orderedEquals(exploration));
      controller.selectCharacter();
      controller.closeControls();
      await tester.pump();
      expect(find.byType(ActorStatsView), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Defeat leaves a usable return-to-menu control', (tester) async {
    final settings = ValueNotifier(const GameSettings(skipTutorials: true));
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: DungeonTheme.dark,
        home: DungeonPage(
          settings: settings,
          initialDungeon: combatFixture(
            adventurer: const Adventurer(health: 1),
            enemies: [const GridPosition(8, 7)],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('end-turn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Defeated'), findsOneWidget);
    expect(find.byKey(const ValueKey('defeat-main-menu')), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('defeat-main-menu')),
          )
          .onPressed,
      isNotNull,
    );
    expect(find.byKey(const ValueKey('strike-mode')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

DungeonBoard _board(WidgetTester tester) =>
    tester.widget<DungeonBoard>(find.byType(DungeonBoard));

Color? _actionColor(WidgetTester tester, String key) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(Text),
      ),
    )
    .style
    ?.color;
