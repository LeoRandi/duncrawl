import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duncrawl/app/dungeon_theme.dart';
import 'package:duncrawl/features/dungeon/presentation/stat_info_button.dart';

void main() {
  testWidgets(
    'Stat help anchors safely, dismisses on any tap and consumes the dismissal',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var underlyingTaps = 0;
      for (final size in [const Size(320, 568), const Size(844, 390)]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: DungeonTheme.dark,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(1.5),
              ),
              child: Scaffold(
                body: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => underlyingTaps++,
                        child: const SizedBox.expand(),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: StatInfoButton(
                          statName: 'Example stat',
                          explanation: 'Reusable help for this stat.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('(?)'));
        await tester.pump();
        final popup = tester.getRect(
          find.byKey(const ValueKey('stat-info-popup')),
        );
        expect(popup.left, greaterThanOrEqualTo(0));
        expect(popup.right, lessThanOrEqualTo(size.width));
        expect(popup.top, greaterThanOrEqualTo(0));
        expect(
          popup.bottom,
          lessThan(tester.getTopLeft(find.byType(StatInfoButton)).dy),
        );
        expect(
          tester
              .widget<Text>(find.text('Reusable help for this stat.'))
              .style
              ?.fontSize,
          12,
        );
        await tester.tap(find.text('Reusable help for this stat.'));
        await tester.pump();
        expect(find.byKey(const ValueKey('stat-info-popup')), findsNothing);
        expect(underlyingTaps, 0);
        await tester.tap(find.text('(?)'));
        await tester.pump();
        await tester.tapAt(const Offset(4, 4));
        await tester.pump();
        expect(find.byKey(const ValueKey('stat-info-popup')), findsNothing);
        expect(underlyingTaps, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
}
