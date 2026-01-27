import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter_io/hive_flutter_io.dart';
import 'package:musician_organizer/services/hive_service.dart';

void main() {
  group('HiveService - tareas box removal', () {
    late Directory tmpDir;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync();
      Hive.init(tmpDir.path);
    });

    tearDown(() async {
      try {
        await Hive.close();
        if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('removes old tareas box from disk during initialize', () async {
      // Create a raw box named 'tareas' with a simple value (no adapter)
      final rawBox = await Hive.openBox('tareas');
      await rawBox.put('dummy', 'value');
      await rawBox.flush();
      await rawBox.close();

      final hiveService = HiveService();
      await hiveService.initialize();

      // After initialize the old box should be deleted from disk (and not open)
      expect(Hive.isBoxOpen('tareas'), isFalse);
    });
  });
}
