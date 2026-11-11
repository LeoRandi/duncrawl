import '../../dialogue/presentation/dialogue_sequence.dart';
import '../../tutorial/presentation/tutorial_sequence.dart';

/// Agrupa la espera de llegada, el diálogo y la guía de una planta.
class DungeonTutorialLesson {
  final Duration delay;
  final DialogueSequence dialogue;
  final TutorialSequence guide;

  const DungeonTutorialLesson({
    required this.delay,
    required this.dialogue,
    required this.guide,
  });
}
