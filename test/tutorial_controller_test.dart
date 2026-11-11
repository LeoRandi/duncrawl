import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/tutorial/presentation/tutorial_controller.dart';
import 'package:duncrawl/features/tutorial/presentation/tutorial_sequence.dart';

enum _Event { select, move }

enum _Control { portrait, grid }

void main() {
  testWidgets(
    'Disabled and skipped tutorials release controls and cancel timers',
    (tester) async {
      const sequence = TutorialSequence([
        TutorialStep(id: 'wait', delay: Duration(milliseconds: 500)),
        TutorialStep(id: 'select', advanceOn: _Event.select),
      ]);
      final disabled = TutorialController(sequence, isEnabled: false);
      final active = TutorialController(sequence);
      addTearDown(disabled.dispose);
      addTearDown(active.dispose);
      expect(disabled.isComplete, isTrue);
      expect(disabled.allows(_Control.grid), isTrue);
      active.skip();
      active.skip();
      await tester.pump(const Duration(seconds: 1));
      active.signal(_Event.select);
      expect(active.isComplete, isTrue);
      expect(active.currentStep, isNull);
      expect(active.allowsInput, isTrue);
      expect(active.emphasizes(_Control.grid), isFalse);
    },
  );
  testWidgets(
    'Reusable steps accept caller events, preserve delays and restrict controls',
    (tester) async {
      final controller = TutorialController(
        const TutorialSequence([
          TutorialStep(id: 'wait', delay: Duration(milliseconds: 500)),
          TutorialStep(
            id: 'choose',
            advanceOn: _Event.select,
            enabledControls: {_Control.portrait},
          ),
          TutorialStep(id: 'wait-again', delay: Duration(milliseconds: 500)),
          TutorialStep(
            id: 'walk',
            advanceOn: _Event.move,
            enabledControls: {_Control.grid},
            emphasizedControls: {_Control.grid},
          ),
        ]),
      );
      addTearDown(controller.dispose);
      expect(controller.allowsInput, isFalse);
      controller.signal(_Event.select);
      expect(controller.currentStep?.id, 'wait');
      await tester.pump(const Duration(milliseconds: 499));
      expect(controller.currentStep?.id, 'wait');
      await tester.pump(const Duration(milliseconds: 1));
      expect(controller.allows(_Control.portrait), isTrue);
      expect(controller.allows(_Control.grid), isFalse);
      controller.signal(_Event.move);
      expect(controller.currentStep?.id, 'choose');
      controller.signal(_Event.select);
      expect(controller.allowsInput, isFalse);
      await tester.pump(const Duration(milliseconds: 499));
      expect(controller.currentStep?.id, 'wait-again');
      await tester.pump(const Duration(milliseconds: 1));
      expect(controller.emphasizes(_Control.grid), isTrue);
      controller.signal(_Event.move);
      expect(controller.isComplete, isTrue);
      expect(controller.allows(_Control.portrait), isTrue);
      expect(controller.emphasizes(_Control.grid), isFalse);
      controller.signal(_Event.move);
      expect(controller.isComplete, isTrue);
    },
  );

  testWidgets('Disposal cancels a pending tutorial step', (tester) async {
    final controller = TutorialController(
      const TutorialSequence([
        TutorialStep(id: 'wait', delay: Duration(milliseconds: 500)),
      ]),
    );
    controller.dispose();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.isComplete, isFalse);
  });
}
