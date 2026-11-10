class DialogueSequence {
  final String speaker;
  final List<DialogueLine> lines;

  const DialogueSequence({required this.speaker, required this.lines});
}

class DialogueLine {
  final List<DialogueFragment> fragments;

  const DialogueLine(this.fragments);

  String get text => fragments.map((fragment) => fragment.text).join();
}

class DialogueFragment {
  final String text;
  final bool wobbly;

  const DialogueFragment(this.text, {this.wobbly = false});
}
