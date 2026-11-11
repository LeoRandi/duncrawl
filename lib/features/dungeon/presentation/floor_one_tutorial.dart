import '../../dialogue/presentation/dialogue_sequence.dart';
import '../../tutorial/presentation/tutorial_sequence.dart';
import 'dungeon_strings.dart';
import 'opening_tutorial.dart';

enum FloorOneTutorialStage { dialogue, waitForInspection, inspection, details }

abstract final class FloorOneTutorial {
  static const delay = Duration(milliseconds: 500);
  static const stepDelay = Duration(milliseconds: 500);

  static const dialogue = DialogueSequence(
    speaker: DungeonStrings.mysteriousVoice,
    lines: [
      DialogueLine([
        DialogueFragment(
          'Great, just a couple more floors, you are almost here!',
        ),
      ]),
      DialogueLine([
        DialogueFragment('...Wait, why are there '),
        DialogueFragment('letters on the floor', wobbly: true),
        DialogueFragment('?'),
      ]),
    ],
  );

  static const guide = TutorialSequence([
    TutorialStep(
      id: FloorOneTutorialStage.dialogue,
      advanceOn: DungeonTutorialEvent.dialogueFinished,
    ),
    TutorialStep(id: FloorOneTutorialStage.waitForInspection, delay: stepDelay),
    TutorialStep(
      id: FloorOneTutorialStage.inspection,
      advanceOn: DungeonTutorialEvent.tileInspected,
      enabledControls: {DungeonTutorialControl.inspection},
      spotlight: TutorialSpotlightSpec(
        text: DungeonStrings.tutorialInspectTile,
        highlights: [
          TutorialHighlight(
            target: DungeonTutorialTarget.grid,
            shape: TutorialHighlightShape.rectangle,
          ),
        ],
        placement: TutorialHintPlacement.bottom(DungeonTutorialTarget.menu),
      ),
    ),
    TutorialStep(
      id: FloorOneTutorialStage.details,
      advanceOn: DungeonTutorialEvent.hintClosed,
      spotlight: TutorialSpotlightSpec(
        text: DungeonStrings.tutorialTileDetails,
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
  ]);
}
