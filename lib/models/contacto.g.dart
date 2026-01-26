// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contacto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContactoAdapter extends TypeAdapter<Contacto> {
  @override
  final int typeId = 2;

  @override
  Contacto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Contacto(
      id: fields[0] as String,
      nombre: fields[1] as String,
      telefono: fields[2] as String,
      email: fields[3] as String?,
      notas: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Contacto obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.telefono)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.notas);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
