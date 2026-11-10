import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import 'tutorial_sequence.dart';

/// Resuelve anclas de cualquier pantalla; el recorte también limita los toques.
class TutorialSpotlight extends StatefulWidget {
  final TutorialSpotlightSpec specification;
  final Map<Object, GlobalKey> anchors;
  final ValueChanged<Object> onAction;

  const TutorialSpotlight({
    super.key,
    required this.specification,
    required this.anchors,
    required this.onAction,
  });

  @override
  State<TutorialSpotlight> createState() => _TutorialSpotlightState();
}

class _TutorialSpotlightState extends State<TutorialSpotlight>
    with WidgetsBindingObserver {
  late Map<Object, Rect> _bounds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _measureAnchors();
  }

  void _measureAnchors() {
    _bounds = {
      for (final entry in widget.anchors.entries)
        entry.key: _boundsOf(entry.value),
    };
  }

  Rect _boundsOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) {
      throw StateError('The tutorial target must be mounted and laid out.');
    }

    return box.localToGlobal(Offset.zero) & box.size;
  }

  Rect _target(Object id) {
    final bounds = _bounds[id];
    if (bounds == null) {
      throw StateError('Missing tutorial anchor: $id');
    }

    return bounds;
  }

  @override
  void didUpdateWidget(TutorialSpotlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    _measureAnchors();
  }

  @override
  void didChangeMetrics() => _refreshAfterLayout();

  @override
  void didChangeTextScaleFactor() => _refreshAfterLayout();

  void _refreshAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(_measureAnchors);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final specification = widget.specification;
    final circles = <Rect>[];
    final rectangles = <Rect>[];
    for (final highlight in specification.highlights) {
      final target = _target(highlight.target);
      final padding =
          highlight.padding + target.shortestSide * highlight.relativePadding;
      switch (highlight.shape) {
        case TutorialHighlightShape.circle:
          circles.add(
            Rect.fromCircle(
              center: target.center,
              radius: math.max(target.width, target.height) / 2 + padding,
            ),
          );
        case TutorialHighlightShape.rectangle:
          rectangles.add(target.inflate(padding));
      }
    }
    final placement = specification.placement;
    final secondTarget = placement.secondTarget;
    final dismissEvent = specification.dismissEvent;
    return Stack(
      children: [
        Positioned.fill(
          child: ClipPath(
            key: const ValueKey('tutorial-shade'),
            clipper: SpotlightClipper(circles: circles, rectangles: rectangles),
            child: AbsorbPointer(
              child: ColoredBox(
                color: DungeonColors.background.withValues(
                  alpha: specification.shadeOpacity,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomSingleChildLayout(
            delegate: _HintPlacement(
              first: _target(placement.firstTarget),
              second: secondTarget == null ? null : _target(secondTarget),
              safePadding: MediaQuery.paddingOf(context),
            ),
            child: IgnorePointer(
              ignoring: dismissEvent == null,
              child: TutorialHint(
                text: specification.text,
                actionLabel: specification.dismissLabel,
                onAction: dismissEvent == null
                    ? null
                    : () => widget.onAction(dismissEvent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SpotlightClipper extends CustomClipper<Path> {
  final List<Rect> circles;
  final List<Rect> rectangles;

  const SpotlightClipper({required this.circles, required this.rectangles});

  @override
  Path getClip(Size size) {
    final screen = Path()..addRect(Offset.zero & size);
    final openings = Path();
    for (final circle in circles) {
      openings.addOval(circle);
    }
    for (final rectangle in rectangles) {
      openings.addRect(rectangle);
    }
    return Path.combine(PathOperation.difference, screen, openings);
  }

  @override
  bool shouldReclip(SpotlightClipper oldClipper) => true;
}

class TutorialHint extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const TutorialHint({
    super.key,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('tutorial-hint'),
        padding: const EdgeInsets.all(DungeonTheme.pagePadding),
        decoration: BoxDecoration(
          color: DungeonColors.panel,
          border: Border.all(
            color: DungeonColors.primary,
            width: DungeonTheme.selectedBorderWidth,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            if (onAction != null && label != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const ValueKey('close-tutorial'),
                  onPressed: onAction,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.close),
                  label: Text(label),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HintPlacement extends SingleChildLayoutDelegate {
  final Rect first;
  final Rect? second;
  final EdgeInsets safePadding;

  _HintPlacement({
    required this.first,
    required this.second,
    required this.safePadding,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = second == null
        ? first.width
        : math.min(320.0, constraints.maxWidth - DungeonTheme.pagePadding * 2);
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: second == null ? first.height : constraints.maxHeight / 3,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final target = second;
    if (target == null) {
      return Offset(first.left, first.bottom - childSize.height);
    }

    final left = (target.center.dx - childSize.width / 2).clamp(
      DungeonTheme.pagePadding,
      size.width - childSize.width - DungeonTheme.pagePadding,
    );
    final top = ((first.bottom + target.top) / 2 - childSize.height / 2).clamp(
      safePadding.top + DungeonTheme.spacing,
      size.height -
          safePadding.bottom -
          childSize.height -
          DungeonTheme.spacing,
    );
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_HintPlacement oldDelegate) => true;
}
