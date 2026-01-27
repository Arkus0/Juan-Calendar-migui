import 'package:hive_io/hive_io.dart';

/// Enum para tipos de evento
enum EventType {
  bolo,
  reunion,
  personal,
  clases,
  laboral,
}

extension EventTypeDisplay on EventType {
  String get nameLower => toString().split('.').last;

  String get displayName {
    switch (this) {
      case EventType.bolo:
        return 'Bolo';
      case EventType.reunion:
        return 'Reunión';
      case EventType.personal:
        return 'Personal';
      case EventType.clases:
        return 'Clases';
      case EventType.laboral:
        return 'Laboral';
    }
  }

}

EventType eventTypeFromString(String s) {
  return EventType.values.firstWhere(
    (e) => e.nameLower == s.toLowerCase(),
    orElse: () => EventType.personal,
  );
}

/// Hive TypeAdapter para EventType
class EventTypeAdapter extends TypeAdapter<EventType> {
  @override
  final int typeId = 5;

  @override
  EventType read(BinaryReader reader) {
    final index = reader.readByte();
    return EventType.values[index];
  }

  @override
  void write(BinaryWriter writer, EventType obj) {
    writer.writeByte(obj.index);
  }
}
