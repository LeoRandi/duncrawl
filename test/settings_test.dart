import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dialogue/presentation/dialogue_window.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_page.dart';
import 'package:duncrawl/features/settings/domain/text_speed.dart';
import 'package:duncrawl/main.dart';

import 'helpers/dialogue_helpers.dart';

void main() {
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
      expect(find.byType(Slider), findsNWidgets(2));
      expect(find.byType(SwitchListTile), findsNWidgets(2));
      await _toggleSetting(tester, 'auto-pick-up-items-switch');
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
}

Future<void> _selectSpeed(WidgetTester tester, TextSpeed speed) async {
  final slider = find.byKey(const ValueKey('text-speed-slider'));
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
