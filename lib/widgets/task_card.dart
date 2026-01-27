import 'package:flutter/material.dart';
import '../models/tarea.dart';

class TaskCard extends StatelessWidget {
  final Tarea tarea;
  final ValueChanged<bool?>? onToggle;

  const TaskCard({super.key, required this.tarea, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: ListTile(
        leading: Checkbox(
          value: tarea.completada,
          onChanged: onToggle,
        ),
        title: Text(
          tarea.descripcion,
          style: TextStyle(
            decoration: tarea.completada ? TextDecoration.lineThrough : null,
            color: tarea.completada ? Colors.grey : null,
          ),
        ),
        subtitle: tarea.categoria != null ? Text(tarea.categoria!) : null,
      ),
    );
  }
}
