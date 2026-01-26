import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _templateKey = 'dossier_template';
  static const String _selectedDateKey = 'selected_date';

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
}
