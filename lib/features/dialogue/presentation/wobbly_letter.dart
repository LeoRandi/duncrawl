import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Usa el reloj de la palabra con un desfase expresado en ciclos completos.
class WobblyLetter extends StatelessWidget {
  final String letter;
  final TextStyle style;
  final Animation<double> animation;
  final double phaseOffset;

  const WobblyLetter({
    super.key,
    required this.letter,
    required this.style,
    required this.animation,
    required this.phaseOffset,
  });

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: Text(letter, style: style),
    builder: (context, child) => Transform.translate(
      offset: Offset(
        0,
        math.sin((animation.value - phaseOffset) * math.pi * 2) * 2.5,
      ),
      child: child,
    ),
  );
}
