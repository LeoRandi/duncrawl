import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../domain/dungeon_floor.dart';
import '../domain/grid_position.dart';
import 'dungeon_strings.dart';
import 'movement_preview.dart';
import 'selection_frame.dart';
import 'tile_glyph.dart';

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
  final GridPosition? selectedTile;
  final VoidCallback? onSelectPlayer;
  final ValueChanged<GridPosition>? onSelectTile;
  final GlobalKey? playerAnchorKey;
  final GlobalKey? stairsAnchorKey;

  const DungeonBoard({
    super.key,
    required this.floor,
    required this.player,
    this.movementPath = const [],
    this.isSelected = false,
    this.selectedTile,
    this.onSelectPlayer,
    this.onSelectTile,
    this.playerAnchorKey,
    this.stairsAnchorKey,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: DungeonStrings.grid,
    container: true,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final tileSize = constraints.maxWidth / DungeonFloor.size;
        final stairs = floor.groundObjects
            .where((object) => object.type == GroundObjectType.stairsUp)
            .firstOrNull;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: onSelectTile == null
              ? null
              : (details) {
                  final position = GridPosition(
                    (details.localPosition.dx / tileSize).floor(),
                    (details.localPosition.dy / tileSize).floor(),
                  );
                  if (floor.contains(position)) {
                    onSelectTile?.call(position);
                  }
                },
          child: Stack(
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
                    for (var row = 0; row < DungeonFloor.size; row++)
                      for (var column = 0; column < DungeonFloor.size; column++)
                        if (floor.tileAt(GridPosition(column, row)) ==
                            DungeonTile.water)
                          Positioned(
                            left: column * tileSize,
                            top: row * tileSize,
                            width: tileSize,
                            height: tileSize,
                            child: TileGlyph(
                              key: ValueKey((
                                'water',
                                GridPosition(column, row),
                              )),
                              symbol: 'w',
                              label: DungeonStrings.water,
                              color: DungeonColors.water,
                              fontSize: tileSize * 0.8,
                            ),
                          ),
                    // La ruta es una marca sobre el suelo, no una séptima capa.
                    if (movementPath.isNotEmpty)
                      Positioned.fill(
                        child: MovementPreview(
                          origin: player,
                          path: movementPath,
                        ),
                      ),
                    if (selectedTile case final position?
                        when position != player)
                      Positioned(
                        left: position.column * tileSize,
                        top: position.row * tileSize,
                        width: tileSize,
                        height: tileSize,
                        child: IgnorePointer(
                          child: SelectionFrame(
                            key: ValueKey(('selected-tile', position)),
                            selected: true,
                            child: const SizedBox.expand(),
                          ),
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
                            key: object == stairs ? stairsAnchorKey : null,
                            Icons.stairs_rounded,
                            size: tileSize * 0.8,
                            color: DungeonColors.textSecondary,
                            semanticLabel: DungeonStrings.stairs,
                          ),
                          GroundObjectType.grass => TileGlyph(
                            key: ValueKey(('grass', object.position)),
                            symbol: 'g',
                            label: DungeonStrings.grass,
                            color: DungeonColors.grass,
                            fontSize: tileSize * 0.8,
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
          ),
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
    final floorPaint = Paint()
      ..color = DungeonColors.floorTile
      ..isAntiAlias = false;
    final wallPaint = Paint()
      ..color = DungeonColors.wallTile
      ..isAntiAlias = false;
    for (var row = 0; row < DungeonFloor.size; row++) {
      for (var column = 0; column < DungeonFloor.size; column++) {
        final paint = switch (floor.tileAt(GridPosition(column, row))) {
          DungeonTile.voidTile => null,
          DungeonTile.floor || DungeonTile.water => floorPaint,
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
    for (var row = 0; row <= DungeonFloor.size; row++) {
      for (var column = 0; column < DungeonFloor.size; column++) {
        final joinsTiles =
            row > 0 &&
            row < DungeonFloor.size &&
            _joinsTiles(
              floor.tileAt(GridPosition(column, row - 1)),
              floor.tileAt(GridPosition(column, row)),
            );
        if (!joinsTiles) {
          canvas.drawLine(
            Offset(column * tileSize, row * tileSize),
            Offset((column + 1) * tileSize, row * tileSize),
            gridPaint,
          );
        }
      }
    }
    for (var column = 0; column <= DungeonFloor.size; column++) {
      for (var row = 0; row < DungeonFloor.size; row++) {
        final joinsTiles =
            column > 0 &&
            column < DungeonFloor.size &&
            _joinsTiles(
              floor.tileAt(GridPosition(column - 1, row)),
              floor.tileAt(GridPosition(column, row)),
            );
        if (!joinsTiles) {
          canvas.drawLine(
            Offset(column * tileSize, row * tileSize),
            Offset(column * tileSize, (row + 1) * tileSize),
            gridPaint,
          );
        }
      }
    }
    // El contorno se dibuja al final para que la cuadrícula no lo corte.
    _paintWaterOutline(canvas, tileSize);
  }

  bool _joinsTiles(DungeonTile first, DungeonTile second) =>
      first == second &&
      (first == DungeonTile.wall || first == DungeonTile.water);

  void _paintWaterOutline(Canvas canvas, double tileSize) {
    final outline = Path();
    for (var row = 0; row < DungeonFloor.size; row++) {
      for (var column = 0; column < DungeonFloor.size; column++) {
        if (!_isWater(column, row)) {
          continue;
        }
        final tile = Rect.fromLTWH(
          column * tileSize,
          row * tileSize,
          tileSize,
          tileSize,
        );
        if (!_isWater(column, row - 1)) {
          outline.moveTo(tile.left, tile.top);
          outline.lineTo(tile.right, tile.top);
        }
        if (!_isWater(column + 1, row)) {
          outline.moveTo(tile.right, tile.top);
          outline.lineTo(tile.right, tile.bottom);
        }
        if (!_isWater(column, row + 1)) {
          outline.moveTo(tile.left, tile.bottom);
          outline.lineTo(tile.right, tile.bottom);
        }
        if (!_isWater(column - 1, row)) {
          outline.moveTo(tile.left, tile.top);
          outline.lineTo(tile.left, tile.bottom);
        }
      }
    }
    canvas.drawPath(
      outline,
      Paint()
        ..color = DungeonColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.square
        ..isAntiAlias = false,
    );
  }

  bool _isWater(int column, int row) =>
      column >= 0 &&
      column < DungeonFloor.size &&
      row >= 0 &&
      row < DungeonFloor.size &&
      floor.tileAt(GridPosition(column, row)) == DungeonTile.water;

  @override
  bool shouldRepaint(_DungeonGridPainter oldDelegate) =>
      floor != oldDelegate.floor;
}
