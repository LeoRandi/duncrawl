import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../../../widgets/interaction_gate.dart';
import '../domain/tile_inspection.dart';
import 'action_controls.dart';
import 'actor_stats_view.dart';
import 'character_stats_view.dart';
import 'dungeon_controller.dart';
import 'dungeon_strings.dart';
import 'movement_stat.dart';
import 'tile_inspection_view.dart';

class MovementMenu extends StatelessWidget {
  static const minimumHeight = 216.0;

  final DungeonController controller;
  final bool enabled;
  final bool allowMovement;
  final bool pulseConfirm;
  final bool allowStatHelp;
  final double movementStepDistance;
  final VoidCallback? onReturnToMainMenu;

  const MovementMenu({
    super.key,
    required this.controller,
    this.enabled = true,
    this.allowMovement = true,
    this.pulseConfirm = false,
    this.allowStatHelp = false,
    this.movementStepDistance = 32,
    this.onReturnToMainMenu,
  });

  @override
  Widget build(BuildContext context) => InteractionGate(
    enabled:
        controller.isDefeated ||
        (enabled || allowMovement || allowStatHelp) &&
            controller.isBottomMenuEnabled,
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
        child: Column(
          children: [
            Expanded(
              child: switch (controller.selectedInspection) {
                _ when controller.isControlPadOpen => ActionControls(
                  controller: controller,
                  allowMovement: allowMovement,
                  allowActions: enabled,
                  pulseConfirm: pulseConfirm,
                  movementStepDistance: movementStepDistance,
                ),
                final inspection? => TileInspectionView(
                  key: ValueKey(
                    inspection.actorId ??
                        (
                          inspection.position,
                          inspection.object,
                          inspection.tile,
                        ),
                  ),
                  inspection: inspection,
                  onUnselect: enabled && controller.isBottomMenuEnabled
                      ? controller.unselect
                      : null,
                  headerDetails: switch (inspection) {
                    _ when controller.isSelected => CharacterStatsView(
                      level: controller.dungeon.adventurer.level,
                      health: controller.dungeon.adventurer.health,
                      maximumHealth:
                          controller.dungeon.adventurer.maximumHealth,
                    ),
                    TileInspection(enemy: final enemy?) => CharacterStatsView(
                      level: enemy.level,
                      health: enemy.health,
                      maximumHealth: enemy.maximumHealth,
                    ),
                    _ => null,
                  },
                  body: switch (controller.dungeon.actorById(
                    inspection.actorId ?? '',
                  )) {
                    final actor? => ActorStatsView(
                      actor: actor,
                      showMovement:
                          !inspection.isAdventurer ||
                          controller.isDefeated ||
                          controller.isInCombat,
                      helpEnabled:
                          (enabled || allowStatHelp) &&
                          controller.isBottomMenuEnabled,
                    ),
                    _ => null,
                  },
                  footer:
                      controller.isSelected &&
                          !controller.isDefeated &&
                          !controller.isInCombat
                      ? _MovementEntry(
                          controller: controller,
                          enabled: allowMovement,
                        )
                      : null,
                ),
                null => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
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
            if (controller.isInCombat && !controller.isControlPadOpen)
              Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const ValueKey('return-to-actions'),
                    onPressed:
                        (enabled || allowMovement) && controller.canOpenMove
                        ? controller.beginMove
                        : null,
                    child: const Text(DungeonStrings.actions),
                  ),
                ),
              ),
            if (controller.isDefeated) const Text(DungeonStrings.defeated),
            if (controller.isDefeated && onReturnToMainMenu != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: OutlinedButton(
                  key: const ValueKey('defeat-main-menu'),
                  onPressed: onReturnToMainMenu,
                  child: const Text(DungeonStrings.mainMenu),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _MovementEntry extends StatelessWidget {
  final DungeonController controller;
  final bool enabled;

  const _MovementEntry({required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Text(DungeonStrings.movement)),
      MovementValue(
        value:
            '${controller.dungeon.adventurer.movementSpeed}/${controller.dungeon.adventurer.movementSpeed}',
      ),
      const SizedBox(width: 8),
      Expanded(
        child: OutlinedButton(
          key: const ValueKey('open-move-pad'),
          onPressed: enabled && controller.canOpenMove
              ? controller.beginMove
              : null,
          child: const Text(DungeonStrings.move),
        ),
      ),
    ],
  );
}
