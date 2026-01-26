import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';

/// Pantalla de Perfil y Ajustes completa.
/// Organizada en secciones: Identidad, Herramientas de Músico y Preferencias de la App.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _whatsAppController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final settings = ref.read(userSettingsProvider);
    _nameController.text = settings.userName;
    _whatsAppController.text = settings.whatsAppDefaultMessage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsAppController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isLoading = true);

        // Copiar imagen a directorio de la app para persistencia
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
        final savedImage = await File(image.path).copy('${appDir.path}/$fileName');

        await ref.read(userSettingsProvider.notifier).updateProfileImage(savedImage.path);

        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto de perfil actualizada'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _removeImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Quieres eliminar tu foto de perfil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(userSettingsProvider.notifier).removeProfileImage();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil eliminada'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _saveName() {
    final name = _nameController.text.trim();
    ref.read(userSettingsProvider.notifier).updateUserName(name);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nombre guardado'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _saveWhatsAppMessage() {
    final message = _whatsAppController.text.trim();
    ref.read(userSettingsProvider.notifier).updateWhatsAppMessage(message);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mensaje de WhatsApp guardado'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _openDossierEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _DossierEditorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(userSettingsProvider);
    final themeMode = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil y Ajustes'),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // ============================================
                // SECCIÓN A: IDENTIDAD
                // ============================================
                _buildSectionHeader(context, 'Identidad', Icons.person_outline),

                // Avatar grande
                _buildAvatarSection(settings, colorScheme),

                const SizedBox(height: 16),

                // Campo nombre
                _buildSettingsTile(
                  context,
                  leading: Icon(Icons.badge_outlined, color: colorScheme.primary),
                  title: 'Tu nombre',
                  subtitle: settings.userName.isEmpty
                      ? 'Personaliza cómo te llama la app'
                      : settings.userName,
                  trailing: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _saveName,
                    tooltip: 'Guardar nombre',
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Ej: Juan José Moreno',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => _saveName(),
                    ),
                  ),
                ),

                const Divider(height: 32),

                // ============================================
                // SECCIÓN B: HERRAMIENTAS DE MÚSICO
                // ============================================
                _buildSectionHeader(context, 'Herramientas de Músico', Icons.music_note_outlined),

                // Plantilla de Dossier
                _buildSettingsTile(
                  context,
                  leading: Icon(Icons.description_outlined, color: colorScheme.primary),
                  title: 'Plantilla del Dossier',
                  subtitle: 'Mensaje predefinido para enviar tu material',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openDossierEditor,
                ),

                // Mensaje WhatsApp Default
                _buildSettingsTile(
                  context,
                  leading: Icon(Icons.chat_outlined, color: colorScheme.primary),
                  title: 'Mensaje introductorio',
                  subtitle: 'Texto que acompaña tu dossier por WhatsApp',
                  trailing: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _saveWhatsAppMessage,
                    tooltip: 'Guardar mensaje',
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TextField(
                      controller: _whatsAppController,
                      decoration: const InputDecoration(
                        hintText: 'Hola [Nombre], soy músico y...',
                        helperText: 'Usa [Nombre] para insertar el contacto',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: 3,
                      onSubmitted: (_) => _saveWhatsAppMessage(),
                    ),
                  ),
                ),

                const Divider(height: 32),

                // ============================================
                // SECCIÓN C: PREFERENCIAS DE LA APP
                // ============================================
                _buildSectionHeader(context, 'Preferencias de la App', Icons.tune_outlined),

                // Selector de Tema
                _buildSettingsTile(
                  context,
                  leading: Icon(Icons.palette_outlined, color: colorScheme.primary),
                  title: 'Tema de la aplicación',
                  subtitle: _getThemeLabel(themeMode),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeSelector(context, themeMode),
                ),

                // Vista por defecto
                _buildSettingsTile(
                  context,
                  leading: Icon(Icons.view_agenda_outlined, color: colorScheme.primary),
                  title: 'Vista por defecto',
                  subtitle: settings.defaultView == 'calendar' ? 'Calendario' : 'Agenda',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showViewSelector(context, settings.defaultView),
                ),

                // Recordatorios por defecto
                _buildSettingsTile(
                  context,
                  leading: Icon(Icons.notifications_outlined, color: colorScheme.primary),
                  title: 'Recordatorios por defecto',
                  subtitle: _getReminderLabel(settings.defaultReminderMinutes),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showReminderSelector(context, settings.defaultReminderMinutes),
                ),

                const SizedBox(height: 32),

                // Versión de la app
                Center(
                  child: Text(
                    'Musician Organizer v1.0.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(UserSettings settings, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              onLongPress: settings.hasProfileImage ? _removeImage : null,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: settings.hasProfileImage
                          ? FileImage(File(settings.profileImagePath!))
                          : null,
                      child: settings.hasProfileImage
                          ? null
                          : settings.initials.isNotEmpty
                              ? Text(
                                  settings.initials,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 48,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              settings.displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Toca para cambiar foto',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
            ),
            if (settings.hasProfileImage) ...[
              const SizedBox(height: 4),
              Text(
                'Mantén pulsado para eliminar',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                      fontSize: 11,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required Widget leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    Widget? child,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: leading,
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle) : null,
          trailing: trailing,
          onTap: onTap,
        ),
        if (child != null) child,
      ],
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Automático (sistema)';
    }
  }

  String _getReminderLabel(int minutes) {
    if (minutes < 0) return 'Sin recordatorio';
    if (minutes == 0) return 'En el momento';
    if (minutes == 15) return '15 minutos antes';
    if (minutes == 30) return '30 minutos antes';
    if (minutes == 60) return '1 hora antes';
    if (minutes == 120) return '2 horas antes';
    if (minutes == 1440) return '1 día antes';
    return '$minutes minutos antes';
  }

  void _showThemeSelector(BuildContext context, ThemeMode currentMode) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Tema de la aplicación',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _buildThemeOption(context, ThemeMode.system, 'Automático (sistema)', Icons.brightness_auto, currentMode),
            _buildThemeOption(context, ThemeMode.light, 'Claro', Icons.light_mode, currentMode),
            _buildThemeOption(context, ThemeMode.dark, 'Oscuro', Icons.dark_mode, currentMode),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, ThemeMode mode, String label, IconData icon, ThemeMode currentMode) {
    final isSelected = mode == currentMode;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
      selected: isSelected,
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showViewSelector(BuildContext context, String currentView) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Vista por defecto al abrir la app',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _buildViewOption(context, 'calendar', 'Calendario', Icons.calendar_today, currentView),
            _buildViewOption(context, 'agenda', 'Agenda', Icons.checklist, currentView),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildViewOption(BuildContext context, String view, String label, IconData icon, String currentView) {
    final isSelected = view == currentView;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
      selected: isSelected,
      onTap: () {
        ref.read(userSettingsProvider.notifier).updateDefaultView(view);
        Navigator.pop(context);
      },
    );
  }

  void _showReminderSelector(BuildContext context, int currentMinutes) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Recordatorio por defecto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Los nuevos eventos tendrán este recordatorio preestablecido',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
            _buildReminderOption(context, -1, 'Sin recordatorio', currentMinutes),
            _buildReminderOption(context, 0, 'En el momento', currentMinutes),
            _buildReminderOption(context, 15, '15 minutos antes', currentMinutes),
            _buildReminderOption(context, 30, '30 minutos antes', currentMinutes),
            _buildReminderOption(context, 60, '1 hora antes', currentMinutes),
            _buildReminderOption(context, 120, '2 horas antes', currentMinutes),
            _buildReminderOption(context, 1440, '1 día antes', currentMinutes),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderOption(BuildContext context, int minutes, String label, int currentMinutes) {
    final isSelected = minutes == currentMinutes;
    return ListTile(
      leading: Icon(minutes < 0 ? Icons.notifications_off_outlined : Icons.notifications_outlined),
      title: Text(label),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
      selected: isSelected,
      onTap: () {
        ref.read(userSettingsProvider.notifier).updateDefaultReminderMinutes(minutes);
        Navigator.pop(context);
      },
    );
  }
}

// ============================================================
// SUBPANTALLA: EDITOR DE DOSSIER
// ============================================================

class _DossierEditorScreen extends ConsumerStatefulWidget {
  const _DossierEditorScreen();

  @override
  ConsumerState<_DossierEditorScreen> createState() => _DossierEditorScreenState();
}

class _DossierEditorScreenState extends ConsumerState<_DossierEditorScreen> {
  late TextEditingController _controller;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final currentTemplate = ref.read(userSettingsProvider).dossierTemplate;
    _controller = TextEditingController(text: currentTemplate);
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _saveTemplate() {
    ref.read(userSettingsProvider.notifier).updateDossierTemplate(_controller.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plantilla guardada'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  void _resetTemplate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar plantilla'),
        content: const Text('¿Quieres restaurar la plantilla por defecto? Se perderán tus cambios actuales.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _controller.text = defaultDossierTemplate;
      setState(() => _hasChanges = true);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambios sin guardar'),
        content: const Text('Tienes cambios sin guardar. ¿Qué quieres hacer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () {
              _saveTemplate();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Plantilla del Dossier'),
          actions: [
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'Restaurar por defecto',
              onPressed: _resetTemplate,
            ),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Guardar',
              onPressed: _hasChanges ? _saveTemplate : null,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Usa [Nombre] para insertar automáticamente el nombre del contacto.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'Escribe tu mensaje aquí...',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLowest,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
              ),
              if (_hasChanges) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tienes cambios sin guardar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _hasChanges ? _saveTemplate : null,
              icon: const Icon(Icons.save),
              label: const Text('Guardar plantilla'),
            ),
          ),
        ),
      ),
    );
  }
}
