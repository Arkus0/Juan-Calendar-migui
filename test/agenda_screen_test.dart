import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musician_organizer/models/tarea.dart';
import 'package:musician_organizer/providers/app_providers.dart';
import 'package:musician_organizer/providers/data_providers.dart';
import 'package:musician_organizer/providers/settings_provider.dart';
import 'package:musician_organizer/screens/agenda_screen.dart';
import 'package:musician_organizer/services/hive_service.dart';
import 'package:musician_organizer/services/notification_service.dart';
import 'package:musician_organizer/services/preferences_service.dart';
import 'package:intl/date_symbol_data_local.dart';

class MockPreferencesService implements PreferencesService {
  @override
  Future<String?> getDossierTemplate() async => null;
  @override
  Future<DateTime?> getSelectedDate() async => DateTime(2024, 6, 15);
  @override
  Future<void> saveDossierTemplate(String template) async {}
  @override
  Future<void> saveSelectedDate(DateTime date) async {}
  @override
  Future<bool> getDailyBriefingEnabled() async => false;
  @override
  Future<TimeOfDay> getDailyBriefingTime() async => const TimeOfDay(hour: 9, minute: 0);
  @override
  Future<void> setDailyBriefingEnabled(bool enabled) async {}
  @override
  Future<void> saveDailyBriefingTime(TimeOfDay time) async {}
}

class TestTasksNotifier extends TasksNotifier {
  final List<Tarea> _initial;
  TestTasksNotifier(this._initial)
      : super(
          hiveService: HiveService(),
          notificationService: NotificationService(),
          loadOnInit: false,
        ) {
    state = _initial;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
    // We don't necessarily need to init Hive if we don't use it,
    // but the singleton exists.
    // If we needed to write to Hive, we would call HiveService().initialize().
  });

  testWidgets('AgendaScreen renders tasks for the selected date (Day View)', (WidgetTester tester) async {
    final fixedDate = DateTime(2024, 6, 15);
    final tasks = [
      Tarea(id: '1', descripcion: 'Task 1', fecha: fixedDate),
      Tarea(id: '2', descripcion: 'Task 2', fecha: fixedDate),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(MockPreferencesService()),
          selectedDateProvider.overrideWith((ref) {
            final notifier = SelectedDateNotifier(MockPreferencesService());
            notifier.state = fixedDate;
            return notifier;
          }),
          tasksProvider.overrideWith((ref) => TestTasksNotifier(tasks)),
        ],
        child: const MaterialApp(
          home: AgendaScreen(),
        ),
      ),
    );

    expect(find.text('Task 1'), findsOneWidget);
    expect(find.text('Task 2'), findsOneWidget);
    expect(find.text('No hay tareas para hoy'), findsNothing);
  });

  testWidgets('AgendaScreen renders empty state when no tasks (Day View)', (WidgetTester tester) async {
    final fixedDate = DateTime(2024, 6, 15);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(MockPreferencesService()),
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

    expect(find.text('No hay tareas para hoy'), findsOneWidget);
  });

  testWidgets('AgendaScreen renders headers in Week View', (WidgetTester tester) async {
    // 2024-06-15 is a Saturday. Week is from Mon 10 to Sun 16.
    final fixedDate = DateTime(2024, 6, 15);
    final taskDate = DateTime(2024, 6, 12); // Wednesday
    final tasks = [
      Tarea(id: '1', descripcion: 'Week Task', fecha: taskDate),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(MockPreferencesService()),
          selectedDateProvider.overrideWith((ref) {
            final notifier = SelectedDateNotifier(MockPreferencesService());
            notifier.state = fixedDate;
            return notifier;
          }),
          tasksProvider.overrideWith((ref) => TestTasksNotifier(tasks)),
          agendaViewProvider.overrideWith((ref) => AgendaViewMode.week),
        ],
        child: const MaterialApp(
          home: AgendaScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Check for task
    expect(find.text('Week Task'), findsOneWidget);
    // Check for header "miércoles, 12 jun"
    expect(find.textContaining('miércoles'), findsOneWidget);
  });
}
