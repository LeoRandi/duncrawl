enum TextSpeed {
  slow(Duration(milliseconds: 100)),
  medium(Duration(milliseconds: 50)),
  fast(Duration(milliseconds: 20)),
  instant(Duration.zero);

  static const defaultSpeed = medium;

  final Duration letterInterval;

  const TextSpeed(this.letterInterval);

  Duration intervalFor({required bool isAnimated}) {
    if (this == instant) {
      return Duration.zero;
    }

    return isAnimated ? slow.letterInterval : letterInterval;
  }
}
