import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/evento.dart';
import '../models/tarea.dart';
import '../models/contacto.dart';

const _uuid = Uuid();

// --- Eventos ---

class EventsNotifier extends StateNotifier<List<Evento>> {
  EventsNotifier() : super([]) {
    _loadDummyData();
  }

  void _loadDummyData() {
    final now = DateTime.now();
    state = [
      Evento(
        id: _uuid.v4(),
        titulo: 'Concierto en Sala X',
        tipo: 'bolo',
        inicio: now.add(const Duration(days: 2, hours: 20)),
        fin: now.add(const Duration(days: 2, hours: 23)),
        lugar: 'Sala X, Sevilla',
        notas: 'Llevar guitarra acústica extra.',
      ),
      Evento(
        id: _uuid.v4(),
        titulo: 'Reunión con Manager',
        tipo: 'reunion',
        inicio: now.add(const Duration(days: 1, hours: 10)),
        fin: now.add(const Duration(days: 1, hours: 12)),
        lugar: 'Cafetería Central',
      ),
      Evento(
        id: _uuid.v4(),
        titulo: 'Cena familiar',
        tipo: 'personal',
        inicio: now.add(const Duration(days: 5, hours: 21)),
      ),
       Evento(
        id: _uuid.v4(),
        titulo: 'Festival Indie',
        tipo: 'bolo',
        inicio: now.add(const Duration(days: 15, hours: 18)),
        lugar: 'Recinto Ferial',
      ),
    ];
  }

  void addEvento(Evento evento) {
    state = [...state, evento];
  }

  void updateEvento(Evento evento) {
    state = [
      for (final e in state)
        if (e.id == evento.id) evento else e
    ];
  }

  void deleteEvento(String id) {
    state = state.where((e) => e.id != id).toList();
  }
}

final eventsProvider = StateNotifierProvider<EventsNotifier, List<Evento>>((ref) {
  return EventsNotifier();
});

// --- Tareas ---

class TasksNotifier extends StateNotifier<List<Tarea>> {
  TasksNotifier() : super([]) {
    _loadDummyData();
  }

  void _loadDummyData() {
    final now = DateTime.now();
    state = [
      Tarea(
        id: _uuid.v4(),
        descripcion: 'Llamar al promotor del festival',
        fecha: now,
        categoria: 'Gestión',
      ),
      Tarea(
        id: _uuid.v4(),
        descripcion: 'Publicar reel en Instagram',
        fecha: now,
        categoria: 'Marketing',
      ),
      Tarea(
        id: _uuid.v4(),
        descripcion: 'Comprar cuerdas nuevas',
        fecha: now.add(const Duration(days: 1)),
        categoria: 'Equipo',
      ),
      Tarea(
        id: _uuid.v4(),
        descripcion: 'Revisar contrato discográfica',
        fecha: now.add(const Duration(days: 3)),
        categoria: 'Legal',
      ),
    ];
  }

  void addTarea(Tarea tarea) {
    state = [...state, tarea];
  }

  void toggleTarea(String id) {
    state = [
      for (final t in state)
        if (t.id == id) t.copyWith(completada: !t.completada) else t
    ];
  }

  void updateTarea(Tarea tarea) {
    state = [
      for (final t in state)
        if (t.id == tarea.id) tarea else t
    ];
  }

  void deleteTarea(String id) {
    state = state.where((t) => t.id != id).toList();
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, List<Tarea>>((ref) {
  return TasksNotifier();
});

// --- Contactos ---

class ContactsNotifier extends StateNotifier<List<Contacto>> {
  ContactsNotifier() : super([]) {
    _loadDummyData();
  }

  void _loadDummyData() {
    state = [
      Contacto(
        id: _uuid.v4(),
        nombre: 'Pedro Promotor',
        telefono: '+34600111222',
      ),
      Contacto(
        id: _uuid.v4(),
        nombre: 'María Manager',
        telefono: '+34600333444',
      ),
      Contacto(
        id: _uuid.v4(),
        nombre: 'Sala Malandar',
        telefono: '+34600555666',
      ),
    ];
  }

  void addContacto(Contacto contacto) {
    state = [...state, contacto];
  }

  void updateContacto(Contacto contacto) {
    state = [
      for (final c in state)
        if (c.id == contacto.id) contacto else c
    ];
  }
}

final contactsProvider = StateNotifierProvider<ContactsNotifier, List<Contacto>>((ref) {
  return ContactsNotifier();
});
