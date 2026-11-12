import 'package:flutter/material.dart';

import '../domain/dungeon_floor.dart';
import '../domain/dungeon.dart';
import '../domain/grid_position.dart';

/// Traza solo el perímetro exterior; los bordes interiores nunca se dibujan.
class TileAreaOutline extends StatefulWidget {
  static const combatPulseDuration = Duration(seconds: 6);

  final Set<GridPosition> tiles;
  final Color color;
  final Duration pulseDuration;

  const TileAreaOutline({
    super.key,
    required this.tiles,
    required this.color,
    this.pulseDuration = const Duration(milliseconds: 700),
  });

  @override
  State<TileAreaOutline> createState() => _TileAreaOutlineState();
}

class _TileAreaOutlineState extends State<TileAreaOutline>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: widget.pulseDuration,
  )..repeat(reverse: true);

  @override
  void didUpdateWidget(TileAreaOutline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulseDuration != widget.pulseDuration) {
      _pulse.duration = widget.pulseDuration;
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: TileAreaOutlinePainter(
        tiles: widget.tiles,
        color: widget.color,
        pulse: _pulse,
      ),
    ),
  );
}

class TileAreaOutlinePainter extends CustomPainter {
  final Set<GridPosition> tiles;
  final Color color;
  final Animation<double> pulse;

  TileAreaOutlinePainter({
    required this.tiles,
    required this.color,
    required this.pulse,
  }) : super(repaint: pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final tileSize = size.width / DungeonFloor.size;
    final path = Path();
    for (final tile in tiles) {
      final rect = Rect.fromLTWH(
        tile.column * tileSize,
        tile.row * tileSize,
        tileSize,
        tileSize,
      );
      for (final direction in DungeonDirection.values) {
        if (tiles.contains(direction.stepFrom(tile))) {
          continue;
        }
        final (start, end) = switch (direction) {
          DungeonDirection.north => (rect.topLeft, rect.topRight),
          DungeonDirection.east => (rect.topRight, rect.bottomRight),
          DungeonDirection.south => (rect.bottomLeft, rect.bottomRight),
          DungeonDirection.west => (rect.topLeft, rect.bottomLeft),
        };
        path.moveTo(start.dx, start.dy);
        path.lineTo(end.dx, end.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(
          alpha: 0.5 + 0.5 * Curves.easeInOut.transform(pulse.value),
        )
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.square
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(TileAreaOutlinePainter oldDelegate) =>
      tiles != oldDelegate.tiles || color != oldDelegate.color;
}
