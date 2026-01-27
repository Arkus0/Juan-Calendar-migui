import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/evento.dart';
import '../models/contacto.dart';
import '../services/hive_service.dart';
import '../screens/event_form_screen.dart';
import '../screens/task_form_screen.dart';
import '../screens/contact_form_screen.dart';

class GlobalSearchDelegate extends SearchDelegate<String> {
  final HiveService _hiveService = HiveService();

  @override
  String get searchFieldLabel => 'Buscar eventos, tareas, contactos...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withAlpha((0.5 * 255).round()),
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha((0.3 * 255).round()),
            ),
            const SizedBox(height: 16),
            Text(
              'Busca eventos, tareas o contactos',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha((0.5 * 255).round()),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.length < 2) {
      return const Center(
        child: Text('Escribe al menos 2 caracteres para buscar'),
      );
    }

    final results = _hiveService.searchAll(query);
    final eventos = results['eventos'] as List<Evento>;
    final tareas = (results['tareas'] as List).cast<Evento>();
    final contactos = results['contactos'] as List<Contacto>;

    final totalResults = eventos.length + tareas.length + contactos.length;

    if (totalResults == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha((0.3 * 255).round()),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron resultados',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha((0.5 * 255).round()),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        if (eventos.isNotEmpty) ...[
          _buildSectionHeader(context, 'Eventos', eventos.length),
          ...eventos.map((evento) => _buildEventoTile(context, evento)),
          const Divider(),
        ],
        if (tareas.isNotEmpty) ...[
          _buildSectionHeader(context, 'Tareas', tareas.length),
          ...tareas.map((tarea) => _buildTareaTile(context, tarea)),
          const Divider(),
        ],
        if (contactos.isNotEmpty) ...[
          _buildSectionHeader(context, 'Contactos', contactos.length),
          ...contactos.map((contacto) => _buildContactoTile(context, contacto)),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).round()),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventoTile(BuildContext context, Evento evento) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'es_ES');
    final color = evento.isBolo
        ? Colors.red
        : evento.isReunion
            ? Colors.blue
            : Colors.green;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withAlpha((0.2 * 255).round()),
        child: Icon(
          evento.isBolo ? Icons.music_note : Icons.event,
          color: color,
        ),
      ),
      title: Text(
        evento.titulo,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateFormat.format(evento.inicio)),
          if (evento.lugar != null)
            Text(
              '📍 ${evento.lugar}',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurface.withAlpha((0.5 * 255).round()),
      ),
      onTap: () {
        close(context, '');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventFormScreen(evento: evento),
          ),
        );
      },
    );
  }

  Widget _buildTareaTile(BuildContext context, Evento tarea) {
    final dateFormat = DateFormat('dd MMM yyyy', 'es_ES');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: tarea.completada
            ? Colors.green.withAlpha((0.2 * 255).round())
            : Colors.orange.withAlpha((0.2 * 255).round()),
        child: Icon(
          tarea.completada ? Icons.check_circle : Icons.circle_outlined,
          color: tarea.completada ? Colors.green : Colors.orange,
        ),
      ),
      title: Text(
        tarea.titulo,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          decoration: tarea.completada ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateFormat.format(tarea.inicio)),
          if (tarea.categoria != null)
            Text(
              tarea.categoria!,
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurface.withAlpha((0.5 * 255).round()),
      ),
      onTap: () {
        close(context, '');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskFormScreen(tarea: tarea),
          ),
        );
      },
    );
  }

  Widget _buildContactoTile(BuildContext context, Contacto contacto) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withAlpha((0.2 * 255).round()),
        child: Text(
          contacto.nombre[0].toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      title: Text(
        contacto.nombre,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(contacto.telefono),
          if (contacto.email != null)
            Text(
              contacto.email!,
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurface.withAlpha((0.5 * 255).round()),
      ),
      onTap: () {
        close(context, '');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContactFormScreen(contacto: contacto),
          ),
        );
      },
    );
  }
}
