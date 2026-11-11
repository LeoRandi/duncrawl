import 'package:flutter/material.dart';

import 'dungeon_strings.dart';
import 'selection_panel.dart';
import '../../shards/presentation/shard_colors.dart';

class AdventurerPortrait extends StatelessWidget {
  final double size;

  const AdventurerPortrait({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) => SelectionPortrait(
    size: size,
    label: DungeonStrings.adventurer,
    child: Icon(
      Icons.person_rounded,
      color: ShardColors.adventurer.of(context),
      size: size * 2 / 3,
    ),
  );
}
