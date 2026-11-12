import 'package:flutter/material.dart';

import '../domain/dungeon_actor.dart';
import 'dungeon_strings.dart';
import 'movement_stat.dart';

class ActorStatsView extends StatelessWidget {
  final DungeonActor actor;
  final bool showMovement;
  final bool helpEnabled;

  const ActorStatsView({
    super.key,
    required this.actor,
    this.showMovement = true,
    this.helpEnabled = true,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (showMovement)
        MovementStat(
          normal: actor.movementSpeed,
          combat: actor.combatMovementSpeed,
          helpEnabled: helpEnabled,
        ),
      for (final (label, value) in [
        (DungeonStrings.strength, actor.strength),
        (DungeonStrings.dexterity, actor.dexterity),
        (DungeonStrings.special, actor.special),
      ])
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Semantics(
            label: '$label: $value',
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text('$value', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}
