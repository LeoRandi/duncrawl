import 'dart:collection';

import 'dungeon.dart';
import 'dungeon_visibility.dart';
import 'encounter_state.dart';
import 'grid_position.dart';

abstract final class EncounterDetection {
  static Set<String> enemyIds(Dungeon dungeon, {EncounterState? encounter}) {
    final engaged = <String>{
      if (encounter != null)
        for (final id in encounter.enemyIds)
          if (dungeon.floor.enemyById(id) case final enemy?
              when !enemy.isDefeated)
            id,
      for (final enemy in dungeon.floor.enemies)
        if (DungeonVisibility.detectsPlayer(
          floor: dungeon.floor,
          enemy: enemy,
          player: dungeon.player,
        ))
          enemy.id,
    };
    // El ruido amplía un combate existente; no inicia uno por mera proximidad.
    if (engaged.isEmpty && encounter == null) {
      return const {};
    }

    final sources = Queue<GridPosition>()..add(dungeon.player);
    for (final id in engaged) {
      if (dungeon.positionOf(id) case final position?) {
        sources.add(position);
      }
    }
    while (sources.isNotEmpty) {
      final source = sources.removeFirst();
      for (final enemy in dungeon.floor.enemies) {
        if (enemy.isDefeated ||
            engaged.contains(enemy.id) ||
            !enemy.isWithinAlertRange(source)) {
          continue;
        }
        engaged.add(enemy.id);
        // Un recién alertado puede avisar a otros, sin duplicados ni ciclos.
        sources.add(enemy.position);
      }
    }
    return Set.unmodifiable(engaged);
  }
}
