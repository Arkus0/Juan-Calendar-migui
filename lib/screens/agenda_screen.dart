import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../providers/data_providers.dart';
import '../models/tarea.dart';
import '../models/agenda_item.dart';
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
          final dateStr = DateFormat('EEEE, d MMM', 'es').format(t.fecha); // Need 'es' locale, but assuming default/system
          grouped.putIfAbsent(dateStr, () => []).add(t);
        }

        List<AgendaItem> items = [];
        grouped.forEach((key, value) {
          items.add(AgendaHeader(key));
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

        List<AgendaItem> items = [];
        grouped.forEach((key, value) {
          items.add(AgendaHeader(key));
          items.addAll(value.map((t) => AgendaTaskItem(t)));
        });
        return items.isEmpty ? [AgendaEmptyItem("No hay tareas este mes")] : items;
      }
    }

    final agendaItems = buildAgendaItems();

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
              itemCount: agendaItems.length,
              itemBuilder: (context, index) {
                final item = agendaItems[index];
                return switch (item) {
                  AgendaHeader(text: final text) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: viewMode == AgendaViewMode.month ? Colors.blue : null)),
                    ),
                  AgendaTaskItem(task: final task) => TaskCard(
                      tarea: task,
                      onToggle: (_) => ref.read(tasksProvider.notifier).toggleTarea(task.id),
                    ),
                  AgendaEmptyItem(text: final text) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(text),
                      ),
                    ),
                };
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
