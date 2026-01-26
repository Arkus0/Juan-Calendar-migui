class Tarea {
  final String id;
  final String descripcion;
  final String? categoria;
  final DateTime fecha;
  final bool completada;

  Tarea({
    required this.id,
    required this.descripcion,
    required this.fecha,
    this.categoria,
    this.completada = false,
  });

  Tarea copyWith({
    String? id,
    String? descripcion,
    String? categoria,
    DateTime? fecha,
    bool? completada,
  }) {
    return Tarea(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      fecha: fecha ?? this.fecha,
      completada: completada ?? this.completada,
    );
  }
}
