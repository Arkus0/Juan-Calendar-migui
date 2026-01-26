# 🎸 Gestión de Calendario - Miguel Ángel Rosales

## App profesional de gestión de calendario para músicos con funciones avanzadas

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.4+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

</div>

---

## ✨ Características Principales

### 🔔 Notificaciones Inteligentes
- **Recordatorios múltiples** por evento/tarea (5 min, 30 min, 1 hora, 1 día, personalizado)
- **Notificaciones contextuales**:
  - Bolos: "🎸 ¡Bolo hoy! Prepara tu guitarra y el rider!"
  - Tareas: "✅ No olvides: [descripción]"
- **Soporte recurrencia**: notificaciones para todas las instancias
- **Cancelación automática** al completar o eliminar

### 🔄 Eventos y Tareas Recurrentes
- **Frecuencias**: Nunca, Diario, Semanal, Mensual, Personalizado
- **Configuración avanzada**: intervalo y número de repeticiones
- **Generación automática** de instancias hasta 1 año adelante
- **Indicador visual** de elementos recurrentes
- **Edición flexible**: editar serie completa o instancia individual

### 🗺️ Integración de Mapas
- **Campo de lugar** con autocompletado
- **Botón "Ver en mapa"** → Abre Google Maps/Apple Maps
- **Geolocalización**: sugiere ubicación actual
- **Navegación**: ruta desde tu ubicación al destino
- **Búsqueda inteligente** de lugares

### 🔍 Búsqueda Global y Filtros
- **Búsqueda unificada** en Eventos, Tareas y Contactos
- **Busca por**: título, lugar, descripción, nombre, teléfono, email
- **Resultados agrupados** con preview
- **Filtros inteligentes**:
  - Todos los elementos
  - Solo bolos
  - Solo reuniones
  - Solo tareas pendientes

### 🎨 UI Profesional y Adictiva
- **Material 3**: diseño moderno y limpio
- **Modo oscuro/claro**: automático o manual
- **Animaciones fluidas**:
  - AnimatedList para listas
  - Dismissible: swipe para completar/eliminar
  - Transiciones Hero
- **Feedback háptico**: vibración sutil al completar
- **Colores profesionales**: azul #1976D2
- **Header personalizado**: "Gestión de Calendario - Miguel Ángel Rosales"

### 🎸 Específico para Músicos
- **Campos de bolos**:
  - 💰 **Caché**: Guarda el pago del bolo
  - 🎵 **Setlist**: Lista de canciones
  - 📋 **Rider**: Rider técnico y hospitalidad
- **Dossier personalizable**: envía tu perfil por WhatsApp
- **Gestión de contactos**: promotores, salas, técnicos
- **Vista de calendario** con código de colores por tipo

### 🎤 Entrada Inteligente
- **Voz**: crea eventos y tareas hablando
- **OCR**: escanea pósters y carteles para extraer información
- **Compartir**: recibe texto e imágenes desde otras apps
- **Propuesta inteligente**: sugiere tipo de evento según contexto

### 💾 Persistencia Robusta
- **Hive**: base de datos local rápida y eficiente
- **Sin conexión**: todos los datos locales
- **Backup automático**: no pierdes información
- **Carga instantánea**: acceso inmediato a tus datos

---

## 🚀 Instalación y Configuración

### Requisitos previos
- Flutter SDK 3.4 o superior
- Dart 3.4 o superior
- Android Studio / Xcode (para desarrollo)
- Dispositivo Android 5.0+ (API 21+) o iOS 13.0+

### Paso 1: Clonar el repositorio
```bash
git clone https://github.com/Arkus0/Juan-Calendar-migui.git
cd Juan-Calendar-migui
```

### Paso 2: Instalar dependencias
```bash
flutter pub get
```

### Paso 3: Generar archivos de Hive (si es necesario)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Paso 4: Configurar permisos

#### Android
Edita `android/app/src/main/AndroidManifest.xml` y añade los permisos necesarios (ver [CONFIGURATION.md](CONFIGURATION.md))

#### iOS
Edita `ios/Runner/Info.plist` y añade las descripciones de permisos (ver [CONFIGURATION.md](CONFIGURATION.md))

### Paso 5: Ejecutar
```bash
flutter run
```

Para instrucciones detalladas, consulta [CONFIGURATION.md](CONFIGURATION.md).

---

## 📚 Estructura del Proyecto

```
lib/
├── main.dart                       # Punto de entrada
├── models/                         # Modelos de datos con Hive
│   ├── evento.dart
│   ├── tarea.dart
│   ├── contacto.dart
│   └── recurrence_rule.dart
├── providers/                      # State management (Riverpod)
│   ├── data_providers.dart
│   ├── theme_provider.dart
│   └── settings_provider.dart
├── services/                       # Lógica de negocio
│   ├── hive_service.dart
│   ├── notification_service.dart
│   ├── location_service.dart
│   ├── voice_service.dart
│   └── ocr_service.dart
├── screens/                        # Pantallas
│   ├── main_screen.dart
│   ├── calendar_screen.dart
│   ├── agenda_screen.dart
│   └── contacts_screen.dart
└── widgets/                        # Componentes reutilizables
    ├── global_search_delegate.dart
    ├── recurrence_selector.dart
    └── reminders_selector.dart
```

---

## 🛠️ Tecnologías Utilizadas

| Categoría | Tecnologías |
|-----------|------------|
| **Framework** | Flutter 3.4+, Dart 3.4+ |
| **State Management** | Riverpod 2.5+ |
| **Base de Datos** | Hive 2.2+ |
| **Notificaciones** | flutter_local_notifications 17.2+ |
| **Ubicación** | geolocator 12.0+ |
| **UI** | Material 3, table_calendar |
| **Entrada** | speech_to_text, google_mlkit_text_recognition |
| **Otros** | timezone, url_launcher, vibration |

---

## 🎯 Casos de Uso

### 1. Músico/Banda
- Gestiona tus bolos con caché, setlist y rider
- Recordatorios antes de cada concierto
- Comparte dossier con promotores vía WhatsApp
- Eventos recurrentes para ensayos semanales

### 2. Manager Musical
- Organiza reuniones con artistas
- Gestiona contactos: salas, promotores, técnicos
- Vista de calendario con filtros por tipo
- Búsqueda rápida de cualquier elemento

### 3. Promotor de Eventos
- Planifica festivales y conciertos
- Ubicaciones en mapa para cada evento
- Tareas recurrentes para gestión mensual
- Notificaciones de hitos importantes

---

## 🐛 Reporte de Bugs

Si encuentras un bug:
1. Verifica que no esté ya reportado en [Issues](https://github.com/Arkus0/Juan-Calendar-migui/issues)
2. Crea un nuevo Issue con:
   - Descripción clara del problema
   - Pasos para reproducirlo
   - Screenshots si es posible
   - Versión de Flutter y dispositivo

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver archivo `LICENSE` para más detalles.

---

## 👤 Autor

**Miguel Ángel Rosales**
- GitHub: [@Arkus0](https://github.com/Arkus0)

---

## 🙏 Agradecimientos

- [Flutter Team](https://flutter.dev) por el increíble framework
- Comunidad de Flutter España
- Todos los músicos que inspiraron esta app

---

## 📞 Soporte

¿Necesitas ayuda? Consulta:
- [Documentación de configuración](CONFIGURATION.md)
- [Issues de GitHub](https://github.com/Arkus0/Juan-Calendar-migui/issues)

---

<div align="center">

**Hecho con ❤️ en Sevilla, Andalucía 🎸**

</div>
