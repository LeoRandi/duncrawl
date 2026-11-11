import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import 'dungeon_controller.dart';
import 'dungeon_strings.dart';
import 'tile_inspection_view.dart';
import '../../shards/presentation/shard_text.dart';

class SelectionStackTab extends StatelessWidget {
  static const extent = 40.0;

  final DungeonController controller;
  final bool enabled;

  const SelectionStackTab({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final alternatives = controller.alternateSelections;
    if (alternatives.isEmpty) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < alternatives.length; index++)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: OutlinedButton(
                  key: index == 0
                      ? const ValueKey('selection-stack-tab')
                      : ValueKey(('selection-stack-tab', index)),
                  onPressed: enabled && controller.isBottomMenuEnabled
                      ? () => controller.selectStackEntry(alternatives[index])
                      : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DungeonTheme.spacing,
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  child: ShardText(
                    controller.isAboveSelection(alternatives[index])
                        ? DungeonStrings.below(
                            InspectionContent.fromTile(
                              alternatives[index],
                            ).name,
                          )
                        : DungeonStrings.over(
                            InspectionContent.fromTile(
                              alternatives[index],
                            ).name,
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
