import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_ui_ux/adaptive_ui_ux.dart';

void main() {
  group('AdaptiveWidget', () {
    testWidgets('creates with correct ID', (WidgetTester tester) async {
      const testId = 'test_widget_id';
      const testChild = Text('Test');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdaptiveWidget(
              id: testId,
              child: testChild,
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('tracks tap interactions', (WidgetTester tester) async {
      const testId = 'tap_test_widget';
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveWidget(
              id: testId,
              onInteraction: (event) {
                if (event.type == InteractionType.tap &&
                    event.widgetId == testId) {
                  wasTapped = true;
                }
              },
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('applies constraints when provided',
        (WidgetTester tester) async {
      const testId = 'constrained_widget';
      const constraints = BoxConstraints(minWidth: 200, minHeight: 100);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AdaptiveWidget(
                id: testId,
                constraints: constraints,
                child: Text('Constrained'),
              ),
            ),
          ),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.ancestor(
          of: find.text('Constrained'),
          matching: find.byType(ConstrainedBox),
        ),
      );

      expect(constrainedBox.constraints.minWidth, equals(constraints.minWidth));
      expect(
          constrainedBox.constraints.minHeight, equals(constraints.minHeight));
    });

    testWidgets('auto generates ID when using factory constructor',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveWidget.auto(
              child: const Text('Auto ID'),
            ),
          ),
        ),
      );

      expect(find.text('Auto ID'), findsOneWidget);
    });
  });

  group('InteractionEvent', () {
    test('converts to and from JSON correctly', () {
      const widgetId = 'test_widget';
      const type = InteractionType.tap;
      final timestamp = DateTime.now();

      final event = InteractionEvent(
        widgetId: widgetId,
        type: type,
        timestamp: timestamp,
      );

      final json = event.toJson();
      final fromJson = InteractionEvent.fromJson(json);

      expect(fromJson.widgetId, equals(widgetId));
      expect(fromJson.type, equals(type));
      expect(fromJson.timestamp.toIso8601String(),
          equals(timestamp.toIso8601String()));
    });
  });
}
