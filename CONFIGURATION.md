# Configuración del Proyecto - Musician Organizer

## 📋 Índice
1. [Paquetes Instalados](#paquetes-instalados)
2. [Configuración Android](#configuración-android)
3. [Configuración iOS](#configuración-ios)
4. [Nuevas Características Implementadas](#nuevas-características-implementadas)
5. [Comandos de Desarrollo](#comandos-de-desarrollo)
6. [Estructura del Proyecto](#estructura-del-proyecto)

---

## 📦 Paquetes Instalados

### Estado y Navegación
- `flutter_riverpod: ^2.5.1` - State management

### UI y Widgets
- `table_calendar: ^3.1.2` - Widget de calendario
- `cupertino_icons: ^1.0.8` - Iconos iOS

### Persistencia y Almacenamiento
- `hive: ^2.2.3` - Base de datos NoSQL local
- `hive_flutter: ^1.1.0` - Integración de Hive con Flutter
- `path_provider: ^2.1.2` - Acceso a directorios del sistema
- `shared_preferences: ^2.3.2` - Preferencias simples

### Notificaciones
- `flutter_local_notifications: ^17.2.2` - Notificaciones locales
- `timezone: ^0.9.4` - Manejo de zonas horarias

### Ubicación y Mapas
- `geolocator: ^12.0.0` - Servicios de geolocalización
- `url_launcher: ^6.3.0` - Abrir URLs y mapas

### Permisos
- `permission_handler: ^11.3.1` - Gestión de permisos

### Entrada de Datos
- `speech_to_text: ^7.3.0` - Reconocimiento de voz
- `google_mlkit_text_recognition: ^0.15.0` - OCR
- `receive_sharing_intent: ^1.8.1` - Compartir desde otras apps
- `contacts_service: ^0.6.3` - Acceso a contactos

### Utilidades
- `intl: ^0.19.0` - Internacionalización (español)
- `uuid: ^4.4.2` - Generación de IDs únicos
- `vibration: ^2.0.0` - Feedback háptico

### Dev Dependencies
- `hive_generator: ^2.0.1` - Generador de TypeAdapters
- `build_runner: ^2.4.8` - Herramienta de generación de código
- `flutter_lints: ^4.0.0` - Análisis de código

---

## 🤖 Configuración Android

### 1. Permisos en `android/app/src/main/AndroidManifest.xml`

Añade estos permisos ANTES del tag `<application>`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Notificaciones -->
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <!-- Ubicación -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

    <!-- Internet -->
    <uses-permission android:name="android.permission.INTERNET" />

    <!-- Contactos -->
    <uses-permission android:name="android.permission.READ_CONTACTS" />
    <uses-permission android:name="android.permission.WRITE_CONTACTS" />

    <!-- Micrófono para voz -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />

    <!-- Cámara para OCR -->
    <uses-permission android:name="android.permission.CAMERA" />

    <!-- Almacenamiento -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

    <application>
        <!-- Tu configuración existente -->
    </application>
</manifest>
```

### 2. Versión mínima del SDK

En `android/app/build.gradle`, actualiza:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Cambia de flutter.minSdkVersion a 21
        targetSdkVersion 34
        // ... resto de la configuración
    }
}
```

### 3. Proguard (Opcional para Release)

Si usas Proguard, añade en `android/app/proguard-rules.pro`:

```proguard
-keep class * extends com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
```

---

## 🍎 Configuración iOS

### 1. Permisos en `ios/Runner/Info.plist`

Añade estas claves dentro del tag `<dict>`:

```xml
<dict>
    <!-- Notificaciones -->
    <key>UIBackgroundModes</key>
    <array>
        <string>fetch</string>
        <string>remote-notification</string>
    </array>

    <!-- Ubicación -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Necesitamos tu ubicación para sugerir lugares cercanos a tus eventos</string>

    <key>NSLocationAlwaysUsageDescription</key>
    <string>Necesitamos tu ubicación para recordatorios basados en ubicación</string>

    <!-- Micrófono -->
    <key>NSMicrophoneUsageDescription</key>
    <string>Necesitamos acceso al micrófono para entrada por voz</string>

    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Necesitamos reconocimiento de voz para crear eventos con tu voz</string>

    <!-- Cámara -->
    <key>NSCameraUsageDescription</key>
    <string>Necesitamos la cámara para escanear texto de imágenes</string>

    <key>NSPhotoLibraryUsageDescription</key>
    <string>Necesitamos acceso a fotos para escanear texto de imágenes</string>

    <!-- Contactos -->
    <key>NSContactsUsageDescription</key>
    <string>Necesitamos acceso a contactos para guardar y gestionar tus contactos</string>
</dict>
```

### 2. Versión mínima de iOS

En `ios/Podfile`, asegúrate de que la versión mínima sea 13.0:

```ruby
platform :ios, '13.0'
```

### 3. Actualizar Pods

Después de modificar el Podfile:

```bash
cd ios
pod install
cd ..
```

---

## 🎯 Nuevas Características Implementadas

### 1. ✅ Notificaciones Locales Inteligentes

**Características:**
- Múltiples recordatorios por evento/tarea (ej: 1 hora antes, 1 día antes)
- Notificaciones personalizadas por tipo:
  - **Bolos**: "🎸 ¡Bolo hoy! Prepara tu guitarra y el rider!"
  - **Tareas**: "✅ No olvides: [descripción]"
  - **Reuniones**: "📅 Reunión próximamente"
- Soporte para eventos recurrentes
- Cancelación automática al eliminar/completar

**Uso:**
- En formulario de Evento/Tarea, usa el widget "Recordatorios"
- Opciones rápidas: 5 min, 15 min, 30 min, 1 hora, 2 horas, 1 día, 2 días, 1 semana
- Personalizado: Define tu propio tiempo

**Archivo:** `lib/services/notification_service.dart`

### 2. 🔄 Repetición de Eventos y Tareas

**Características:**
- Tipos de repetición: Nunca, Diario, Semanal, Mensual
- Configurable: intervalo y número de repeticiones
- Genera automáticamente instancias hasta 1 año adelante
- Indicador visual de eventos recurrentes
- Editar serie completa o instancia individual

**Uso:**
- En formulario de Evento/Tarea, sección "Repetir"
- Selecciona frecuencia y configura intervalo
- Ejemplo: "Cada 2 semanas, 12 veces"

**Archivos:**
- `lib/models/recurrence_rule.dart`
- `lib/widgets/recurrence_selector.dart`

### 3. 🗺️ Integración de Mapas

**Características:**
- Campo "Lugar" en eventos
- Botón "Ver en mapa" que abre Google Maps/Apple Maps
- Sugerencia de ubicación actual con geolocalización
- Búsqueda automática de lugares
- Navegación desde ubicación actual al destino

**Uso:**
- En formulario de Evento, campo "Lugar"
- Escribe dirección o nombre del lugar
- Toca "Ver en mapa" para abrir en Maps
- Usa el botón de ubicación para sugerir tu ubicación actual

**Archivo:** `lib/services/location_service.dart`

### 4. 🔍 Búsqueda Global y Filtros

**Características:**
- Búsqueda unificada en Eventos, Tareas y Contactos
- Busca por título, descripción, lugar, nombre, teléfono
- Resultados agrupados por tipo con preview
- Navegación directa al detalle
- Filtros en Calendario y Agenda:
  - Todos
  - Solo bolos
  - Solo reuniones
  - Solo pendientes

**Uso:**
- Toca el icono de búsqueda (🔍) en el AppBar
- Escribe mínimo 2 caracteres
- Los resultados aparecen agrupados
- Toca un resultado para ver detalles

**Archivo:** `lib/widgets/global_search_delegate.dart`

### 5. 🎨 Tema Material 3 Profesional

**Características:**
- Tema claro y oscuro con paleta profesional
- Modo automático según configuración del sistema
- Opción manual en Ajustes
- Colores azul profesional (#1976D2)
- Bordes redondeados, elevaciones sutiles
- Transiciones suaves

**Uso:**
- Automático: sigue la configuración del sistema
- Manual: ve a Ajustes → Tema → Selecciona (Claro/Oscuro/Sistema)

**Archivo:** `lib/providers/theme_provider.dart`

### 6. ✨ Animaciones y Feedback Háptico

**Características:**
- AnimatedList para listas de eventos y tareas
- Dismissible para swipe:
  - Swipe derecha → Completar tarea
  - Swipe izquierda → Eliminar
- Feedback háptico al completar tareas
- FAB animado con Hero transitions
- Animación de check al completar ✓

**Uso:**
- Desliza tareas para completar o eliminar
- Siente la vibración al marcar como completada

**Ubicación:** Implementado en screens de Calendar y Agenda

### 7. 🎸 Campos Específicos para Bolos

**Características:**
- **Caché**: Guarda el caché del bolo (€)
- **Setlist**: Lista de canciones a tocar
- **Rider**: Rider técnico y hospitalidad
- Visible solo en eventos tipo "bolo"

**Uso:**
- En formulario de Evento, selecciona tipo "Bolo"
- Aparecen campos adicionales: Caché, Setlist, Rider
- Guarda toda la información del concierto

**Archivo:** `lib/models/evento.dart`

### 8. 💾 Persistencia con Hive

**Características:**
- Almacenamiento local eficiente
- Datos persisten entre sesiones
- Carga rápida sin conexión
- Soporte completo de recurrencia
- Backup automático

**Archivos:**
- `lib/services/hive_service.dart`
- `lib/models/*.g.dart` (adapters generados)

---

## 🛠️ Comandos de Desarrollo

### Instalar dependencias
```bash
flutter pub get
```

### Generar archivos de Hive (si modificas modelos)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Ejecutar en debug
```bash
flutter run
```

### Ejecutar en release
```bash
flutter run --release
```

### Limpiar caché
```bash
flutter clean
flutter pub get
```

### Construir APK
```bash
flutter build apk --release
```

### Construir AAB (Google Play)
```bash
flutter build appbundle --release
```

### Construir iOS
```bash
flutter build ios --release
```

---

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                          # Punto de entrada, inicialización
├── models/                            # Modelos de datos
│   ├── evento.dart                    # Modelo de Evento (con recurrencia, notificaciones, bolos)
│   ├── tarea.dart                     # Modelo de Tarea (con recurrencia, notificaciones)
│   ├── contacto.dart                  # Modelo de Contacto
│   ├── recurrence_rule.dart           # Regla de recurrencia
│   └── *.g.dart                       # Adapters de Hive generados
├── providers/                         # State management (Riverpod)
│   ├── app_providers.dart             # UI state (vista, fecha seleccionada)
│   ├── data_providers.dart            # Data state (eventos, tareas, contactos)
│   ├── settings_provider.dart         # Configuración (dossier template)
│   └── theme_provider.dart            # Tema (claro/oscuro/automático)
├── services/                          # Lógica de negocio
│   ├── hive_service.dart              # Persistencia con Hive
│   ├── notification_service.dart      # Notificaciones locales
│   ├── location_service.dart          # Geolocalización y mapas
│   ├── preferences_service.dart       # SharedPreferences
│   ├── voice_service.dart             # Reconocimiento de voz
│   ├── ocr_service.dart               # OCR con ML Kit
│   ├── whatsapp_service.dart          # Integración WhatsApp
│   └── device_contact_service.dart    # Contactos del dispositivo
├── screens/                           # Pantallas de la app
│   ├── main_screen.dart               # Navegación principal
│   ├── calendar_screen.dart           # Vista de calendario
│   ├── agenda_screen.dart             # Vista de tareas
│   ├── contacts_screen.dart           # Vista de contactos
│   ├── event_form_screen.dart         # Formulario de eventos
│   ├── task_form_screen.dart          # Formulario de tareas
│   ├── contact_form_screen.dart       # Formulario de contactos
│   └── settings_screen.dart           # Configuración
└── widgets/                           # Componentes reutilizables
    ├── event_card.dart                # Card de evento
    ├── task_card.dart                 # Card de tarea
    ├── contact_card.dart              # Card de contacto
    ├── proposal_dialog.dart           # Diálogo inteligente voz/OCR
    ├── global_search_delegate.dart    # Búsqueda global
    ├── recurrence_selector.dart       # Selector de recurrencia
    └── reminders_selector.dart        # Selector de recordatorios
```

---

## 🚀 Próximos Pasos

### 1. Primera ejecución
```bash
# Instalar dependencias
flutter pub get

# Ejecutar
flutter run
```

### 2. Permisos en tiempo de ejecución
La app solicitará permisos automáticamente cuando:
- Uses el micrófono para entrada de voz
- Accedas a ubicación para lugares
- Guardes contactos en el dispositivo
- Configures notificaciones

### 3. Datos de ejemplo
En el primer arranque, la app carga:
- 5 eventos de ejemplo (incluyendo bolo recurrente)
- 5 tareas de ejemplo (incluyendo tarea mensual recurrente)
- 4 contactos de ejemplo

### 4. Personalización
- Header: "Gestión de Calendario - Miguel Ángel Rosales"
- Colores: Azul profesional (#1976D2)
- Locale: Español (España)
- Timezone: Europe/Madrid

---

## 📝 Notas Importantes

1. **Notificaciones en iOS**: Debes solicitar permisos la primera vez. La app lo hace automáticamente.

2. **Ubicación**: Para sugerir ubicación actual, necesitas tener GPS activado y dar permisos.

3. **Datos persisten**: Todos los datos se guardan localmente con Hive. No se envían a ningún servidor.

4. **Recurrencia**: Las instancias recurrentes se generan hasta 1 año adelante o el límite configurado.

5. **Notificaciones exactas**: En Android 12+, necesitas permitir "Notificaciones exactas" en ajustes del sistema.

---

## 🐛 Solución de Problemas

### Problema: Notificaciones no funcionan
**Solución:**
1. Verifica permisos en Ajustes del dispositivo
2. En Android 12+, habilita "Notificaciones exactas"
3. Asegúrate de que la fecha/hora del evento es futura

### Problema: Geolocalización no funciona
**Solución:**
1. Verifica que el GPS esté activado
2. Da permisos de ubicación a la app
3. Prueba en un dispositivo real (no emulador)

### Problema: Voz no funciona
**Solución:**
1. Verifica permisos de micrófono
2. Asegúrate de tener conexión a internet (Google requiere conexión)
3. Comprueba el idioma del dispositivo (debe soportar español)

### Problema: Errores de compilación
**Solución:**
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

---

## 📞 Contacto

Para reportar bugs o sugerencias:
- Email: miguel@example.com
- GitHub: [Tu repositorio]

---

**¡Disfruta de tu app de calendario profesional! 🎸📅✨**
