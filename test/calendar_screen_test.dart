import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musician_organizer/models/evento.dart';
import 'package:musician_organizer/models/tarea.dart';
import 'package:musician_organizer/models/contacto.dart';
import 'package:musician_organizer/providers/app_providers.dart';
import 'package:musician_organizer/providers/data_providers.dart';
import 'package:musician_organizer/providers/settings_provider.dart';
import 'package:musician_organizer/screens/calendar_screen.dart';
import 'package:musician_organizer/services/preferences_service.dart';
import 'package:musician_organizer/services/hive_service.dart';
import 'package:musician_organizer/services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

class MockHiveService implements HiveService {
  final List<Evento> events;

  MockHiveService({this.events = const []});

  @override
  List<Evento> getAllEventos() => events;

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> close() async {}

  @override
  Box<Contacto> get contactosBoxInstance => throw UnimplementedError();

  @override
  Future<void> deleteContacto(String id) async {}

  @override
  Future<void> deleteEvento(String id) async {}

  @override
  Future<void> deleteTarea(String id) async {}

  @override
  Box<Evento> get eventosBoxInstance => throw UnimplementedError();

  @override
  List<Contacto> getAllContactos() => [];

  @override
  List<Tarea> getAllTareas() => [];

  @override
  Contacto? getContacto(String id) => null;

  @override
  Evento? getEvento(String id) => null;

  @override
  List<Evento> getEventosForDate(DateTime date) => [];

  @override
  Tarea? getTarea(String id) => null;

  @override
  List<Tarea> getTareasForDate(DateTime date) => [];

  @override
  List<Tarea> getTareasForMonth(DateTime month) => [];

  @override
  List<Tarea> getTareasForWeek(DateTime startOfWeek) => [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveContacto(Contacto contacto) async {}

  @override
  Future<void> saveEvento(Evento evento) async {}

  @override
  Future<void> saveTarea(Tarea tarea) async {}

  @override
  Map<String, List> searchAll(String query) => {};

  @override
  Box<Tarea> get tareasBoxInstance => throw UnimplementedError();
}

class MockNotificationService implements NotificationService {
  @override
  Future<void> cancelAllNotifications() async {}

  @override
  Future<void> cancelEventNotifications(String eventId) async {}

  @override
  Future<void> cancelTaskNotifications(String taskId) async {}

  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async => [];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> scheduleEventNotifications(Evento evento) async {}

  @override
  Future<void> scheduleTaskNotifications(Tarea tarea) async {}

  @override
  Future<void> showImmediateNotification({required String title, required String body}) async {}
}

// Custom EventsNotifier to load test dataset
class TestEventsNotifier extends EventsNotifier {
  TestEventsNotifier(List<Evento> initial)
      : super(
          hiveService: MockHiveService(events: initial),
          notificationService: MockNotificationService(),
        ) {
    // state is set by super constructor via _loadData -> getAllEventos
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
