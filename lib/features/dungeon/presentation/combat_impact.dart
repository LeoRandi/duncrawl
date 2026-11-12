import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import 'dungeon_strings.dart';

class CombatImpact extends StatelessWidget {
  final int damage;

  const CombatImpact({super.key, required this.damage});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Semantics(
      label: DungeonStrings.damageTaken(damage),
      liveRegion: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        builder: (context, progress, child) => Transform.translate(
          offset: Offset(0, -12 * progress),
          child: Opacity(opacity: 1 - progress, child: child),
        ),
        child: Center(
          child: Text(
            '-$damage',
            textScaler: TextScaler.noScaling,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: DungeonColors.primary,
              backgroundColor: DungeonColors.background,
            ),
          ),
        ),
      ),
    ),
  );
}
