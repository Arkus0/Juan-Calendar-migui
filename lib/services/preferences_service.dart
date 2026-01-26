import 'package:shared_preferences/shared_preferences.dart';

/// Servicio centralizado de preferencias del usuario.
/// Gestiona la persistencia de configuraciones de perfil, herramientas de músico
/// y preferencias de la aplicación.
class PreferencesService {
  // === CLAVES DE ALMACENAMIENTO ===

  // Identidad del usuario
  static const String _userNameKey = 'user_name';
  static const String _profileImagePathKey = 'profile_image_path';

  // Herramientas de músico
  static const String _templateKey = 'dossier_template';
  static const String _whatsappDefaultMessageKey = 'whatsapp_default_message';

  // Preferencias de la app
  static const String _selectedDateKey = 'selected_date';
  static const String _defaultViewKey = 'default_view'; // 'calendar' o 'agenda'
  static const String _defaultReminderMinutesKey = 'default_reminder_minutes';

  // ============================================================
  // SECCIÓN A: IDENTIDAD DEL USUARIO
  // ============================================================

  /// Guarda el nombre del usuario
  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  /// Obtiene el nombre del usuario
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  /// Guarda la ruta de la imagen de perfil
  Future<void> saveProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImagePathKey, path);
  }

  /// Obtiene la ruta de la imagen de perfil
  Future<String?> getProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImagePathKey);
  }

  /// Elimina la imagen de perfil
  Future<void> removeProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileImagePathKey);
  }

  // ============================================================
  // SECCIÓN B: HERRAMIENTAS DE MÚSICO
  // ============================================================

  /// Guarda la plantilla del dossier
  Future<void> saveDossierTemplate(String template) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_templateKey, template);
  }

  /// Obtiene la plantilla del dossier
  Future<String?> getDossierTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_templateKey);
  }

  /// Guarda el mensaje por defecto de WhatsApp
  Future<void> saveWhatsAppDefaultMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_whatsappDefaultMessageKey, message);
  }

  /// Obtiene el mensaje por defecto de WhatsApp
  Future<String?> getWhatsAppDefaultMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_whatsappDefaultMessageKey);
  }

  // ============================================================
  // SECCIÓN C: PREFERENCIAS DE LA APP
  // ============================================================

  /// Guarda la fecha seleccionada en el calendario
  Future<void> saveSelectedDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedDateKey, date.toIso8601String());
  }

  /// Obtiene la fecha seleccionada del calendario
  Future<DateTime?> getSelectedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_selectedDateKey);
    if (dateStr != null) {
      return DateTime.tryParse(dateStr);
    }
    return null;
  }

  /// Guarda la vista por defecto ('calendar' o 'agenda')
  Future<void> saveDefaultView(String view) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultViewKey, view);
  }

  /// Obtiene la vista por defecto
  Future<String> getDefaultView() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultViewKey) ?? 'calendar';
  }

  /// Guarda los minutos por defecto para recordatorios
  /// -1 significa sin recordatorio, otros valores son minutos antes del evento
  Future<void> saveDefaultReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultReminderMinutesKey, minutes);
  }

  /// Obtiene los minutos por defecto para recordatorios
  /// Retorna 60 (1 hora) como valor por defecto
  Future<int> getDefaultReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_defaultReminderMinutesKey) ?? 60;
  }

  // ============================================================
  // UTILIDADES
  // ============================================================

  /// Limpia todas las preferencias (útil para logout o reset)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
