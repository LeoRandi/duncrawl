import 'package:flutter/material.dart';

import '../../shards/presentation/shard_colors.dart';
import '../domain/dungeon_enemy.dart';
import '../domain/dungeon_floor.dart';
import '../domain/dungeon_visibility.dart';
import '../domain/grid_position.dart';
import 'tile_area_outline.dart';

class EnemyRanges extends StatelessWidget {
  final DungeonFloor floor;
  final Set<String> engagedEnemyIds;
  final DungeonEnemy? inspectedEnemy;

  const EnemyRanges({
    super.key,
    required this.floor,
    required this.engagedEnemyIds,
    this.inspectedEnemy,
  });

  @override
  Widget build(BuildContext context) {
    final movement = <GridPosition>{};
    final vision = <GridPosition>{};
    final alert = <GridPosition>{};
    for (final enemy in floor.enemies) {
      if (enemy.isDefeated) {
        continue;
      }
      final engaged = engagedEnemyIds.contains(enemy.id);
      final inspected = inspectedEnemy?.id == enemy.id;
      if (engaged) {
        movement.addAll(enemy.movementArea.where(floor.contains));
      } else if (inspected) {
        vision.addAll(DungeonVisibility.visibleArea(floor, enemy));
      }
      if (engaged || inspected) {
        alert.addAll(enemy.alertArea.where(floor.contains));
      }
    }

    // Se unen las casillas antes de trazar para eliminar bordes dentro de cada tipo.
    return Stack(
      fit: StackFit.expand,
      children: [
        if (alert.isNotEmpty)
          TileAreaOutline(
            key: const ValueKey('enemy-alert'),
            tiles: alert,
            color: ShardColors.alert.of(context),
            pulseDuration: TileAreaOutline.combatPulseDuration,
          ),
        if (movement.isNotEmpty)
          TileAreaOutline(
            key: const ValueKey('combat-movement'),
            tiles: movement,
            color: ShardColors.vision.unlocked,
            pulseDuration: TileAreaOutline.combatPulseDuration,
          ),
        if (vision.isNotEmpty)
          TileAreaOutline(
            key: const ValueKey('enemy-vision'),
            tiles: vision,
            color: ShardColors.vision.of(context),
          ),
      ],
    );
  }
}
