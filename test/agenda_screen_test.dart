import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musician_organizer/models/tarea.dart';
import 'package:musician_organizer/providers/app_providers.dart';
import 'package:musician_organizer/providers/data_providers.dart';
import 'package:musician_organizer/providers/settings_provider.dart';
import 'package:musician_organizer/screens/agenda_screen.dart';
import 'package:musician_organizer/services/preferences_service.dart';
import 'package:musician_organizer/services/hive_service.dart';
import 'package:musician_organizer/services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';

final fixedDate = DateTime(2024, 6, 15); // Saturday

// Mock PreferencesService
class MockPreferencesService implements PreferencesService {
  @override
  Future<String?> getDossierTemplate() async => null;
  @override
  Future<DateTime?> getSelectedDate() async => fixedDate;
  @override
  Future<void> saveDossierTemplate(String template) async {}
  @override
  Future<void> saveSelectedDate(DateTime date) async {}
}

class MockHiveService implements HiveService {
  final List<Tarea> tasks;
  MockHiveService({this.tasks = const []});

  @override
  List<Tarea> getAllTareas() => tasks;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockNotificationService implements NotificationService {
  @override
  Future<void> scheduleTaskNotifications(Tarea tarea) async {}

  @override
  Future<void> cancelTaskNotifications(String id) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Custom TasksNotifier to load test dataset
class TestTasksNotifier extends TasksNotifier {
  final List<Tarea> _initial;
  TestTasksNotifier(this._initial) : super(
    hiveService: MockHiveService(tasks: _initial),
    notificationService: MockNotificationService()
  ) {
    state = _initial;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  testWidgets('AgendaScreen renders tasks correctly in Day view', (WidgetTester tester) async {
    final List<Tarea> testTasks = [
      Tarea(
        id: 'task_1',
        descripcion: 'Task 1',
        fecha: fixedDate, // Same day
        categoria: 'General',
      ),
      Tarea(
        id: 'task_2',
        descripcion: 'Task 2',
        fecha: fixedDate.add(const Duration(days: 1)), // Next day
        categoria: 'General',
      ),
    ];

    final mockPrefs = MockPreferencesService();
    final mockHive = MockHiveService(tasks: testTasks);
    final mockNotification = MockNotificationService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(mockPrefs),
          hiveServiceProvider.overrideWithValue(mockHive),
          notificationServiceProvider.overrideWithValue(mockNotification),
          selectedDateProvider.overrideWith((ref) {
            final notifier = SelectedDateNotifier(mockPrefs);
            notifier.state = fixedDate;
            return notifier;
          }),
          tasksProvider.overrideWith((ref) => TestTasksNotifier(testTasks)),
          agendaViewProvider.overrideWith((ref) => AgendaViewMode.day),
        ],
        child: const MaterialApp(
          home: AgendaScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify 'Task 1' is visible
    expect(find.text('Task 1'), findsOneWidget);
    // Verify 'Task 2' is NOT visible (filtered out)
    expect(find.text('Task 2'), findsNothing);
  });

  testWidgets('AgendaScreen renders tasks correctly in Week view with headers', (WidgetTester tester) async {
      // fixedDate is Saturday June 15, 2024.
      // Week starts Monday June 10, ends Sunday June 16.

      final List<Tarea> testTasks = [
        Tarea(
          id: 'task_1',
          descripcion: 'Task 1',
          fecha: fixedDate, // Saturday 15
          categoria: 'General',
        ),
        Tarea(
          id: 'task_2',
          descripcion: 'Task 2',
          fecha: fixedDate.add(const Duration(days: 1)), // Sunday 16 (in week)
          categoria: 'General',
        ),
         Tarea(
          id: 'task_3',
          descripcion: 'Task 3',
          fecha: fixedDate.add(const Duration(days: 2)), // Monday 17 (next week)
          categoria: 'General',
        ),
      ];

      final mockPrefs = MockPreferencesService();
      final mockHive = MockHiveService(tasks: testTasks);
      final mockNotification = MockNotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(mockPrefs),
            hiveServiceProvider.overrideWithValue(mockHive),
            notificationServiceProvider.overrideWithValue(mockNotification),
            selectedDateProvider.overrideWith((ref) {
              final notifier = SelectedDateNotifier(mockPrefs);
              notifier.state = fixedDate;
              return notifier;
            }),
            tasksProvider.overrideWith((ref) => TestTasksNotifier(testTasks)),
            // Note: StateProvider override syntax might differ if not using .notifier
            agendaViewProvider.overrideWith((ref) => AgendaViewMode.week),
          ],
          child: const MaterialApp(
            home: AgendaScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify 'Task 1' and 'Task 2' are visible
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsOneWidget);
      // 'Task 3' is next week
      expect(find.text('Task 3'), findsNothing);

      // Verify Headers
      // "sábado, 15 jun" and "domingo, 16 jun"
      // Note: Locale might be issue if system default is not Spanish.
      // The code uses DateFormat('...', 'es'). initializeDateFormatting() was called.
      // But we didn't force locale in MaterialApp.
      // However, DateFormat('...', 'es') forces it.
      // find.text might need exact match.

      // Let's check for "sábado" or "jun" parts if strict matching fails.
      // But expecting full string if formatting is correct.
      // 'sábado, 15 jun' might be 'sábado, 15 jun.' or similar depending on intl version.
      // Let's rely on tasks for now, and check if any header text exists.
      expect(find.textContaining('sábado'), findsOneWidget);
    });
}
