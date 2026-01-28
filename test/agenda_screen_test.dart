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

final fixedDate = DateTime(2024, 6, 15);

class MockPreferencesService implements PreferencesService {
  @override
  Future<String?> getDossierTemplate() async => null;
  @override
  Future<DateTime?> getSelectedDate() async => fixedDate;
  @override
  Future<void> saveDossierTemplate(String template) async {}
  @override
  Future<void> saveSelectedDate(DateTime date) async {}
  @override
  Future<bool> getDailyBriefingEnabled() async => false;
  @override
  Future<TimeOfDay> getDailyBriefingTime() async => const TimeOfDay(hour: 8, minute: 0);
  @override
  Future<void> saveDailyBriefingTime(TimeOfDay time) async {}
  @override
  Future<void> setDailyBriefingEnabled(bool enabled) async {}
}

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
    await HiveService().initialize();
  });

  testWidgets('AgendaScreen renders day tasks correctly', (WidgetTester tester) async {
    final List<Tarea> testTasks = [
        Tarea(
            id: '1',
            descripcion: 'Task Today',
            fecha: fixedDate,
            categoria: 'General'
        ),
        Tarea(
            id: '2',
            descripcion: 'Task Tomorrow',
            fecha: fixedDate.add(const Duration(days: 1)),
            categoria: 'General'
        ),
    ];

    final mockPrefs = MockPreferencesService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(mockPrefs),
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

    expect(find.byType(AgendaScreen), findsOneWidget);
    expect(find.text('Task Today'), findsOneWidget);
    expect(find.text('Task Tomorrow'), findsNothing);
  });
}
