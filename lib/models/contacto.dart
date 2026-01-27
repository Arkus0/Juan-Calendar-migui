import 'package:hive_io/hive_io.dart';

part 'contacto.g.dart';

@HiveType(typeId: 2)
class Contacto extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String nombre;

  @HiveField(2)
  final String telefono;

  @HiveField(3)
  final String? email;

  @HiveField(4)
  final String? notas;

  Contacto({
    required this.id,
    required this.nombre,
    required this.telefono,
    this.email,
    this.notas,
  });

  Contacto copyWith({
    String? id,
    String? nombre,
    String? telefono,
    String? email,
    String? notas,
  }) {
    return Contacto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      notas: notas ?? this.notas,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'notas': notas,
    };
  }

  factory Contacto.fromJson(Map<String, dynamic> json) {
    return Contacto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String,
      email: json['email'] as String?,
      notas: json['notas'] as String?,
    );
  }
}
