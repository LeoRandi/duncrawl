import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../../dungeon/presentation/dungeon_strings.dart';
import '../domain/game_settings.dart';
import '../domain/text_speed.dart';
import '../domain/movement_speed.dart';

class GameSettingsDialog extends StatefulWidget {
  final GameSettings settings;

  const GameSettingsDialog({super.key, required this.settings});

  @override
  State<GameSettingsDialog> createState() => _GameSettingsDialogState();
}

class _GameSettingsDialogState extends State<GameSettingsDialog> {
  late GameSettings _settings = widget.settings;

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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(DungeonStrings.movementSensitivity),
            const SizedBox(height: DungeonTheme.spacing),
            Slider(
              key: const ValueKey('movement-sensitivity-slider'),
              semanticFormatterCallback: (value) => switch (value) {
                GameSettings.minimumMovementSensitivity =>
                  DungeonStrings.slower,
                GameSettings.maximumMovementSensitivity =>
                  DungeonStrings.faster,
                _ => value.round().toString(),
              },
              min: GameSettings.minimumMovementSensitivity,
              max: GameSettings.maximumMovementSensitivity,
              divisions: 4,
              value: _settings.movementSensitivity,
              label: _settings.movementSensitivity.round().toString(),
              onChanged: (value) => setState(() {
                _settings = _settings.copyWith(movementSensitivity: value);
              }),
            ),
            const _SliderEndpoints(
              minimum: DungeonStrings.slower,
              maximum: DungeonStrings.faster,
            ),
            const SizedBox(height: DungeonTheme.spacing * 3),
            Text(DungeonStrings.textSpeedSetting(_settings.textSpeed)),
            const SizedBox(height: DungeonTheme.spacing),
            Slider(
              key: const ValueKey('text-speed-slider'),
              min: 0,
              max: TextSpeed.values.length - 1,
              divisions: TextSpeed.values.length - 1,
              value: _settings.textSpeed.index.toDouble(),
              label: DungeonStrings.textSpeedName(_settings.textSpeed),
              semanticFormatterCallback: (value) =>
                  DungeonStrings.textSpeedName(TextSpeed.values[value.round()]),
              onChanged: (value) => setState(() {
                _settings = _settings.copyWith(
                  textSpeed: TextSpeed.values[value.round()],
                );
              }),
            ),
            _SliderEndpoints(
              minimum: DungeonStrings.slowText,
              maximum: DungeonStrings.instantText,
              onMaximumTap: () => setState(() {
                _settings = _settings.copyWith(isTutorialSkipUnlocked: true);
              }),
            ),
            if (_settings.isTutorialSkipUnlocked)
              SwitchListTile(
                key: const ValueKey('skip-tutorials-switch'),
                contentPadding: EdgeInsets.zero,
                title: const Text(DungeonStrings.skipTutorials),
                value: _settings.skipTutorials,
                onChanged: (value) => setState(() {
                  _settings = _settings.copyWith(skipTutorials: value);
                }),
              ),
            const SizedBox(height: DungeonTheme.spacing * 3),
            Text(DungeonStrings.movementSpeedSetting(_settings.movementSpeed)),
            const SizedBox(height: DungeonTheme.spacing),
            Slider(
              key: const ValueKey('movement-speed-slider'),
              min: 0,
              max: MovementSpeed.values.length - 1,
              divisions: MovementSpeed.values.length - 1,
              value: _settings.movementSpeed.index.toDouble(),
              label: DungeonStrings.movementSpeedName(_settings.movementSpeed),
              semanticFormatterCallback: (value) =>
                  DungeonStrings.movementSpeedName(
                    MovementSpeed.values[value.round()],
                  ),
              onChanged: (value) => setState(() {
                _settings = _settings.copyWith(
                  movementSpeed: MovementSpeed.values[value.round()],
                );
              }),
            ),
            const _SliderEndpoints(
              minimum: DungeonStrings.slowText,
              maximum: DungeonStrings.ultraFast,
            ),
            const SizedBox(height: DungeonTheme.spacing * 3),
            SwitchListTile(
              key: const ValueKey('auto-climb-stairs-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text(DungeonStrings.autoClimbStairs),
              value: _settings.autoClimbStairs,
              onChanged: (value) => setState(() {
                _settings = _settings.copyWith(autoClimbStairs: value);
              }),
            ),
            SwitchListTile(
              key: const ValueKey('auto-pick-up-items-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text(DungeonStrings.autoPickUpItems),
              value: _settings.autoPickUpItems,
              onChanged: (value) => setState(() {
                _settings = _settings.copyWith(autoPickUpItems: value);
              }),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(_settings),
        child: const Text(DungeonStrings.done),
      ),
    ],
  );
}

class _SliderEndpoints extends StatelessWidget {
  final String minimum;
  final String maximum;
  final VoidCallback? onMaximumTap;

  const _SliderEndpoints({
    required this.minimum,
    required this.maximum,
    this.onMaximumTap,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(minimum)),
      const SizedBox(width: DungeonTheme.spacing),
      Expanded(
        child: onMaximumTap == null
            ? Text(maximum, textAlign: TextAlign.end)
            : TextButton(
                onPressed: onMaximumTap,
                style: TextButton.styleFrom(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.zero,
                ),
                child: Text(maximum),
              ),
      ),
    ],
  );
}
