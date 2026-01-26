import 'package:hive/hive.dart';
import 'recurrence_rule.dart';

part 'tarea.g.dart';

@HiveType(typeId: 1)
class Tarea extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String descripcion;

  @HiveField(2)
  final String? categoria;

  @HiveField(3)
  final DateTime fecha;

  @HiveField(4)
  final bool completada;

  // Recurrencia
  @HiveField(5)
  final RecurrenceRule? recurrence;

  @HiveField(6)
  final String? parentId; // ID de la tarea padre si es una instancia recurrente

  @HiveField(7)
  final bool isRecurringInstance; // Si es una instancia de una tarea recurrente

  // Recordatorios (en minutos antes de la fecha)
  @HiveField(8)
  final List<int> reminders; // ej. [60, 1440] = 1 hora antes, 1 día antes

  @HiveField(9)
  final DateTime? hora; // Hora específica para la tarea (opcional)

  Tarea({
    required this.id,
    required this.descripcion,
    required this.fecha,
    this.categoria,
    this.completada = false,
    this.recurrence,
    this.parentId,
    this.isRecurringInstance = false,
    this.reminders = const [],
    this.hora,
  });

  Tarea copyWith({
    String? id,
    String? descripcion,
    String? categoria,
    DateTime? fecha,
    bool? completada,
    RecurrenceRule? recurrence,
    String? parentId,
    bool? isRecurringInstance,
    List<int>? reminders,
    DateTime? hora,
  }) {
    return Tarea(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      fecha: fecha ?? this.fecha,
      completada: completada ?? this.completada,
      recurrence: recurrence ?? this.recurrence,
      parentId: parentId ?? this.parentId,
      isRecurringInstance: isRecurringInstance ?? this.isRecurringInstance,
      reminders: reminders ?? this.reminders,
      hora: hora ?? this.hora,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descripcion': descripcion,
      'categoria': categoria,
      'fecha': fecha.toIso8601String(),
      'completada': completada,
      'recurrence': recurrence?.toJson(),
      'parentId': parentId,
      'isRecurringInstance': isRecurringInstance,
      'reminders': reminders,
      'hora': hora?.toIso8601String(),
    };
  }

  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      id: json['id'] as String,
      descripcion: json['descripcion'] as String,
      categoria: json['categoria'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
      completada: json['completada'] as bool? ?? false,
      recurrence: json['recurrence'] != null
          ? RecurrenceRule.fromJson(json['recurrence'] as Map<String, dynamic>)
          : null,
      parentId: json['parentId'] as String?,
      isRecurringInstance: json['isRecurringInstance'] as bool? ?? false,
      reminders: (json['reminders'] as List<dynamic>?)?.cast<int>() ?? [],
      hora: json['hora'] != null ? DateTime.parse(json['hora'] as String) : null,
    );
  }

  /// Genera instancias recurrentes basadas en la regla de recurrencia
  List<Tarea> generateRecurringInstances() {
    if (recurrence == null || recurrence!.type == RecurrenceType.none) {
      return [this];
    }

    final occurrences = recurrence!.generateOccurrences(fecha);
    final instances = <Tarea>[];

    for (var i = 0; i < occurrences.length; i++) {
      if (i == 0) {
        instances.add(this);
      } else {
        final occurrence = occurrences[i];

        instances.add(
          copyWith(
            id: '$id-instance-$i',
            fecha: occurrence,
            hora: hora != null
                ? DateTime(
                    occurrence.year,
                    occurrence.month,
                    occurrence.day,
                    hora!.hour,
                    hora!.minute,
                  )
                : null,
            parentId: id,
            isRecurringInstance: true,
            completada: false, // Las instancias nuevas no están completadas
          ),
        );
      }
    }

    return instances;
  }

  DateTime get fechaCompleta {
    if (hora != null) {
      return DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora!.hour,
        hora!.minute,
      );
    }
    return fecha;
  }
}
