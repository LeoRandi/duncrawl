import 'grid_position.dart';

/// La petición se conserva hasta que la transición visual permite cambiar la escena.
class FloorChangeRequest {
  final int floorNumber;
  final int sourceFloorNumber;
  final GridPosition sourcePosition;

  const FloorChangeRequest({
    required this.floorNumber,
    required this.sourceFloorNumber,
    required this.sourcePosition,
  });
}
