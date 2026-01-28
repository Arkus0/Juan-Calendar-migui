import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musician_organizer/screens/task_form_screen.dart';
import 'package:musician_organizer/models/tarea.dart';
import 'package:musician_organizer/services/hive_service.dart';

void main() {
  setUpAll(() async {
    // Ensure Hive boxes are initialized for tests
    await HiveService().initialize();
  });

  testWidgets('Delete button shows confirmation dialog and has tooltip', (WidgetTester tester) async {
    final tarea = Tarea(
      id: 'test-id',
      descripcion: 'Test Task',
      fecha: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TaskFormScreen(tarea: tarea),
        ),
      ),
    );

    // Verify delete button is present
    final deleteButtonFinder = find.byIcon(Icons.delete);
    expect(deleteButtonFinder, findsOneWidget);

    // Verify tooltip
    final tooltipFinder = find.byTooltip('Eliminar tarea');
    expect(tooltipFinder, findsOneWidget, reason: 'Delete button should have a tooltip');

    // Tap delete button
    await tester.tap(deleteButtonFinder);
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Eliminar tarea'), findsOneWidget, reason: 'Confirmation dialog title should be visible');
    expect(find.text('¿Estás seguro de que quieres eliminar esta tarea?'), findsOneWidget, reason: 'Confirmation dialog content should be visible');

    // Tap Cancel
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    // Verify dialog is gone
    expect(find.text('Eliminar tarea'), findsNothing);
  });

  testWidgets('Delete button confirms deletion and closes screen', (WidgetTester tester) async {
    final tarea = Tarea(
      id: 'test-id-2',
      descripcion: 'Test Task 2',
      fecha: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TaskFormScreen(tarea: tarea),
        ),
      ),
    );

    // Tap delete button
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    // Tap Confirm (Eliminar)
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    // Verify screen is closed (TaskFormScreen should not be in the tree)
    expect(find.byType(TaskFormScreen), findsNothing);
  });
}
