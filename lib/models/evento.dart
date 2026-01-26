class Evento {
  final String id;
  final String titulo;
  final String tipo; // 'bolo', 'reunion', 'personal'
  final DateTime inicio;
  final DateTime? fin;
  final String? lugar;
  final String? notas;

  Evento({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.inicio,
    this.fin,
    this.lugar,
    this.notas,
  });

  Evento copyWith({
    String? id,
    String? titulo,
    String? tipo,
    DateTime? inicio,
    DateTime? fin,
    String? lugar,
    String? notas,
  }) {
    return Evento(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      tipo: tipo ?? this.tipo,
      inicio: inicio ?? this.inicio,
      fin: fin ?? this.fin,
      lugar: lugar ?? this.lugar,
      notas: notas ?? this.notas,
    );
  }
}
