import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../domain/dungeon_floor.dart';
import '../domain/dungeon_enemy.dart';
import '../domain/tile_inspection.dart';
import 'dungeon_strings.dart';
import 'tile_glyph.dart';
import 'selection_panel.dart';
import '../../shards/presentation/shard_colors.dart';

class TileInspectionView extends StatelessWidget {
  final TileInspection inspection;
  final VoidCallback? onUnselect;
  final Widget? headerDetails;
  final Widget? footer;

  const TileInspectionView({
    super.key,
    required this.inspection,
    required this.onUnselect,
    this.headerDetails,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final content = InspectionContent.fromTile(inspection);
    return SelectionPanel(
      name: content.name,
      description: content.description,
      note: content.note,
      onUnselect: onUnselect,
      headerDetails: headerDetails,
      footer: footer,
      portraitBuilder: (size) => switch ((content.glyph, content.icon)) {
        (final glyph?, _) => TileGlyph(
          symbol: glyph,
          label: content.name,
          fontSize: size,
          color: content.resolvedColor(context),
          prefix: content.prefix,
          prefixColor: ShardColors.shallowWaterPrefix.of(context),
        ),
        (_, final icon?) => Icon(
          icon,
          size: size,
          color: content.resolvedColor(context),
        ),
        _ => ColoredBox(color: content.resolvedColor(context)),
      },
    );
  }
}

enum InspectionContent {
  adventurer(
    name: DungeonStrings.adventurer,
    description: DungeonStrings.adventurerDescription,
    color: DungeonColors.primary,
    icon: Icons.person_rounded,
  ),
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
  bat(
    name: DungeonStrings.bat,
    description: DungeonStrings.batDescription,
    color: DungeonColors.enemy,
    glyph: 'B',
  ),
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

  const InspectionContent({
    required this.name,
    this.description,
    this.note,
    required this.color,
    this.glyph,
    this.icon,
    this.prefix = '',
    this.prefixColor,
  });

  Color resolvedColor(BuildContext context) => switch (this) {
    adventurer => ShardColors.adventurer.of(context),
    bat => ShardColors.bat.of(context),
    grass => ShardColors.grass.of(context),
    water => ShardColors.water.of(context),
    shallowWater => ShardColors.shallowWater.of(context),
    stairs || wall => color,
  };

  static InspectionContent fromTile(TileInspection inspection) {
    if (inspection.isAdventurer) {
      return adventurer;
    }
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
