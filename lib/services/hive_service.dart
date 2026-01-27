import 'dart:io';
import 'package:hive_flutter_io/hive_flutter_io.dart';
import '../models/evento.dart';
import '../models/tarea.dart';
import '../models/contacto.dart';
import '../models/recurrence_rule.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static const String eventosBox = 'eventos';
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
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TareaAdapter());
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
    await Hive.openBox<Tarea>(tareasBox);
    await Hive.openBox<Contacto>(contactosBox);

    _initialized = true;
  }

  /// Obtiene la caja de eventos
  Box<Evento> get eventosBoxInstance => Hive.box<Evento>(eventosBox);

  /// Obtiene la caja de tareas
  Box<Tarea> get tareasBoxInstance => Hive.box<Tarea>(tareasBox);

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

  /// Guarda o actualiza una tarea
  Future<void> saveTarea(Tarea tarea) async {
    await tareasBoxInstance.put(tarea.id, tarea);
  }

  /// Obtiene todas las tareas (incluyendo instancias recurrentes generadas)
  List<Tarea> getAllTareas() {
    final tareas = tareasBoxInstance.values.toList();
    final allInstances = <Tarea>[];

    for (var tarea in tareas) {
      // Solo procesar tareas padre (no instancias)
      if (!tarea.isRecurringInstance) {
        final instances = tarea.generateRecurringInstances();
        allInstances.addAll(instances);
      }
    }

    return allInstances;
  }

  /// Obtiene una tarea por ID
  Tarea? getTarea(String id) {
    return tareasBoxInstance.get(id);
  }

  /// Elimina una tarea
  Future<void> deleteTarea(String id) async {
    await tareasBoxInstance.delete(id);
  }

  /// Obtiene tareas de un día específico
  List<Tarea> getTareasForDate(DateTime date) {
    final allTareas = getAllTareas();
    return allTareas.where((tarea) {
      return tarea.fecha.year == date.year &&
          tarea.fecha.month == date.month &&
          tarea.fecha.day == date.day;
    }).toList();
  }

  /// Obtiene tareas de una semana específica
  List<Tarea> getTareasForWeek(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final allTareas = getAllTareas();

    return allTareas.where((tarea) {
      return tarea.fecha.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          tarea.fecha.isBefore(endOfWeek);
    }).toList();
  }

  /// Obtiene tareas de un mes específico
  List<Tarea> getTareasForMonth(DateTime month) {
    final allTareas = getAllTareas();
    return allTareas.where((tarea) {
      return tarea.fecha.year == month.year && tarea.fecha.month == month.month;
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
    await tareasBoxInstance.clear();
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
      return tarea.descripcion.toLowerCase().contains(lowercaseQuery) ||
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
