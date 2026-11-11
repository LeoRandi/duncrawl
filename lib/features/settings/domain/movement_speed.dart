enum MovementSpeed {
  slow(Duration(milliseconds: 500)),
  medium(Duration(milliseconds: 300)),
  fast(Duration(milliseconds: 150)),
  ultraFast(Duration(milliseconds: 50));

  static const defaultSpeed = medium;

  final Duration stepInterval;

  const MovementSpeed(this.stepInterval);
}
