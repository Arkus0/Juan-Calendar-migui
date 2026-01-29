import 'package:flutter_test/flutter_test.dart';
import 'package:musician_organizer/services/hive_service.dart';
import 'package:musician_organizer/models/evento.dart';
import 'package:musician_organizer/models/recurrence_rule.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  late HiveService hiveService;
  const uuid = Uuid();

  setUpAll(() async {
    await initializeDateFormatting();
  });

  setUp(() async {
    hiveService = HiveService();
    await hiveService.initialize();
    await hiveService.clearAll();
  });

  tearDown(() async {
    await hiveService.clearAll();
  });

  test('searchAll returns only parent event for recurring events (optimized)', () async {
    final now = DateTime.now();

    // Create a daily event for 10 days
    final recurringEvent = Evento(
      id: uuid.v4(),
      titulo: 'Daily Practice',
      tipo: 'personal',
      inicio: now,
      fin: now.add(const Duration(hours: 1)),
      recurrence: RecurrenceRule(
        type: RecurrenceType.daily,
        interval: 1,
        count: 10,
      ),
    );

    await hiveService.saveEvento(recurringEvent);

    // Verify it generates 10 instances when using getAllEventos (normal agenda behavior)
    expect(hiveService.getAllEventos().length, 10);

    // Search for it
    final results = hiveService.searchAll('Practice');
    final eventos = results['eventos'] as List<dynamic>;

    // Optimized behavior: returns 1 item (the parent event)
    // This confirms that searchAll avoids recurrence expansion, reducing complexity from O(N*Instances) to O(N).
    expect(eventos.length, 1);
  });
}
