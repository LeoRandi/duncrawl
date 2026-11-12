import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../app/dungeon_theme.dart';
import '../domain/dungeon.dart';
import 'cardinal_drag.dart';
import 'dungeon_controller.dart';
import 'dungeon_strings.dart';

class ActionPad extends StatefulWidget {
  final DungeonController controller;
  final double movementStepDistance;
  final bool enabled;
  final String hint;
  final String summary;

  const ActionPad({
    super.key,
    required this.controller,
    required this.movementStepDistance,
    required this.enabled,
    required this.hint,
    required this.summary,
  });

  @override
  State<ActionPad> createState() => _ActionPadState();
}

class _ActionPadState extends State<ActionPad> {
  final _drag = CardinalDrag();
  ControlMode? _gestureMode;
  Offset _aimOffset = Offset.zero;
  DungeonDirection? _previousAim;
  int? _pointer;

  @override
  void didUpdateWidget(ActionPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled || _gestureMode != widget.controller.controlMode) {
      _gestureMode = null;
      _drag.reset();
    }
  }

  void _start() {
    if (!widget.enabled) {
      return;
    }
    _gestureMode = widget.controller.controlMode;
    _drag.reset();
    _aimOffset = Offset.zero;
    _previousAim = widget.controller.aimDirection;
    if (_gestureMode == ControlMode.move) {
      widget.controller.beginPadDrag();
    }
  }

  void _update(DragUpdateDetails details) {
    if (!widget.enabled || _gestureMode != widget.controller.controlMode) {
      return;
    }
    if (_gestureMode == ControlMode.strike) {
      _aimOffset += details.delta;
      widget.controller.aim(
        CardinalDrag.directionFor(dx: _aimOffset.dx, dy: _aimOffset.dy),
      );
      return;
    }
    final movement = _drag.add(
      dx: details.delta.dx,
      dy: details.delta.dy,
      stepDistance: widget.movementStepDistance,
    );
    if (movement != null) {
      widget.controller.preview(movement.direction, steps: movement.steps);
    }
  }

  void _finish() {
    if (_gestureMode == ControlMode.move) {
      widget.controller.endDrag();
    }
    _gestureMode = null;
    _drag.reset();
  }

  void _cancel() {
    if (_gestureMode == ControlMode.move) {
      widget.controller.cancelPadDrag();
    } else if (_gestureMode == ControlMode.strike) {
      widget.controller.aim(_previousAim);
    }
    _gestureMode = null;
    _drag.reset();
  }

  void _tapDirection(DungeonDirection? direction) {
    if (!widget.enabled || direction == null) {
      return;
    }
    if (widget.controller.isTargetingAttack) {
      widget.controller.aim(direction);
    } else {
      widget.controller.beginPadDrag();
      widget.controller.preview(direction);
      widget.controller.endDrag();
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
        color: DungeonColors.controlPadText,
        height: 1.2,
      );
      return Listener(
        onPointerDown: (event) => _pointer ??= event.pointer,
        onPointerUp: (event) {
          if (_pointer == event.pointer) {
            _pointer = null;
          }
        },
        onPointerCancel: (event) {
          if (_pointer == event.pointer) {
            _cancel();
            _pointer = null;
          }
        },
        child: Semantics(
          label: widget.controller.isTargetingAttack
              ? DungeonStrings.strikePad
              : DungeonStrings.movementPad,
          enabled: widget.enabled,
          customSemanticsActions: {
            if (widget.enabled)
              for (final direction in DungeonDirection.values)
                CustomSemanticsAction(
                  label: DungeonStrings.directionName(direction),
                ): () =>
                    _tapDirection(direction),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onPanStart: widget.enabled ? (_) => _start() : null,
            onPanUpdate: widget.enabled ? _update : null,
            onPanEnd: widget.enabled ? (_) => _finish() : null,
            onPanCancel: _cancel,
            onTapUp: widget.enabled
                ? (details) => _tapDirection(
                    CardinalDrag.directionFor(
                      dx: details.localPosition.dx - constraints.maxWidth / 2,
                      dy: details.localPosition.dy - constraints.maxHeight / 2,
                    ),
                  )
                : null,
            child: Container(
              key: const ValueKey('action-pad'),
              decoration: BoxDecoration(
                color: DungeonColors.background,
                border: Border.all(color: DungeonColors.controlPadText),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _PadDirectionPainter(
                        widget.controller.isTargetingAttack
                            ? widget.controller.aimDirection
                            : null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.hint,
                            key: const ValueKey('action-pad-hint'),
                            style: textStyle,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.summary,
                            key: const ValueKey('action-pad-summary'),
                            style: textStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _PadDirectionPainter extends CustomPainter {
  final DungeonDirection? direction;

  const _PadDirectionPainter(this.direction);

  @override
  void paint(Canvas canvas, Size size) {
    final centers = {
      DungeonDirection.north: Offset(size.width / 2, 9),
      DungeonDirection.east: Offset(size.width - 9, size.height / 2),
      DungeonDirection.south: Offset(size.width / 2, size.height - 9),
      DungeonDirection.west: Offset(9, size.height / 2),
    };
    for (final entry in centers.entries) {
      final forward = Offset(
        entry.key.columnOffset.toDouble(),
        entry.key.rowOffset.toDouble(),
      );
      final side = Offset(-forward.dy, forward.dx);
      final point = entry.value;
      final path = Path()
        ..moveTo(
          (point - forward * 3 + side * 3).dx,
          (point - forward * 3 + side * 3).dy,
        )
        ..lineTo((point + forward * 2).dx, (point + forward * 2).dy)
        ..lineTo(
          (point - forward * 3 - side * 3).dx,
          (point - forward * 3 - side * 3).dy,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = DungeonColors.controlPadText.withValues(
            alpha: direction == entry.key ? 1 : 0.5,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_PadDirectionPainter oldDelegate) =>
      direction != oldDelegate.direction;
}
