import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riso/features/chat/presentation/widgets/chat_input.dart';

void main() {
  group('ChatInput', () {
    testWidgets('muestra hint text y botón de enviar deshabilitado al inicio',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(onSend: (_) {}),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      final button = tester.widget<IconButton>(find.byIcon(Icons.send_rounded));
      expect(button.onPressed, isNull);
    });

    testWidgets('botón se habilita al escribir texto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(onSend: (_) {}),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hola mundo');
      await tester.pump();

      final button = tester.widget<IconButton>(find.byIcon(Icons.send_rounded));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('onSend se llama con el texto al presionar enviar',
        (tester) async {
      String? sentText;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(onSend: (text) => sentText = text),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'mensaje de prueba');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(sentText, 'mensaje de prueba');
    });

    testWidgets('el campo se limpia después de enviar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(onSend: (_) {}),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'texto');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(find.text('texto'), findsNothing);
    });

    testWidgets('deshabilitado cuando enabled=false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(onSend: (_) {}, enabled: false),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'texto');
      await tester.pump();

      final button = tester.widget<IconButton>(find.byIcon(Icons.send_rounded));
      expect(button.onPressed, isNull);
    });
  });
}
