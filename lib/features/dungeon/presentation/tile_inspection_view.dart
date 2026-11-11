import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../domain/dungeon_floor.dart';
import '../domain/dungeon_enemy.dart';
import '../domain/tile_inspection.dart';
import 'dungeon_strings.dart';
import 'tile_glyph.dart';

class TileInspectionView extends StatelessWidget {
  final TileInspection inspection;
  final VoidCallback onUnselect;

  const TileInspectionView({
    super.key,
    required this.inspection,
    required this.onUnselect,
  });

  @override
  Widget build(BuildContext context) {
    final content = _InspectionContent.fromTile(inspection);
    return SingleChildScrollView(
      key: const ValueKey('tile-inspection'),
      padding: const EdgeInsets.all(DungeonTheme.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InspectionPortrait(content: content),
                    const SizedBox(width: DungeonTheme.spacing),
                    Expanded(
                      child: Text(
                        content.name,
                        key: const ValueKey('tile-inspection-name'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DungeonTheme.spacing),
              OutlinedButton(
                onPressed: onUnselect,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
                child: const Text(DungeonStrings.unselect),
              ),
            ],
          ),
          if (content.description case final description?) ...[
            const SizedBox(height: DungeonTheme.spacing * 2),
            Text(
              description,
              key: const ValueKey('tile-inspection-description'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (content.note case final note?) ...[
            const SizedBox(height: DungeonTheme.spacing),
            Text(
              note,
              key: const ValueKey('tile-inspection-note'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

enum _InspectionContent {
  water(
    name: DungeonStrings.water,
    description: DungeonStrings.waterDescription,
    color: DungeonColors.water,
    glyph: 'w',
  ),
  grass(
    name: DungeonStrings.grass,
    description: DungeonStrings.grassDescription,
    color: DungeonColors.grass,
    glyph: 'g',
  ),
  shallowWater(
    name: DungeonStrings.shallowWater,
    description: DungeonStrings.waterDescription,
    note: DungeonStrings.shallowWaterDescription,
    color: DungeonColors.water,
    glyph: 'w',
    prefix: 's',
    prefixColor: DungeonColors.shallowWaterPrefix,
  ),
  bat(name: DungeonStrings.bat, color: DungeonColors.enemy, glyph: 'B'),
  stairs(
    name: DungeonStrings.stairsName,
    description: DungeonStrings.stairsDescription,
    color: DungeonColors.textSecondary,
    icon: Icons.stairs_rounded,
  ),
  wall(
    name: DungeonStrings.wall,
    description: DungeonStrings.wallDescription,
    color: DungeonColors.wallTile,
  );

  final String name;
  final String? description;
  final String? note;
  final Color color;
  final String? glyph;
  final String prefix;
  final Color? prefixColor;
  final IconData? icon;

  const _InspectionContent({
    required this.name,
    this.description,
    this.note,
    required this.color,
    this.glyph,
    this.icon,
    this.prefix = '',
    this.prefixColor,
  });

  static _InspectionContent fromTile(TileInspection inspection) {
    final enemy = inspection.enemy;
    if (enemy != null) {
      return switch (enemy.type) {
        EnemyType.bat => bat,
      };
    }
    final object = inspection.object;
    if (object != null) {
      return switch (object.type) {
        GroundObjectType.grass => grass,
        GroundObjectType.stairsUp => stairs,
        GroundObjectType.shallowWater => shallowWater,
      };
    }
    return switch (inspection.tile) {
      DungeonTile.water => water,
      DungeonTile.wall => wall,
      DungeonTile.floor || DungeonTile.voidTile => throw ArgumentError.value(
        inspection,
        'inspection',
        'Empty terrain has no inspection panel.',
      ),
    };
  }
}

class _InspectionPortrait extends StatelessWidget {
  final _InspectionContent content;

  const _InspectionPortrait({required this.content});

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: content.name,
    child: ExcludeSemantics(
      child: Container(
        key: const ValueKey('tile-inspection-portrait'),
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: DungeonColors.floorTile,
          border: Border.all(
            color: DungeonColors.primary,
            width: DungeonTheme.selectedBorderWidth,
          ),
        ),
        child: switch ((content.glyph, content.icon)) {
          (final glyph?, _) => TileGlyph(
            symbol: glyph,
            label: content.name,
            fontSize: 28,
            color: content.color,
            prefix: content.prefix,
            prefixColor: content.prefixColor,
          ),
          (_, final icon?) => Icon(icon, size: 28, color: content.color),
          _ => ColoredBox(color: content.color),
        },
      ),
    ),
  );
}
