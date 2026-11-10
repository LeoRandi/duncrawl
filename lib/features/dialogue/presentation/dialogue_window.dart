import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../../dungeon/presentation/dungeon_strings.dart';
import '../../settings/domain/text_speed.dart';
import 'dialogue_sequence.dart';
import 'wobbly_word.dart';

class DialogueWindow extends StatefulWidget {
  final DialogueSequence sequence;
  final VoidCallback onClose;
  final TextSpeed textSpeed;

  const DialogueWindow({
    super.key,
    required this.sequence,
    required this.onClose,
    this.textSpeed = TextSpeed.defaultSpeed,
  });

  @override
  State<DialogueWindow> createState() => _DialogueWindowState();
}

class _DialogueWindowState extends State<DialogueWindow> {
  final _scrollController = ScrollController();
  Timer? _typingTimer;
  int _lineIndex = 0;
  int _visibleCharacters = 0;
  bool _isClosing = false;
  late List<List<String>> _fragmentCharacters;
  late List<String> _characters;
  late List<bool> _animatedCharacters;

  bool get _isComplete => _visibleCharacters == _characters.length;
  bool get _isLast => _lineIndex == widget.sequence.lines.length - 1;

  @override
  void initState() {
    super.initState();
    _startLine();
  }

  void _startLine() {
    _typingTimer?.cancel();
    _visibleCharacters = 0;
    _fragmentCharacters = widget.sequence.lines[_lineIndex].fragments
        .map((fragment) => fragment.text.characters.toList())
        .toList();
    _characters = _fragmentCharacters.expand((letters) => letters).toList();
    _animatedCharacters = [
      for (var index = 0; index < _fragmentCharacters.length; index++)
        for (
          var letter = 0;
          letter < _fragmentCharacters[index].length;
          letter++
        )
          widget.sequence.lines[_lineIndex].fragments[index].wobbly,
    ];
    if (widget.textSpeed == TextSpeed.instant) {
      _visibleCharacters = _characters.length;
    }
    _scheduleNextCharacter();
  }

  void _scheduleNextCharacter() {
    if (_isComplete) {
      return;
    }

    final interval = widget.textSpeed.intervalFor(
      isAnimated: _animatedCharacters[_visibleCharacters],
    );
    _typingTimer = Timer(interval, () {
      setState(() => _visibleCharacters++);
      _scrollToEndAfterLayout();
      _scheduleNextCharacter();
    });
  }

  void _revealLine() {
    if (_isComplete || _isClosing) {
      return;
    }

    _typingTimer?.cancel();
    setState(() => _visibleCharacters = _characters.length);
    _scrollToEndAfterLayout();
  }

  void _scrollToEndAfterLayout() {
    // El texto nuevo sigue visible incluso con letra grande o paneles bajos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _advance() {
    if (!_isComplete || _isClosing) {
      return;
    }
    if (_isLast) {
      setState(() => _isClosing = true);
      widget.onClose();
      return;
    }

    setState(() {
      _lineIndex++;
      _startLine();
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = DefaultTextStyle.of(
      context,
    ).style.merge(Theme.of(context).textTheme.bodyMedium);
    final fragments = widget.sequence.lines[_lineIndex].fragments;
    final spans = <InlineSpan>[];
    var remainingCharacters = _visibleCharacters;
    for (
      var fragmentIndex = 0;
      fragmentIndex < fragments.length;
      fragmentIndex++
    ) {
      final letters = _fragmentCharacters[fragmentIndex]
          .take(remainingCharacters)
          .toList();
      remainingCharacters -= letters.length;
      if (letters.isEmpty) {
        continue;
      }
      if (!fragments[fragmentIndex].wobbly) {
        spans.add(TextSpan(text: letters.join()));
        continue;
      }

      // Una sola caja conserva la palabra animada en la misma línea.
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: WobblyWord(
            key: ValueKey('wobbly-word-$_lineIndex-$fragmentIndex'),
            letters: letters,
            style: textStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _revealLine,
            child: Container(
              key: const ValueKey('dialogue-box'),
              padding: const EdgeInsets.all(DungeonTheme.pagePadding),
              decoration: BoxDecoration(
                color: DungeonColors.panel,
                border: Border.all(
                  color: DungeonColors.primary,
                  width: DungeonTheme.selectedBorderWidth,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Semantics(
                        key: const ValueKey('dialogue-text'),
                        liveRegion: _isComplete,
                        label: _characters.take(_visibleCharacters).join(),
                        child: ExcludeSemantics(
                          child: Text.rich(
                            TextSpan(children: spans),
                            key: ValueKey('dialogue-line-$_lineIndex'),
                            style: textStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DungeonTheme.spacing),
                  SizedBox(
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _isComplete
                          ? TextButton.icon(
                              key: const ValueKey('dialogue-advance'),
                              onPressed: _isClosing ? null : _advance,
                              iconAlignment: IconAlignment.end,
                              icon: Icon(
                                _isLast ? Icons.close : Icons.arrow_forward,
                              ),
                              label: Text(
                                _isLast
                                    ? DungeonStrings.close
                                    : DungeonStrings.continueGame,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: FractionalTranslation(
            translation: const Offset(0, -1),
            child: Padding(
              padding: const EdgeInsets.only(bottom: DungeonTheme.spacing),
              child: Semantics(
                header: true,
                child: Text(
                  widget.sequence.speaker,
                  style: textStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
