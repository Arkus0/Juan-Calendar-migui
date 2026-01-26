import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/evento.dart';

class EventCard extends StatelessWidget {
  final Evento evento;
  final VoidCallback? onTap;

  const EventCard({Key? key, required this.evento, this.onTap}) : super(key: key);

  Color _getColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'bolo':
        return Colors.redAccent;
      case 'reunion':
        return Colors.blueAccent;
      case 'personal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm');
    final color = _getColor(evento.tipo);

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
        title: Text(
          evento.titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${dateFormat.format(evento.inicio)} ${evento.fin != null ? "- ${dateFormat.format(evento.fin!)}" : ""}',
            ),
            if (evento.lugar != null)
              Text(
                evento.lugar!,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: Text(
          evento.tipo.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
