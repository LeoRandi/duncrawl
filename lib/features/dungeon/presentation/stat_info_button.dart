import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import 'dungeon_strings.dart';

/// Ayuda modal anclada al botón; el toque que la cierra no llega al juego.
class StatInfoButton extends StatelessWidget {
  final String statName;
  final String explanation;
  final bool enabled;

  const StatInfoButton({
    super.key,
    required this.statName,
    required this.explanation,
    this.enabled = true,
  });

  Future<void> _showInfo(BuildContext context) async {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return;
    }
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: DungeonStrings.dismissStatInfo,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (popupContext, animation, secondaryAnimation) =>
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(popupContext).pop(),
            child: CustomSingleChildLayout(
              delegate: _StatInfoPlacement(
                anchor: anchor,
                safePadding: MediaQuery.paddingOf(popupContext),
              ),
              child: Material(
                color: DungeonColors.panel,
                child: Container(
                  key: const ValueKey('stat-info-popup'),
                  padding: const EdgeInsets.all(DungeonTheme.spacing),
                  decoration: BoxDecoration(
                    border: Border.all(color: DungeonColors.primary),
                  ),
                  child: SingleChildScrollView(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        explanation,
                        style: Theme.of(popupContext).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: enabled ? () => unawaited(_showInfo(context)) : null,
    style: TextButton.styleFrom(
      minimumSize: const Size(24, 24),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 9),
      alignment: Alignment.topCenter,
    ),
    child: Text('(?)', semanticsLabel: DungeonStrings.statInfo(statName)),
  );
}

class _StatInfoPlacement extends SingleChildLayoutDelegate {
  final Rect anchor;
  final EdgeInsets safePadding;

  _StatInfoPlacement({required this.anchor, required this.safePadding});

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: math.min(
          280,
          constraints.maxWidth -
              safePadding.horizontal -
              DungeonTheme.pagePadding * 2,
        ),
        maxHeight: math.max(
          0,
          (constraints.maxHeight - safePadding.vertical) / 2,
        ),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final margin = DungeonTheme.spacing;
    final minTop = safePadding.top + margin;
    final maxTop = size.height - safePadding.bottom - childSize.height - margin;
    final above = anchor.top - childSize.height - margin;
    final top = above >= minTop ? above : anchor.bottom + margin;
    final left = (anchor.center.dx - childSize.width / 2).clamp(
      safePadding.left + margin,
      size.width - safePadding.right - childSize.width - margin,
    );
    return Offset(left, top.clamp(minTop, maxTop));
  }

  @override
  bool shouldRelayout(_StatInfoPlacement oldDelegate) =>
      anchor != oldDelegate.anchor || safePadding != oldDelegate.safePadding;
}
