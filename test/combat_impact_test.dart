import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/app/dungeon_theme.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_enemy.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/presentation/combat_impact.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_page.dart';
import 'package:duncrawl/features/dungeon/presentation/movement_menu.dart';
import 'package:duncrawl/features/settings/domain/game_settings.dart';

import 'support/combat_fixture.dart';

void main() {
  testWidgets(
    'Aiming after two bat turns does not replay an old damage effect',
    (tester) async {
      final settings = ValueNotifier(const GameSettings(skipTutorials: true));
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: DungeonTheme.dark,
          home: DungeonPage(
            settings: settings,
            initialDungeon: combatFixture(
              enemies: [const GridPosition(8, 7), const GridPosition(12, 7)],
            ),
          ),
        ),
      );
      await tester.pump();
      final controller = tester
          .widget<MovementMenu>(find.byType(MovementMenu))
          .controller;
      await tester.tap(find.byKey(const ValueKey('end-turn')));
      await tester.pump();
      for (var step = 0; step < 5; step++) {
        await tester.pump(EnemyType.bat.stepInterval);
      }
      expect(controller.isPlayerTurn, isTrue);
      expect(controller.dungeon.adventurer.health, 9);
      expect(
        controller.dungeon.floor.enemies.last.position.distanceTo(
          controller.dungeon.player,
        ),
        greaterThan(1),
      );
      await tester.pump(const Duration(milliseconds: 600));
      final impact = find.byType(CombatImpact);
      final originalElement = tester.element(impact);
      final originalSequence = controller.attackSequence;
      expect(_opacity(tester), 0);

      await tester.tap(find.byKey(const ValueKey('strike-mode')));
      await tester.pump();
      expect(tester.element(impact), same(originalElement));
      expect(_opacity(tester), 0);
      await tester.drag(
        find.byKey(const ValueKey('action-pad')),
        const Offset(40, 0),
      );
      await tester.pump();
      expect(controller.canStrike, isTrue);
      expect(controller.attackSequence, originalSequence);
      expect(controller.dungeon.adventurer.health, 9);
      expect(tester.element(impact), same(originalElement));
      expect(_opacity(tester), 0);
      await tester.pump(const Duration(milliseconds: 150));
      expect(_opacity(tester), 0);

      await tester.tap(find.byKey(const ValueKey('cancel-action')));
      await tester.pump();
      expect(tester.element(impact), same(originalElement));
      expect(_opacity(tester), 0);
      await tester.tap(find.byKey(const ValueKey('inspect-action')));
      await tester.pump();
      expect(_opacity(tester), 0);
      await tester.tap(find.byKey(const ValueKey('return-to-actions')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('strike-mode')));
      await tester.pump();
      await tester.drag(
        find.byKey(const ValueKey('action-pad')),
        const Offset(40, 0),
      );
      await tester.pump();
      expect(_opacity(tester), 0);

      await tester.tap(find.byKey(const ValueKey('confirm-action')));
      await tester.pump();
      expect(controller.attackSequence, originalSequence + 1);
      expect(controller.dungeon.floor.enemies.first.health, 1);
      expect(controller.dungeon.adventurer.health, 9);
      expect(tester.element(impact), isNot(same(originalElement)));
      expect(tester.widget<CombatImpact>(impact).damage, 2);
      expect(_opacity(tester), 1);
      await tester.pump(const Duration(milliseconds: 600));
      expect(_opacity(tester), 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

double _opacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.descendant(
        of: find.byType(CombatImpact),
        matching: find.byType(Opacity),
      ),
    )
    .opacity;
