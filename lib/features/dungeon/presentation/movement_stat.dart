import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import 'dungeon_strings.dart';
import 'stat_info_button.dart';

class MovementStat extends StatelessWidget {
  final int normal;
  final int combat;
  final bool helpEnabled;

  const MovementStat({
    super.key,
    required this.normal,
    required this.combat,
    this.helpEnabled = true,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(DungeonStrings.movement),
              ),
            ),
            const SizedBox(width: 4),
            StatInfoButton(
              key: const ValueKey('movement-stat-info'),
              statName: DungeonStrings.movement,
              explanation: DungeonStrings.movementHelp,
              enabled: helpEnabled,
            ),
          ],
        ),
      ),
      const SizedBox(width: DungeonTheme.spacing),
      MovementValue(
        value: DungeonStrings.movementStat(normal: normal, combat: combat),
      ),
    ],
  );
}

class MovementValue extends StatelessWidget {
  final String value;
  final double fontSize;

  const MovementValue({super.key, required this.value, this.fontSize = 12});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(border: Border.all(color: DungeonColors.primary)),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: DungeonTheme.spacing,
      ),
      child: Text(
        value,
        key: const ValueKey('movement-allowance'),
        style: TextStyle(fontSize: fontSize),
      ),
    ),
  );
}
