import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../domain/dungeon_floor.dart';
import '../domain/grid_position.dart';
import 'dungeon_strings.dart';
import 'movement_preview.dart';
import 'selection_frame.dart';

/// Orden de composición del tablero, desde el fondo hasta la niebla.
enum DungeonLayer {
  background,
  floorTiles,
  groundObjects,
  characters,
  aboveCharacters,
  fogAndDarkness,
}

class DungeonBoard extends StatelessWidget {
  final DungeonFloor floor;
  final GridPosition player;
  final List<GridPosition> movementPath;
  final bool isSelected;
  final VoidCallback? onSelectPlayer;
  final GlobalKey? playerAnchorKey;

  const DungeonBoard({
    super.key,
    required this.floor,
    required this.player,
    this.movementPath = const [],
    this.isSelected = false,
    this.onSelectPlayer,
    this.playerAnchorKey,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: DungeonStrings.grid,
    container: true,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final tileSize = constraints.maxWidth / DungeonFloor.size;
        return Stack(
          fit: StackFit.expand,
          children: [
            const _BoardLayer(
              layer: DungeonLayer.background,
              child: ColoredBox(color: DungeonColors.voidTile),
            ),
            _BoardLayer(
              layer: DungeonLayer.floorTiles,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _DungeonGridPainter(floor)),
                  ),
                  // La ruta es una marca sobre el suelo, no una séptima capa.
                  if (movementPath.isNotEmpty)
                    Positioned.fill(
                      child: MovementPreview(
                        origin: player,
                        path: movementPath,
                      ),
                    ),
                ],
              ),
            ),
            _BoardLayer(
              layer: DungeonLayer.groundObjects,
              child: Stack(
                children: [
                  for (final object in floor.groundObjects)
                    Positioned(
                      left: object.position.column * tileSize,
                      top: object.position.row * tileSize,
                      width: tileSize,
                      height: tileSize,
                      child: switch (object.type) {
                        GroundObjectType.stairsUp => Icon(
                          Icons.stairs_rounded,
                          size: tileSize * 0.8,
                          color: DungeonColors.textSecondary,
                          semanticLabel: DungeonStrings.stairs,
                        ),
                      },
                    ),
                ],
              ),
            ),
            _BoardLayer(
              layer: DungeonLayer.characters,
              child: Stack(
                children: [
                  Positioned(
                    key: playerAnchorKey,
                    left: player.column * tileSize,
                    top: player.row * tileSize,
                    width: tileSize,
                    height: tileSize,
                    child: Semantics(
                      button: true,
                      selected: isSelected,
                      label: DungeonStrings.playerPosition(
                        column: player.column + 1,
                        row: player.row + 1,
                      ),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onSelectPlayer,
                        child: SelectionFrame(
                          selected: isSelected,
                          child: DecoratedBox(
                            key: const ValueKey('player'),
                            decoration: BoxDecoration(
                              color: DungeonColors.background,
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: tileSize * 0.75,
                              color: DungeonColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const _BoardLayer(
              layer: DungeonLayer.aboveCharacters,
              child: SizedBox.expand(),
            ),
            const _BoardLayer(
              layer: DungeonLayer.fogAndDarkness,
              child: SizedBox.expand(),
            ),
          ],
        );
      },
    ),
  );
}

class _BoardLayer extends StatelessWidget {
  final DungeonLayer layer;
  final Widget child;

  const _BoardLayer({required this.layer, required this.child});

  @override
  Widget build(BuildContext context) =>
      Positioned.fill(key: ValueKey(layer), child: child);
}

class _DungeonGridPainter extends CustomPainter {
  final DungeonFloor floor;

  const _DungeonGridPainter(this.floor);

  @override
  void paint(Canvas canvas, Size size) {
    final tileSize = size.width / DungeonFloor.size;
    final floorPaint = Paint()..color = DungeonColors.floorTile;
    final wallPaint = Paint()..color = DungeonColors.surfaceRaised;
    for (var row = 0; row < DungeonFloor.size; row++) {
      for (var column = 0; column < DungeonFloor.size; column++) {
        final paint = switch (floor.tileAt(GridPosition(column, row))) {
          DungeonTile.voidTile => null,
          DungeonTile.floor => floorPaint,
          DungeonTile.wall => wallPaint,
        };
        if (paint != null) {
          canvas.drawRect(
            Rect.fromLTWH(
              column * tileSize,
              row * tileSize,
              tileSize,
              tileSize,
            ),
            paint,
          );
        }
      }
    }

    final gridPaint = Paint()
      ..color = DungeonColors.voidTile
      ..strokeWidth = 1
      ..isAntiAlias = false;
    for (var index = 0; index <= DungeonFloor.size; index++) {
      final offset = index * tileSize;
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset, size.height),
        gridPaint,
      );
      canvas.drawLine(Offset(0, offset), Offset(size.width, offset), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_DungeonGridPainter oldDelegate) =>
      floor != oldDelegate.floor;
}
