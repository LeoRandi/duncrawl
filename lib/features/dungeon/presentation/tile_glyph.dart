import 'package:flutter/material.dart';

/// Centra el dibujo visible de los glifos, compensando el ascenso de la fuente.
class TileGlyph extends StatelessWidget {
  final String symbol;
  final String label;
  final Color color;
  final double fontSize;
  final String prefix;
  final Color? prefixColor;

  const TileGlyph({
    super.key,
    required this.symbol,
    required this.label,
    required this.color,
    required this.fontSize,
    this.prefix = '',
    this.prefixColor,
  });

  @override
  Widget build(BuildContext context) {
    // La g desciende bajo la línea base; la w no ocupa esa zona de la caja tipográfica.
    final verticalOffset = switch (symbol) {
      'g' => 0.12,
      'w' => 0.04,
      _ => 0.0,
    };
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Transform.translate(
          offset: Offset(0, -fontSize * verticalOffset),
          child: Text.rich(
            prefix.isEmpty
                ? TextSpan(text: symbol)
                : TextSpan(
                    children: [
                      TextSpan(
                        text: prefix,
                        style: TextStyle(color: prefixColor ?? color),
                      ),
                      TextSpan(text: symbol),
                    ],
                  ),
            semanticsLabel: label,
            textScaler: TextScaler.noScaling,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: fontSize,
              height: 1,
              leadingDistribution: TextLeadingDistribution.even,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
