import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../domain/adventurer.dart';
import '../domain/dungeon.dart';
import '../domain/dungeon_floor.dart';
import '../floors/floor_0.dart';
import '../../main_menu/presentation/movement_settings_dialog.dart';
import 'cardinal_drag.dart';
import 'dungeon_board.dart';
import 'dungeon_controller.dart';
import 'dungeon_strings.dart';
import 'movement_menu.dart';
import 'game_menu_dialog.dart';
import 'selection_frame.dart';

class DungeonPage extends StatefulWidget {
  static const defaultDragDistanceMultiplier = 3.0;

  final double dragDistanceMultiplier;

  const DungeonPage({
    super.key,
    this.dragDistanceMultiplier = defaultDragDistanceMultiplier,
  }) : assert(dragDistanceMultiplier > 0);

  @override
  State<DungeonPage> createState() => _DungeonPageState();
}

class _DungeonPageState extends State<DungeonPage> {
  final _drag = CardinalDrag();
  final _controller = DungeonController(Dungeon.start(floor0.create()));
  late double _dragDistanceMultiplier = widget.dragDistanceMultiplier;

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
        builder: (context) => const GameMenuDialog(),
      );
      if (!mounted) {
        return;
      }
      switch (action) {
        case GameMenuAction.settings:
          final multiplier = await showDialog<double>(
            context: context,
            builder: (context) => MovementSettingsDialog(
              dragDistanceMultiplier: _dragDistanceMultiplier,
            ),
          );
          if (!mounted) {
            return;
          }
          if (multiplier != null) {
            setState(() => _dragDistanceMultiplier = multiplier);
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
          _controller.unselect();
          Navigator.of(context).pop();
          return;
        case GameMenuAction.continueGame || null:
          _controller.resume();
          return;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                          // Conserva espacio para el panel incluso en pantallas bajas.
                          final boardSize = math.min(
                            constraints.maxWidth,
                            math.min(
                              constraints.maxHeight * 0.64,
                              math.max(
                                0.0,
                                constraints.maxHeight -
                                    80 -
                                    DungeonTheme.spacing * 2,
                              ),
                            ),
                          );
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
                                      _dragDistanceMultiplier,
                                );
                                if (movement == null) {
                                  return;
                                }

                                _controller.preview(
                                  movement.direction,
                                  steps: movement.steps,
                                );
                              },
                              child: Column(
                                children: [
                                  SizedBox.square(
                                    dimension: boardSize,
                                    child: DungeonBoard(
                                      key: const ValueKey('dungeon-grid'),
                                      floor: _controller.dungeon.floor,
                                      player: _controller.dungeon.player,
                                      movementPath: _controller.remainingPath,
                                      isSelected: _controller.isSelected,
                                      onSelectPlayer:
                                          _controller.selectCharacter,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: DungeonTheme.spacing * 2,
                                  ),
                                  Expanded(
                                    child: MovementMenu(
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectionFrame(
                  selected: isSelected,
                  child: Container(
                    key: const ValueKey('player-portrait'),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: DungeonColors.surface,
                      border: Border.all(
                        color: DungeonColors.primary,
                        width: DungeonTheme.selectedBorderWidth,
                      ),
                      borderRadius: BorderRadius.circular(
                        DungeonTheme.cornerRadius,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: DungeonColors.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: DungeonTheme.spacing),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DungeonStrings.level(adventurer.level),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      DungeonStrings.health(
                        current: adventurer.health,
                        maximum: adventurer.maximumHealth,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: DungeonTheme.spacing),
      const Divider(height: 1),
    ],
  );
}
