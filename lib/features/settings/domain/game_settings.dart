import 'text_speed.dart';

class GameSettings {
  static const minimumMovementSensitivity = 1.0;
  static const maximumMovementSensitivity = 5.0;

  final double movementSensitivity;
  final TextSpeed textSpeed;
  final bool autoClimbStairs;
  final bool autoPickUpItems;

  const GameSettings({
    this.movementSensitivity = 4,
    this.textSpeed = TextSpeed.defaultSpeed,
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
    bool? autoClimbStairs,
    bool? autoPickUpItems,
  }) => GameSettings(
    movementSensitivity: movementSensitivity ?? this.movementSensitivity,
    textSpeed: textSpeed ?? this.textSpeed,
    autoClimbStairs: autoClimbStairs ?? this.autoClimbStairs,
    autoPickUpItems: autoPickUpItems ?? this.autoPickUpItems,
  );
}
