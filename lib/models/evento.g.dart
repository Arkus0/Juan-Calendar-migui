// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evento.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventoAdapter extends TypeAdapter<Evento> {
  @override
  final int typeId = 0;

  @override
  Evento read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Evento(
      id: fields[0] as String,
      titulo: fields[1] as String,
      tipo: fields[2] as String,
      inicio: fields[3] as DateTime,
      fin: fields[4] as DateTime?,
      lugar: fields[5] as String?,
      notas: fields[6] as String?,
      cache: fields[7] as double?,
      setlist: fields[8] as String?,
      rider: fields[9] as String?,
      recurrence: fields[10] as RecurrenceRule?,
      parentId: fields[11] as String?,
      isRecurringInstance: fields[12] as bool,
      reminders: (fields[13] as List?)?.cast<int>() ?? const [],
    );
  }

  @override
  void write(BinaryWriter writer, Evento obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.titulo)
      ..writeByte(2)
      ..write(obj.tipo)
      ..writeByte(3)
      ..write(obj.inicio)
      ..writeByte(4)
      ..write(obj.fin)
      ..writeByte(5)
      ..write(obj.lugar)
      ..writeByte(6)
      ..write(obj.notas)
      ..writeByte(7)
      ..write(obj.cache)
      ..writeByte(8)
      ..write(obj.setlist)
      ..writeByte(9)
      ..write(obj.rider)
      ..writeByte(10)
      ..write(obj.recurrence)
      ..writeByte(11)
      ..write(obj.parentId)
      ..writeByte(12)
      ..write(obj.isRecurringInstance)
      ..writeByte(13)
      ..write(obj.reminders);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
