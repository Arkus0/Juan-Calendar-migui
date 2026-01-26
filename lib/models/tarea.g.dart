// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tarea.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TareaAdapter extends TypeAdapter<Tarea> {
  @override
  final int typeId = 1;

  @override
  Tarea read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tarea(
      id: fields[0] as String,
      descripcion: fields[1] as String,
      fecha: fields[3] as DateTime,
      categoria: fields[2] as String?,
      completada: fields[4] as bool,
      recurrence: fields[5] as RecurrenceRule?,
      parentId: fields[6] as String?,
      isRecurringInstance: fields[7] as bool,
      reminders: (fields[8] as List?)?.cast<int>() ?? const [],
      hora: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Tarea obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.descripcion)
      ..writeByte(2)
      ..write(obj.categoria)
      ..writeByte(3)
      ..write(obj.fecha)
      ..writeByte(4)
      ..write(obj.completada)
      ..writeByte(5)
      ..write(obj.recurrence)
      ..writeByte(6)
      ..write(obj.parentId)
      ..writeByte(7)
      ..write(obj.isRecurringInstance)
      ..writeByte(8)
      ..write(obj.reminders)
      ..writeByte(9)
      ..write(obj.hora);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TareaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
