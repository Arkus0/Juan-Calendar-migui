import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/preferences_service.dart';
import '../services/notification_service.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _controller;
  final PreferencesService _prefsService = PreferencesService();
  final NotificationService _notificationService = NotificationService();

  bool _briefingEnabled = false;
  TimeOfDay _briefingTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final currentTemplate = ref.read(dossierTemplateProvider);
    _controller = TextEditingController(text: currentTemplate);
    _loadBriefingSettings();
  }

  Future<void> _loadBriefingSettings() async {
    final enabled = await _prefsService.getDailyBriefingEnabled();
    final time = await _prefsService.getDailyBriefingTime();
    setState(() {
      _briefingEnabled = enabled;
      _briefingTime = time;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _ensureFilePath(XFile f) async {
    try {
      final maybePath = f.path;
      if (maybePath.isNotEmpty) return maybePath;
    } catch (_) {}

    try {
      final bytes = await f.readAsBytes();
      final dir = await getApplicationDocumentsDirectory();
      final name = f.name.replaceAll(RegExp(r"[^0-9A-Za-z._-]"), '_');
      final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}_$name');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  Future<void> _toggleBriefing(bool value) async {
    setState(() => _briefingEnabled = value);
    await _prefsService.setDailyBriefingEnabled(value);

    if (value) {
      // Activar: programar notificación
      await _notificationService.scheduleDailyBriefing(_briefingTime);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Briefing Matutino activado para las ${_briefingTime.hour.toString().padLeft(2, '0')}:${_briefingTime.minute.toString().padLeft(2, '0')}',
            ),
          ),
        );
      }
    } else {
      // Desactivar: cancelar notificación
      await _notificationService.cancelDailyBriefing();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Briefing Matutino desactivado')),
        );
      }
    }
  }

  Future<void> _selectBriefingTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _briefingTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _briefingTime) {
      setState(() => _briefingTime = picked);
      await _prefsService.saveDailyBriefingTime(picked);

      // Si está activado, reprogramar
      if (_briefingEnabled) {
        await _notificationService.scheduleDailyBriefing(picked);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Briefing Matutino reprogramado para las ${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              try {
                await ref.read(dossierTemplateProvider.notifier).updateTemplate(_controller.text);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Plantilla guardada')),
                  );
                  navigator.pop();
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error al guardar plantilla: $e')),
                  );
                }
              }
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Sección de Notificaciones
                const Text(
                  'Notificaciones',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.wb_sunny, color: Colors.orange),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Briefing Matutino',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Recibe un recordatorio diario para revisar tus tareas',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _briefingEnabled,
                              onChanged: _toggleBriefing,
                            ),
                          ],
                        ),
                        if (_briefingEnabled) ...[
                          const Divider(height: 24),
                          InkWell(
                            onTap: _selectBriefingTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withAlpha((0.3 * 255).round()),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, size: 20),
                                  const SizedBox(width: 12),
                                  const Text('Hora:'),
                                  const Spacer(),
                                  Text(
                                    '${_briefingTime.hour.toString().padLeft(2, '0')}:${_briefingTime.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.edit, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Sección de Adjuntos del Dossier
                const Text(
                  'Adjuntos del Dossier',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Añadir PDFs'),
                          onPressed: () async {
                            String? snackBarMessage;
                            try {
                              final files = await openFiles(
                                acceptedTypeGroups: [
                                  XTypeGroup(extensions: ['pdf'], label: 'PDF')
                                ],
                              );
                              if (files.isNotEmpty) {
                                final List<String> paths = [];
                                for (final f in files) {
                                  final p = await _ensureFilePath(f);
                                  if (p != null && p.isNotEmpty) paths.add(p);
                                }
                                if (paths.isNotEmpty) {
                                  final current = await _prefsService.getDossierFiles();
                                  final merged = {...current, ...paths}.toList();
                                  await _prefsService.saveDossierFiles(merged);
                                  // refresh UI
                                  setState(() {
                                    snackBarMessage = 'PDF(s) añadidos';
                                  });
                                } else {
                                  setState(() {
                                    snackBarMessage = 'No se pudo acceder a los archivos seleccionados';
                                  });
                                }
                              }
                            } on MissingPluginException catch (_) {
                              setState(() {
                                snackBarMessage = 'Función no soportada en esta plataforma (MissingPluginException).';
                              });
                            } catch (e) {
                              setState(() {
                                snackBarMessage = 'Error al añadir PDF: $e';
                              });
                            }
                            if (snackBarMessage != null && mounted) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snackBarMessage!)));
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<List<String>>(
                          future: _prefsService.getDossierFiles(),
                          builder: (context, snap) {
                            final files = snap.data ?? [];
                            if (files.isEmpty) return const Text('No hay PDFs añadidos.');
                            return Column(
                              children: files.map((p) {
                                final name = p.split(RegExp(r'[\\\\/]')).last;
                                return ListTile(
                                  title: Text(name),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      String? snackBarMessage;
                                      final current = await _prefsService.getDossierFiles();
                                      final updated = current.where((x) => x != p).toList();
                                      await _prefsService.saveDossierFiles(updated);
                                      setState(() {
                                        snackBarMessage = 'Adjunto eliminado';
                                      });
                                      if (snackBarMessage != null && mounted) {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snackBarMessage!)));
                                          }
                                        });
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Sección de Plantilla del Dossier
                const Text(
                  'Plantilla del Dossier',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Usa [Nombre] para insertar el nombre del contacto automáticamente.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Escribe tu mensaje aquí...',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
