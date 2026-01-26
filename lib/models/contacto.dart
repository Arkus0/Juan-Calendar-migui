class Contacto {
  final String id;
  final String nombre;
  final String telefono;

  Contacto({
    required this.id,
    required this.nombre,
    required this.telefono,
  });

  Contacto copyWith({
    String? id,
    String? nombre,
    String? telefono,
  }) {
    return Contacto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
    );
  }
}
