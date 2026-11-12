import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dialogue/presentation/dialogue_window.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_page.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/tutorial/presentation/tutorial_spotlight.dart';
import 'package:duncrawl/features/settings/domain/movement_speed.dart';
import 'package:duncrawl/features/settings/domain/text_speed.dart';
import 'package:duncrawl/features/shards/domain/shard_progress.dart';
import 'package:duncrawl/features/shards/presentation/shard_scope.dart';
import 'package:duncrawl/main.dart';

import 'helpers/dialogue_helpers.dart';

void main() {
  testWidgets(
    'Instant reveals an optional tutorial bypass and movement speed reaches gameplay',
    (tester) async {
      await tester.pumpWidget(const DungeonCrawlerApp());
      await _openSettings(tester);
      expect(find.byKey(const ValueKey('skip-tutorials-switch')), findsNothing);
      expect(_slider(tester, 'movement-speed-slider').value, 1);
      await _selectSpeed(tester, TextSpeed.instant);
      expect(find.byKey(const ValueKey('skip-tutorials-switch')), findsNothing);
      await tester.ensureVisible(find.text('Instant'));
      await tester.tap(find.text('Instant'));
      await tester.pumpAndSettle();
      expect(_switch(tester, 'skip-tutorials-switch').value, isFalse);
      await _toggleSetting(tester, 'skip-tutorials-switch');
      final movementSlider = find.byKey(
        const ValueKey('movement-speed-slider'),
      );
      await tester.ensureVisible(movementSlider);
      await tester.drag(movementSlider, const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(find.text('Movement speed: Ultra Fast'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await _openSettings(tester);
      expect(_switch(tester, 'skip-tutorials-switch').value, isTrue);
      expect(_slider(tester, 'movement-speed-slider').value, 3);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(find.byType(DialogueWindow), findsNothing);
      expect(find.byType(TutorialSpotlight), findsNothing);
      await tester.tap(find.byKey(const ValueKey('player-portrait')));
      await tester.pump();
      expect(
        tester.widget<DungeonBoard>(find.byType(DungeonBoard)).isSelected,
        isTrue,
      );
      final board = find.byType(DungeonBoard);
      final settings = tester
          .widget<DungeonPage>(find.byType(DungeonPage))
          .settings
          .value;
      expect(settings.movementSpeed, MovementSpeed.ultraFast);
      final distance =
          tester.getSize(board).width / 15 * settings.dragDistanceMultiplier;
      await tester.drag(await movementPad(tester), Offset(distance * 1.2, 0));
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 49));
      expect(
        tester.widget<DungeonBoard>(board).player,
        const GridPosition(7, 7),
      );
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        tester.widget<DungeonBoard>(board).player,
        const GridPosition(8, 7),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(DialogueWindow), findsNothing);
      expect(find.byType(TutorialSpotlight), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Defaults are sensitivity 4 and Medium, and Fast reaches the tutorial',
    (tester) async {
      await tester.pumpWidget(const DungeonCrawlerApp());
      await _openSettings(tester);
      expect(_slider(tester, 'movement-sensitivity-slider').value, 4);
      expect(_slider(tester, 'text-speed-slider').value, 1);
      expect(find.text('Text speed: Medium'), findsOneWidget);
      expect(_switch(tester, 'auto-climb-stairs-switch').value, isTrue);
      expect(_switch(tester, 'auto-pick-up-items-switch').value, isTrue);
      await _selectSpeed(tester, TextSpeed.fast);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      final settings = tester
          .widget<DungeonPage>(find.byType(DungeonPage))
          .settings
          .value;
      expect(settings.dragDistanceMultiplier, 2);
      expect(settings.textSpeed, TextSpeed.fast);
      expect(settings.autoClimbStairs, isTrue);
      expect(settings.autoPickUpItems, isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DialogueWindow), findsOneWidget);
      expect(_visibleText(tester), '');
      await tester.pump(const Duration(milliseconds: 19));
      expect(_visibleText(tester), '');
      await tester.pump(const Duration(milliseconds: 1));
      expect(_visibleText(tester), '.');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Settings changed inside the dungeon are retained in the main menu',
    (tester) async {
      await tester.pumpWidget(const DungeonCrawlerApp());
      await _openSettings(tester);
      await _selectSpeed(tester, TextSpeed.instant);
      await _toggleSetting(tester, 'auto-climb-stairs-switch');
      await _toggleSetting(tester, 'auto-pick-up-items-switch');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      expect(_visibleText(tester), '...');
      expect(find.text('Continue'), findsOneWidget);
      await completeOpeningTutorial(tester);
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await _openSettings(tester);
      expect(find.text('Text speed: Instant'), findsOneWidget);
      expect(_switch(tester, 'auto-climb-stairs-switch').value, isFalse);
      expect(_switch(tester, 'auto-pick-up-items-switch').value, isFalse);
      await _selectSpeed(tester, TextSpeed.slow);
      await tester.ensureVisible(
        find.byKey(const ValueKey('movement-sensitivity-slider')),
      );
      await tester.drag(
        find.byKey(const ValueKey('movement-sensitivity-slider')),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
      await _toggleSetting(tester, 'auto-climb-stairs-switch');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Main menu'));
      await tester.pumpAndSettle();
      await _openSettings(tester);
      expect(_slider(tester, 'movement-sensitivity-slider').value, 1);
      expect(_slider(tester, 'text-speed-slider').value, 0);
      expect(find.text('Text speed: Slow'), findsOneWidget);
      expect(_switch(tester, 'auto-climb-stairs-switch').value, isTrue);
      expect(_switch(tester, 'auto-pick-up-items-switch').value, isFalse);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      final settings = tester
          .widget<DungeonPage>(find.byType(DungeonPage))
          .settings
          .value;
      expect(settings.dragDistanceMultiplier, 5);
      expect(settings.textSpeed, TextSpeed.slow);
      expect(settings.autoClimbStairs, isTrue);
      expect(settings.autoPickUpItems, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Dismissing settings does not apply unfinished edits', (
    tester,
  ) async {
    await tester.pumpWidget(const DungeonCrawlerApp());
    await _openSettings(tester);
    await _selectSpeed(tester, TextSpeed.instant);
    await _toggleSetting(tester, 'auto-climb-stairs-switch');
    await _toggleSetting(tester, 'auto-pick-up-items-switch');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await _openSettings(tester);
    expect(_slider(tester, 'text-speed-slider').value, 1);
    expect(_slider(tester, 'movement-sensitivity-slider').value, 4);
    expect(_switch(tester, 'auto-climb-stairs-switch').value, isTrue);
    expect(_switch(tester, 'auto-pick-up-items-switch').value, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Sliders and switches fit small screens with larger text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final size in [const Size(320, 568), const Size(844, 390)]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const DungeonCrawlerApp());
      await _openSettings(tester);
      expect(find.byType(Slider), findsNWidgets(3));
      expect(find.byType(SwitchListTile), findsNWidgets(4));
      await _toggleSetting(tester, 'auto-pick-up-items-switch');
      await _toggleSetting(tester, 'colorblind-hate-switch');
      await _toggleSetting(tester, 'floor-zero-bats-switch');
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Testing settings apply on Done and reach the first floor', (
    tester,
  ) async {
    await tester.pumpWidget(const DungeonCrawlerApp());
    await _openSettings(tester);
    expect(_switch(tester, 'colorblind-hate-switch').value, isFalse);
    expect(_switch(tester, 'floor-zero-bats-switch').value, isFalse);
    await _toggleSetting(tester, 'colorblind-hate-switch');
    await _toggleSetting(tester, 'floor-zero-bats-switch');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await _openSettings(tester);
    expect(_switch(tester, 'colorblind-hate-switch').value, isFalse);
    expect(_switch(tester, 'floor-zero-bats-switch').value, isFalse);
    await _toggleSetting(tester, 'colorblind-hate-switch');
    await _toggleSetting(tester, 'floor-zero-bats-switch');
    expect(find.text('colorblind hate'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    final board = tester.widget<DungeonBoard>(find.byType(DungeonBoard));
    expect(board.floor.number, 0);
    expect(board.floor.enemies.map((enemy) => enemy.position).toSet(), {
      const GridPosition(11, 12),
      const GridPosition(12, 12),
    });
    final context = tester.element(find.byType(DungeonPage));
    expect(ShardScope.progressOf(context).unlocked, ColorShard.values.toSet());
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
}

Future<void> _selectSpeed(WidgetTester tester, TextSpeed speed) async {
  final slider = find.byKey(const ValueKey('text-speed-slider'));
  await tester.ensureVisible(slider);
  final rect = tester.getRect(slider);
  await tester.tapAt(
    Offset(
      rect.left + 24 + (rect.width - 48) * speed.index / 3,
      rect.center.dy,
    ),
  );
  await tester.pumpAndSettle();
  expect(_slider(tester, 'text-speed-slider').value, speed.index.toDouble());
}

Slider _slider(WidgetTester tester, String key) =>
    tester.widget<Slider>(find.byKey(ValueKey(key)));

SwitchListTile _switch(WidgetTester tester, String key) =>
    tester.widget<SwitchListTile>(find.byKey(ValueKey(key)));

Future<void> _toggleSetting(WidgetTester tester, String key) async {
  final setting = find.byKey(ValueKey(key));
  await tester.ensureVisible(setting);
  await tester.tap(setting);
  await tester.pumpAndSettle();
}

String _visibleText(WidgetTester tester) => tester
    .widget<Semantics>(find.byKey(const ValueKey('dialogue-text')))
    .properties
    .label!;
