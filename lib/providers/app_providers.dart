import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/preferences_service.dart';
import 'settings_provider.dart';

enum AgendaViewMode { day, week, month }

class AgendaViewNotifier extends Notifier<AgendaViewMode> {
  @override
  AgendaViewMode build() => AgendaViewMode.day;

  void set(AgendaViewMode v) => state = v;
}

final agendaViewProvider = NotifierProvider<AgendaViewNotifier, AgendaViewMode>(AgendaViewNotifier.new);

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
