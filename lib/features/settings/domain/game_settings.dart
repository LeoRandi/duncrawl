import 'text_speed.dart';
import 'movement_speed.dart';

class GameSettings {
  static const minimumMovementSensitivity = 1.0;
  static const maximumMovementSensitivity = 5.0;

  final double movementSensitivity;
  final TextSpeed textSpeed;
  final MovementSpeed movementSpeed;
  final bool isTutorialSkipUnlocked;
  final bool skipTutorials;
  final bool autoClimbStairs;
  final bool autoPickUpItems;

  const GameSettings({
    this.movementSensitivity = 4,
    this.textSpeed = TextSpeed.defaultSpeed,
    this.movementSpeed = MovementSpeed.defaultSpeed,
    this.isTutorialSkipUnlocked = false,
    this.skipTutorials = false,
    this.autoClimbStairs = true,
    this.autoPickUpItems = true,
  }) : assert(movementSensitivity >= minimumMovementSensitivity),
       assert(movementSensitivity <= maximumMovementSensitivity);

  double get dragDistanceMultiplier =>
      minimumMovementSensitivity +
      maximumMovementSensitivity -
      movementSensitivity;

  GameSettings copyWith({
    double? movementSensitivity,
    TextSpeed? textSpeed,
    MovementSpeed? movementSpeed,
    bool? isTutorialSkipUnlocked,
    bool? skipTutorials,
    bool? autoClimbStairs,
    bool? autoPickUpItems,
  }) => GameSettings(
    movementSensitivity: movementSensitivity ?? this.movementSensitivity,
    textSpeed: textSpeed ?? this.textSpeed,
    movementSpeed: movementSpeed ?? this.movementSpeed,
    isTutorialSkipUnlocked:
        isTutorialSkipUnlocked ?? this.isTutorialSkipUnlocked,
    skipTutorials: skipTutorials ?? this.skipTutorials,
    autoClimbStairs: autoClimbStairs ?? this.autoClimbStairs,
    autoPickUpItems: autoPickUpItems ?? this.autoPickUpItems,
  );
}
