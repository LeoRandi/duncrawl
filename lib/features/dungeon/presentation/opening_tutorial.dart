import '../../dialogue/presentation/dialogue_sequence.dart';
import '../../tutorial/presentation/tutorial_sequence.dart';
import 'dungeon_strings.dart';

enum DungeonTutorialEvent {
  dialogueFinished,
  characterSelected,
  movementPreviewed,
  movementFinished,
  tileInspected,
  hintClosed,
}

enum DungeonTutorialControl { selection, movement, menu, confirm, inspection }

enum DungeonTutorialTarget { character, portrait, grid, stairs, menu }

enum OpeningTutorialStage {
  dialogue,
  waitForSelection,
  selection,
  waitForDrag,
  dragging,
  practice,
  stairs,
}

abstract final class OpeningTutorial {
  static const delay = Duration(seconds: 1);
  static const stepDelay = Duration(milliseconds: 500);

  static const guide = TutorialSequence([
    TutorialStep(
      id: OpeningTutorialStage.dialogue,
      advanceOn: DungeonTutorialEvent.dialogueFinished,
    ),
    TutorialStep(id: OpeningTutorialStage.waitForSelection, delay: stepDelay),
    TutorialStep(
      id: OpeningTutorialStage.selection,
      advanceOn: DungeonTutorialEvent.characterSelected,
      enabledControls: {DungeonTutorialControl.selection},
      spotlight: TutorialSpotlightSpec(
        text: DungeonStrings.tutorialSelect,
        highlights: [
          TutorialHighlight(
            target: DungeonTutorialTarget.character,
            shape: TutorialHighlightShape.circle,
            relativePadding: 0.4,
          ),
          TutorialHighlight(
            target: DungeonTutorialTarget.portrait,
            shape: TutorialHighlightShape.rectangle,
            padding: 6,
          ),
        ],
        placement: TutorialHintPlacement.between(
          firstTarget: DungeonTutorialTarget.portrait,
          secondTarget: DungeonTutorialTarget.character,
        ),
      ),
    ),
    TutorialStep(id: OpeningTutorialStage.waitForDrag, delay: stepDelay),
    TutorialStep(
      id: OpeningTutorialStage.dragging,
      advanceOn: DungeonTutorialEvent.movementPreviewed,
      enabledControls: {DungeonTutorialControl.movement},
      spotlight: TutorialSpotlightSpec(
        text: DungeonStrings.tutorialDrag,
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
      id: OpeningTutorialStage.practice,
      advanceOn: DungeonTutorialEvent.movementFinished,
      enabledControls: {
        DungeonTutorialControl.selection,
        DungeonTutorialControl.movement,
        DungeonTutorialControl.menu,
        DungeonTutorialControl.confirm,
      },
      emphasizedControls: {DungeonTutorialControl.confirm},
    ),
    TutorialStep(
      id: OpeningTutorialStage.stairs,
      advanceOn: DungeonTutorialEvent.hintClosed,
      spotlight: TutorialSpotlightSpec(
        text: DungeonStrings.tutorialStairs,
        highlights: [
          TutorialHighlight(
            target: DungeonTutorialTarget.stairs,
            shape: TutorialHighlightShape.circle,
            relativePadding: 0.5,
          ),
        ],
        placement: TutorialHintPlacement.bottom(DungeonTutorialTarget.menu),
        dismissEvent: DungeonTutorialEvent.hintClosed,
        dismissLabel: DungeonStrings.close,
      ),
    ),
  ]);

  static const dialogue = DialogueSequence(
    speaker: DungeonStrings.mysteriousVoice,
    lines: [
      DialogueLine([DialogueFragment('...')]),
      DialogueLine([DialogueFragment('...Hey, wake up')]),
      DialogueLine([DialogueFragment('...Are you dead? Damn, not again')]),
      DialogueLine([
        DialogueFragment("Oh! It seems you ARE alive, just don't want to move"),
      ]),
      DialogueLine([
        DialogueFragment('Come on, quick, '),
        DialogueFragment('drag', wobbly: true),
        DialogueFragment(
          ' yourself up to those stairs so i can give you a quick look',
        ),
      ]),
    ],
  );
}
