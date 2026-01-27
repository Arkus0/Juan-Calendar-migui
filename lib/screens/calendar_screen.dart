import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/app_providers.dart';
import '../providers/data_providers.dart';
import '../models/evento.dart';
import '../models/event_type.dart';
import '../widgets/event_card.dart';
import 'event_form_screen.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final events = ref.watch(eventsProvider);
    final filters = ref.watch(eventFilterProvider);

    bool passesFilter(Evento event) {
      // Las tareas nunca deben aparecer en el calendario
      if (event.isTask) return false;
      // Type filters (if any selected, event.type must be included)
      if (filters.selectedTypes.isNotEmpty && !filters.selectedTypes.contains(event.tipo)) return false;
      return true;
    }

    List<Evento> getEventsForDay(DateTime day) {
      final list = events.where((event) {
        return isSameDay(event.inicio, day) && passesFilter(event);
      }).toList();
      list.sort((a, b) => a.inicio.compareTo(b.inicio));
      return list;
    }

    final dayEvents = getEventsForDay(selectedDate);

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 360,
            child: TableCalendar<Evento>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: selectedDate,
              selectedDayPredicate: (day) => isSameDay(selectedDate, day),
              locale: 'es',
              eventLoader: getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
              ),
              onFormatChanged: (format) => ref.read(calendarFormatProvider.notifier).setFormat(format),
              onDaySelected: (selectedDay, focusedDay) {
                ref.read(selectedDateProvider.notifier).setDate(selectedDay);
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: events.take(4).map((event) {
                      Color color;
                      switch (event.tipo) {
                        case EventType.bolo:
                          color = Colors.red;
                          break;
                        case EventType.reunion:
                          color = Colors.blue;
                          break;
                        case EventType.personal:
                          color = Colors.green;
                          break;
                        case EventType.clases:
                          color = Colors.purple;
                          break;
                        case EventType.laboral:
                          color = Colors.orange;
                          break;
                      }
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: dayEvents.length,
              itemBuilder: (context, index) {
                final event = dayEvents[index];
                return EventCard(
                  evento: event,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventFormScreen(evento: event),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendar_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EventFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
