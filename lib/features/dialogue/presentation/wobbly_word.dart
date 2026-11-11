import 'package:flutter/material.dart';

import '../../settings/domain/text_speed.dart';
import 'wobbly_letter.dart';

/// El desfase por posición mantiene la onda aunque las letras aparezcan juntas.
class WobblyWord extends StatefulWidget {
  static const cycleDuration = Duration(milliseconds: 900);

  final List<String> letters;
  final TextStyle style;
  final Animation<double>? animation;
  final int letterOffset;

  const WobblyWord({
    super.key,
    required this.letters,
    required this.style,
    this.animation,
    this.letterOffset = 0,
  });

  @override
  State<WobblyWord> createState() => _WobblyWordState();
}

class _WobblyWordState extends State<WobblyWord>
    with SingleTickerProviderStateMixin {
  AnimationController? _ownedAnimation;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _configureAnimation();
  }

  @override
  void didUpdateWidget(WobblyWord oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _configureAnimation();
    }
  }

  void _configureAnimation() {
    final externalAnimation = widget.animation;
    if (externalAnimation != null) {
      _ownedAnimation?.stop();
      _animation = externalAnimation;
      return;
    }
    final controller = _ownedAnimation ??= AnimationController(
      vsync: this,
      duration: WobblyWord.cycleDuration,
    );
    _animation = controller;
    controller.repeat();
  }

  @override
  void dispose() {
    _ownedAnimation?.dispose();
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
              (widget.letterOffset + index) *
              TextSpeed.slow.letterInterval.inMicroseconds /
              WobblyWord.cycleDuration.inMicroseconds,
        ),
    ],
  );
}
