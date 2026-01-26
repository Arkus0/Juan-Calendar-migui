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

class DossierTemplateNotifier extends StateNotifier<String> {
  final PreferencesService _prefsService;

  DossierTemplateNotifier(this._prefsService) : super(defaultDossierTemplate) {
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final saved = await _prefsService.getDossierTemplate();
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> updateTemplate(String newTemplate) async {
    state = newTemplate;
    await _prefsService.saveDossierTemplate(newTemplate);
  }
}

final dossierTemplateProvider = StateNotifierProvider<DossierTemplateNotifier, String>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider);
  return DossierTemplateNotifier(prefsService);
});
