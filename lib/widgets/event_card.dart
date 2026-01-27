import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/evento.dart';
import '../models/event_type.dart';
import '../models/recurrence_rule.dart';

class EventCard extends StatelessWidget {
  final Evento evento;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.evento, this.onTap});

  Color _getColor(EventType tipo) {
    switch (tipo) {
      case EventType.bolo:
        return Colors.redAccent;
      case EventType.reunion:
        return Colors.blueAccent;
      case EventType.personal:
        return Colors.green;
      case EventType.clases:
        return Colors.purple;
      case EventType.laboral:
        return Colors.orange;
    }
  }

  /// 🔥 NUEVO: Truncar texto largo de notas
  String _truncateNotes(String? notes, int maxLength) {
    if (notes == null || notes.isEmpty) return '';
    if (notes.length <= maxLength) return notes;
    return '${notes.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm');
    final color = _getColor(evento.tipo);
    // 🔥 NUEVO: Verificar si hay notas
    final hasNotes = evento.notas != null && evento.notas!.isNotEmpty;
    // 🔥 NUEVO: Verificar si es recurrente
    final isRecurring = evento.recurrence != null &&
                       evento.recurrence!.type != RecurrenceType.none;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                evento.titulo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // 🔥 NUEVO: Indicador de evento recurrente
            if (isRecurring)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.repeat,
                  size: 16,
                  color: color.withAlpha((0.7 * 255).round()),
                ),
              ),
            // 🔥 NUEVO: Indicador de notas
            if (hasNotes)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.note,
                  size: 16,
                  color: Colors.amber[700],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${dateFormat.format(evento.inicio)} ${evento.fin != null ? "- ${dateFormat.format(evento.fin!)}" : ""}',
            ),
            if (evento.lugar != null)
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      evento.lugar!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            // 🔥 NUEVO: Mostrar preview de notas si existen
            if (hasNotes)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _truncateNotes(evento.notas, 50),
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            // 🔥 NUEVO: Mostrar información de recurrencia
            if (isRecurring)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      size: 14,
                      color: color.withAlpha((0.7 * 255).round()),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      evento.recurrence!.getDisplayText(),
                      style: TextStyle(
                        fontSize: 11,
                        color: color.withAlpha((0.7 * 255).round()),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              evento.tipo.displayName.toUpperCase(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            // 🔥 NUEVO: Mostrar número de recordatorios si hay
            if (evento.reminders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_active,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${evento.reminders.length}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
