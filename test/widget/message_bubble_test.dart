import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riso/models/chat_message.dart';
import 'package:riso/features/chat/presentation/widgets/message_bubble.dart';

void main() {
  group('MessageBubble', () {
    testWidgets('renderiza mensaje de usuario a la derecha', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: ChatMessage(
                id: '1',
                threadId: 't1',
                role: MessageRole.user,
                content: 'Hola',
                timestamp: DateTime(2025, 1, 1),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hola'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renderiza mensaje del asistente a la izquierda con icono',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: ChatMessage(
                id: '2',
                threadId: 't1',
                role: MessageRole.assistant,
                content: 'Respuesta en **markdown**',
                timestamp: DateTime(2025, 1, 1),
                modelUsed: 'gemini-1.5-flash',
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
      expect(find.text('gemini-1.5-flash'), findsOneWidget);
    });

    testWidgets('renderiza timestamp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: ChatMessage(
                id: '3',
                threadId: 't1',
                role: MessageRole.user,
                content: 'test',
                timestamp: DateTime(2025, 6, 6, 14, 30),
              ),
            ),
          ),
        ),
      );

      expect(find.text('14:30'), findsOneWidget);
    });
  });
}
