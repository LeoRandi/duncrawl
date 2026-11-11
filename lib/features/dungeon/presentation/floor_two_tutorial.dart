import '../../dialogue/presentation/dialogue_sequence.dart';
import '../../tutorial/presentation/tutorial_sequence.dart';
import 'dungeon_strings.dart';
import 'opening_tutorial.dart';
import '../../shards/domain/shard_progress.dart';

enum FloorTwoTutorialStage {
  dialogue,
  waitForBat,
  selection,
  details,
  waitForShardDialogue,
  shardDialogue,
  waitForShard,
  shardReveal,
}

abstract final class FloorTwoTutorial {
  static const delay = Duration(milliseconds: 500);
  static const stepDelay = Duration(milliseconds: 500);

  static const shardDialogue = DialogueSequence(
    speaker: DungeonStrings.mysteriousVoice,
    lines: [
      DialogueLine([
        DialogueFragment(
          'Gods, i really cannot see if those Bats are angry at you or not...',
        ),
      ]),
      DialogueLine([DialogueFragment('Let me see if i can find this...')]),
      DialogueLine([DialogueFragment('...')]),
      DialogueLine([
        DialogueFragment("...Ah! Here it is, let's see if "),
        DialogueFragment('this', wobbly: true),
        DialogueFragment(' works...'),
      ]),
    ],
  );

  static const dialogue = DialogueSequence(
    speaker: DungeonStrings.mysteriousVoice,
    lines: [
      DialogueLine([
        DialogueFragment('You are almost there, just one more floor...'),
      ]),
      DialogueLine([
        DialogueFragment('...Wait are those '),
        DialogueFragment('Bats', wobbly: true),
        DialogueFragment(
          '? They keep getting into this floor, im not sure how.',
        ),
      ]),
      DialogueLine([
        DialogueFragment(
          '...Are you colorblind or something? Why is everything so gray?',
        ),
      ]),
      DialogueLine([
        DialogueFragment("Hurry up, and don't get "),
        DialogueFragment('eaten', wobbly: true),
        DialogueFragment('!'),
      ]),
    ],
  );

  static const guide = TutorialSequence([
    TutorialStep(
      id: FloorTwoTutorialStage.dialogue,
      advanceOn: DungeonTutorialEvent.dialogueFinished,
    ),
    TutorialStep(id: FloorTwoTutorialStage.waitForBat, delay: stepDelay),
    TutorialStep(
      id: FloorTwoTutorialStage.selection,
      advanceOn: DungeonTutorialEvent.batSelected,
      enabledControls: {DungeonTutorialControl.enemySelection},
      spotlight: TutorialSpotlightSpec(
        text: DungeonStrings.tutorialSelectBat,
        highlights: [
          TutorialHighlight(
            target: DungeonTutorialTarget.bat,
            shape: TutorialHighlightShape.circle,
            relativePadding: 0.3,
          ),
        ],
        placement: TutorialHintPlacement.bottom(DungeonTutorialTarget.menu),
      ),
    ),
    TutorialStep(
      id: FloorTwoTutorialStage.details,
      advanceOn: DungeonTutorialEvent.hintClosed,
      enabledControls: {DungeonTutorialControl.statHelp},
      spotlight: TutorialSpotlightSpec(
        text: DungeonStrings.tutorialBatStats,
        highlights: [
          TutorialHighlight(
            target: DungeonTutorialTarget.menu,
            shape: TutorialHighlightShape.rectangle,
          ),
        ],
        placement: TutorialHintPlacement.bottom(DungeonTutorialTarget.grid),
        dismissEvent: DungeonTutorialEvent.hintClosed,
        dismissLabel: DungeonStrings.close,
      ),
    ),
    TutorialStep(
      id: FloorTwoTutorialStage.waitForShardDialogue,
      delay: stepDelay,
    ),
    TutorialStep(
      id: FloorTwoTutorialStage.shardDialogue,
      advanceOn: DungeonTutorialEvent.dialogueFinished,
      effect: shardDialogue,
    ),
    TutorialStep(
      id: FloorTwoTutorialStage.waitForShard,
      delay: Duration(milliseconds: 100),
    ),
    TutorialStep(
      id: FloorTwoTutorialStage.shardReveal,
      advanceOn: DungeonTutorialEvent.effectFinished,
      effect: ColorShard.red,
    ),
  ]);
}
