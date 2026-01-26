import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musician_organizer/screens/event_form_screen.dart';
import 'package:musician_organizer/models/evento.dart';

void main() {
  testWidgets('Delete button shows confirmation dialog', (WidgetTester tester) async {
    final event = Evento(
      id: 'test-id',
      titulo: 'Test Event',
      tipo: 'bolo',
      inicio: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EventFormScreen(evento: event),
        ),
      ),
    );

    // Verify delete button is present
    final deleteButtonFinder = find.byIcon(Icons.delete);
    expect(deleteButtonFinder, findsOneWidget);

    // Tap delete button
    await tester.tap(deleteButtonFinder);
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Eliminar evento'), findsOneWidget);
    expect(find.text('¿Estás seguro de que quieres eliminar este evento?'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    // Verify dialog is gone
    expect(find.text('Eliminar evento'), findsNothing);

    // Tap delete button again
    await tester.tap(deleteButtonFinder);
    await tester.pumpAndSettle();

    // Tap Delete
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
  });
}
