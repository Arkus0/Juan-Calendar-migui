import 'dart:io';
import 'package:hive_flutter_io/hive_flutter_io.dart';
import '../models/evento.dart';
import '../models/event_type.dart';
import '../models/contacto.dart';
import '../models/recurrence_rule.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static const String eventosBox = 'eventos';
  // Deprecated: tasks are migrated into eventos box. Kept for migration step only.
  static const String tareasBox = 'tareas';
  static const String contactosBox = 'contactos';

  bool _initialized = false;

  /// Inicializa Hive y registra adapters
  Future<void> initialize() async {
    if (_initialized) return;

    // Try platform-aware init first (normal app). If it fails (tests without plugins),
    // fallback to a filesystem temp init so tests can run headless.
    try {
      await Hive.initFlutter(null);
    } catch (e) {
      // MissingPluginException or other plugin-init errors
      // Use system temp directory for tests or environments without path_provider
      Hive.init(Directory.systemTemp.createTempSync().path);
    }

    // Registrar adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EventoAdapter());
    }
    // EventType adapter (nuevo)
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(EventTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ContactoAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(RecurrenceTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(RecurrenceRuleAdapter());
    }

    // Abrir boxes
    await Hive.openBox<Evento>(eventosBox);
    await Hive.openBox<Contacto>(contactosBox);

    // Si existe una caja antigua de 'tareas' en disco, eliminarla (retiramos el modelo Tarea)
    if (await Hive.boxExists(tareasBox)) {
      try {
        await Hive.deleteBoxFromDisk(tareasBox);
      } catch (_) {
        // No bloquear inicialización si falla
      }
    }

    _initialized = true;
  }

  /// Obtiene la caja de eventos
  Box<Evento> get eventosBoxInstance => Hive.box<Evento>(eventosBox);

  /// Obtiene la caja de contactos
  Box<Contacto> get contactosBoxInstance => Hive.box<Contacto>(contactosBox);

  // ======== EVENTOS ========

  /// Guarda o actualiza un evento
  Future<void> saveEvento(Evento evento) async {
    await eventosBoxInstance.put(evento.id, evento);
  }

  /// Obtiene todos los eventos (incluyendo instancias recurrentes generadas)
  List<Evento> getAllEventos() {
    final eventos = eventosBoxInstance.values.toList();
    final allInstances = <Evento>[];

    for (var evento in eventos) {
      // Solo procesar eventos padre (no instancias)
      if (!evento.isRecurringInstance) {
        final instances = evento.generateRecurringInstances();
        allInstances.addAll(instances);
      }
    }

    return allInstances;
  }

  /// Obtiene un evento por ID
  Evento? getEvento(String id) {
    return eventosBoxInstance.get(id);
  }

  /// Elimina un evento
  Future<void> deleteEvento(String id) async {
    await eventosBoxInstance.delete(id);
  }

  /// Obtiene eventos de un día específico
  List<Evento> getEventosForDate(DateTime date) {
    final allEventos = getAllEventos();
    return allEventos.where((evento) {
      return evento.inicio.year == date.year &&
          evento.inicio.month == date.month &&
          evento.inicio.day == date.day;
    }).toList();
  }

  // ======== TAREAS ========

  /// Obtiene todas las tareas (incluyendo instancias recurrentes generadas)
  /// Ahora devuelve Eventos marcados como tareas (usa la caja `eventos`)
  List<Evento> getAllTareas() {
    final allEventos = getAllEventos();
    // Solo tareas sin fecha (hasDate == false)
    return allEventos.where((e) => e.isTask && !e.hasDate).toList();
  }

  /// Obtiene una tarea por ID (busca en eventos)
  Evento? getTarea(String id) {
    return eventosBoxInstance.get(id);
  }

  /// Elimina una tarea (delegado a eventos)
  Future<void> deleteTarea(String id) async {
    await eventosBoxInstance.delete(id);
  }

  /// Obtiene tareas de un día específico
  List<Evento> getTareasForDate(DateTime date) {
    final allTareas = getAllTareas();
    return allTareas.where((tarea) {
      return tarea.inicio.year == date.year &&
          tarea.inicio.month == date.month &&
          tarea.inicio.day == date.day;
    }).toList();
  }

  /// Obtiene tareas de una semana específica
  List<Evento> getTareasForWeek(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final allTareas = getAllTareas();

    return allTareas.where((tarea) {
      return tarea.inicio.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          tarea.inicio.isBefore(endOfWeek);
    }).toList();
  }

  /// Obtiene tareas de un mes específico
  List<Evento> getTareasForMonth(DateTime month) {
    final allTareas = getAllTareas();
    return allTareas.where((tarea) {
      return tarea.inicio.year == month.year && tarea.inicio.month == month.month;
    }).toList();
  }

  // ======== CONTACTOS ========

  /// Guarda o actualiza un contacto
  Future<void> saveContacto(Contacto contacto) async {
    await contactosBoxInstance.put(contacto.id, contacto);
  }

  /// Obtiene todos los contactos
  List<Contacto> getAllContactos() {
    return contactosBoxInstance.values.toList();
  }

  /// Obtiene un contacto por ID
  Contacto? getContacto(String id) {
    return contactosBoxInstance.get(id);
  }

  /// Elimina un contacto
  Future<void> deleteContacto(String id) async {
    await contactosBoxInstance.delete(id);
  }

  // ======== UTILIDADES ========

  /// Limpia todas las cajas (útil para reset)
  Future<void> clearAll() async {
    await eventosBoxInstance.clear();
    // Si existe una caja antigua de tareas en disco, eliminarla totalmente
    if (await Hive.boxExists(tareasBox)) {
      try {
        await Hive.deleteBoxFromDisk(tareasBox);
      } catch (_) {}
    }
    await contactosBoxInstance.clear();
  }

  /// Cierra todas las cajas
  Future<void> close() async {
    await Hive.close();
    _initialized = false;
  }



  /// Búsqueda global en eventos, tareas y contactos
  Map<String, List<dynamic>> searchAll(String query) {
    final lowercaseQuery = query.toLowerCase();

    final eventos = getAllEventos().where((evento) {
      return evento.titulo.toLowerCase().contains(lowercaseQuery) ||
          (evento.lugar?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (evento.notas?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();

    final tareas = getAllTareas().where((tarea) {
      return tarea.titulo.toLowerCase().contains(lowercaseQuery) ||
          (tarea.categoria?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();

    final contactos = getAllContactos().where((contacto) {
      return contacto.nombre.toLowerCase().contains(lowercaseQuery) ||
          contacto.telefono.contains(query) ||
          (contacto.email?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();

    return {
      'eventos': eventos,
      'tareas': tareas,
      'contactos': contactos,
    };
  }
}
