import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/app/dungeon_theme.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_enemy.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/floors/floor_2.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_controller.dart';
import 'package:duncrawl/features/dungeon/presentation/movement_menu.dart';
import 'package:duncrawl/features/dungeon/presentation/selection_stack_tab.dart';
import 'package:duncrawl/features/dungeon/presentation/tile_area_outline.dart';
import 'package:duncrawl/features/dungeon/presentation/tile_glyph.dart';
import 'package:duncrawl/features/shards/domain/shard_progress.dart';
import 'package:duncrawl/features/shards/presentation/shard_colors.dart';
import 'package:duncrawl/features/shards/presentation/shard_scope.dart';

void main() {
  test(
    'Shards unlock only their own colors and preserve previous progress',
    () {
      const locked = ShardProgress.empty();
      final red = locked.unlock(ColorShard.red);
      expect(locked.unlocked, isEmpty);
      expect(red.unlocked, {ColorShard.red});
      expect(red.unlock(ColorShard.red), same(red));
      final tokens = [
        ShardColors.bat,
        ShardColors.vision,
        ShardColors.mainMenu,
        ShardColors.adventurer,
        ShardColors.grass,
        ShardColors.water,
        ShardColors.waterBorder,
        ShardColors.shallowWater,
        ShardColors.shallowWaterPrefix,
      ];
      for (final token in tokens) {
        expect(token.resolve(locked), token.grey);
        expect(
          token.resolve(red),
          token.shard == ColorShard.red ? token.unlocked : token.grey,
        );
        expect(token.resolve(locked.unlock(token.shard)), token.unlocked);
      }
      expect(red.unlock(ColorShard.gold).unlocked, {
        ColorShard.red,
        ColorShard.gold,
      });
      expect(() => red.unlocked.add(ColorShard.blue), throwsUnsupportedError);
    },
  );

  test('Bat vision includes thirteen tiles in a radius-two diamond', () {
    const bat = DungeonEnemy.bat(GridPosition(7, 7), id: 'bat');
    expect(bat.visionRadius, 2);
    expect(bat.visionArea, hasLength(13));
    expect(
      bat.visionArea,
      containsAll([
        const GridPosition(7, 5),
        const GridPosition(9, 7),
        const GridPosition(7, 9),
        const GridPosition(5, 7),
        const GridPosition(8, 8),
      ]),
    );
    expect(bat.visionArea, isNot(contains(const GridPosition(9, 9))));
    expect(bat.visionArea, isNot(contains(const GridPosition(10, 7))));
  });

  testWidgets(
    'Unlocks update board, portraits, mentions and the selected vision independently',
    (tester) async {
      final shards = ShardController();
      final controller = DungeonController(Dungeon.start(floor2.create()));
      addTearDown(shards.dispose);
      addTearDown(controller.dispose);
      controller.selectTile(const GridPosition(5, 7));
      await tester.pumpWidget(
        ShardScope(
          controller: shards,
          child: MaterialApp(
            theme: DungeonTheme.dark,
            home: Scaffold(
              body: ListenableBuilder(
                listenable: controller,
                builder: (context, child) => Column(
                  children: [
                    SizedBox.square(
                      dimension: 240,
                      child: DungeonBoard(
                        floor: controller.dungeon.floor,
                        player: controller.dungeon.player,
                        selectedTile: controller.selectedPosition,
                        selectedInspection: controller.selectedInspection,
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
      );
      expect(
        tester.widget<TileAreaOutline>(find.byType(TileAreaOutline)).color,
        ShardColors.vision.grey,
      );
      expect(
        _glyphs(
          tester,
          'B',
        ).every((glyph) => glyph.color == ShardColors.bat.grey),
        isTrue,
      );
      shards.unlock(ColorShard.red);
      await tester.pump();
      expect(
        _glyphs(
          tester,
          'B',
        ).every((glyph) => glyph.color == ShardColors.bat.unlocked),
        isTrue,
      );
      expect(
        _glyphs(
          tester,
          'g',
        ).every((glyph) => glyph.color == ShardColors.grass.grey),
        isTrue,
      );
      expect(
        tester.widget<TileAreaOutline>(find.byType(TileAreaOutline)).color,
        ShardColors.vision.unlocked,
      );
      expect(_mentionColor(tester, 'Bat', 'Bat'), ShardColors.bat.unlocked);
      await tester.tap(find.text('Over: Shallow Water'));
      await tester.pump();
      expect(find.byType(TileAreaOutline), findsNothing);
      expect(
        _mentionColor(tester, 'Below: Bat', 'Bat'),
        ShardColors.bat.unlocked,
      );
      shards.unlock(ColorShard.lightBlue);
      await tester.pump();
      expect(
        _glyphs(tester, 'w')
            .where((glyph) => glyph.prefix == 's')
            .every(
              (glyph) =>
                  glyph.color == ShardColors.shallowWater.unlocked &&
                  glyph.prefixColor == ShardColors.shallowWaterPrefix.unlocked,
            ),
        isTrue,
      );
      expect(
        _glyphs(tester, 'w')
            .where((glyph) => glyph.prefix.isEmpty)
            .every((glyph) => glyph.color == ShardColors.water.grey),
        isTrue,
      );
      shards.unlock(ColorShard.blue);
      shards.unlock(ColorShard.green);
      shards.unlock(ColorShard.gold);
      await tester.pump();
      expect(
        _glyphs(
          tester,
          'g',
        ).every((glyph) => glyph.color == ShardColors.grass.unlocked),
        isTrue,
      );
      expect(
        _glyphs(tester, 'w')
            .where((glyph) => glyph.prefix.isEmpty)
            .every((glyph) => glyph.color == ShardColors.water.unlocked),
        isTrue,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.person_rounded)).color,
        ShardColors.adventurer.unlocked,
      );
      expect(find.textContaining('Vision'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

Iterable<TileGlyph> _glyphs(WidgetTester tester, String symbol) => tester
    .widgetList<TileGlyph>(find.byType(TileGlyph))
    .where((glyph) => glyph.symbol == symbol);

Color? _mentionColor(WidgetTester tester, String text, String mention) {
  final span = tester.widget<Text>(find.text(text)).textSpan! as TextSpan;
  return span.children!
      .whereType<TextSpan>()
      .firstWhere((span) => span.text == mention)
      .style
      ?.color;
}
