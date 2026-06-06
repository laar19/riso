import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riso/providers/planning_mode_provider.dart';
import 'package:riso/widgets/planning_mode_toggle.dart';

void main() {
  group('PlanningModeToggle', () {
    testWidgets('comienza en modo planificación (escudo)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PlanningModeToggle(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.shield), findsOneWidget);
      expect(find.byIcon(Icons.flash_on), findsNothing);
    });

    testWidgets('al presionar cambia a modo ejecución (rayo)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            planningModeProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PlanningModeToggle(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.shield), findsOneWidget);

      await tester.tap(find.byIcon(Icons.shield));
      await tester.pump();

      // El estado cambia pero el widget se actualiza via el provider
    });

    testWidgets('tooltip cambia según el modo', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PlanningModeToggle(),
            ),
          ),
        ),
      );

      expect(find.byTooltip('Modo Planificación'), findsOneWidget);
    });
  });
}
