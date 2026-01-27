import 'package:flutter/material.dart';

import '../models/evento.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';

class TaskCard extends StatefulWidget {
  final Evento tarea;
  final ValueChanged<bool?>? onToggle;
  final List<Evento> subtareas;
  final ValueChanged<Evento>? onTap;

  const TaskCard({super.key, required this.tarea, this.onToggle, this.subtareas = const [], this.onTap});

  @override
  State<TaskCard> createState() => _TaskCardState();
}


class _TaskCardState extends State<TaskCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final completed = widget.tarea.completada;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
        child: Column(
          key: ValueKey(completed),
          children: [
            ListTile(
              leading: Checkbox(
                value: completed,
                onChanged: (v) => widget.onToggle?.call(v),
              ),
              title: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  decoration: (completed ? TextDecoration.lineThrough : null),
                  color: completed ? Colors.grey : null,
                  fontWeight: FontWeight.w500,
                ),
                child: Text(widget.tarea.titulo),
              ),
              subtitle: widget.tarea.categoria != null ? Text(widget.tarea.categoria!) : null,
              trailing: widget.subtareas.isNotEmpty
                  ? IconButton(
                      icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                      onPressed: () => setState(() => _expanded = !_expanded),
                    )
                  : null,
              onTap: () => widget.onTap?.call(widget.tarea),
            ),
            if (_expanded && widget.subtareas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 32, right: 8, bottom: 8),
                child: Consumer(
                  builder: (context, ref, _) => Column(
                    children: widget.subtareas
                        .map((sub) => ListTile(
                              leading: Checkbox(
                                value: sub.completada,
                                onChanged: (v) {
                                  ref.read(tasksProvider.notifier).toggleTarea(sub.id);
                                },
                              ),
                              title: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  decoration: sub.completada ? TextDecoration.lineThrough : null,
                                  color: sub.completada ? Colors.grey : null,
                                ),
                                child: Text(sub.titulo),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
