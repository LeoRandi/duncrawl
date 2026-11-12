import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../domain/basic_attack.dart';
import 'action_pad.dart';
import 'dungeon_controller.dart';
import 'dungeon_strings.dart';
import 'selection_frame.dart';

class ActionControls extends StatelessWidget {
  final DungeonController controller;
  final bool allowMovement;
  final bool allowActions;
  final bool pulseConfirm;
  final double movementStepDistance;

  const ActionControls({
    super.key,
    required this.controller,
    this.allowMovement = true,
    this.allowActions = true,
    this.pulseConfirm = false,
    this.movementStepDistance = 32,
  });

  @override
  Widget build(BuildContext context) {
    final striking = controller.isTargetingAttack;
    final available = controller.isBottomMenuEnabled && !controller.isMoving;
    final encounter = controller.encounter;
    final movementExhausted =
        controller.isPlayerTurn && encounter?.remainingMovement == 0;
    final actionExhausted =
        controller.isPlayerTurn && encounter?.actionAvailable == false;
    final canConfirm =
        allowActions &&
        (striking ? controller.canStrike : controller.canConfirm);
    final direction = controller.aimDirection;
    final hint = switch (controller.controlMode) {
      _ when controller.isMoving => DungeonStrings.moving,
      ControlMode.strike when direction != null =>
        DungeonStrings.aimedDirection(direction),
      ControlMode.strike => DungeonStrings.dragAim,
      _ => DungeonStrings.dragMovement,
    };
    final damage = BasicAttack.damageFor(controller.dungeon.adventurer);
    final target = controller.dungeon.actorById(
      controller.attackTargetId ?? '',
    );
    final summary = switch (controller.controlMode) {
      ControlMode.strike when direction != null && target == null =>
        DungeonStrings.noAttackTarget,
      ControlMode.strike when target != null && damage >= target.health =>
        '${DungeonStrings.damageTaken(damage)} · ${DungeonStrings.lethal}',
      ControlMode.strike => DungeonStrings.attackFormula(
        baseDamage: BasicAttack.baseDamage,
        strength: controller.dungeon.adventurer.strength,
        damage: damage,
      ),
      _ when controller.isInCombat => DungeonStrings.turnAllowance(
        movement: controller.plan.remainingMovement,
        total: controller.dungeon.adventurer.combatMovementSpeed,
        actionAvailable: controller.encounter?.actionAvailable ?? false,
      ),
      _ =>
        '${DungeonStrings.movement}: ${controller.plan.remainingMovement}/${controller.plan.movementBudget}',
    };
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  key: const ValueKey('move-mode'),
                  label: DungeonStrings.move,
                  selected: !striking,
                  exhausted: movementExhausted,
                  onPressed:
                      allowMovement &&
                          controller.canOpenMove &&
                          !movementExhausted
                      ? controller.beginMove
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ActionButton(
                  key: const ValueKey('strike-mode'),
                  label: DungeonStrings.strike,
                  selected: striking,
                  exhausted: actionExhausted,
                  onPressed: allowActions && controller.canAttack
                      ? controller.beginAttack
                      : null,
                ),
              ),
              SizedBox(
                width: 40,
                height: 48,
                child: IconButton(
                  key: const ValueKey('inspect-action'),
                  tooltip: DungeonStrings.inspect,
                  icon: const Icon(
                    Icons.info_outline,
                    color: DungeonColors.primary,
                    size: 20,
                  ),
                  onPressed: available ? controller.closeControls : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ActionPad(
              controller: controller,
              movementStepDistance: movementStepDistance,
              enabled:
                  available &&
                  (striking
                      ? allowActions && controller.canAttack
                      : allowMovement && !movementExhausted),
              hint: hint,
              summary: summary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  key: const ValueKey('cancel-action'),
                  label: DungeonStrings.cancel,
                  onPressed:
                      (allowMovement || allowActions) &&
                          controller.canCancelAction
                      ? controller.cancelAction
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SelectionFrame(
                  key: const ValueKey('tutorial-confirm-pulse'),
                  selected: pulseConfirm && canConfirm,
                  child: _ActionButton(
                    key: const ValueKey('confirm-action'),
                    label: DungeonStrings.confirm,
                    primary: true,
                    onPressed: canConfirm ? controller.confirmAction : null,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SelectionFrame(
                  key: const ValueKey('end-turn-pulse'),
                  selected:
                      allowActions &&
                      controller.canEndTurn &&
                      encounter?.isExhausted == true,
                  child: _ActionButton(
                    key: const ValueKey('end-turn'),
                    label: DungeonStrings.endTurn,
                    onPressed: allowActions && controller.canEndTurn
                        ? controller.endTurn
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool selected;
  final bool exhausted;

  const _ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.selected = false,
    this.exhausted = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = exhausted
        ? DungeonColors.textDisabled
        : DungeonColors.textPrimary;
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 4),
      ),
      foregroundColor: WidgetStatePropertyAll(textColor),
      backgroundColor: const WidgetStatePropertyAll(DungeonColors.background),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.disabled)
              ? DungeonColors.textDisabled
              : DungeonColors.primary,
          width: selected || primary && !states.contains(WidgetState.disabled)
              ? 2
              : 1,
        ),
      ),
    );
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: textColor,
        ),
      ),
    );
    return primary
        ? FilledButton(onPressed: onPressed, style: style, child: child)
        : OutlinedButton(onPressed: onPressed, style: style, child: child);
  }
}
