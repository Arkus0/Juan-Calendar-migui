import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:musician_organizer/models/tarea.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });

  test('Benchmark DateFormat instantiation in loop', () {
    // 1. Setup Data
    final now = DateTime.now();
    final List<Tarea> tasks = List.generate(10000, (index) {
      return Tarea(
        id: 'task_$index',
        descripcion: 'Description $index',
        fecha: now.add(Duration(hours: index % 168)), // Spread over a week
      );
    });

    // 2. Original Implementation
    final stopwatchOriginal = Stopwatch()..start();
    Map<String, List<Tarea>> groupedOriginal = {};
    for (var t in tasks) {
      final dateStr = DateFormat('EEEE, d MMM', 'es').format(t.fecha);
      groupedOriginal.putIfAbsent(dateStr, () => []).add(t);
    }
    stopwatchOriginal.stop();
    print('Original Implementation Time: ${stopwatchOriginal.elapsedMicroseconds} µs');

    // 3. Optimized Implementation
    final stopwatchOptimized = Stopwatch()..start();
    Map<String, List<Tarea>> groupedOptimized = {};
    final dateFormat = DateFormat('EEEE, d MMM', 'es'); // Instantiated once
    for (var t in tasks) {
      final dateStr = dateFormat.format(t.fecha);
      groupedOptimized.putIfAbsent(dateStr, () => []).add(t);
    }
    stopwatchOptimized.stop();
    print('Optimized Implementation Time: ${stopwatchOptimized.elapsedMicroseconds} µs');

    // 4. Verification
    expect(groupedOriginal.keys.length, groupedOptimized.keys.length);
    for (var key in groupedOriginal.keys) {
      expect(groupedOriginal[key]!.length, groupedOptimized[key]!.length);
    }

    // Expect optimization to be faster
    expect(stopwatchOptimized.elapsedMicroseconds, lessThan(stopwatchOriginal.elapsedMicroseconds));
  });
}
