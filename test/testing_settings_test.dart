import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/app/dungeon_theme.dart';
import 'package:duncrawl/features/dungeon/domain/adventurer.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_enemy.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/floors/floor_0.dart';
import 'package:duncrawl/features/dungeon/floors/floor_1.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_controller.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_page.dart';
import 'package:duncrawl/features/settings/domain/game_settings.dart';
import 'package:duncrawl/features/shards/domain/shard_progress.dart';
import 'package:duncrawl/features/shards/presentation/shard_scope.dart';

void main() {
  test('Testing flags default off and survive unrelated settings changes', () {
    const defaults = GameSettings();
    expect(defaults.colorblindHate, isFalse);
    expect(defaults.floorZeroBats, isFalse);
    final enabled = defaults
        .copyWith(colorblindHate: true, floorZeroBats: true)
        .copyWith(autoClimbStairs: false);
    expect(enabled.colorblindHate, isTrue);
    expect(enabled.floorZeroBats, isTrue);
    expect(enabled.autoClimbStairs, isFalse);
  });

  test('Unlocking all shards preserves earned rewards when switched off', () {
    final shards = ShardController();
    addTearDown(shards.dispose);
    shards.unlock(ColorShard.red);
    shards.setUnlockAll(true);
    expect(shards.value.unlocked, ColorShard.values.toSet());
    shards.unlock(ColorShard.gold);
    shards.setUnlockAll(false);
    expect(shards.value.unlocked, {ColorShard.red, ColorShard.gold});
    shards.setUnlockAll(true);
    expect(shards.value.unlocked, ColorShard.values.toSet());
  });

  test('Test bats preserve the current floor, actor and existing enemies', () {
    final start = Dungeon.start(
      floor0.create(),
      adventurer: const Adventurer(health: 7),
    );
    final existing = start.addEnemy(
      const DungeonEnemy.bat(GridPosition(2, 2), id: 'existing'),
    );
    final controller = DungeonController(existing);
    addTearDown(controller.dispose);
    controller.setFloorZeroBats(true);
    expect(controller.dungeon.floor.enemies, hasLength(3));
    expect(controller.dungeon.player, existing.player);
    expect(controller.dungeon.adventurer, same(existing.adventurer));
    expect(
      controller.dungeon.floor.groundObjects,
      same(existing.floor.groundObjects),
    );
    expect(controller.isInCombat, isFalse);
    final snapshot = controller.dungeon;
    controller.setFloorZeroBats(true);
    expect(controller.dungeon, same(snapshot));
    controller.setFloorZeroBats(false);
    expect(controller.dungeon.floor.enemies.single.id, 'existing');
    expect(controller.dungeon.adventurer.health, 7);
    expect(start.floor.enemies, isEmpty);
  });

  test(
    'Enabling bats avoids the player and disabling them clears their encounter',
    () {
      final corner = Dungeon.start(floor0.create())
          .move(DungeonDirection.east, steps: 4)
          .move(DungeonDirection.south, steps: 5);
      final controller = DungeonController(corner);
      addTearDown(controller.dispose);
      controller.setFloorZeroBats(true);
      expect(controller.dungeon.floor.enemies, hasLength(2));
      expect(
        controller.dungeon.floor.enemies.every(
          (enemy) => enemy.position != corner.player,
        ),
        isTrue,
      );
      expect(controller.isInCombat, isTrue);
      controller.setFloorZeroBats(false);
      expect(controller.isInCombat, isFalse);
      expect(controller.dungeon.floor.enemies, isEmpty);
      expect(controller.dungeon.player, corner.player);
    },
  );

  test('The bat setting only populates floor zero', () {
    final controller = DungeonController(
      Dungeon.start(floor1.create()),
      floorZeroBats: true,
    );
    addTearDown(controller.dispose);
    expect(controller.dungeon.floor.enemies, isEmpty);
    expect(controller.dungeon.floor.number, 1);
  });

  testWidgets('Both settings update an active game without starting over', (
    tester,
  ) async {
    final settings = ValueNotifier(const GameSettings(skipTutorials: true));
    final shards = ShardController();
    addTearDown(settings.dispose);
    addTearDown(shards.dispose);
    await tester.pumpWidget(
      ShardScope(
        controller: shards,
        child: MaterialApp(
          theme: DungeonTheme.dark,
          home: DungeonPage(settings: settings),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(
      tester.widget<DungeonBoard>(find.byType(DungeonBoard)).floor.enemies,
      isEmpty,
    );
    shards.unlock(ColorShard.red);
    settings.value = settings.value.copyWith(
      colorblindHate: true,
      floorZeroBats: true,
    );
    await tester.pump();
    final board = tester.widget<DungeonBoard>(find.byType(DungeonBoard));
    expect(board.floor.enemies, hasLength(2));
    expect(board.player, const GridPosition(7, 7));
    expect(shards.value.unlocked, ColorShard.values.toSet());
    settings.value = settings.value.copyWith(
      colorblindHate: false,
      floorZeroBats: false,
    );
    await tester.pump();
    expect(
      tester.widget<DungeonBoard>(find.byType(DungeonBoard)).floor.enemies,
      isEmpty,
    );
    expect(shards.value.unlocked, {ColorShard.red});
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
