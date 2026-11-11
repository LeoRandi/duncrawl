import 'grid_position.dart';

enum EnemyType { bat }

class DungeonEnemy {
  final EnemyType type;
  final GridPosition position;

  const DungeonEnemy({required this.type, required this.position});

  const DungeonEnemy.bat(this.position) : type = EnemyType.bat;
}
