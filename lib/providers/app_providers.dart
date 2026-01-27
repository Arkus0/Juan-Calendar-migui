import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/preferences_service.dart';
import 'settings_provider.dart';
import '../models/event_type.dart';

enum TareasViewMode { day, week, month }

class TareasViewNotifier extends Notifier<TareasViewMode> {
  @override
  TareasViewMode build() => TareasViewMode.day;

  void set(TareasViewMode v) => state = v;
}

final tareasViewProvider = NotifierProvider<TareasViewNotifier, TareasViewMode>(TareasViewNotifier.new);

// Calendar format provider for TableCalendar
class CalendarFormatNotifier extends Notifier<CalendarFormat> {
  @override
  CalendarFormat build() => CalendarFormat.month;

  void setFormat(CalendarFormat f) => state = f;
}

final calendarFormatProvider = NotifierProvider<CalendarFormatNotifier, CalendarFormat>(CalendarFormatNotifier.new);

class SelectedDateNotifier extends Notifier<DateTime> {
  PreferencesService get _prefsService => ref.read(preferencesServiceProvider);

  @override
  DateTime build() {
    _loadDate();
    return DateTime.now();
  }

  Future<void> _loadDate() async {
    final saved = await _prefsService.getSelectedDate();
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> setDate(DateTime date) async {
    state = date;
    await _prefsService.saveSelectedDate(date);
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);

// --- Filtros de eventos ---
class EventFilterState {
  final Set<EventType> selectedTypes;
  final bool showCompleted; // show completed tasks in lists
  final String? selectedCategory; // filter backlog / tasks by category
  final String sortBy; // 'title' or 'category'

  const EventFilterState({this.selectedTypes = const {}, this.showCompleted = true, this.selectedCategory, this.sortBy = 'title'});

  EventFilterState copyWith({Set<EventType>? selectedTypes, bool? showCompleted, String? selectedCategory, String? sortBy}) {
    return EventFilterState(
      selectedTypes: selectedTypes ?? this.selectedTypes,
      showCompleted: showCompleted ?? this.showCompleted,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class EventFilterNotifier extends Notifier<EventFilterState> {
  @override
  EventFilterState build() => const EventFilterState(selectedTypes: {});

  void toggleType(EventType t) {
    final next = Set<EventType>.from(state.selectedTypes);
    if (next.contains(t)) {
      next.remove(t);
    } else {
      next.add(t);
    }
    state = state.copyWith(selectedTypes: next);
  }

  void setShowCompleted(bool show) => state = state.copyWith(showCompleted: show);

  void setCategory(String? cat) => state = state.copyWith(selectedCategory: cat);

  void setSortBy(String key) => state = state.copyWith(sortBy: key);

  void clear() => state = const EventFilterState(selectedTypes: {});
}

final eventFilterProvider = NotifierProvider<EventFilterNotifier, EventFilterState>(EventFilterNotifier.new);
