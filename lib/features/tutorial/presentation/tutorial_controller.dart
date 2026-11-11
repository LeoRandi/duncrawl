import 'dart:async';

import 'package:flutter/foundation.dart';

import 'tutorial_sequence.dart';

/// Avanza por eventos o por tiempo y cancela las esperas al liberar el tutorial.
class TutorialController extends ChangeNotifier {
  late TutorialSequence _sequence;
  int _stepIndex = 0;
  Timer? _stepTimer;

  TutorialController(TutorialSequence sequence, {bool isEnabled = true}) {
    _resetSequence(sequence, isEnabled: isEnabled);
  }

  TutorialSequence get sequence => _sequence;

  /// Sustituye la guía activa y cancela las esperas de la anterior.
  void start(TutorialSequence sequence, {bool isEnabled = true}) {
    _resetSequence(sequence, isEnabled: isEnabled);
    notifyListeners();
  }

  bool get isComplete => _stepIndex == sequence.steps.length;
  TutorialStep? get currentStep =>
      isComplete ? null : sequence.steps[_stepIndex];
  bool get allowsInput =>
      isComplete || (currentStep?.enabledControls.isNotEmpty ?? false);

  bool allows(Object control) =>
      isComplete || (currentStep?.enabledControls.contains(control) ?? false);

  bool emphasizes(Object control) =>
      currentStep?.emphasizedControls.contains(control) ?? false;

  void signal(Object event) {
    if (!isComplete && currentStep?.advanceOn == event) {
      _advance();
    }
  }

  /// Cancela las esperas y libera todos los controles, también para futuros tutoriales.
  void skip() {
    if (isComplete) {
      return;
    }
    _stepTimer?.cancel();
    _stepIndex = sequence.steps.length;
    notifyListeners();
  }

  void _resetSequence(TutorialSequence sequence, {required bool isEnabled}) {
    if (sequence.steps.isEmpty) {
      throw ArgumentError.value(
        sequence.steps,
        'sequence.steps',
        'Must not be empty',
      );
    }
    _stepTimer?.cancel();
    _sequence = sequence;
    _stepIndex = isEnabled ? 0 : sequence.steps.length;
    _scheduleStep();
  }

  void _advance() {
    _stepTimer?.cancel();
    _stepIndex++;
    _scheduleStep();
    notifyListeners();
  }

  void _scheduleStep() {
    final delay = currentStep?.delay;
    if (delay != null) {
      _stepTimer = Timer(delay, _advance);
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }
}
