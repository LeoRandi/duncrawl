import 'text_speed.dart';

class GameSettings {
  static const minimumMovementSensitivity = 1.0;
  static const maximumMovementSensitivity = 5.0;

  final double movementSensitivity;
  final TextSpeed textSpeed;

  const GameSettings({
    this.movementSensitivity = 4,
    this.textSpeed = TextSpeed.defaultSpeed,
  }) : assert(movementSensitivity >= minimumMovementSensitivity),
       assert(movementSensitivity <= maximumMovementSensitivity);

  double get dragDistanceMultiplier =>
      minimumMovementSensitivity +
      maximumMovementSensitivity -
      movementSensitivity;

  GameSettings copyWith({double? movementSensitivity, TextSpeed? textSpeed}) =>
      GameSettings(
        movementSensitivity: movementSensitivity ?? this.movementSensitivity,
        textSpeed: textSpeed ?? this.textSpeed,
      );
}
