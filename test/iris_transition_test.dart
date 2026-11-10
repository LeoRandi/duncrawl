import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/game_menu_dialog.dart';
import 'package:duncrawl/main.dart';
import 'package:duncrawl/widgets/iris_transition.dart';

import 'helpers/dialogue_helpers.dart';

void main() {
  test(
    'Iris follows the 750/350/400 ms motion and rebounds in both directions',
    () {
      const curve = IrisTransitionCurve();
      expect(curve.transform(0), 0);
      expect(curve.transform(375 / 1500), closeTo(0.335, 0.000001));
      expect(curve.transform(750 / 1500), closeTo(0.67, 0.000001));
      expect(curve.transform(925 / 1500), closeTo(0.585, 0.000001));
      expect(curve.transform(1100 / 1500), closeTo(0.5, 0.000001));
      expect(curve.transform(1300 / 1500), closeTo(0.75, 0.000001));
      expect(curve.transform(1), 1);
      expect(1 - curve.transform(1 - 400 / 1500), closeTo(0.5, 0.000001));
      expect(1 - curve.transform(1 - 575 / 1500), closeTo(0.415, 0.000001));
      expect(1 - curve.transform(1 - 750 / 1500), closeTo(0.33, 0.000001));
    },
  );

  test(
    'Each closing and opening phase eases into and out of its endpoints',
    () {
      const curve = IrisTransitionCurve();
      for (final isOpening in [false, true]) {
        final boundaries = isOpening
            ? [0.0, 400 / 1500, 750 / 1500, 1.0]
            : [0.0, 750 / 1500, 1100 / 1500, 1.0];
        for (var phase = 0; phase < 3; phase++) {
          final start = boundaries[phase];
          final duration = boundaries[phase + 1] - start;
          double progressAt(double fraction) {
            final time = start + duration * fraction;
            return isOpening
                ? 1 - curve.transform(1 - time)
                : curve.transform(time);
          }

          final startingStep = (progressAt(0.01) - progressAt(0)).abs();
          final middleStep = (progressAt(0.5) - progressAt(0.49)).abs();
          final endingStep = (progressAt(1) - progressAt(0.99)).abs();
          expect(startingStep, lessThan(middleStep * 0.1));
          expect(endingStep, lessThan(middleStep * 0.1));
        }
      }
    },
  );

  test(
    'The initial aperture extends past every corner for off-center anchors',
    () {
      const size = Size(800, 600);
      for (final center in [
        Offset.zero,
        const Offset(780, 20),
        const Offset(20, 580),
        const Offset(-40, 300),
      ]) {
        final radius = IrisMask.coveringRadius(size, center);
        for (final corner in [
          Offset.zero,
          const Offset(800, 0),
          const Offset(0, 600),
          const Offset(800, 600),
        ]) {
          expect(radius, greaterThan((corner - center).distance));
        }
      }
    },
  );

  testWidgets(
    'Start closes around its button and opens around the player in three seconds',
    (tester) async {
      await tester.pumpWidget(const DungeonCrawlerApp());
      final startButton = find.widgetWithText(FilledButton, 'Start');
      final startCenter = tester.getCenter(startButton);
      final settingsCenter = tester.getCenter(
        find.widgetWithText(OutlinedButton, 'Settings'),
      );
      await tester.tap(startButton);
      await tester.pump();
      expect(_mask(tester).center, startCenter);
      expect(_mask(tester).aperture, 1);
      // La máscara captura cualquier intento de volver a iniciar o abrir ajustes.
      await tester.tapAt(startCenter);
      await tester.tapAt(settingsCenter);
      await tester.pump(const Duration(milliseconds: 750));
      expect(_mask(tester).aperture, closeTo(0.33, 0.000001));
      expect(find.byType(DungeonBoard), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.pump(const Duration(milliseconds: 350));
      expect(_mask(tester).aperture, closeTo(0.5, 0.000001));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(_mask(tester).aperture, 0);
      final playerCenter = tester.getCenter(
        find.byKey(const ValueKey('player')),
      );
      expect(_mask(tester).center, playerCenter);
      await tester.tapAt(playerCenter);
      await tester.pump();
      expect(
        tester.widget<DungeonBoard>(find.byType(DungeonBoard)).isSelected,
        isFalse,
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(_mask(tester).aperture, closeTo(0.5, 0.000001));
      await tester.pump(const Duration(milliseconds: 350));
      expect(_mask(tester).aperture, closeTo(0.33, 0.000001));
      await tester.pump(const Duration(milliseconds: 750));
      expect(_mask(tester).aperture, closeTo(1, 0.000001));
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byType(IrisMask), findsNothing);
      expect(find.byType(DungeonBoard), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Main menu stays visible while closing from its button and reveals the screen center',
    (tester) async {
      await tester.pumpWidget(const DungeonCrawlerApp());
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      await completeOpeningTutorial(tester);
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      final menuButton = find.widgetWithText(OutlinedButton, 'Main menu');
      final menuCenter = tester.getCenter(menuButton);
      await tester.tap(menuButton);
      await tester.pump();
      expect(_mask(tester).center, menuCenter);
      expect(find.byType(GameMenuDialog), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1499));
      expect(find.byType(GameMenuDialog), findsOneWidget);
      expect(find.byType(DungeonBoard), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(_mask(tester).aperture, 0);
      expect(
        _mask(tester).center,
        tester.getSize(find.byType(IrisTransition)).center(Offset.zero),
      );
      expect(find.byType(DungeonBoard), findsNothing);
      expect(find.byType(GameMenuDialog), findsNothing);
      expect(find.text('Start'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      expect(_mask(tester).aperture, closeTo(0.5, 0.000001));
      await tester.pump(const Duration(milliseconds: 350));
      expect(_mask(tester).aperture, closeTo(0.33, 0.000001));
      await tester.pump(const Duration(milliseconds: 750));
      expect(_mask(tester).aperture, closeTo(1, 0.000001));
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byType(IrisMask), findsNothing);
    },
  );

  testWidgets('System back uses the same transition, centered on the player', (
    tester,
  ) async {
    await tester.pumpWidget(const DungeonCrawlerApp());
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await completeOpeningTutorial(tester);
    final playerCenter = tester.getCenter(find.byKey(const ValueKey('player')));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(_mask(tester).center, playerCenter);
    await tester.pumpAndSettle();
    expect(find.byType(DungeonBoard), findsNothing);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('Disposing an active transition cancels its ticker safely', (
    tester,
  ) async {
    await tester.pumpWidget(const DungeonCrawlerApp());
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

IrisMask _mask(WidgetTester tester) =>
    tester.widget<IrisMask>(find.byType(IrisMask));
