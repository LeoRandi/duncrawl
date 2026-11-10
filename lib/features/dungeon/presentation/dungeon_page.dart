import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../../../widgets/interaction_gate.dart';
import '../../../widgets/iris_transition.dart';
import '../../dialogue/presentation/show_dialogue.dart';
import '../domain/adventurer.dart';
import '../domain/dungeon.dart';
import '../domain/dungeon_floor.dart';
import '../floors/floor_0.dart';
import '../../settings/domain/game_settings.dart';
import '../../settings/presentation/game_settings_dialog.dart';
import 'cardinal_drag.dart';
import 'dungeon_board.dart';
import 'dungeon_controller.dart';
import 'dungeon_strings.dart';
import 'movement_menu.dart';
import 'opening_tutorial.dart';
import 'game_menu_dialog.dart';
import 'selection_frame.dart';
import 'adventurer_information.dart';

class DungeonPage extends StatefulWidget {
  final ValueNotifier<GameSettings> settings;
  final GlobalKey? playerAnchorKey;

  /// Se completa cuando la transición de entrada descubre toda la escena.
  final Future<void>? entryTransition;

  const DungeonPage({
    super.key,
    required this.settings,
    this.playerAnchorKey,
    this.entryTransition,
  });

  @override
  State<DungeonPage> createState() => _DungeonPageState();
}

class _DungeonPageState extends State<DungeonPage> {
  final _drag = CardinalDrag();
  final _controller = DungeonController(Dungeon.start(floor0.create()));
  late final _playerAnchorKey =
      widget.playerAnchorKey ??
      GlobalKey(debugLabel: 'player-transition-anchor');
  bool _isLeaving = false;
  final _movementMenuKey = GlobalKey(debugLabel: 'dialogue-menu-anchor');
  Timer? _tutorialTimer;
  bool _isTutorialComplete = false;

  @override
  void initState() {
    super.initState();
    _controller.pause();
    unawaited(_scheduleTutorial());
  }

  Future<void> _scheduleTutorial() async {
    await (widget.entryTransition ?? WidgetsBinding.instance.endOfFrame);
    if (!mounted || _isLeaving) {
      return;
    }
    _tutorialTimer = Timer(OpeningTutorial.delay, () {
      unawaited(_showTutorial());
    });
  }

  Future<void> _showTutorial() async {
    if (_isLeaving || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    await showDialogue(
      context,
      sequence: OpeningTutorial.dialogue,
      anchorKey: _movementMenuKey,
      textSpeed: widget.settings.value.textSpeed,
    );
    if (mounted && !_isLeaving) {
      setState(() => _isTutorialComplete = true);
      _controller.resume();
    }
  }

  Future<void> _returnToMainMenu(Offset closingCenter) async {
    if (!_isTutorialComplete ||
        _isLeaving ||
        IrisTransition.isRunning(context)) {
      return;
    }
    final navigator = Navigator.of(context);
    _isLeaving = true;
    _tutorialTimer?.cancel();
    _controller.pause();
    await IrisTransition.run(
      context,
      closingCenter: closingCenter,
      onCovered: () => navigator.popUntil((route) => route.isFirst),
    );
  }

  Future<void> _openMenu() async {
    if (_controller.isPaused) {
      return;
    }
    _controller.pause();
    while (true) {
      if (!mounted) {
        return;
      }
      final action = await showDialog<GameMenuAction>(
        context: context,
        barrierDismissible: false,
        barrierColor: DungeonColors.background.withValues(alpha: 0.8),
        animationStyle: const AnimationStyle(
          duration: Duration.zero,
          reverseDuration: Duration.zero,
        ),
        builder: (context) => GameMenuDialog(onMainMenu: _returnToMainMenu),
      );
      if (!mounted || _isLeaving) {
        return;
      }
      switch (action) {
        case GameMenuAction.settings:
          final settings = await showDialog<GameSettings>(
            context: context,
            builder: (context) =>
                GameSettingsDialog(settings: widget.settings.value),
          );
          if (!mounted) {
            return;
          }
          if (settings != null) {
            widget.settings.value = settings;
          }
        case GameMenuAction.bestiary:
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(DungeonStrings.bestiary),
              content: const Text(DungeonStrings.emptyBestiary),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(DungeonStrings.back),
                ),
              ],
            ),
          );
        case GameMenuAction.mainMenu:
          await _returnToMainMenu(IrisTransition.centerOf(_playerAnchorKey));
          return;
        case GameMenuAction.continueGame || null:
          _controller.resume();
          return;
      }
    }
  }

  @override
  void dispose() {
    _tutorialTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InteractionGate(
    enabled: _isTutorialComplete,
    child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _returnToMainMenu(IrisTransition.centerOf(_playerAnchorKey));
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(DungeonTheme.pagePadding),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, child) => TickerMode(
                    enabled: !_controller.isPaused,
                    child: Column(
                      children: [
                        _DungeonHeader(
                          floorNumber: _controller.dungeon.floor.number,
                          adventurer: _controller.dungeon.adventurer,
                          isSelected: _controller.isSelected,
                          onSelect: _controller.selectCharacter,
                          onMenu: _openMenu,
                        ),
                        const SizedBox(height: DungeonTheme.spacing * 2),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // En pantallas bajas y anchas, el panel va al lado para conservar ambos.
                              final sideMenu =
                                  constraints.maxWidth >= 480 &&
                                  constraints.maxHeight <
                                      MovementMenu.minimumHeight * 2;
                              final verticalBoardSize = math.min(
                                constraints.maxWidth,
                                math.min(
                                  constraints.maxHeight * 0.64,
                                  math.max(
                                    0.0,
                                    constraints.maxHeight -
                                        MovementMenu.minimumHeight -
                                        DungeonTheme.spacing * 2,
                                  ),
                                ),
                              );
                              final boardSize = sideMenu
                                  ? math.min(
                                      constraints.maxHeight,
                                      constraints.maxWidth * 0.4,
                                    )
                                  : verticalBoardSize;
                              final tileSize = boardSize / DungeonFloor.size;
                              return Listener(
                                onPointerCancel: (_) {
                                  _drag.reset();
                                  _controller.cancelDrag();
                                },
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  dragStartBehavior: DragStartBehavior.down,
                                  onPanStart: (_) {
                                    _drag.reset();
                                    _controller.beginDrag();
                                  },
                                  onPanEnd: (_) {
                                    _drag.reset();
                                    _controller.endDrag();
                                  },
                                  onPanCancel: () {
                                    _drag.reset();
                                    _controller.cancelDrag();
                                  },
                                  onPanUpdate: (details) {
                                    final movement = _drag.add(
                                      dx: details.delta.dx,
                                      dy: details.delta.dy,
                                      stepDistance:
                                          math.max(tileSize, 16) *
                                          widget
                                              .settings
                                              .value
                                              .dragDistanceMultiplier,
                                    );
                                    if (movement == null) {
                                      return;
                                    }

                                    _controller.preview(
                                      movement.direction,
                                      steps: movement.steps,
                                    );
                                  },
                                  child: Flex(
                                    direction: sideMenu
                                        ? Axis.horizontal
                                        : Axis.vertical,
                                    children: [
                                      SizedBox.square(
                                        dimension: boardSize,
                                        child: DungeonBoard(
                                          key: const ValueKey('dungeon-grid'),
                                          floor: _controller.dungeon.floor,
                                          player: _controller.dungeon.player,
                                          movementPath:
                                              _controller.remainingPath,
                                          isSelected: _controller.isSelected,
                                          onSelectPlayer:
                                              _controller.selectCharacter,
                                          playerAnchorKey: _playerAnchorKey,
                                        ),
                                      ),
                                      SizedBox(
                                        width: sideMenu
                                            ? DungeonTheme.spacing * 2
                                            : 0,
                                        height: sideMenu
                                            ? 0
                                            : DungeonTheme.spacing * 2,
                                      ),
                                      Expanded(
                                        child: MovementMenu(
                                          key: _movementMenuKey,
                                          controller: _controller,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _DungeonHeader extends StatelessWidget {
  final int floorNumber;
  final Adventurer adventurer;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onMenu;

  const _DungeonHeader({
    required this.floorNumber,
    required this.adventurer,
    required this.isSelected,
    required this.onSelect,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              DungeonStrings.floor(floorNumber),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(width: DungeonTheme.spacing),
          IconButton(
            tooltip: DungeonStrings.menu,
            onPressed: onMenu,
            style: IconButton.styleFrom(
              foregroundColor: DungeonColors.textPrimary,
              side: const BorderSide(color: DungeonColors.textSecondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DungeonTheme.cornerRadius),
              ),
            ),
            icon: const Icon(Icons.menu_rounded),
          ),
        ],
      ),
      const SizedBox(height: DungeonTheme.spacing),
      const Divider(height: 1),
      const SizedBox(height: DungeonTheme.spacing),
      Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          button: true,
          selected: isSelected,
          label: DungeonStrings.selectAdventurer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSelect,
            child: AdventurerInformation(
              adventurer: adventurer,
              portrait: SelectionFrame(
                selected: isSelected,
                child: const AdventurerPortrait(
                  key: ValueKey('player-portrait'),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: DungeonTheme.spacing),
      const Divider(height: 1),
    ],
  );
}
