import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../providers/data_providers.dart';
import '../models/tarea.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

sealed class AgendaItem {}

class AgendaHeaderItem extends AgendaItem {
  final String title;
  final bool isMonthView;
  AgendaHeaderItem(this.title, {this.isMonthView = false});
}

class AgendaTaskItem extends AgendaItem {
  final Tarea tarea;
  AgendaTaskItem(this.tarea);
}

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({Key? key}) : super(key: key);

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

    String getEmptyMessage() {
      switch (viewMode) {
        case AgendaViewMode.day: return "No hay tareas para hoy";
        case AgendaViewMode.week: return "No hay tareas esta semana";
        case AgendaViewMode.month: return "No hay tareas este mes";
      }
    }

    List<AgendaItem> buildAgendaItems() {
      List<Tarea> filteredTasks = [];

      if (viewMode == AgendaViewMode.day) {
        filteredTasks = tasks.where((t) => isSameDate(t.fecha, selectedDate)).toList();
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

        List<AgendaItem> items = [];
        grouped.forEach((key, value) {
          items.add(AgendaHeaderItem(key));
          items.addAll(value.map((t) => AgendaTaskItem(t)));
        });
        return items;

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
          items.add(AgendaHeaderItem(key, isMonthView: true));
          items.addAll(value.map((t) => AgendaTaskItem(t)));
        });
        return items;
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
            child: agendaItems.isEmpty
                ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(getEmptyMessage())))
                : ListView.builder(
                    itemCount: agendaItems.length,
                    itemBuilder: (context, index) {
                      final item = agendaItems[index];
                      if (item is AgendaHeaderItem) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: item.isMonthView ? Colors.blue : null,
                            ),
                          ),
                        );
                      } else if (item is AgendaTaskItem) {
                        return TaskCard(
                          tarea: item.tarea,
                          onToggle: (_) => ref.read(tasksProvider.notifier).toggleTarea(item.tarea.id),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
