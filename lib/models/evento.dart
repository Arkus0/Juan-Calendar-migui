import 'package:hive_io/hive_io.dart';
import 'recurrence_rule.dart';
import 'event_type.dart';

part 'evento.g.dart';

@HiveType(typeId: 0)
class Evento extends HiveObject {
    @HiveField(18)
    final List<String>? contactos; // IDs o nombres de contactos asociados
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String titulo;

  @HiveField(2)
  final EventType tipo; // EventType: bolo, reunion, personal, clases, laboral

  @HiveField(3)
  final DateTime inicio;

  @HiveField(4)
  final DateTime? fin;

  @HiveField(5)
  final String? lugar;

  @HiveField(6)
  final String? notas;

  // Campos específicos para bolos
  @HiveField(7)
  final double? cache; // Caché del bolo

  @HiveField(8)
  final String? setlist; // Setlist de canciones

  @HiveField(9)
  final String? rider; // Rider técnico/hospitalidad

  // Recurrencia
  @HiveField(10)
  final RecurrenceRule? recurrence;

  @HiveField(11)
  final String? parentId; // ID del evento padre si es una instancia recurrente

  @HiveField(12)
  final bool isRecurringInstance; // Si es una instancia de un evento recurrente

  // Recordatorios (en minutos antes del evento)
  @HiveField(13)
  final List<int> reminders; // ej. [60, 1440] = 1 hora antes, 1 día antes

  // Campos para tareas ahora fusionadas en Evento
  @HiveField(14)
  final bool completada; // Solo relevante si isTask == true

  @HiveField(15)
  final String? categoria; // Categoría para tareas (ej. Gestión, Marketing)

  @HiveField(16)
  final bool isTask; // Indica si este evento representa una tarea

  @HiveField(17)
  final bool hasDate; // Si false => tarea en backlog (sin fecha)

  Evento({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.inicio,
    this.fin,
    this.lugar,
    this.notas,
    this.cache,
    this.setlist,
    this.rider,
    this.recurrence,
    this.parentId,
    this.isRecurringInstance = false,
    this.reminders = const [],
    this.completada = false,
    this.categoria,
    this.isTask = false,
    this.hasDate = true,
    this.contactos,
  });

  Evento copyWith({
    String? id,
    String? titulo,
    EventType? tipo,
    DateTime? inicio,
    DateTime? fin,
    String? lugar,
    String? notas,
    double? cache,
    String? setlist,
    String? rider,
    RecurrenceRule? recurrence,
    String? parentId,
    bool? isRecurringInstance,
    List<int>? reminders,
    bool? completada,
    String? categoria,
    bool? isTask,
    bool? hasDate,
    List<String>? contactos,
  }) {
    return Evento(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      tipo: tipo ?? this.tipo,
      inicio: inicio ?? this.inicio,
      fin: fin ?? this.fin,
      lugar: lugar ?? this.lugar,
      notas: notas ?? this.notas,
      cache: cache ?? this.cache,
      setlist: setlist ?? this.setlist,
      rider: rider ?? this.rider,
      recurrence: recurrence ?? this.recurrence,
      parentId: parentId ?? this.parentId,
      isRecurringInstance: isRecurringInstance ?? this.isRecurringInstance,
      reminders: reminders ?? this.reminders,
      completada: completada ?? this.completada,
      categoria: categoria ?? this.categoria,
      isTask: isTask ?? this.isTask,
      hasDate: hasDate ?? this.hasDate,
      contactos: contactos ?? this.contactos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'tipo': tipo.nameLower,
      'inicio': inicio.toIso8601String(),
      'fin': fin?.toIso8601String(),
      'lugar': lugar,
      'notas': notas,
      'cache': cache,
      'setlist': setlist,
      'rider': rider,
      'recurrence': recurrence?.toJson(),
      'parentId': parentId,
      'isRecurringInstance': isRecurringInstance,
      'reminders': reminders,
      'completada': completada,
      'categoria': categoria,
      'isTask': isTask,
      'hasDate': hasDate,
      'contactos': contactos,
    };
  }

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      tipo: json['tipo'] is String ? eventTypeFromString(json['tipo'] as String) : (json['tipo'] is int ? EventType.values[json['tipo'] as int] : EventType.personal),
      inicio: DateTime.parse(json['inicio'] as String),
      fin: json['fin'] != null ? DateTime.parse(json['fin'] as String) : null,
      lugar: json['lugar'] as String?,
      notas: json['notas'] as String?,
      cache: json['cache'] as double?,
      setlist: json['setlist'] as String?,
      rider: json['rider'] as String?,
      recurrence: json['recurrence'] != null
          ? RecurrenceRule.fromJson(json['recurrence'] as Map<String, dynamic>)
          : null,
      parentId: json['parentId'] as String?,
      isRecurringInstance: json['isRecurringInstance'] as bool? ?? false,
      reminders: (json['reminders'] as List<dynamic>?)?.cast<int>() ?? [],
      completada: json['completada'] as bool? ?? false,
      categoria: json['categoria'] as String?,
      isTask: json['isTask'] as bool? ?? false,
      hasDate: json['hasDate'] as bool? ?? true,
      contactos: (json['contactos'] as List<dynamic>?)?.cast<String>(),
    );
  }

  /// Genera instancias recurrentes basadas en la regla de recurrencia
  List<Evento> generateRecurringInstances() {
    if (recurrence == null || recurrence!.type == RecurrenceType.none) {
      return [this];
    }

    final occurrences = recurrence!.generateOccurrences(inicio);
    final instances = <Evento>[];

    for (var i = 0; i < occurrences.length; i++) {
      if (i == 0) {
        instances.add(this);
      } else {
        final occurrence = occurrences[i];
        final duration = fin?.difference(inicio);

        instances.add(
          copyWith(
            id: '$id-instance-$i',
            inicio: occurrence,
            fin: duration != null ? occurrence.add(duration) : null,
            parentId: id,
            isRecurringInstance: true,
          ),
        );
      }
    }

    return instances;
  }

  bool get isBolo => tipo == EventType.bolo;
  bool get isReunion => tipo == EventType.reunion;
  bool get isPersonal => tipo == EventType.personal;
}
