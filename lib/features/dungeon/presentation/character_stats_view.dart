import 'package:flutter/material.dart';

import 'dungeon_strings.dart';

class CharacterStatsView extends StatelessWidget {
  final int level;
  final int health;
  final int maximumHealth;

  const CharacterStatsView({
    super.key,
    required this.level,
    required this.health,
    required this.maximumHealth,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        DungeonStrings.level(level),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Text(
        DungeonStrings.health(current: health, maximum: maximumHealth),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}
