import '../../dialogue/presentation/dialogue_sequence.dart';

abstract final class OpeningTutorial {
  static const delay = Duration(seconds: 1);

  static const dialogue = DialogueSequence(
    speaker: 'Misteryous voice',
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
