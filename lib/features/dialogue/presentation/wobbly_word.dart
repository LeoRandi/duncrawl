import 'package:flutter/material.dart';

import '../../settings/domain/text_speed.dart';
import 'wobbly_letter.dart';

/// El desfase por posición mantiene la onda aunque las letras aparezcan juntas.
class WobblyWord extends StatefulWidget {
  final List<String> letters;
  final TextStyle style;

  const WobblyWord({super.key, required this.letters, required this.style});

  @override
  State<WobblyWord> createState() => _WobblyWordState();
}

class _WobblyWordState extends State<WobblyWord>
    with SingleTickerProviderStateMixin {
  static const _cycleDuration = Duration(milliseconds: 900);
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this, duration: _cycleDuration)
      ..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      for (var index = 0; index < widget.letters.length; index++)
        WobblyLetter(
          key: ValueKey('wobbly-letter-$index'),
          letter: widget.letters[index],
          style: widget.style,
          animation: _animation,
          phaseOffset:
              index *
              TextSpeed.slow.letterInterval.inMicroseconds /
              _cycleDuration.inMicroseconds,
        ),
    ],
  );
}
