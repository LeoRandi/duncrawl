import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../domain/shard_progress.dart';
import 'shard_scope.dart';

/// Un token mantiene su tono original y depende de un único fragmento.
class ShardColor {
  final Color grey;
  final Color unlocked;
  final ColorShard shard;

  const ShardColor({
    required this.grey,
    required this.unlocked,
    required this.shard,
  });

  Color resolve(ShardProgress progress) =>
      progress.contains(shard) ? unlocked : grey;

  Color of(BuildContext context) => resolve(ShardScope.progressOf(context));
}

abstract final class ShardColors {
  static const bat = ShardColor(
    grey: DungeonColors.enemy,
    unlocked: Color(0xFFDC3838),
    shard: ColorShard.red,
  );
  static const vision = ShardColor(
    grey: Color(0xFFB0B0B0),
    unlocked: Color(0xFFFF7979),
    shard: ColorShard.red,
  );
  static const alert = ShardColor(
    grey: Color(0xFFB0B0B0),
    unlocked: Color(0xFFFFA447),
    shard: ColorShard.orange,
  );
  static const mainMenu = ShardColor(
    grey: DungeonColors.primary,
    unlocked: Color(0xFFDC3838),
    shard: ColorShard.red,
  );
  static const adventurer = ShardColor(
    grey: DungeonColors.primary,
    unlocked: Color(0xFFFFD166),
    shard: ColorShard.gold,
  );
  static const grass = ShardColor(
    grey: DungeonColors.grass,
    unlocked: Color(0xFF43864C),
    shard: ColorShard.green,
  );
  static const water = ShardColor(
    grey: DungeonColors.water,
    unlocked: Color(0xFF3868B0),
    shard: ColorShard.blue,
  );
  static const waterBorder = ShardColor(
    grey: DungeonColors.primary,
    unlocked: Color(0xFF3868B0),
    shard: ColorShard.blue,
  );
  static const shallowWater = ShardColor(
    grey: DungeonColors.water,
    unlocked: Color(0xFF83CEEF),
    shard: ColorShard.lightBlue,
  );
  static const shallowWaterPrefix = ShardColor(
    grey: DungeonColors.shallowWaterPrefix,
    unlocked: Color(0xFFB8E8FF),
    shard: ColorShard.lightBlue,
  );
}
