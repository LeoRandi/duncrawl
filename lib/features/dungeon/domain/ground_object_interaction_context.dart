import 'dungeon.dart';
import 'dungeon_floor.dart';

enum GroundObjectTrigger { enteredTile, activated }

/// Ofrece el estado actual y acciones del juego sin acoplar el callback a Flutter.
class GroundObjectInteractionContext {
  final DungeonGroundObject object;
  final GroundObjectTrigger trigger;
  final Dungeon Function() _readDungeon;
  final void Function(Dungeon dungeon) updateDungeon;
  final void Function(int floorNumber) requestFloorChange;

  GroundObjectInteractionContext({
    required this.object,
    required this.trigger,
    required Dungeon Function() readDungeon,
    required this.updateDungeon,
    required this.requestFloorChange,
  }) : _readDungeon = readDungeon;

  Dungeon get dungeon => _readDungeon();
}
