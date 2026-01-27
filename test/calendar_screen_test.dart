import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musician_organizer/models/evento.dart';
import 'package:musician_organizer/providers/app_providers.dart';
import 'package:musician_organizer/providers/data_providers.dart';
import 'package:musician_organizer/providers/settings_provider.dart';
import 'package:musician_organizer/screens/calendar_screen.dart';
import 'package:musician_organizer/services/preferences_service.dart';
import 'package:musician_organizer/services/hive_service.dart';
import 'package:musician_organizer/models/event_type.dart';
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

  // New briefing preference APIs (added in PreferencesService)
  @override
  Future<bool> getDailyBriefingEnabled() async => false;
  @override
  Future<TimeOfDay> getDailyBriefingTime() async => const TimeOfDay(hour: 8, minute: 0);
  @override
  Future<void> saveDailyBriefingTime(TimeOfDay time) async {}
  @override
  Future<void> setDailyBriefingEnabled(bool enabled) async {}

  // Dossier attachments (mock)
  @override
  Future<void> saveDossierFiles(List<String> files) async {}
  @override
  Future<List<String>> getDossierFiles() async => <String>[];
}

// Custom EventsNotifier to load test dataset
class TestEventsNotifier extends EventsNotifier {
  @override
  List<Evento> build() {
    return [];
  }

  // Helper to set test data from the test override
  void setInitial(List<Evento> initial) {
    state = initial;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    // Initialize Hive for tests
    await HiveService().initialize();
  });

  testWidgets('CalendarScreen renders events correctly', (WidgetTester tester) async {
    // Increase screen size to avoid overflow from TableCalendar
    tester.view.physicalSize = const Size(800, 3000); // Reasonable height
    tester.view.devicePixelRatio = 1.0;

    final List<Evento> testEvents = List.generate(20, (index) {
      return Evento(
        id: 'event_$index',
        titulo: 'Event $index',
        tipo: EventType.bolo,
        inicio: fixedDate,
        lugar: 'Location $index',
      );
    });

    final mockPrefs = MockPreferencesService();

    // Ensure Hive contains our test events
    final hive = HiveService();
    await hive.clearAll();
    for (var e in testEvents) {
      await hive.saveEvento(e);
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override the service provider to inject our mock
          preferencesServiceProvider.overrideWithValue(mockPrefs),
          // Ensure SelectedDate has the correct initial state
          selectedDateProvider.overrideWith(() {
            final notifier = SelectedDateNotifier();
            notifier.state = fixedDate;
            return notifier;
          }),
          // Populate Hive with our test events so the real HiveService returns them
          // (HiveService is a singleton used by the provider)
        ],
        child: const MaterialApp(
          home: CalendarScreen(),
        ),
      ),
    );

    // Ensure all frame callbacks are done
    await tester.pumpAndSettle();

    // Verification
    expect(find.byType(CalendarScreen), findsOneWidget);

    // Check content
    expect(find.text('Event 0'), findsOneWidget);
    expect(find.text('Event 19'), findsOneWidget);

    // Cleanup
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
