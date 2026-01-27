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

final dossierTemplateProvider = NotifierProvider<DossierTemplateNotifier, String>(DossierTemplateNotifier.new);
