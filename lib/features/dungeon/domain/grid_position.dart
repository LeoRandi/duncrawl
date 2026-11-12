class GridPosition {
  final int column;
  final int row;

  const GridPosition(this.column, this.row);

  int distanceTo(GridPosition other) =>
      (column - other.column).abs() + (row - other.row).abs();

  bool isAdjacentTo(GridPosition other) => distanceTo(other) == 1;

  /// Radio ortogonal sin obstáculos; el tablero limita después sus bordes.
  Set<GridPosition> areaWithin(int radius) {
    assert(radius >= 0);
    return Set.unmodifiable({
      for (var dy = -radius; dy <= radius; dy++)
        for (var dx = -radius; dx <= radius; dx++)
          if (dx.abs() + dy.abs() <= radius)
            GridPosition(column + dx, row + dy),
    });
  }

  @override
  bool operator ==(Object other) =>
      other is GridPosition && column == other.column && row == other.row;

  @override
  int get hashCode => Object.hash(column, row);

  @override
  String toString() => 'GridPosition($column, $row)';
}
