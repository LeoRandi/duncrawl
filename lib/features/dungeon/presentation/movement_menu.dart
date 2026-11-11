import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../../../widgets/interaction_gate.dart';
import 'dungeon_controller.dart';
import 'dungeon_strings.dart';
import 'adventurer_information.dart';
import 'selection_frame.dart';
import 'tile_inspection_view.dart';

class MovementMenu extends StatelessWidget {
  static const minimumHeight = 216.0;

  final DungeonController controller;
  final bool enabled;
  final bool pulseConfirm;

  const MovementMenu({
    super.key,
    required this.controller,
    this.enabled = true,
    this.pulseConfirm = false,
  });

  @override
  Widget build(BuildContext context) {
    return InteractionGate(
      enabled: enabled && controller.isBottomMenuEnabled,
      child: Semantics(
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
          child: switch (controller.inspectedTile) {
            final inspection? => TileInspectionView(
              key: ValueKey(inspection.position),
              inspection: inspection,
              onUnselect: controller.unselect,
            ),
            null when controller.isSelected => _SelectedCharacterMenu(
              controller: controller,
              pulseConfirm: pulseConfirm,
            ),
            null => Center(
              child: Padding(
                padding: const EdgeInsets.all(DungeonTheme.spacing),
                child: Text(
                  DungeonStrings.selectPrompt,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DungeonColors.textDisabled,
                  ),
                ),
              ),
            ),
          },
        ),
      ),
    );
  }
}

class _SelectedCharacterMenu extends StatelessWidget {
  final DungeonController controller;
  final bool pulseConfirm;

  const _SelectedCharacterMenu({
    required this.controller,
    required this.pulseConfirm,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 360 ||
          MediaQuery.textScalerOf(context).scale(14) > 18;
      final fontSize = compact ? 12.0 : 14.0;
      final buttonStyle = ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 8),
        ),
        textStyle: WidgetStatePropertyAll(
          TextStyle(fontFamily: 'monospace', fontSize: fontSize),
        ),
      );
      final destination = controller.plan.destination;
      final canConfirm = controller.canConfirm;
      return Padding(
        padding: EdgeInsets.all(
          compact || constraints.maxHeight < 180
              ? DungeonTheme.spacing
              : DungeonTheme.pagePadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AdventurerInformation(
                    key: const ValueKey('selected-character-info'),
                    adventurer: controller.dungeon.adventurer,
                    portrait: AdventurerPortrait(
                      size: compact || constraints.maxHeight < 180 ? 36 : 44,
                    ),
                    textStyle: compact
                        ? Theme.of(context).textTheme.bodySmall
                        : null,
                  ),
                ),
                const SizedBox(width: DungeonTheme.spacing),
                SizedBox(
                  width: compact ? 112 : 120,
                  child: OutlinedButton(
                    style: buttonStyle,
                    onPressed: controller.isBottomMenuEnabled
                        ? controller.unselect
                        : null,
                    child: const Text(DungeonStrings.unselect),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DungeonTheme.spacing),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DungeonStrings.adventurer,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: DungeonTheme.spacing),
                    Text(
                      DungeonStrings.adventurerDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DungeonTheme.spacing),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            DungeonStrings.movement,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                      const SizedBox(width: DungeonTheme.spacing),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: DungeonColors.primary),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: DungeonTheme.spacing,
                          ),
                          child: Text(
                            DungeonStrings.movementAllowance(
                              remaining: controller.plan.remainingMovement,
                              total:
                                  controller.dungeon.adventurer.movementSpeed,
                            ),
                            key: const ValueKey('movement-allowance'),
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DungeonTheme.spacing),
                Expanded(
                  child: TapRegion(
                    enabled: canConfirm,
                    onTapOutside: (_) => controller.cancelPreview(),
                    child: Tooltip(
                      message: DungeonStrings.destination(
                        column: destination.column + 1,
                        row: destination.row + 1,
                      ),
                      child: Listener(
                        onPointerDown: (_) {
                          // Un segundo dedo puede confirmar aunque el arrastre siga activo.
                          if (controller.phase == MovementPhase.dragging) {
                            controller.confirm();
                          }
                        },
                        child: SelectionFrame(
                          key: const ValueKey('tutorial-confirm-pulse'),
                          selected: pulseConfirm && canConfirm,
                          child: FilledButton(
                            key: const ValueKey('confirm-movement'),
                            style: buttonStyle.copyWith(
                              foregroundColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.disabled)
                                    ? DungeonColors.textDisabled
                                    : DungeonColors.background,
                              ),
                              backgroundColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.disabled)
                                    ? DungeonColors.background
                                    : DungeonColors.primary,
                              ),
                              side: WidgetStateProperty.resolveWith(
                                (states) => BorderSide(
                                  color: states.contains(WidgetState.disabled)
                                      ? DungeonColors.textDisabled
                                      : DungeonColors.primary,
                                ),
                              ),
                            ),
                            onPressed: canConfirm ? controller.confirm : null,
                            child: const Text(DungeonStrings.confirm),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
