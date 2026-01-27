import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _templateKey = 'dossier_template';
  static const String _selectedDateKey = 'selected_date';
  static const String _dailyBriefingEnabledKey = 'daily_briefing_enabled';
  static const String _dailyBriefingHourKey = 'daily_briefing_hour';
  static const String _dailyBriefingMinuteKey = 'daily_briefing_minute';

  Future<void> saveDossierTemplate(String template) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_templateKey, template);
  }

  Future<String?> getDossierTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_templateKey);
  }

  Future<void> saveSelectedDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedDateKey, date.toIso8601String());
  }

  Future<DateTime?> getSelectedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_selectedDateKey);
    if (dateStr != null) {
      return DateTime.tryParse(dateStr);
    }
    return null;
  }

  /// Guarda la configuración de activación del Briefing Matutino
  Future<void> setDailyBriefingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyBriefingEnabledKey, enabled);
  }

  /// Obtiene si el Briefing Matutino está activado (default: false)
  Future<bool> getDailyBriefingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dailyBriefingEnabledKey) ?? false;
  }

  /// Guarda la hora del Briefing Matutino
  Future<void> saveDailyBriefingTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyBriefingHourKey, time.hour);
    await prefs.setInt(_dailyBriefingMinuteKey, time.minute);
  }

  /// Obtiene la hora del Briefing Matutino (default: 9:00 AM)
  Future<TimeOfDay> getDailyBriefingTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_dailyBriefingHourKey) ?? 9;
    final minute = prefs.getInt(_dailyBriefingMinuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
