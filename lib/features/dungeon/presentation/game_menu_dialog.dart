import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import 'dungeon_strings.dart';

enum GameMenuAction { continueGame, bestiary, settings, mainMenu }

class GameMenuDialog extends StatelessWidget {
  const GameMenuDialog({super.key});

  @override
  Widget build(BuildContext context) => Dialog(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(DungeonTheme.pagePadding),
      child: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final action in GameMenuAction.values) ...[
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(action),
                child: Text(switch (action) {
                  GameMenuAction.continueGame => DungeonStrings.continueGame,
                  GameMenuAction.bestiary => DungeonStrings.bestiary,
                  GameMenuAction.settings => DungeonStrings.settings,
                  GameMenuAction.mainMenu => DungeonStrings.mainMenu,
                }),
              ),
              if (action != GameMenuAction.values.last)
                const SizedBox(height: DungeonTheme.spacing),
            ],
          ],
        ),
      ),
    ),
  );
}
