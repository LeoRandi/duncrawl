class GridPosition {
  final int column;
  final int row;

  const GridPosition(this.column, this.row);

  bool isAdjacentTo(GridPosition other) =>
      (column - other.column).abs() + (row - other.row).abs() == 1;

  @override
  bool operator ==(Object other) =>
      other is GridPosition && column == other.column && row == other.row;

  @override
  int get hashCode => Object.hash(column, row);

  @override
  String toString() => 'GridPosition($column, $row)';
}
