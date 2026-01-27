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
}

// Custom EventsNotifier to load test dataset
class TestEventsNotifier extends EventsNotifier {
  final List<Evento> _initial;
  TestEventsNotifier(this._initial)
      : super(hiveService: HiveService(), notificationService: NotificationService(), loadOnInit: false) {
    state = _initial;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  testWidgets('CalendarScreen renders events correctly', (WidgetTester tester) async {
    // Increase screen size to avoid overflow from TableCalendar
    tester.view.physicalSize = const Size(800, 3000); // Reasonable height
    tester.view.devicePixelRatio = 1.0;

    final List<Evento> testEvents = List.generate(20, (index) {
      return Evento(
        id: 'event_$index',
        titulo: 'Event $index',
        tipo: 'bolo',
        inicio: fixedDate,
        lugar: 'Location $index',
      );
    });

    final mockPrefs = MockPreferencesService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override the service provider to inject our mock
          preferencesServiceProvider.overrideWithValue(mockPrefs),
          // Override selectedDateProvider to ensure correct initial state
          selectedDateProvider.overrideWith((ref) {
            final notifier = SelectedDateNotifier(mockPrefs);
            notifier.state = fixedDate;
            return notifier;
          }),
          // Override events
          eventsProvider.overrideWith((ref) => TestEventsNotifier(testEvents)),
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
