import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musician_organizer/models/tarea.dart';
import 'package:musician_organizer/providers/app_providers.dart';
import 'package:musician_organizer/providers/data_providers.dart';
import 'package:musician_organizer/screens/agenda_screen.dart';
import 'package:musician_organizer/services/hive_service.dart';
import 'package:musician_organizer/services/notification_service.dart';
import 'package:musician_organizer/services/preferences_service.dart';
import 'package:intl/date_symbol_data_local.dart';

final fixedDate = DateTime(2024, 6, 15);

// Mock PreferencesService
class MockPreferencesService implements PreferencesService {
  @override
  Future<DateTime?> getSelectedDate() async => fixedDate;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return null or dummy values for other methods if needed to prevent crashes
    // but better to implement what's needed.
    return super.noSuchMethod(invocation);
  }
}

// Custom TasksNotifier to load test dataset
class TestTasksNotifier extends TasksNotifier {
  final List<Tarea> _initial;
  TestTasksNotifier(this._initial)
      : super(hiveService: HiveService(), notificationService: NotificationService(), loadOnInit: false) {
    state = _initial;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    // Initialize Hive for tests (uses in-memory or fallback)
    await HiveService().initialize();
  });

  testWidgets('AgendaScreen shows empty state with icon when no tasks', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedDateProvider.overrideWith((ref) {
             final notifier = SelectedDateNotifier(MockPreferencesService());
             notifier.state = fixedDate;
             return notifier;
          }),
          tasksProvider.overrideWith((ref) => TestTasksNotifier([])),
        ],
        child: const MaterialApp(
          home: AgendaScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify empty state text
    expect(find.text('No hay tareas para hoy'), findsOneWidget);

    // Verify empty state icon
    expect(find.byIcon(Icons.assignment_turned_in_outlined), findsOneWidget);
  });

  testWidgets('AgendaScreen FAB has tooltip', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedDateProvider.overrideWith((ref) {
             final notifier = SelectedDateNotifier(MockPreferencesService());
             notifier.state = fixedDate;
             return notifier;
          }),
          tasksProvider.overrideWith((ref) => TestTasksNotifier([])),
        ],
        child: const MaterialApp(
          home: AgendaScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify FAB has tooltip
    expect(find.byTooltip('Añadir tarea'), findsOneWidget);
  });
}
