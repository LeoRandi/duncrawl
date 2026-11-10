import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../domain/adventurer.dart';
import 'dungeon_strings.dart';

class AdventurerInformation extends StatelessWidget {
  final Adventurer adventurer;
  final Widget portrait;
  final TextStyle? textStyle;

  const AdventurerInformation({
    super.key,
    required this.adventurer,
    required this.portrait,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      portrait,
      const SizedBox(width: DungeonTheme.spacing),
      Flexible(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DungeonStrings.level(adventurer.level),
              style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              DungeonStrings.health(
                current: adventurer.health,
                maximum: adventurer.maximumHealth,
              ),
              style: textStyle ?? Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ],
  );
}

class AdventurerPortrait extends StatelessWidget {
  final double size;

  const AdventurerPortrait({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: DungeonColors.surface,
      border: Border.all(
        color: DungeonColors.primary,
        width: DungeonTheme.selectedBorderWidth,
      ),
    ),
    child: Icon(
      Icons.person_rounded,
      color: DungeonColors.primary,
      size: size * 2 / 3,
    ),
  );
}
