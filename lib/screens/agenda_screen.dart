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

    List<Widget> buildTaskList() {
      List<Tarea> filteredTasks = [];

      if (viewMode == AgendaViewMode.day) {
        filteredTasks = tasks.where((t) => isSameDate(t.fecha, selectedDate)).toList();
        if (filteredTasks.isEmpty) {
           return [const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No hay tareas para hoy")))];
        }
        return filteredTasks.map((t) => TaskCard(
          tarea: t,
          onToggle: (_) => ref.read(tasksProvider.notifier).toggleTarea(t.id),
        )).toList();

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

        List<Widget> widgets = [];
        grouped.forEach((key, value) {
          widgets.add(Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
          ));
          widgets.addAll(value.map((t) => TaskCard(
            tarea: t,
            onToggle: (_) => ref.read(tasksProvider.notifier).toggleTarea(t.id),
          )));
        });
        return widgets.isEmpty ? [const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No hay tareas esta semana")))] : widgets;

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

        List<Widget> widgets = [];
        grouped.forEach((key, value) {
          widgets.add(Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ));
          widgets.addAll(value.map((t) => TaskCard(
            tarea: t,
            onToggle: (_) => ref.read(tasksProvider.notifier).toggleTarea(t.id),
          )));
        });
        return widgets.isEmpty ? [const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No hay tareas este mes")))] : widgets;
      }
    }

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
                ref.read(agendaViewProvider.notifier).set(newSelection.first);
              },
            ),
          ),
          Padding(
             padding: const EdgeInsets.symmetric(vertical: 4),
             child: Text("Fecha seleccionada: ${DateFormat('d/MM/yyyy').format(selectedDate)}", style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: ListView(
              children: buildTaskList(),
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
