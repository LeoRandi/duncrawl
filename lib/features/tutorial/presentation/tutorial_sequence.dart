enum TutorialHighlightShape { circle, rectangle }

class TutorialHighlight {
  final Object target;
  final TutorialHighlightShape shape;
  final double padding;
  final double relativePadding;

  const TutorialHighlight({
    required this.target,
    required this.shape,
    this.padding = 0,
    this.relativePadding = 0,
  });
}

class TutorialHintPlacement {
  final Object firstTarget;
  final Object? secondTarget;

  const TutorialHintPlacement.between({
    required this.firstTarget,
    required Object this.secondTarget,
  });

  const TutorialHintPlacement.bottom(Object target)
    : firstTarget = target,
      secondTarget = null;
}

class TutorialSpotlightSpec {
  final List<TutorialHighlight> highlights;
  final String text;
  final TutorialHintPlacement placement;
  final Object? dismissEvent;
  final String? dismissLabel;
  final double shadeOpacity;

  const TutorialSpotlightSpec({
    required this.highlights,
    required this.text,
    required this.placement,
    this.dismissEvent,
    this.dismissLabel,
    this.shadeOpacity = 0.5,
  }) : assert((dismissEvent == null) == (dismissLabel == null)),
       assert(shadeOpacity >= 0 && shadeOpacity <= 1);
}

/// Los identificadores y eventos pertenecen al tutorial que define los pasos.
class TutorialStep {
  final Object id;
  final Object? advanceOn;
  final Duration? delay;
  final Set<Object> enabledControls;
  final Set<Object> emphasizedControls;
  final TutorialSpotlightSpec? spotlight;

  const TutorialStep({
    required this.id,
    this.advanceOn,
    this.delay,
    this.enabledControls = const {},
    this.emphasizedControls = const {},
    this.spotlight,
  }) : assert((advanceOn == null) != (delay == null));
}

class TutorialSequence {
  final List<TutorialStep> steps;

  const TutorialSequence(this.steps);
}
