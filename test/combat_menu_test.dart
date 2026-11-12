import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/app/dungeon_theme.dart';
import 'package:duncrawl/features/dungeon/domain/adventurer.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_page.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_strings.dart';
import 'package:duncrawl/features/dungeon/presentation/actor_stats_view.dart';
import 'package:duncrawl/features/dungeon/presentation/character_stats_view.dart';
import 'package:duncrawl/features/dungeon/presentation/movement_menu.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/settings/domain/game_settings.dart';

import 'support/combat_fixture.dart';

void main() {
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
      await tester.tap(find.byKey(const ValueKey('basic-attack')));
      await tester.pump();
      expect(find.byKey(const ValueKey('attack-range')), findsOneWidget);
      expect(find.text('0 + STR 2 = 2 damage'), findsOneWidget);
      await _tapTile(tester, const GridPosition(8, 7));
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
      await tester.tap(find.byKey(const ValueKey('confirm-attack')));
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
      await tester.tap(find.byKey(const ValueKey('basic-attack')));
      await tester.pump();
      await _tapTile(tester, const GridPosition(8, 7));
      await tester.tap(find.byKey(const ValueKey('confirm-attack')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_board(tester).floor.enemies, isEmpty);
      expect(_board(tester).player, const GridPosition(7, 7));
      expect(find.text('Victory — exploration resumed'), findsNothing);
      expect(find.text('Enemies spotted you'), findsNothing);
      expect(find.byKey(const ValueKey('combat-turn-tab')), findsNothing);
      expect(find.byKey(const ValueKey('end-turn')), findsNothing);
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
      for (final key in ['combat-move', 'basic-attack', 'end-turn']) {
        final rect = tester.getRect(find.byKey(ValueKey(key)));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      await tester.tap(find.byKey(const ValueKey('basic-attack')));
      await tester.pump();
      await _tapTile(tester, const GridPosition(8, 7));
      expect(find.text('Bat'), findsOneWidget);
      expect(find.text(DungeonStrings.batDescription), findsNothing);
      expect(find.byKey(const ValueKey('selection-description')), findsNothing);
      expect(find.byType(ActorStatsView), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('cancel-attack')));
      await tester.pump();
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
      controller.selectTile(const GridPosition(10, 7));
      await tester.pump();
      expect(targets.map(tester.getRect), orderedEquals(exploration));
      controller.strike();
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.isInCombat, isFalse);
      expect(targets.map(tester.getRect), orderedEquals(exploration));
      controller.selectCharacter();
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
    expect(find.byKey(const ValueKey('basic-attack')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

DungeonBoard _board(WidgetTester tester) =>
    tester.widget<DungeonBoard>(find.byType(DungeonBoard));

Future<void> _tapTile(WidgetTester tester, GridPosition position) async {
  final rect = tester.getRect(find.byType(DungeonBoard));
  final tileSize = rect.width / 15;
  await tester.tapAt(
    rect.topLeft +
        Offset(
          (position.column + 0.5) * tileSize,
          (position.row + 0.5) * tileSize,
        ),
  );
  await tester.pump();
}
