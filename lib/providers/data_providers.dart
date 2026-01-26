import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/evento.dart';
import '../models/tarea.dart';
import '../models/contacto.dart';
import '../models/recurrence_rule.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

const _uuid = Uuid();

// --- Eventos ---

class EventsNotifier extends StateNotifier<List<Evento>> {
  final HiveService _hiveService = HiveService();
  final NotificationService _notificationService = NotificationService();

  EventsNotifier() : super([]) {
    _loadData();
  }

  Future<void> _loadData() async {
    // Cargar eventos desde Hive
    final eventos = _hiveService.getAllEventos();

    if (eventos.isEmpty) {
      // Si no hay eventos, cargar datos de ejemplo
      await _loadDummyData();
    } else {
      state = eventos;
    }
  }

  Future<void> _loadDummyData() async {
    final now = DateTime.now();
    final dummyEventos = [
      Evento(
        id: _uuid.v4(),
        titulo: 'Concierto en Sala X',
        tipo: 'bolo',
        inicio: now.add(const Duration(days: 2, hours: 20)),
        fin: now.add(const Duration(days: 2, hours: 23)),
        lugar: 'Sala X, Sevilla',
        notas: 'Llevar guitarra acústica extra. Setlist: Rock español clásico.',
        cache: 500.0,
        setlist: '1. Entre dos tierras\n2. La chispa adecuada\n3. Maldito duende\n4. Por la cara\n5. Se acabó',
        rider: 'Rider técnico:\n- 2 micrófonos SM58\n- Amplificador Fender\n- Monitor de retorno\n\nHospitalidad:\n- 6 cervezas\n- Agua y refrescos\n- Bocadillos',
        reminders: [60, 1440], // 1 hora y 1 día antes
      ),
      Evento(
        id: _uuid.v4(),
        titulo: 'Reunión con Manager',
        tipo: 'reunion',
        inicio: now.add(const Duration(days: 1, hours: 10)),
        fin: now.add(const Duration(days: 1, hours: 12)),
        lugar: 'Cafetería Central, Calle Sierpes 15, Sevilla',
        reminders: [30, 120], // 30 min y 2 horas antes
      ),
      Evento(
        id: _uuid.v4(),
        titulo: 'Cena familiar',
        tipo: 'personal',
        inicio: now.add(const Duration(days: 5, hours: 21)),
        reminders: [60], // 1 hora antes
      ),
      Evento(
        id: _uuid.v4(),
        titulo: 'Festival Indie Andaluz',
        tipo: 'bolo',
        inicio: now.add(const Duration(days: 15, hours: 18)),
        fin: now.add(const Duration(days: 15, hours: 20)),
        lugar: 'Recinto Ferial, Dos Hermanas',
        cache: 1200.0,
        notas: 'Compartir cartel con otros 5 grupos. Llevar merchandising.',
        reminders: [60, 1440, 10080], // 1 hora, 1 día y 1 semana antes
      ),
      Evento(
        id: _uuid.v4(),
        titulo: 'Ensayo semanal',
        tipo: 'personal',
        inicio: now.add(const Duration(days: 3, hours: 19)),
        fin: now.add(const Duration(days: 3, hours: 22)),
        lugar: 'Local de ensayo, Triana',
        recurrence: RecurrenceRule(
          type: RecurrenceType.weekly,
          interval: 1,
          count: 12, // 12 semanas
        ),
        reminders: [120], // 2 horas antes
      ),
    ];

    for (var evento in dummyEventos) {
      await _hiveService.saveEvento(evento);
      await _notificationService.scheduleEventNotifications(evento);
    }

    state = _hiveService.getAllEventos();
  }

  Future<void> addEvento(Evento evento) async {
    await _hiveService.saveEvento(evento);
    await _notificationService.scheduleEventNotifications(evento);
    state = _hiveService.getAllEventos();
  }

  Future<void> updateEvento(Evento evento) async {
    await _hiveService.saveEvento(evento);
    await _notificationService.scheduleEventNotifications(evento);
    state = _hiveService.getAllEventos();
  }

  Future<void> deleteEvento(String id) async {
    await _notificationService.cancelEventNotifications(id);
    await _hiveService.deleteEvento(id);
    state = _hiveService.getAllEventos();
  }

  void refresh() {
    state = _hiveService.getAllEventos();
  }
}

final eventsProvider = StateNotifierProvider<EventsNotifier, List<Evento>>((ref) {
  return EventsNotifier();
});

// --- Tareas ---

class TasksNotifier extends StateNotifier<List<Tarea>> {
  final HiveService _hiveService = HiveService();
  final NotificationService _notificationService = NotificationService();

  TasksNotifier() : super([]) {
    _loadData();
  }

  Future<void> _loadData() async {
    // Cargar tareas desde Hive
    final tareas = _hiveService.getAllTareas();

    if (tareas.isEmpty) {
      // Si no hay tareas, cargar datos de ejemplo
      await _loadDummyData();
    } else {
      state = tareas;
    }
  }

  Future<void> _loadDummyData() async {
    final now = DateTime.now();
    final dummyTareas = [
      Tarea(
        id: _uuid.v4(),
        descripcion: 'Llamar al promotor del festival',
        fecha: now,
        categoria: 'Gestión',
        hora: DateTime(now.year, now.month, now.day, 11, 0),
        reminders: [30, 120], // 30 min y 2 horas antes
      ),
      Tarea(
        id: _uuid.v4(),
        descripcion: 'Publicar reel en Instagram',
        fecha: now,
        categoria: 'Marketing',
        reminders: [60], // 1 hora antes
      ),
      Tarea(
        id: _uuid.v4(),
        descripcion: 'Comprar cuerdas nuevas',
        fecha: now.add(const Duration(days: 1)),
        categoria: 'Equipo',
        reminders: [1440], // 1 día antes
      ),
      Tarea(
        id: _uuid.v4(),
        descripcion: 'Revisar contrato discográfica',
        fecha: now.add(const Duration(days: 3)),
        categoria: 'Legal',
        reminders: [60, 2880], // 1 hora y 2 días antes
      ),
      Tarea(
        id: _uuid.v4(),
        descripcion: 'Mantenimiento guitarra',
        fecha: now.add(const Duration(days: 7)),
        categoria: 'Equipo',
        recurrence: RecurrenceRule(
          type: RecurrenceType.monthly,
          interval: 1,
          count: 6, // 6 meses
        ),
        reminders: [1440], // 1 día antes
      ),
    ];

    for (var tarea in dummyTareas) {
      await _hiveService.saveTarea(tarea);
      await _notificationService.scheduleTaskNotifications(tarea);
    }

    state = _hiveService.getAllTareas();
  }

  Future<void> addTarea(Tarea tarea) async {
    await _hiveService.saveTarea(tarea);
    await _notificationService.scheduleTaskNotifications(tarea);
    state = _hiveService.getAllTareas();
  }

  Future<void> toggleTarea(String id) async {
    final tarea = _hiveService.getTarea(id);
    if (tarea != null) {
      final updated = tarea.copyWith(completada: !tarea.completada);
      await _hiveService.saveTarea(updated);

      // Si se completa, cancelar notificaciones
      if (updated.completada) {
        await _notificationService.cancelTaskNotifications(id);
      } else {
        // Si se marca como no completada, reprogramar notificaciones
        await _notificationService.scheduleTaskNotifications(updated);
      }

      state = _hiveService.getAllTareas();
    }
  }

  Future<void> updateTarea(Tarea tarea) async {
    await _hiveService.saveTarea(tarea);
    await _notificationService.scheduleTaskNotifications(tarea);
    state = _hiveService.getAllTareas();
  }

  Future<void> deleteTarea(String id) async {
    await _notificationService.cancelTaskNotifications(id);
    await _hiveService.deleteTarea(id);
    state = _hiveService.getAllTareas();
  }

  void refresh() {
    state = _hiveService.getAllTareas();
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, List<Tarea>>((ref) {
  return TasksNotifier();
});

// --- Contactos ---

class ContactsNotifier extends StateNotifier<List<Contacto>> {
  final HiveService _hiveService = HiveService();

  ContactsNotifier() : super([]) {
    _loadData();
  }

  Future<void> _loadData() async {
    // Cargar contactos desde Hive
    final contactos = _hiveService.getAllContactos();

    if (contactos.isEmpty) {
      // Si no hay contactos, cargar datos de ejemplo
      await _loadDummyData();
    } else {
      state = contactos;
    }
  }

  Future<void> _loadDummyData() async {
    final dummyContactos = [
      Contacto(
        id: _uuid.v4(),
        nombre: 'Pedro Promotor',
        telefono: '+34600111222',
        email: 'pedro@promotora.com',
        notas: 'Organiza festivales en Andalucía',
      ),
      Contacto(
        id: _uuid.v4(),
        nombre: 'María Manager',
        telefono: '+34600333444',
        email: 'maria@management.es',
        notas: 'Mi representante actual',
      ),
      Contacto(
        id: _uuid.v4(),
        nombre: 'Sala Malandar',
        telefono: '+34600555666',
        email: 'info@salamalandar.com',
        notas: 'Sala de conciertos en Sevilla centro',
      ),
      Contacto(
        id: _uuid.v4(),
        nombre: 'Juan Técnico de Sonido',
        telefono: '+34600777888',
        email: 'juan@sonido.com',
        notas: 'Técnico freelance, muy profesional',
      ),
    ];

    for (var contacto in dummyContactos) {
      await _hiveService.saveContacto(contacto);
    }

    state = _hiveService.getAllContactos();
  }

  Future<void> addContacto(Contacto contacto) async {
    await _hiveService.saveContacto(contacto);
    state = _hiveService.getAllContactos();
  }

  Future<void> updateContacto(Contacto contacto) async {
    await _hiveService.saveContacto(contacto);
    state = _hiveService.getAllContactos();
  }

  Future<void> deleteContacto(String id) async {
    await _hiveService.deleteContacto(id);
    state = _hiveService.getAllContactos();
  }

  void refresh() {
    state = _hiveService.getAllContactos();
  }
}

final contactsProvider = StateNotifierProvider<ContactsNotifier, List<Contacto>>((ref) {
  return ContactsNotifier();
});
