import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/preferences_service.dart';
import 'settings_provider.dart';

enum AgendaViewMode { day, week, month }

final agendaViewProvider = StateProvider<AgendaViewMode>((ref) => AgendaViewMode.day);

// Calendar format provider for TableCalendar
final calendarFormatProvider = StateProvider<CalendarFormat>((ref) => CalendarFormat.month);

class SelectedDateNotifier extends StateNotifier<DateTime> {
  final PreferencesService _prefsService;

  SelectedDateNotifier(this._prefsService) : super(DateTime.now()) {
    _loadDate();
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

final selectedDateProvider = StateNotifierProvider<SelectedDateNotifier, DateTime>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider);
  return SelectedDateNotifier(prefsService);
});
