import 'package:flutter/material.dart';

import 'shard_colors.dart';

/// Colorea menciones completas sin alterar el texto ni sus efectos tipográficos.
abstract final class ShardMentions {
  static final _mentions = RegExp(
    r'\b(shallow water|deep water|water|grass|adventurer|bats?)\b',
    caseSensitive: false,
  );

  static List<TextSpan> spans(BuildContext context, String text) {
    final spans = <TextSpan>[];
    var end = 0;
    for (final match in _mentions.allMatches(text)) {
      if (match.start > end) {
        spans.add(TextSpan(text: text.substring(end, match.start)));
      }
      final word = match.group(0)!;
      final token = switch (word.toLowerCase()) {
        'bat' || 'bats' => ShardColors.bat,
        'adventurer' => ShardColors.adventurer,
        'grass' => ShardColors.grass,
        'shallow water' => ShardColors.shallowWater,
        _ => ShardColors.water,
      };
      spans.add(
        TextSpan(
          text: word,
          style: TextStyle(color: token.of(context)),
        ),
      );
      end = match.end;
    }
    if (end < text.length) {
      spans.add(TextSpan(text: text.substring(end)));
    }
    return spans;
  }
}

class ShardText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const ShardText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(children: ShardMentions.spans(context, text)),
    style: style,
  );
}
