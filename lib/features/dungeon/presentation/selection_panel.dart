import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import 'dungeon_strings.dart';
import '../../shards/presentation/shard_text.dart';

class SelectionPanel extends StatelessWidget {
  final String name;
  final String? description;
  final String? note;
  final Widget Function(double size) portraitBuilder;
  final Widget? headerDetails;
  final Widget? footer;
  final Widget? body;
  final VoidCallback? onUnselect;

  const SelectionPanel({
    super.key,
    required this.name,
    required this.portraitBuilder,
    required this.onUnselect,
    this.description,
    this.note,
    this.headerDetails,
    this.footer,
    this.body,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 360 ||
          MediaQuery.textScalerOf(context).scale(14) > 18;
      final portraitSize = compact || constraints.maxHeight < 180 ? 36.0 : 44.0;
      return Padding(
        padding: EdgeInsets.all(
          compact ? DungeonTheme.spacing : DungeonTheme.pagePadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                key: ValueKey(('selection-body', name)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            key: const ValueKey('selection-info'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectionPortrait(
                                key: const ValueKey('selection-portrait'),
                                size: portraitSize,
                                label: name,
                                child: portraitBuilder(portraitSize * 2 / 3),
                              ),
                              if (headerDetails case final details?) ...[
                                const SizedBox(width: DungeonTheme.spacing),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.topLeft,
                                    child: details,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: DungeonTheme.spacing),
                        SizedBox(
                          height: portraitSize,
                          child: OutlinedButton(
                            key: const ValueKey('unselect-selection'),
                            onPressed: onUnselect,
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(0, portraitSize),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                            child: const Text(DungeonStrings.unselect),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DungeonTheme.spacing),
                    ShardText(
                      name,
                      key: const ValueKey('selection-name'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (body case final stats?) ...[
                      const SizedBox(height: DungeonTheme.spacing),
                      stats,
                    ],
                    if (description case final text?) ...[
                      const SizedBox(height: DungeonTheme.spacing),
                      ShardText(
                        text,
                        key: const ValueKey('selection-description'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (note case final text?) ...[
                      const SizedBox(height: DungeonTheme.spacing),
                      ShardText(
                        text,
                        key: const ValueKey('selection-note'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (footer case final actions?) ...[
              const SizedBox(height: DungeonTheme.spacing),
              actions,
            ],
          ],
        ),
      );
    },
  );
}

class SelectionPortrait extends StatelessWidget {
  final double size;
  final String label;
  final Widget child;

  const SelectionPortrait({
    super.key,
    required this.size,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: label,
    child: ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: DungeonColors.surface,
          border: Border.all(
            color: DungeonColors.primary,
            width: DungeonTheme.selectedBorderWidth,
          ),
        ),
        child: SizedBox.square(dimension: size * 2 / 3, child: child),
      ),
    ),
  );
}
