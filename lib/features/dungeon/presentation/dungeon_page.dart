import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../../../widgets/interaction_gate.dart';
import '../../../widgets/iris_transition.dart';
import '../../dialogue/presentation/show_dialogue.dart';
import '../../dialogue/presentation/dialogue_sequence.dart';
import '../../tutorial/presentation/tutorial_sequence.dart';
import '../../shards/domain/shard_progress.dart';
import '../../shards/presentation/shard_scope.dart';
import '../../shards/presentation/shard_reveal.dart';
import '../domain/dungeon.dart';
import '../domain/dungeon_floor.dart';
import '../domain/dungeon_enemy.dart';
import '../domain/grid_position.dart';
import '../floors/floor_0.dart';
import '../floors/dungeon_floors.dart';
import '../../settings/domain/game_settings.dart';
import '../../settings/presentation/game_settings_dialog.dart';
import 'cardinal_drag.dart';
import 'dungeon_board.dart';
import 'dungeon_controller.dart';
import 'dungeon_strings.dart';
import 'dungeon_tutorial_lesson.dart';
import 'floor_tutorials.dart';
import '../../tutorial/presentation/tutorial_controller.dart';
import 'movement_menu.dart';
import 'selection_stack_tab.dart';
import 'opening_tutorial.dart';
import 'game_menu_dialog.dart';
import 'ground_object_confirmation_dialog.dart';
import 'selection_frame.dart';
import 'adventurer_information.dart';
import '../../tutorial/presentation/tutorial_spotlight.dart';

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
  late final _controller = DungeonController(
    Dungeon.start(floor0.create()),
    requiresConfirmation: _requiresInteractionConfirmation,
    movementInterval: () => widget.settings.value.movementSpeed.stepInterval,
  );
  late final _tutorial = TutorialController(
    OpeningTutorial.guide,
    isEnabled: !widget.settings.value.skipTutorials,
  );
  DungeonTutorialLesson? _activeLesson = dungeonTutorials[0];
  final _visitedTutorialFloors = <int>{0};
  late final _playerAnchorKey =
      widget.playerAnchorKey ??
      GlobalKey(debugLabel: 'player-transition-anchor');
  bool _isLeaving = false;
  bool _isChangingFloor = false;
  bool _isConfirmingInteraction = false;
  final _movementMenuKey = GlobalKey(debugLabel: 'dialogue-menu-anchor');
  final _portraitAnchorKey = GlobalKey(debugLabel: 'tutorial-portrait');
  final _gridAnchorKey = GlobalKey(debugLabel: 'tutorial-grid');
  final _stairsAnchorKey = GlobalKey(debugLabel: 'tutorial-stairs');
  final _batAnchorKey = GlobalKey(debugLabel: 'tutorial-bat');
  DungeonEnemy? get _tutorialBat => _controller.dungeon.floor.enemies
      .where((enemy) => enemy.type == EnemyType.bat)
      .firstOrNull;

  Map<Object, GlobalKey> get _tutorialAnchors => {
    DungeonTutorialTarget.character: _playerAnchorKey,
    DungeonTutorialTarget.portrait: _portraitAnchorKey,
    DungeonTutorialTarget.grid: _gridAnchorKey,
    DungeonTutorialTarget.stairs: _stairsAnchorKey,
    DungeonTutorialTarget.menu: _movementMenuKey,
    if (_tutorialBat != null) DungeonTutorialTarget.bat: _batAnchorKey,
  };
  Timer? _tutorialTimer;
  bool _wasMoving = false;
  TutorialStep? _effectStep;

  bool _requiresInteractionConfirmation(
    InteractiveDungeonGroundObject object,
  ) => switch (object.interactionKind) {
    GroundObjectInteractionKind.generic => false,
    GroundObjectInteractionKind.stairs =>
      !widget.settings.value.autoClimbStairs,
    GroundObjectInteractionKind.pickup =>
      !widget.settings.value.autoPickUpItems,
  };

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onDungeonChanged);
    _tutorial.addListener(_onTutorialChanged);
    widget.settings.addListener(_onSettingsChanged);
    _controller.pause();
    unawaited(_scheduleTutorial());
  }

  Future<void> _scheduleTutorial() async {
    await (widget.entryTransition ?? WidgetsBinding.instance.endOfFrame);
    if (!mounted || _isLeaving) {
      return;
    }
    _scheduleActiveLesson();
  }

  void _prepareTutorial(int floorNumber) {
    _tutorialTimer?.cancel();
    final lesson = dungeonTutorials[floorNumber];
    if (widget.settings.value.skipTutorials) {
      _grantSkippedRewards(lesson);
    }
    if (lesson == null ||
        widget.settings.value.skipTutorials ||
        !_visitedTutorialFloors.add(floorNumber)) {
      _activeLesson = null;
      _tutorial.skip();
      return;
    }
    _activeLesson = lesson;
    _tutorial.start(lesson.guide);
  }

  void _scheduleActiveLesson() {
    final lesson = _activeLesson;
    if (lesson == null ||
        _tutorial.isComplete ||
        widget.settings.value.skipTutorials) {
      _updateInputState();
      return;
    }
    _tutorialTimer?.cancel();
    _tutorialTimer = Timer(lesson.delay, () {
      unawaited(_showTutorial(lesson));
    });
  }

  void _onSettingsChanged() {
    if (widget.settings.value.skipTutorials) {
      _grantSkippedRewards(dungeonTutorials[_controller.dungeon.floor.number]);
      _tutorialTimer?.cancel();
      _activeLesson = null;
      _tutorial.skip();
    }
  }

  void _grantSkippedRewards(DungeonTutorialLesson? lesson) {
    if (lesson == null) {
      return;
    }
    final shards = ShardScope.controllerOf(context);
    for (final reward in lesson.shardRewards) {
      shards?.unlock(reward);
    }
  }

  Future<void> _showTutorial(DungeonTutorialLesson lesson) async {
    if (!mounted ||
        _isLeaving ||
        !identical(_activeLesson, lesson) ||
        widget.settings.value.skipTutorials ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    await showDialogue(
      context,
      sequence: lesson.dialogue,
      anchorKey: _movementMenuKey,
      textSpeed: widget.settings.value.textSpeed,
    );
    if (mounted && !_isLeaving && identical(_activeLesson, lesson)) {
      _tutorial.signal(DungeonTutorialEvent.dialogueFinished);
    }
  }

  void _onTutorialChanged() {
    _updateInputState();
    setState(() {});
    final step = _tutorial.currentStep;
    if (step != null && step.effect != null && !identical(step, _effectStep)) {
      _effectStep = step;
      unawaited(_runTutorialEffect(step));
    }
  }

  Future<void> _runTutorialEffect(TutorialStep step) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || _isLeaving || !identical(_tutorial.currentStep, step)) {
      return;
    }
    final effect = step.effect;
    if (effect is DialogueSequence) {
      await showDialogue(
        context,
        sequence: effect,
        anchorKey: _movementMenuKey,
        textSpeed: widget.settings.value.textSpeed,
      );
    } else if (effect is ColorShard) {
      await showShardReveal(context, effect);
      if (mounted && identical(_tutorial.currentStep, step)) {
        ShardScope.controllerOf(context)?.unlock(effect);
      }
    }
    if (mounted && !_isLeaving && identical(_tutorial.currentStep, step)) {
      _tutorial.signal(
        effect is DialogueSequence
            ? DungeonTutorialEvent.dialogueFinished
            : DungeonTutorialEvent.effectFinished,
      );
    }
  }

  void _updateInputState() {
    if (_tutorial.allowsInput &&
        !_isChangingFloor &&
        !_isConfirmingInteraction &&
        !_isLeaving) {
      _controller.resume();
    } else {
      _controller.pause();
    }
  }

  void _onDungeonChanged() {
    final finishedMoving = _wasMoving && !_controller.isMoving;
    _wasMoving = _controller.isMoving;
    if (_controller.plan.path.isNotEmpty) {
      _tutorial.signal(DungeonTutorialEvent.movementPreviewed);
    }
    if (finishedMoving) {
      _tutorial.signal(DungeonTutorialEvent.movementFinished);
    }
    if (_tutorial.isComplete && !_controller.isMoving) {
      if (_controller.pendingInteraction != null) {
        unawaited(_confirmInteraction());
      } else if (_controller.pendingFloorChange != null) {
        unawaited(_changeFloor());
      }
    }
  }

  Future<void> _confirmInteraction() async {
    final request = _controller.pendingInteraction;
    if (request == null ||
        _isConfirmingInteraction ||
        _isChangingFloor ||
        _isLeaving ||
        IrisTransition.isRunning(context)) {
      return;
    }

    setState(() => _isConfirmingInteraction = true);
    _controller.pause();
    try {
      final accepted = await showGroundObjectConfirmation(
        context,
        interactionKind: request.object.interactionKind,
      );
      if (mounted && !_isLeaving) {
        _controller.respondToInteraction(request: request, accept: accepted);
      }
    } finally {
      if (mounted && !_isLeaving) {
        setState(() => _isConfirmingInteraction = false);
        _updateInputState();
      }
    }
  }

  Future<void> _changeFloor() async {
    final destination =
        dungeonFloors[_controller.pendingFloorChange?.floorNumber];
    if (destination == null ||
        _isChangingFloor ||
        _isConfirmingInteraction ||
        _controller.pendingInteraction != null ||
        _isLeaving ||
        IrisTransition.isRunning(context)) {
      return;
    }

    final nextFloor = destination.create();
    setState(() => _isChangingFloor = true);
    _controller.pause();
    try {
      // La casilla de llegada debe haberse dibujado antes de centrar el cierre.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
      await IrisTransition.run(
        context,
        closingCenter: IrisTransition.centerOf(_playerAnchorKey),
        onCovered: () {
          if (_controller.completeFloorChange(nextFloor)) {
            _prepareTutorial(nextFloor.number);
          }
        },
        openingCenter: () => IrisTransition.centerOf(_playerAnchorKey),
      );
    } finally {
      if (mounted && !_isLeaving) {
        setState(() => _isChangingFloor = false);
        _scheduleActiveLesson();
        _updateInputState();
      }
    }
  }

  void _selectCharacter() {
    if (!_tutorial.allows(DungeonTutorialControl.selection)) {
      return;
    }
    _controller.selectCharacter();
    if (_controller.isSelected) {
      _tutorial.signal(DungeonTutorialEvent.characterSelected);
    }
  }

  void _selectTile(GridPosition position) {
    if (position == _controller.dungeon.player) {
      _selectCharacter();
      return;
    }
    if (_tutorial.allows(DungeonTutorialControl.enemySelection) &&
        _controller.dungeon.floor.inspectTile(position)?.enemy?.type ==
            EnemyType.bat) {
      _controller.selectTile(position);
      if (_controller.inspectedTile?.enemy?.type == EnemyType.bat) {
        _tutorial.signal(DungeonTutorialEvent.batSelected);
      }
      return;
    }
    if (!_tutorial.allows(DungeonTutorialControl.inspection)) {
      return;
    }
    _controller.selectTile(position);
    if (_controller.inspectedTile != null) {
      _tutorial.signal(DungeonTutorialEvent.tileInspected);
    }
  }

  Future<void> _returnToMainMenu(Offset closingCenter) async {
    if (!_tutorial.allows(DungeonTutorialControl.menu) ||
        _isChangingFloor ||
        _isConfirmingInteraction ||
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
    if (!_tutorial.allows(DungeonTutorialControl.menu) ||
        _controller.isPaused) {
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
    widget.settings.removeListener(_onSettingsChanged);
    _tutorialTimer?.cancel();
    _tutorial.removeListener(_onTutorialChanged);
    _tutorial.dispose();
    _controller.removeListener(_onDungeonChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) {
        _returnToMainMenu(IrisTransition.centerOf(_playerAnchorKey));
      }
    },
    child: Stack(
      fit: StackFit.expand,
      children: [
        InteractionGate(
          enabled:
              _tutorial.allowsInput &&
              !_isChangingFloor &&
              !_isConfirmingInteraction,
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
                              isSelected: _controller.isSelected,
                              onSelect:
                                  _tutorial.allows(
                                    DungeonTutorialControl.selection,
                                  )
                                  ? _selectCharacter
                                  : null,
                              onMenu:
                                  _tutorial.allows(DungeonTutorialControl.menu)
                                  ? _openMenu
                                  : null,
                              portraitAnchorKey: _portraitAnchorKey,
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
                                            SelectionStackTab.extent,
                                      ),
                                    ),
                                  );
                                  final boardSize = sideMenu
                                      ? math.min(
                                          constraints.maxHeight,
                                          constraints.maxWidth * 0.4,
                                        )
                                      : verticalBoardSize;
                                  final tileSize =
                                      boardSize / DungeonFloor.size;
                                  return Listener(
                                    onPointerCancel: (_) {
                                      _drag.reset();
                                      _controller.cancelDrag();
                                    },
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      dragStartBehavior: DragStartBehavior.down,
                                      onPanStart: (_) {
                                        if (!_tutorial.allows(
                                          DungeonTutorialControl.movement,
                                        )) {
                                          return;
                                        }
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
                                        if (!_tutorial.allows(
                                          DungeonTutorialControl.movement,
                                        )) {
                                          return;
                                        }
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
                                            key: _gridAnchorKey,
                                            dimension: boardSize,
                                            child: DungeonBoard(
                                              key: const ValueKey(
                                                'dungeon-grid',
                                              ),
                                              floor: _controller.dungeon.floor,
                                              player:
                                                  _controller.dungeon.player,
                                              movementPath:
                                                  _controller.remainingPath,
                                              isSelected:
                                                  _controller.isSelected,
                                              selectedTile:
                                                  _controller.selectedPosition,
                                              selectedInspection: _controller
                                                  .selectedInspection,
                                              onSelectTile: _selectTile,
                                              onSelectPlayer:
                                                  _tutorial.allows(
                                                    DungeonTutorialControl
                                                        .selection,
                                                  )
                                                  ? _selectCharacter
                                                  : null,
                                              playerAnchorKey: _playerAnchorKey,
                                              stairsAnchorKey: _stairsAnchorKey,
                                              enemyAnchorKeys: {
                                                if (_tutorialBat
                                                    case final bat?)
                                                  bat.position: _batAnchorKey,
                                              },
                                            ),
                                          ),
                                          SizedBox(
                                            width: sideMenu
                                                ? DungeonTheme.spacing * 2
                                                : 0,
                                          ),
                                          if (!sideMenu)
                                            SizedBox(
                                              height: SelectionStackTab.extent,
                                              child: SelectionStackTab(
                                                controller: _controller,
                                                enabled: _tutorial.allows(
                                                  DungeonTutorialControl
                                                      .inspection,
                                                ),
                                              ),
                                            ),
                                          Expanded(
                                            child: Column(
                                              children: [
                                                if (sideMenu)
                                                  SizedBox(
                                                    height: SelectionStackTab
                                                        .extent,
                                                    child: SelectionStackTab(
                                                      controller: _controller,
                                                      enabled: _tutorial.allows(
                                                        DungeonTutorialControl
                                                            .inspection,
                                                      ),
                                                    ),
                                                  ),
                                                Expanded(
                                                  child: MovementMenu(
                                                    key: _movementMenuKey,
                                                    controller: _controller,
                                                    enabled: _tutorial.allows(
                                                      DungeonTutorialControl
                                                          .confirm,
                                                    ),
                                                    allowStatHelp: _tutorial
                                                        .allows(
                                                          DungeonTutorialControl
                                                              .statHelp,
                                                        ),
                                                    pulseConfirm: _tutorial
                                                        .emphasizes(
                                                          DungeonTutorialControl
                                                              .confirm,
                                                        ),
                                                  ),
                                                ),
                                              ],
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
        if (_tutorial.currentStep?.spotlight case final spotlight?)
          Positioned.fill(
            child: TutorialSpotlight(
              key: const ValueKey('tutorial-spotlight'),
              specification: spotlight,
              anchors: _tutorialAnchors,
              onAction: _tutorial.signal,
            ),
          ),
      ],
    ),
  );
}

class _DungeonHeader extends StatelessWidget {
  final bool isSelected;
  final VoidCallback? onSelect;
  final VoidCallback? onMenu;
  final GlobalKey portraitAnchorKey;

  const _DungeonHeader({
    required this.isSelected,
    required this.onSelect,
    required this.onMenu,
    required this.portraitAnchorKey,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Semantics(
            button: true,
            selected: isSelected,
            label: DungeonStrings.selectAdventurer,
            child: GestureDetector(
              key: portraitAnchorKey,
              behavior: HitTestBehavior.opaque,
              onTap: onSelect,
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: SelectionFrame(
                    selected: isSelected,
                    child: const AdventurerPortrait(
                      key: ValueKey('player-portrait'),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          SizedBox.square(
            dimension: 48,
            child: IconButton(
              tooltip: DungeonStrings.menu,
              onPressed: onMenu,
              style: IconButton.styleFrom(
                foregroundColor: DungeonColors.textPrimary,
                side: const BorderSide(color: DungeonColors.textSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DungeonTheme.cornerRadius,
                  ),
                ),
              ),
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
        ],
      ),
      const SizedBox(height: DungeonTheme.spacing),
      const Divider(height: 1),
    ],
  );
}
