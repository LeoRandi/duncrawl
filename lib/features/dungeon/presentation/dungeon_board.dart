import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../domain/dungeon_floor.dart';
import '../domain/dungeon_enemy.dart';
import '../domain/grid_position.dart';
import '../domain/tile_inspection.dart';
import '../domain/dungeon_visibility.dart';
import '../domain/game_event.dart';
import 'combat_impact.dart';
import 'dungeon_strings.dart';
import 'movement_preview.dart';
import 'selection_frame.dart';
import 'tile_glyph.dart';
import 'tile_area_outline.dart';
import '../../shards/presentation/shard_colors.dart';
import '../../shards/presentation/shard_scope.dart';
import '../../shards/domain/shard_progress.dart';

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
  final TileInspection? selectedInspection;
  final VoidCallback? onSelectPlayer;
  final ValueChanged<GridPosition>? onSelectTile;
  final GlobalKey? playerAnchorKey;
  final GlobalKey? stairsAnchorKey;
  final Map<String, GlobalKey> enemyAnchorKeys;
  final Set<GridPosition> attackRange;
  final Set<String> engagedEnemyIds;
  final String? activeActorId;
  final AttackResolved? lastAttack;
  final int attackSequence;

  const DungeonBoard({
    super.key,
    required this.floor,
    required this.player,
    this.movementPath = const [],
    this.isSelected = false,
    this.selectedTile,
    this.selectedInspection,
    this.onSelectPlayer,
    this.onSelectTile,
    this.playerAnchorKey,
    this.stairsAnchorKey,
    this.enemyAnchorKeys = const {},
    this.attackRange = const {},
    this.engagedEnemyIds = const {},
    this.activeActorId,
    this.lastAttack,
    this.attackSequence = 0,
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
                      child: CustomPaint(
                        painter: _DungeonGridPainter(
                          floor,
                          ShardScope.progressOf(context),
                        ),
                      ),
                    ),
                    for (var row = 0; row < DungeonFloor.size; row++)
                      for (var column = 0; column < DungeonFloor.size; column++)
                        if (floor.tileAt(GridPosition(column, row)) ==
                                DungeonTile.water &&
                            !floor.hasShallowWaterAt(GridPosition(column, row)))
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
                              color: ShardColors.water.of(context),
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
                        when position != player || !isSelected)
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
                            color: ShardColors.grass.of(context),
                            fontSize: tileSize * 0.8,
                          ),
                          GroundObjectType.shallowWater => TileGlyph(
                            key: ValueKey(('shallow-water', object.position)),
                            symbol: 'w',
                            prefix: 's',
                            prefixColor: ShardColors.shallowWaterPrefix.of(
                              context,
                            ),
                            label: DungeonStrings.shallowWater,
                            color: ShardColors.shallowWater.of(context),
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
                    for (final enemy in floor.enemies)
                      Positioned(
                        key:
                            enemyAnchorKeys[enemy.id] ??
                            ValueKey(('enemy', enemy.id)),
                        left: enemy.position.column * tileSize,
                        top: enemy.position.row * tileSize,
                        width: tileSize,
                        height: tileSize,
                        child: Semantics(
                          button: true,
                          selected: selectedInspection?.actorId == enemy.id,
                          label: DungeonStrings.bat,
                          onTap: onSelectTile == null
                              ? null
                              : () => onSelectTile?.call(enemy.position),
                          child: SelectionFrame(
                            selected: activeActorId == enemy.id,
                            child: Padding(
                              padding: const EdgeInsets.all(1),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ColoredBox(
                                    color: DungeonColors.floorTile,
                                    child: switch (enemy.type) {
                                      EnemyType.bat => TileGlyph(
                                        symbol: 'B',
                                        label: DungeonStrings.bat,
                                        color: ShardColors.bat.of(context),
                                        fontSize: tileSize * 0.8,
                                      ),
                                    },
                                  ),
                                  if (engagedEnemyIds.contains(enemy.id))
                                    const Align(
                                      alignment: Alignment.topRight,
                                      child: Text(
                                        '!',
                                        textScaler: TextScaler.noScaling,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: DungeonColors.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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
                                color: ShardColors.adventurer.of(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _BoardLayer(
                layer: DungeonLayer.aboveCharacters,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    for (final enemy in floor.enemies)
                      if (!enemy.isDefeated &&
                          engagedEnemyIds.contains(enemy.id))
                        TileAreaOutline(
                          key: ValueKey(('combat-vision', enemy.id)),
                          tiles: DungeonVisibility.visibleArea(floor, enemy),
                          color: ShardColors.vision.unlocked,
                          pulseDuration: TileAreaOutline.combatPulseDuration,
                        ),
                    switch (selectedInspection?.enemy) {
                      final enemy? when !engagedEnemyIds.contains(enemy.id) =>
                        TileAreaOutline(
                          key: const ValueKey('enemy-vision'),
                          tiles: DungeonVisibility.visibleArea(floor, enemy),
                          color: ShardColors.vision.of(context),
                        ),
                      _ => const SizedBox.expand(),
                    },
                    if (attackRange.isNotEmpty)
                      TileAreaOutline(
                        key: const ValueKey('attack-range'),
                        tiles: attackRange,
                        color: DungeonColors.primary,
                      ),
                    if (lastAttack case final attack?)
                      Positioned(
                        left:
                            attack.targetPosition.column * tileSize -
                            tileSize / 2,
                        top:
                            attack.targetPosition.row * tileSize - tileSize / 2,
                        width: tileSize * 2,
                        height: tileSize * 1.5,
                        child: CombatImpact(
                          key: ValueKey(('combat-impact', attackSequence)),
                          damage: attack.damage,
                        ),
                      ),
                  ],
                ),
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

enum _WaterDepth { shallow, deep }

class _DungeonGridPainter extends CustomPainter {
  final DungeonFloor floor;

  final ShardProgress shards;

  const _DungeonGridPainter(this.floor, this.shards);

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
              GridPosition(column, row - 1),
              GridPosition(column, row),
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
              GridPosition(column - 1, row),
              GridPosition(column, row),
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
    // El borde profundo prevalece en el límite entre ambas profundidades.
    _paintWaterOutline(canvas, tileSize: tileSize, depth: _WaterDepth.shallow);
    _paintWaterOutline(canvas, tileSize: tileSize, depth: _WaterDepth.deep);
  }

  bool _joinsTiles(GridPosition first, GridPosition second) {
    final depth = _waterDepthAt(first.column, first.row);
    if (depth != null) {
      return depth == _waterDepthAt(second.column, second.row);
    }
    return floor.tileAt(first) == DungeonTile.wall &&
        floor.tileAt(second) == DungeonTile.wall;
  }

  void _paintWaterOutline(
    Canvas canvas, {
    required double tileSize,
    required _WaterDepth depth,
  }) {
    final outline = Path();
    for (var row = 0; row < DungeonFloor.size; row++) {
      for (var column = 0; column < DungeonFloor.size; column++) {
        if (_waterDepthAt(column, row) != depth) {
          continue;
        }
        final tile = Rect.fromLTWH(
          column * tileSize,
          row * tileSize,
          tileSize,
          tileSize,
        );
        if (_waterDepthAt(column, row - 1) != depth) {
          outline.moveTo(tile.left, tile.top);
          outline.lineTo(tile.right, tile.top);
        }
        if (_waterDepthAt(column + 1, row) != depth) {
          outline.moveTo(tile.right, tile.top);
          outline.lineTo(tile.right, tile.bottom);
        }
        if (_waterDepthAt(column, row + 1) != depth) {
          outline.moveTo(tile.left, tile.bottom);
          outline.lineTo(tile.right, tile.bottom);
        }
        if (_waterDepthAt(column - 1, row) != depth) {
          outline.moveTo(tile.left, tile.top);
          outline.lineTo(tile.left, tile.bottom);
        }
      }
    }
    canvas.drawPath(
      outline,
      Paint()
        ..color = switch (depth) {
          _WaterDepth.shallow => ShardColors.shallowWaterPrefix.resolve(shards),
          _WaterDepth.deep => ShardColors.waterBorder.resolve(shards),
        }
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.square
        ..isAntiAlias = false,
    );
  }

  _WaterDepth? _waterDepthAt(int column, int row) {
    final position = GridPosition(column, row);
    if (!floor.contains(position)) {
      return null;
    }
    if (floor.hasShallowWaterAt(position)) {
      return _WaterDepth.shallow;
    }
    return floor.tileAt(position) == DungeonTile.water
        ? _WaterDepth.deep
        : null;
  }

  @override
  bool shouldRepaint(_DungeonGridPainter oldDelegate) =>
      floor != oldDelegate.floor || shards != oldDelegate.shards;
}
