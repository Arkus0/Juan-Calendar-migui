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

  @override
  Future<bool> getDailyBriefingEnabled() async => false;
  @override
  Future<TimeOfDay> getDailyBriefingTime() async => const TimeOfDay(hour: 8, minute: 0);
  @override
  Future<void> saveDailyBriefingTime(TimeOfDay time) async {}
  @override
  Future<void> setDailyBriefingEnabled(bool enabled) async {}
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
    // Initialize Hive for tests
    await HiveService().initialize();
  });

  testWidgets('AgendaScreen renders tasks correctly', (WidgetTester tester) async {
    // Increase screen size
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;

    final List<Tarea> testTasks = List.generate(20, (index) {
      return Tarea(
        id: 'task_$index',
        descripcion: 'Task $index',
        fecha: fixedDate,
      );
    });

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
        ],
        child: const MaterialApp(
          home: AgendaScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AgendaScreen), findsOneWidget);
    expect(find.text('Task 0'), findsOneWidget);
    expect(find.text('Task 19'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
