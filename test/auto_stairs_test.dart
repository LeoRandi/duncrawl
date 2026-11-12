import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/features/dungeon/domain/dungeon_floor.dart';
import 'package:duncrawl/features/dungeon/domain/grid_position.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_board.dart';
import 'package:duncrawl/features/dungeon/presentation/dungeon_page.dart';
import 'package:duncrawl/features/dungeon/presentation/game_menu_dialog.dart';
import 'package:duncrawl/features/dungeon/presentation/ground_object_confirmation_dialog.dart';
import 'package:duncrawl/main.dart';
import 'package:duncrawl/widgets/iris_transition.dart';

import 'helpers/dialogue_helpers.dart';

void main() {
  testWidgets(
    'Manual stairs ask once per entry, No leaves the floor and Yes climbs',
    (tester) async {
      await _startWithManualStairs(tester);
      await _walkToStairs(tester);
      expect(find.text('Climb the stairs?'), findsOneWidget);
      expect(_board(tester).player, const GridPosition(7, 1));
      expect(_board(tester).floor.number, 0);
      expect(find.byType(IrisMask), findsNothing);
      await tester.tapAt(tester.getCenter(find.byTooltip('Menu')));
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('player-portrait'))),
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(GroundObjectConfirmationDialog), findsOneWidget);
      expect(find.byType(GameMenuDialog), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('decline-ground-interaction')),
      );
      await tester.pump();
      await tester.tapAt(
        tester.getCenter(
          find.byKey(const ValueKey('decline-ground-interaction')),
        ),
      );
      await _finishPromptExit(tester);
      expect(find.byType(GroundObjectConfirmationDialog), findsNothing);
      expect(find.byType(IrisMask), findsNothing);
      expect(_board(tester).player, const GridPosition(7, 1));
      expect(find.byType(DungeonPage), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('player-portrait')));
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(GroundObjectConfirmationDialog), findsNothing);
      await _walk(tester, const Offset(0, 1), 1);
      expect(_board(tester).player, const GridPosition(7, 2));
      expect(find.byType(GroundObjectConfirmationDialog), findsNothing);
      await _walk(tester, const Offset(0, -1), 1);
      await tester.pumpAndSettle();
      expect(find.text('Climb the stairs?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('accept-ground-interaction')));
      await tester.pumpAndSettle();
      expect(find.byType(GroundObjectConfirmationDialog), findsNothing);
      expect(_board(tester).floor.number, 1);
      expect(_board(tester).player, _board(tester).floor.spawn);
      expect(find.byType(IrisMask), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Disposing with a stairs prompt open is safe', (tester) async {
    await _startWithManualStairs(tester);
    await _walkToStairs(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final accepted in [false, true]) {
    testWidgets(
      'Pickup confirmation returns $accepted through the shared prompt',
      (tester) async {
        bool? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    result = await showGroundObjectConfirmation(
                      context,
                      interactionKind: GroundObjectInteractionKind.pickup,
                    );
                  },
                  child: const Text('Ask'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Ask'));
        await tester.pumpAndSettle();
        expect(find.text('Pick up this item?'), findsOneWidget);
        expect(result, isNull);
        await tester.tap(
          find.byKey(
            ValueKey(
              accepted
                  ? 'accept-ground-interaction'
                  : 'decline-ground-interaction',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(result, accepted);
      },
    );
  }
}

Future<void> _startWithManualStairs(WidgetTester tester) async {
  await tester.pumpWidget(const DungeonCrawlerApp());
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
  final toggle = find.byKey(const ValueKey('auto-climb-stairs-switch'));
  await tester.ensureVisible(toggle);
  await tester.tap(toggle);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start'));
  await tester.pumpAndSettle();
  await completeOpeningTutorial(tester);
  await tester.tap(find.byKey(const ValueKey('player-portrait')));
  await tester.pump();
}

Future<void> _walkToStairs(WidgetTester tester) async {
  await _walk(tester, const Offset(0, -1), 5);
  expect(_board(tester).player, const GridPosition(7, 2));
  await _walk(tester, const Offset(0, -1), 1);
  await tester.pumpAndSettle();
  expect(find.byType(GroundObjectConfirmationDialog), findsOneWidget);
}

Future<void> _walk(WidgetTester tester, Offset direction, int steps) async {
  final distance =
      math.max(
        tester.getSize(find.byType(DungeonBoard)).width / DungeonFloor.size,
        16,
      ) *
      tester
          .widget<DungeonPage>(find.byType(DungeonPage))
          .settings
          .value
          .dragDistanceMultiplier;
  await tester.drag(
    await movementPad(tester),
    direction * (distance * (steps + 0.1)),
  );
  await tester.pump();
  await tester.tap(find.text('Confirm'));
  await tester.pump();
  await tester.pump(Duration(milliseconds: 300 * steps));
}

Future<void> _finishPromptExit(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

DungeonBoard _board(WidgetTester tester) =>
    tester.widget<DungeonBoard>(find.byType(DungeonBoard));
