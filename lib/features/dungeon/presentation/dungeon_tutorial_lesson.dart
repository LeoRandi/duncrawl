import '../../dialogue/presentation/dialogue_sequence.dart';
import '../../tutorial/presentation/tutorial_sequence.dart';
import '../../shards/domain/shard_progress.dart';

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

  Iterable<ColorShard> get shardRewards =>
      guide.steps.map((step) => step.effect).whereType<ColorShard>();
}
