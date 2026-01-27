import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/preferences_service.dart';

final preferencesServiceProvider = Provider((ref) => PreferencesService());

const String defaultDossierTemplate = """¡Hola [Nombre]!

Aquí te envío mi dossier actualizado como cantautor:

- Bio breve: Cantautor sevillano con influencias flamencas y pop.
- Rider técnico: [describe o pega link]
- Tarifas aproximadas: Desde 300€ según formato y desplazamiento.
- Links importantes: EPK, vídeos en vivo, redes sociales...

¿Qué fechas tenéis disponibles para bolos?

Un saludo,
Juan José Moreno""";

class DossierTemplateNotifier extends Notifier<String> {
  @override
  String build() {
    // Start with default and load persisted value asynchronously.
    _loadTemplate();
    return defaultDossierTemplate;
  }

  Future<void> _loadTemplate() async {
    final prefs = ref.read(preferencesServiceProvider);
    final saved = await prefs.getDossierTemplate();
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> updateTemplate(String newTemplate) async {
    state = newTemplate;
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.saveDossierTemplate(newTemplate);
  }
}

// Provider for dossier attachment files
final dossierFilesProvider = FutureProvider<List<String>>((ref) async {
  final prefs = ref.read(preferencesServiceProvider);
  return prefs.getDossierFiles();
});

// Notifier to manage selection & updates
class DossierFilesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    _loadFiles();
    return [];
  }

  Future<void> _loadFiles() async {
    final prefs = ref.read(preferencesServiceProvider);
    final files = await prefs.getDossierFiles();
    state = files;
  }

  Future<void> setFiles(List<String> files) async {
    state = files;
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.saveDossierFiles(files);
  }
}

final dossierFilesNotifierProvider = NotifierProvider<DossierFilesNotifier, List<String>>(DossierFilesNotifier.new);

final dossierTemplateProvider = NotifierProvider<DossierTemplateNotifier, String>(DossierTemplateNotifier.new);
