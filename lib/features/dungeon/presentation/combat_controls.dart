import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../domain/basic_attack.dart';
import 'dungeon_controller.dart';
import 'dungeon_strings.dart';

class CombatControls extends StatelessWidget {
  final DungeonController controller;

  const CombatControls({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final encounter = controller.encounter;
    if (encounter == null) {
      return const SizedBox.shrink();
    }
    final targeting = controller.isTargetingAttack;
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(height: 1.2);
    final canConfirm = controller.canConfirm;
    final canMove =
        controller.isPlayerTurn &&
        encounter.remainingMovement > 0 &&
        controller.isBottomMenuEnabled &&
        !controller.isMoving;
    final (firstKey, firstLabel, firstAction) = switch ((
      targeting,
      canConfirm,
    )) {
      (true, _) => (
        'cancel-attack',
        DungeonStrings.cancel,
        controller.cancelAttack,
      ),
      (false, true) => (
        'confirm-movement',
        DungeonStrings.confirm,
        controller.confirm,
      ),
      (false, false) => (
        'combat-move',
        DungeonStrings.move,
        canMove ? controller.selectCharacter : null,
      ),
    };
    final secondAction = switch ((
      targeting,
      controller.canStrike,
      controller.canAttack,
    )) {
      (true, true, _) => controller.strike,
      (false, _, true) => controller.beginAttack,
      _ => null,
    };
    final remainingMovement = controller.isSelected
        ? controller.plan.remainingMovement
        : encounter.remainingMovement;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              targeting
                  ? DungeonStrings.chooseAttackTarget
                  : DungeonStrings.turnAllowance(
                      movement: remainingMovement,
                      total: controller.dungeon.adventurer.combatMovementSpeed,
                      actionAvailable: encounter.actionAvailable,
                    ),
              key: const ValueKey('combat-allowance'),
              style: textStyle,
            ),
          ),
          if (targeting)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                DungeonStrings.attackFormula(
                  baseDamage: BasicAttack.baseDamage,
                  strength: controller.dungeon.adventurer.strength,
                  damage: BasicAttack.damageFor(controller.dungeon.adventurer),
                ),
                style: textStyle,
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _BattleButton(
                  key: ValueKey(firstKey),
                  label: firstLabel,
                  onPressed: firstAction,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _BattleButton(
                  key: ValueKey(targeting ? 'confirm-attack' : 'basic-attack'),
                  label: targeting
                      ? DungeonStrings.strike
                      : DungeonStrings.attack,
                  isPrimary: true,
                  onPressed: secondAction,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _BattleButton(
                  key: const ValueKey('end-turn'),
                  label: DungeonStrings.endTurn,
                  onPressed: controller.canEndTurn ? controller.endTurn : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BattleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _BattleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 4),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return DungeonColors.textDisabled;
        }
        return isPrimary ? DungeonColors.background : DungeonColors.primary;
      }),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => isPrimary && !states.contains(WidgetState.disabled)
            ? DungeonColors.primary
            : DungeonColors.background,
      ),
    );
    final child = FittedBox(fit: BoxFit.scaleDown, child: Text(label));
    return Tooltip(
      message: label,
      child: isPrimary
          ? FilledButton(onPressed: onPressed, style: style, child: child)
          : OutlinedButton(onPressed: onPressed, style: style, child: child),
    );
  }
}
