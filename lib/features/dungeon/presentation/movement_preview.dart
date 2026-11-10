import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../domain/dungeon_floor.dart';
import '../domain/grid_position.dart';
import 'dungeon_strings.dart';

class MovementPreview extends StatelessWidget {
  final GridPosition origin;
  final List<GridPosition> path;

  const MovementPreview({super.key, required this.origin, required this.path});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final tileSize = constraints.maxWidth / DungeonFloor.size;
      return Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _MovementPathPainter(origin: origin, path: path),
          ),
          for (final (index, position) in path.indexed)
            Positioned(
              left: position.column * tileSize,
              top: position.row * tileSize,
              width: tileSize,
              height: tileSize,
              child: Semantics(
                key: index == path.length - 1
                    ? const ValueKey('movement-destination')
                    : null,
                label: index == path.length - 1
                    ? DungeonStrings.destination(
                        column: position.column + 1,
                        row: position.row + 1,
                      )
                    : DungeonStrings.pathStep(
                        step: index + 1,
                        column: position.column + 1,
                        row: position.row + 1,
                      ),
                child: const SizedBox.expand(),
              ),
            ),
        ],
      );
    },
  );
}

class _MovementPathPainter extends CustomPainter {
  final GridPosition origin;
  final List<GridPosition> path;

  const _MovementPathPainter({required this.origin, required this.path});

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) {
      return;
    }

    final tileSize = size.width / DungeonFloor.size;
    final highlight = Paint()
      ..color = DungeonColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final position in path) {
      canvas.drawRect(
        Rect.fromLTWH(
          position.column * tileSize,
          position.row * tileSize,
          tileSize,
          tileSize,
        ),
        highlight,
      );
    }

    final points = [
      for (final position in [origin, ...path])
        Offset(
          (position.column + 0.5) * tileSize,
          (position.row + 0.5) * tileSize,
        ),
    ];
    final tip = points.last;
    final lastSegment = tip - points[points.length - 2];
    final heading = lastSegment / lastSegment.distance;
    final perpendicular = Offset(-heading.dy, heading.dx);
    final arrowLength = tileSize * 0.33;
    final arrowHalfWidth = tileSize * 0.25;
    final arrowBase = tip - heading * arrowLength;

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1).take(points.length - 2)) {
      line.lineTo(point.dx, point.dy);
    }
    // La línea termina en la base para no sobresalir por la punta de la flecha.
    line.lineTo(arrowBase.dx, arrowBase.dy);
    canvas.drawPath(
      line,
      Paint()
        ..color = DungeonColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = (tileSize * 0.12).clamp(2.0, 4.0)
        ..strokeJoin = StrokeJoin.miter
        ..strokeCap = StrokeCap.square,
    );

    final left = arrowBase + perpendicular * arrowHalfWidth;
    final right = arrowBase - perpendicular * arrowHalfWidth;
    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(arrow, Paint()..color = DungeonColors.primary);
  }

  @override
  bool shouldRepaint(_MovementPathPainter oldDelegate) =>
      origin != oldDelegate.origin || !listEquals(path, oldDelegate.path);
}
