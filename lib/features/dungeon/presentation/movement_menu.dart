import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../../../widgets/interaction_gate.dart';
import 'dungeon_controller.dart';
import 'dungeon_strings.dart';
import 'character_stats_view.dart';
import '../domain/tile_inspection.dart';
import 'movement_stat.dart';
import 'selection_frame.dart';
import 'tile_inspection_view.dart';

class MovementMenu extends StatelessWidget {
  static const minimumHeight = 216.0;

  final DungeonController controller;
  final bool enabled;
  final bool pulseConfirm;
  final bool allowStatHelp;

  const MovementMenu({
    super.key,
    required this.controller,
    this.enabled = true,
    this.pulseConfirm = false,
    this.allowStatHelp = false,
  });

  @override
  Widget build(BuildContext context) {
    return InteractionGate(
      enabled: (enabled || allowStatHelp) && controller.isBottomMenuEnabled,
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
          child: switch (controller.selectedInspection) {
            final inspection? => TileInspectionView(
              key: ValueKey((
                inspection.position,
                inspection.isAdventurer,
                inspection.object,
                inspection.enemy,
              )),
              inspection: inspection,
              onUnselect: enabled && controller.isBottomMenuEnabled
                  ? controller.unselect
                  : null,
              headerDetails: switch (inspection) {
                _ when controller.isSelected => CharacterStatsView(
                  level: controller.dungeon.adventurer.level,
                  health: controller.dungeon.adventurer.health,
                  maximumHealth: controller.dungeon.adventurer.maximumHealth,
                ),
                TileInspection(enemy: final enemy?) => CharacterStatsView(
                  level: enemy.level,
                  health: enemy.health,
                  maximumHealth: enemy.maximumHealth,
                ),
                _ => null,
              },
              footer: switch (inspection) {
                _ when controller.isSelected => _CharacterMovementActions(
                  controller: controller,
                  pulseConfirm: pulseConfirm,
                ),
                TileInspection(enemy: final enemy?) => MovementStat(
                  normal: enemy.movementSpeed,
                  combat: enemy.combatMovementSpeed,
                  helpEnabled:
                      (enabled || allowStatHelp) &&
                      controller.isBottomMenuEnabled,
                ),
                _ => null,
              },
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

class _CharacterMovementActions extends StatelessWidget {
  final DungeonController controller;
  final bool pulseConfirm;

  const _CharacterMovementActions({
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
      return Row(
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
                MovementValue(
                  value: DungeonStrings.movementAllowance(
                    remaining: controller.plan.remainingMovement,
                    total: controller.dungeon.adventurer.movementSpeed,
                  ),
                  fontSize: fontSize,
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
                          (states) => states.contains(WidgetState.disabled)
                              ? DungeonColors.textDisabled
                              : DungeonColors.background,
                        ),
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.disabled)
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
      );
    },
  );
}
