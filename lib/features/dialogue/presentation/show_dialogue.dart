import 'package:flutter/material.dart';

import '../../../app/dungeon_theme.dart';
import '../../settings/domain/text_speed.dart';
import 'dialogue_sequence.dart';
import 'dialogue_window.dart';

/// Ocupa el área del ancla y bloquea el resto de la pantalla hasta terminar.
/// El Future se completa al acabar también la animación de salida.
Future<void> showDialogue(
  BuildContext context, {
  required DialogueSequence sequence,
  required GlobalKey anchorKey,
  TextSpeed textSpeed = TextSpeed.defaultSpeed,
}) async {
  if (sequence.lines.isEmpty) {
    throw ArgumentError.value(
      sequence.lines,
      'sequence.lines',
      'Must not be empty',
    );
  }

  final navigator = Navigator.of(context, rootNavigator: true);
  final route = RawDialogRoute<void>(
    barrierDismissible: false,
    barrierColor: DungeonColors.background.withValues(alpha: 0.8),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) => PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: _AnchoredDialogue(
          sequence: sequence,
          anchorKey: anchorKey,
          textSpeed: textSpeed,
        ),
      ),
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: animation.drive(
            CurveTween(
              curve: animation.status == AnimationStatus.reverse
                  ? Curves.easeOut
                  : Curves.easeIn,
            ),
          ),
          child: child,
        ),
  );
  await navigator.push(route);
  await route.completed;
}

class _AnchoredDialogue extends StatefulWidget {
  final DialogueSequence sequence;
  final GlobalKey anchorKey;
  final TextSpeed textSpeed;

  const _AnchoredDialogue({
    required this.sequence,
    required this.anchorKey,
    required this.textSpeed,
  });

  @override
  State<_AnchoredDialogue> createState() => _AnchoredDialogueState();
}

class _AnchoredDialogueState extends State<_AnchoredDialogue>
    with WidgetsBindingObserver {
  late Rect _bounds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bounds = _readBounds();
  }

  Rect _readBounds() {
    final box = widget.anchorKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) {
      throw StateError('The dialogue anchor must be mounted and laid out.');
    }

    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  void didChangeMetrics() {
    // Se mide tras el layout para no leer el tamaño de otro render durante él.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final bounds = _readBounds();
      if (bounds != _bounds) {
        setState(() => _bounds = bounds);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fromRect(
        rect: _bounds,
        child: DialogueWindow(
          sequence: widget.sequence,
          textSpeed: widget.textSpeed,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    ],
  );
}
