import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../domain/dungeon_floor.dart';
import 'dungeon_strings.dart';

Future<bool> showGroundObjectConfirmation(
  BuildContext context, {
  required GroundObjectInteractionKind interactionKind,
}) async {
  final route = DialogRoute<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: DungeonColors.background.withValues(alpha: 0.8),
    builder: (context) => PopScope(
      canPop: false,
      child: GroundObjectConfirmationDialog(interactionKind: interactionKind),
    ),
  );
  final answer = await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
  return answer ?? false;
}

class GroundObjectConfirmationDialog extends StatefulWidget {
  final GroundObjectInteractionKind interactionKind;

  const GroundObjectConfirmationDialog({
    super.key,
    required this.interactionKind,
  });

  @override
  State<GroundObjectConfirmationDialog> createState() =>
      _GroundObjectConfirmationDialogState();
}

class _GroundObjectConfirmationDialogState
    extends State<GroundObjectConfirmationDialog> {
  bool _hasAnswered = false;

  void _answer(bool accepted) {
    if (_hasAnswered) {
      return;
    }
    setState(() => _hasAnswered = true);
    Navigator.of(context).pop(accepted);
  }

  @override
  Widget build(BuildContext context) {
    final question = switch (widget.interactionKind) {
      GroundObjectInteractionKind.stairs => DungeonStrings.climbStairsQuestion,
      GroundObjectInteractionKind.pickup => DungeonStrings.pickUpItemQuestion,
      GroundObjectInteractionKind.generic =>
        DungeonStrings.activateObjectQuestion,
    };
    return AlertDialog(
      title: const Text(DungeonStrings.confirm),
      content: Text(question),
      actions: [
        TextButton(
          key: const ValueKey('decline-ground-interaction'),
          onPressed: _hasAnswered ? null : () => _answer(false),
          child: const Text(DungeonStrings.no),
        ),
        TextButton(
          key: const ValueKey('accept-ground-interaction'),
          onPressed: _hasAnswered ? null : () => _answer(true),
          child: const Text(DungeonStrings.yes),
        ),
      ],
    );
  }
}
