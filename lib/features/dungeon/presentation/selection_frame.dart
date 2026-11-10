import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';

/// Mantiene fijo el contenido y anima únicamente el marco de selección.
class SelectionFrame extends StatefulWidget {
  final bool selected;
  final Widget child;

  const SelectionFrame({
    super.key,
    required this.selected,
    required this.child,
  });

  @override
  State<SelectionFrame> createState() => _SelectionFrameState();
}

class _SelectionFrameState extends State<SelectionFrame>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimation();
  }

  @override
  void didUpdateWidget(SelectionFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
  }

  void _updateAnimation() {
    if (widget.selected && !MediaQuery.disableAnimationsOf(context)) {
      if (!_animation.isAnimating) {
        _animation.repeat(reverse: true);
      }
      return;
    }
    _animation.stop();
    _animation.value = 0;
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    fit: StackFit.passthrough,
    children: [
      widget.child,
      if (widget.selected)
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final expansion = _animation.value * 1.5;
            return Positioned(
              left: -expansion,
              right: -expansion,
              top: -expansion,
              bottom: -expansion,
              child: child!,
            );
          },
          child: IgnorePointer(
            child: DecoratedBox(
              key: const ValueKey('selection-border'),
              decoration: BoxDecoration(
                border: Border.all(
                  color: DungeonColors.primary,
                  width: DungeonTheme.selectedBorderWidth,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
