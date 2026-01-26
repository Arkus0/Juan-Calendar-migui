import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/preferences_service.dart';

// ============================================================
// PROVIDER DE SERVICIO DE PREFERENCIAS
// ============================================================

final preferencesServiceProvider = Provider((ref) => PreferencesService());

// ============================================================
// PLANTILLAS POR DEFECTO
// ============================================================

const String defaultDossierTemplate = """¡Hola [Nombre]!

Aquí te envío mi dossier actualizado como cantautor:

- Bio breve: Cantautor sevillano con influencias flamencas y pop.
- Rider técnico: [describe o pega link]
- Tarifas aproximadas: Desde 300€ según formato y desplazamiento.
- Links importantes: EPK, vídeos en vivo, redes sociales...

¿Qué fechas tenéis disponibles para bolos?

Un saludo,
Juan José Moreno""";

const String defaultWhatsAppMessage =
    "Hola [Nombre], soy músico y te paso mi material promocional. ¡Espero que te guste!";

// ============================================================
// MODELO DE ESTADO COMPLETO DE CONFIGURACIÓN
// ============================================================

@immutable
class UserSettings {
  // Identidad
  final String userName;
  final String? profileImagePath;

  // Herramientas de músico
  final String dossierTemplate;
  final String whatsAppDefaultMessage;

  // Preferencias de la app
  final String defaultView; // 'calendar' o 'agenda'
  final int defaultReminderMinutes; // -1 = sin recordatorio

  const UserSettings({
    this.userName = '',
    this.profileImagePath,
    this.dossierTemplate = defaultDossierTemplate,
    this.whatsAppDefaultMessage = defaultWhatsAppMessage,
    this.defaultView = 'calendar',
    this.defaultReminderMinutes = 60,
  });

  /// Verifica si el usuario tiene imagen de perfil válida
  bool get hasProfileImage {
    if (profileImagePath == null || profileImagePath!.isEmpty) return false;
    return File(profileImagePath!).existsSync();
  }

  /// Obtiene las iniciales del nombre de usuario (máximo 2 caracteres)
  String get initials {
    if (userName.isEmpty) return '';
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return userName.substring(0, userName.length.clamp(0, 2)).toUpperCase();
  }

  /// Obtiene el nombre para mostrar o un valor por defecto
  String get displayName => userName.isEmpty ? 'Músico' : userName;

  UserSettings copyWith({
    String? userName,
    String? profileImagePath,
    bool clearProfileImage = false,
    String? dossierTemplate,
    String? whatsAppDefaultMessage,
    String? defaultView,
    int? defaultReminderMinutes,
  }) {
    return UserSettings(
      userName: userName ?? this.userName,
      profileImagePath:
          clearProfileImage ? null : (profileImagePath ?? this.profileImagePath),
      dossierTemplate: dossierTemplate ?? this.dossierTemplate,
      whatsAppDefaultMessage:
          whatsAppDefaultMessage ?? this.whatsAppDefaultMessage,
      defaultView: defaultView ?? this.defaultView,
      defaultReminderMinutes:
          defaultReminderMinutes ?? this.defaultReminderMinutes,
    );
  }
}

// ============================================================
// NOTIFIER DE CONFIGURACIÓN COMPLETA
// ============================================================

class UserSettingsNotifier extends StateNotifier<UserSettings> {
  final PreferencesService _prefsService;

  UserSettingsNotifier(this._prefsService) : super(const UserSettings()) {
    _loadAllSettings();
  }

  /// Carga todas las configuraciones desde el almacenamiento persistente
  Future<void> _loadAllSettings() async {
    final userName = await _prefsService.getUserName();
    final profileImagePath = await _prefsService.getProfileImagePath();
    final dossierTemplate = await _prefsService.getDossierTemplate();
    final whatsAppMessage = await _prefsService.getWhatsAppDefaultMessage();
    final defaultView = await _prefsService.getDefaultView();
    final reminderMinutes = await _prefsService.getDefaultReminderMinutes();

    state = UserSettings(
      userName: userName ?? '',
      profileImagePath: profileImagePath,
      dossierTemplate: dossierTemplate ?? defaultDossierTemplate,
      whatsAppDefaultMessage: whatsAppMessage ?? defaultWhatsAppMessage,
      defaultView: defaultView,
      defaultReminderMinutes: reminderMinutes,
    );
  }

  // === MÉTODOS DE IDENTIDAD ===

  Future<void> updateUserName(String name) async {
    state = state.copyWith(userName: name);
    await _prefsService.saveUserName(name);
  }

  Future<void> updateProfileImage(String path) async {
    state = state.copyWith(profileImagePath: path);
    await _prefsService.saveProfileImagePath(path);
  }

  Future<void> removeProfileImage() async {
    state = state.copyWith(clearProfileImage: true);
    await _prefsService.removeProfileImage();
  }

  // === MÉTODOS DE HERRAMIENTAS DE MÚSICO ===

  Future<void> updateDossierTemplate(String template) async {
    state = state.copyWith(dossierTemplate: template);
    await _prefsService.saveDossierTemplate(template);
  }

  Future<void> updateWhatsAppMessage(String message) async {
    state = state.copyWith(whatsAppDefaultMessage: message);
    await _prefsService.saveWhatsAppDefaultMessage(message);
  }

  // === MÉTODOS DE PREFERENCIAS DE LA APP ===

  Future<void> updateDefaultView(String view) async {
    state = state.copyWith(defaultView: view);
    await _prefsService.saveDefaultView(view);
  }

  Future<void> updateDefaultReminderMinutes(int minutes) async {
    state = state.copyWith(defaultReminderMinutes: minutes);
    await _prefsService.saveDefaultReminderMinutes(minutes);
  }

  /// Restaura los valores por defecto de las herramientas de músico
  Future<void> resetMusicianTools() async {
    await updateDossierTemplate(defaultDossierTemplate);
    await updateWhatsAppMessage(defaultWhatsAppMessage);
  }
}

// ============================================================
// PROVIDERS PRINCIPALES
// ============================================================

/// Provider principal de configuración del usuario
final userSettingsProvider =
    StateNotifierProvider<UserSettingsNotifier, UserSettings>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider);
  return UserSettingsNotifier(prefsService);
});

// ============================================================
// PROVIDERS DE CONVENIENCIA (para acceso directo a campos específicos)
// ============================================================

/// Provider solo para la plantilla del dossier (retrocompatibilidad)
final dossierTemplateProvider = Provider<String>((ref) {
  return ref.watch(userSettingsProvider).dossierTemplate;
});

/// Provider solo para el nombre de usuario
final userNameProvider = Provider<String>((ref) {
  return ref.watch(userSettingsProvider).userName;
});

/// Provider solo para la imagen de perfil
final profileImageProvider = Provider<String?>((ref) {
  return ref.watch(userSettingsProvider).profileImagePath;
});

/// Provider solo para la vista por defecto
final defaultViewProvider = Provider<String>((ref) {
  return ref.watch(userSettingsProvider).defaultView;
});

/// Provider solo para los minutos de recordatorio por defecto
final defaultReminderMinutesProvider = Provider<int>((ref) {
  return ref.watch(userSettingsProvider).defaultReminderMinutes;
});

/// Provider para verificar si tiene imagen de perfil
final hasProfileImageProvider = Provider<bool>((ref) {
  return ref.watch(userSettingsProvider).hasProfileImage;
});

/// Provider para las iniciales del usuario
final userInitialsProvider = Provider<String>((ref) {
  return ref.watch(userSettingsProvider).initials;
});

// ============================================================
// PROVIDERS LEGACY (para retrocompatibilidad con código existente)
// ============================================================

/// Notifier legacy para la plantilla del dossier
/// DEPRECATED: Usar userSettingsProvider.notifier en su lugar
class DossierTemplateNotifier extends StateNotifier<String> {
  final UserSettingsNotifier _settingsNotifier;

  DossierTemplateNotifier(this._settingsNotifier)
      : super(_settingsNotifier.state.dossierTemplate);

  Future<void> updateTemplate(String newTemplate) async {
    state = newTemplate;
    await _settingsNotifier.updateDossierTemplate(newTemplate);
  }
}

/// Provider legacy para actualizar solo el dossier template
/// DEPRECATED: Usar ref.read(userSettingsProvider.notifier).updateDossierTemplate()
final dossierTemplateNotifierProvider =
    StateNotifierProvider<DossierTemplateNotifier, String>((ref) {
  final settingsNotifier = ref.watch(userSettingsProvider.notifier);
  return DossierTemplateNotifier(settingsNotifier);
});
