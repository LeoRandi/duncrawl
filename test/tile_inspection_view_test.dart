import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/app/dungeon_theme.dart';
import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/domain/tile_inspection.dart';
import 'package:duncrawl/features/dungeon/presentation/tile_inspection_view.dart';

void main() {
  testWidgets('Tile details remain usable in compact panels with larger text', (
    tester,
  ) async {
    var unselected = 0;
    const inspections = [
      TileInspection(position: GridPosition(1, 1), tile: DungeonTile.water),
      TileInspection(
        position: GridPosition(1, 1),
        tile: DungeonTile.floor,
        object: DungeonGroundObject(
          type: GroundObjectType.stairsUp,
          position: GridPosition(1, 1),
        ),
      ),
    ];
    for (final width in [256.0, 320.0]) {
      for (final inspection in inspections) {
        await tester.pumpWidget(
          MaterialApp(
            theme: DungeonTheme.dark,
            home: Scaffold(
              body: Center(
                child: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.5),
                  ),
                  child: SizedBox(
                    width: width,
                    height: 216,
                    child: TileInspectionView(
                      inspection: inspection,
                      onUnselect: () => unselected++,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('tile-inspection-name')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('tile-inspection-description')),
          findsOneWidget,
        );
        if (inspection.tile == DungeonTile.water) {
          final glyph = tester.widget<Text>(find.text('w'));
          expect(glyph.style?.color, DungeonColors.water);
          expect(glyph.textScaler, TextScaler.noScaling);
        }
        await tester.ensureVisible(find.text('Unselect'));
        await tester.tap(find.text('Unselect'));
      }
    }
    expect(unselected, 4);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
