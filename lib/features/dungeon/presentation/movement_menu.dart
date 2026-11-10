import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import 'dungeon_controller.dart';
import 'dungeon_strings.dart';

class MovementMenu extends StatelessWidget {
  final DungeonController controller;

  const MovementMenu({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final destination = controller.plan.destination;
    return Semantics(
      label: DungeonStrings.optionMenu,
      child: Container(
        key: const ValueKey('option-menu'),
        width: double.infinity,
        decoration: BoxDecoration(
          color: DungeonColors.panel,
          border: Border.all(
            color: DungeonColors.primary,
            width: DungeonTheme.selectedBorderWidth,
          ),
          borderRadius: BorderRadius.circular(DungeonTheme.cornerRadius),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Padding(
            padding: EdgeInsets.all(
              constraints.maxHeight < 120 ? 4 : DungeonTheme.pagePadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (controller.canConfirm)
                          Text(
                            DungeonStrings.destination(
                              column: destination.column + 1,
                              row: destination.row + 1,
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        if (controller.isMoving)
                          const Text(DungeonStrings.moving),
                      ],
                    ),
                  ),
                ),
                if (controller.isSelected)
                  Row(
                    children: [
                      if (controller.canConfirm) ...[
                        Expanded(
                          child: TapRegion(
                            onTapOutside: (_) => controller.cancelPreview(),
                            child: FilledButton(
                              key: const ValueKey('confirm-movement'),
                              style: _buttonStyle,
                              onPressed: controller.confirm,
                              child: const Text(DungeonStrings.confirm),
                            ),
                          ),
                        ),
                        const SizedBox(width: DungeonTheme.spacing),
                      ],
                      Expanded(
                        child: OutlinedButton(
                          style: _buttonStyle,
                          onPressed: controller.unselect,
                          child: const Text(DungeonStrings.unselect),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static final _buttonStyle = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(fontFamily: 'monospace', fontSize: 14),
    ),
  );
}
