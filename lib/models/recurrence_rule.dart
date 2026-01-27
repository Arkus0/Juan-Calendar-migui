import 'package:hive_io/hive_io.dart';

part 'recurrence_rule.g.dart';

@HiveType(typeId: 3)
enum RecurrenceType {
  @HiveField(0)
  none,
  @HiveField(1)
  daily,
  @HiveField(2)
  weekly,
  @HiveField(3)
  monthly,
  @HiveField(4)
  custom,
}

@HiveType(typeId: 4)
class RecurrenceRule {
  @HiveField(0)
  final RecurrenceType type;

  @HiveField(1)
  final int? interval; // Cada N días/semanas/meses

  @HiveField(2)
  final DateTime? endDate; // Fecha fin de recurrencia

  @HiveField(3)
  final int? count; // Número de repeticiones

  @HiveField(4)
  final List<int>? weekdays; // Para semanal: [1=Lun, 2=Mar, ..., 7=Dom]

  @HiveField(5)
  final int? monthDay; // Para mensual: día del mes (1-31)

  RecurrenceRule({
    required this.type,
    this.interval = 1,
    this.endDate,
    this.count,
    this.weekdays,
    this.monthDay,
  });

  RecurrenceRule copyWith({
    RecurrenceType? type,
    int? interval,
    DateTime? endDate,
    int? count,
    List<int>? weekdays,
    int? monthDay,
  }) {
    return RecurrenceRule(
      type: type ?? this.type,
      interval: interval ?? this.interval,
      endDate: endDate ?? this.endDate,
      count: count ?? this.count,
      weekdays: weekdays ?? this.weekdays,
      monthDay: monthDay ?? this.monthDay,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'interval': interval,
      'endDate': endDate?.toIso8601String(),
      'count': count,
      'weekdays': weekdays,
      'monthDay': monthDay,
    };
  }

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      type: RecurrenceType.values[json['type'] as int],
      interval: json['interval'] as int?,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      count: json['count'] as int?,
      weekdays: (json['weekdays'] as List<dynamic>?)?.cast<int>(),
      monthDay: json['monthDay'] as int?,
    );
  }

  String getDisplayText() {
    switch (type) {
      case RecurrenceType.none:
        return 'No se repite';
      case RecurrenceType.daily:
        return interval == 1 ? 'Diariamente' : 'Cada $interval días';
      case RecurrenceType.weekly:
        if (interval == 1) {
          return 'Semanalmente';
        } else {
          return 'Cada $interval semanas';
        }
      case RecurrenceType.monthly:
        return interval == 1 ? 'Mensualmente' : 'Cada $interval meses';
      case RecurrenceType.custom:
        return 'Personalizado';
    }
  }

  /// Genera las próximas fechas de ocurrencia basadas en esta regla
  List<DateTime> generateOccurrences(DateTime startDate, {int maxCount = 365}) {
    if (type == RecurrenceType.none) return [startDate];

    final occurrences = <DateTime>[startDate];
    var current = startDate;
    final limit = count ?? maxCount;

    for (var i = 1; i < limit; i++) {
      switch (type) {
        case RecurrenceType.daily:
          current = DateTime(
            current.year,
            current.month,
            current.day + (interval ?? 1),
            current.hour,
            current.minute,
          );
          break;
        case RecurrenceType.weekly:
          current = DateTime(
            current.year,
            current.month,
            current.day + (7 * (interval ?? 1)),
            current.hour,
            current.minute,
          );
          break;
        case RecurrenceType.monthly:
          var newMonth = current.month + (interval ?? 1);
          var newYear = current.year;
          while (newMonth > 12) {
            newMonth -= 12;
            newYear++;
          }
          current = DateTime(
            newYear,
            newMonth,
            current.day,
            current.hour,
            current.minute,
          );
          break;
        default:
          break;
      }

      if (endDate != null && current.isAfter(endDate!)) break;
      occurrences.add(current);
    }

    return occurrences;
  }
}
