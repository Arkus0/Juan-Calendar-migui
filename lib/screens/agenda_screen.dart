import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../providers/data_providers.dart';
import '../models/tarea.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final tasks = ref.watch(tasksProvider);
    final viewMode = ref.watch(agendaViewProvider);

    // Helpers
    DateTime getStartOfWeek(DateTime date) {
      return date.subtract(Duration(days: date.weekday - 1));
    }

    DateTime getEndOfWeek(DateTime date) {
      return date.add(Duration(days: DateTime.sunday - date.weekday));
    }

    bool isSameDate(DateTime d1, DateTime d2) {
      return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
    }

    List<AgendaItem> buildAgendaItems() {
      List<Tarea> filteredTasks = [];
      List<AgendaItem> items = [];

      if (viewMode == AgendaViewMode.day) {
        filteredTasks = tasks.where((t) => isSameDate(t.fecha, selectedDate)).toList();
        if (filteredTasks.isEmpty) {
           return [AgendaEmptyItem("No hay tareas para hoy")];
        }
        return filteredTasks.map((t) => AgendaTaskItem(t)).toList();

      } else if (viewMode == AgendaViewMode.week) {
        final start = getStartOfWeek(selectedDate);
        final end = getEndOfWeek(selectedDate);

        // Filter
        filteredTasks = tasks.where((t) =>
          !t.fecha.isBefore(start.subtract(const Duration(seconds: 1))) &&
          !t.fecha.isAfter(end.add(const Duration(seconds: 1)))
        ).toList();

        // Group by day
        filteredTasks.sort((a, b) => a.fecha.compareTo(b.fecha));

        Map<String, List<Tarea>> grouped = {};
        for (var t in filteredTasks) {
          final dateStr = DateFormat('EEEE, d MMM', 'es').format(t.fecha);
          grouped.putIfAbsent(dateStr, () => []).add(t);
        }

        grouped.forEach((key, value) {
          items.add(AgendaHeaderItem(key, style: const TextStyle(fontWeight: FontWeight.bold)));
          items.addAll(value.map((t) => AgendaTaskItem(t)));
        });
        return items.isEmpty ? [AgendaEmptyItem("No hay tareas esta semana")] : items;

      } else {
        // Month
        // Filter
        filteredTasks = tasks.where((t) => t.fecha.year == selectedDate.year && t.fecha.month == selectedDate.month).toList();

        // Group by week
        filteredTasks.sort((a, b) => a.fecha.compareTo(b.fecha));

        Map<String, List<Tarea>> grouped = {};
        for (var t in filteredTasks) {
          final weekStart = getStartOfWeek(t.fecha);
          final weekStr = "Semana del ${DateFormat('d MMM').format(weekStart)}";
          grouped.putIfAbsent(weekStr, () => []).add(t);
        }

        grouped.forEach((key, value) {
          items.add(AgendaHeaderItem(key, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)));
          items.addAll(value.map((t) => AgendaTaskItem(t)));
        });
        return items.isEmpty ? [AgendaEmptyItem("No hay tareas este mes")] : items;
      }
    }

    final items = buildAgendaItems();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SegmentedButton<AgendaViewMode>(
              segments: const [
                ButtonSegment(value: AgendaViewMode.day, label: Text('Día')),
                ButtonSegment(value: AgendaViewMode.week, label: Text('Semana')),
                ButtonSegment(value: AgendaViewMode.month, label: Text('Mes')),
              ],
              selected: {viewMode},
              onSelectionChanged: (Set<AgendaViewMode> newSelection) {
                ref.read(agendaViewProvider.notifier).state = newSelection.first;
              },
            ),
          ),
          Padding(
             padding: const EdgeInsets.symmetric(vertical: 4),
             child: Text("Fecha seleccionada: ${DateFormat('d/MM/yyyy').format(selectedDate)}", style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item is AgendaHeaderItem) {
                   return Padding(
                     padding: const EdgeInsets.all(8.0),
                     child: Text(item.text, style: item.style),
                   );
                } else if (item is AgendaTaskItem) {
                   return TaskCard(
                     tarea: item.tarea,
                     onToggle: (_) => ref.read(tasksProvider.notifier).toggleTarea(item.tarea.id),
                   );
                } else if (item is AgendaEmptyItem) {
                   return Center(
                     child: Padding(
                       padding: const EdgeInsets.all(20),
                       child: Text(item.message),
                     ),
                   );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'agenda_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TaskFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add_task),
      ),
    );
  }
}

// Sealed class hierarchy for Agenda items to support ListView.builder
sealed class AgendaItem {}

class AgendaHeaderItem extends AgendaItem {
  final String text;
  final TextStyle? style;
  AgendaHeaderItem(this.text, {this.style});
}

class AgendaTaskItem extends AgendaItem {
  final Tarea tarea;
  AgendaTaskItem(this.tarea);
}

class AgendaEmptyItem extends AgendaItem {
  final String message;
  AgendaEmptyItem(this.message);
}
