import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../../dungeon/presentation/dungeon_strings.dart';

class MovementSettingsDialog extends StatefulWidget {
  final double dragDistanceMultiplier;

  const MovementSettingsDialog({
    super.key,
    required this.dragDistanceMultiplier,
  });

  @override
  State<MovementSettingsDialog> createState() => _MovementSettingsDialogState();
}

class _MovementSettingsDialogState extends State<MovementSettingsDialog> {
  static const _minimum = 1.0;
  static const _maximum = 5.0;

  late double _sensitivity =
      _minimum + _maximum - widget.dragDistanceMultiplier;

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: DungeonColors.panel,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DungeonTheme.cornerRadius),
      side: const BorderSide(
        color: DungeonColors.primary,
        width: DungeonTheme.selectedBorderWidth,
      ),
    ),
    title: const Text(DungeonStrings.settings),
    content: SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(DungeonStrings.movementSensitivity),
          const SizedBox(height: DungeonTheme.spacing),
          Slider(
            semanticFormatterCallback: (value) => switch (value) {
              _minimum => DungeonStrings.slower,
              _maximum => DungeonStrings.faster,
              _ => value.round().toString(),
            },
            min: _minimum,
            max: _maximum,
            divisions: 4,
            value: _sensitivity,
            onChanged: (value) => setState(() => _sensitivity = value),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DungeonStrings.slower),
              Text(DungeonStrings.faster),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () =>
            Navigator.of(context).pop(_minimum + _maximum - _sensitivity),
        child: const Text(DungeonStrings.done),
      ),
    ],
  );
}
