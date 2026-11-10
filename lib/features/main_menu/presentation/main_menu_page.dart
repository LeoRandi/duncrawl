import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/dungeon_theme.dart';
import '../../../widgets/iris_transition.dart';
import '../../dungeon/presentation/dungeon_page.dart';
import '../../dungeon/presentation/dungeon_strings.dart';
import 'movement_settings_dialog.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  final _startButtonKey = GlobalKey(debugLabel: 'start-transition-anchor');
  double _dragDistanceMultiplier = DungeonPage.defaultDragDistanceMultiplier;
  bool _isStarting = false;

  Future<void> _startGame() async {
    if (_isStarting) {
      return;
    }
    final navigator = Navigator.of(context);
    final playerAnchorKey = GlobalKey(debugLabel: 'arrival-player-anchor');
    setState(() => _isStarting = true);
    try {
      await IrisTransition.run(
        context,
        closingCenter: IrisTransition.centerOf(_startButtonKey),
        onCovered: () {
          navigator.push(
            PageRouteBuilder<void>(
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              pageBuilder: (context, animation, secondaryAnimation) =>
                  DungeonPage(
                    dragDistanceMultiplier: _dragDistanceMultiplier,
                    playerAnchorKey: playerAnchorKey,
                  ),
            ),
          );
        },
        openingCenter: () => IrisTransition.centerOf(playerAnchorKey),
      );
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  Future<void> _openSettings() async {
    final multiplier = await showDialog<double>(
      context: context,
      builder: (context) => MovementSettingsDialog(
        dragDistanceMultiplier: _dragDistanceMultiplier,
      ),
    );
    if (!mounted || multiplier == null) {
      return;
    }

    setState(() => _dragDistanceMultiplier = multiplier);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isStarting,
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DungeonTheme.pagePadding),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(DungeonTheme.pagePadding * 1.5),
              decoration: BoxDecoration(
                color: DungeonColors.panel,
                border: Border.all(color: DungeonColors.primary),
                borderRadius: BorderRadius.circular(DungeonTheme.cornerRadius),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: DungeonTheme.spacing * 2),
                  Text(
                    DungeonStrings.appTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: DungeonTheme.spacing * 4),
                  FilledButton(
                    key: _startButtonKey,
                    style: FilledButton.styleFrom(
                      backgroundColor: DungeonColors.primary,
                      foregroundColor: DungeonColors.background,
                      minimumSize: const Size.fromHeight(52),
                      textStyle: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DungeonTheme.cornerRadius,
                        ),
                      ),
                    ),
                    onPressed: _startGame,
                    child: const Text(DungeonStrings.start),
                  ),
                  const SizedBox(height: DungeonTheme.spacing * 2),
                  OutlinedButton(
                    style: _secondaryButtonStyle,
                    onPressed: _openSettings,
                    child: const Text(DungeonStrings.settings),
                  ),
                  const SizedBox(height: DungeonTheme.spacing * 2),
                  OutlinedButton(
                    style: _secondaryButtonStyle,
                    onPressed: () => SystemNavigator.pop(),
                    child: const Text(DungeonStrings.close),
                  ),
                  const SizedBox(height: DungeonTheme.spacing * 2),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  static final _secondaryButtonStyle = OutlinedButton.styleFrom(
    backgroundColor: DungeonColors.surface,
    foregroundColor: DungeonColors.textPrimary,
    minimumSize: const Size.fromHeight(52),
    side: const BorderSide(color: DungeonColors.textSecondary),
    textStyle: const TextStyle(
      fontFamily: 'monospace',
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DungeonTheme.cornerRadius),
    ),
  );
}
