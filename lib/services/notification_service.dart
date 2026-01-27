import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/evento.dart';
import '../models/tarea.dart';
import '../models/recurrence_rule.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    // Inicializar timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Madrid')); // España

    // Configuración Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Crear canal de notificaciones para Android
    await _createNotificationChannels();

    _initialized = true;
  }

  /// Crea los canales de notificación en Android
  Future<void> _createNotificationChannels() async {
    const boloChannel = AndroidNotificationChannel(
      'bolo_channel',
      'Bolos y Conciertos',
      description: 'Notificaciones para bolos y conciertos',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    const tareaChannel = AndroidNotificationChannel(
      'tarea_channel',
      'Tareas',
      description: 'Recordatorios de tareas pendientes',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    const eventoChannel = AndroidNotificationChannel(
      'evento_channel',
      'Eventos',
      description: 'Recordatorios de reuniones y eventos personales',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(boloChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(tareaChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(eventoChannel);
  }

  /// Maneja el tap en la notificación
  void _onNotificationTap(NotificationResponse response) {
    // Aquí puedes navegar a la pantalla correspondiente
    // basándote en response.payload
    debugPrint('Notificación tocada: ${response.payload}');
  }

  /// Solicita permisos de notificación (principalmente para iOS)
  Future<bool> requestPermissions() async {
    final iosImplementation = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    final granted = await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return granted ?? true; // Android no requiere solicitud explícita
  }

  /// Programa notificaciones para un evento
  /// 🔥 CORREGIDO: Ahora soporta eventos recurrentes
  Future<void> scheduleEventNotifications(Evento evento) async {
    if (!_initialized) await initialize();

    // Cancelar todas las notificaciones previas de este evento
    await cancelEventNotifications(evento.id);

    // 🔥 NUEVA LÓGICA: Verificar si el evento tiene recurrencia
    List<Evento> eventInstances;

    if (evento.recurrence != null && evento.recurrence!.type != RecurrenceType.none) {
      // Evento recurrente: generar todas las instancias
      eventInstances = evento.generateRecurringInstances();
      debugPrint('📅 Evento recurrente detectado: ${evento.titulo}');
      debugPrint('   Programando notificaciones para ${eventInstances.length} instancias');
    } else {
      // Evento único: usar solo este evento
      eventInstances = [evento];
    }

    // Programar notificaciones para cada instancia
    int totalScheduled = 0;
    for (var instanceIndex = 0; instanceIndex < eventInstances.length; instanceIndex++) {
      final instance = eventInstances[instanceIndex];

      // Si la instancia ya pasó, no programar notificaciones
      if (instance.inicio.isBefore(DateTime.now())) {
        continue;
      }

      // Programar cada recordatorio para esta instancia
      for (var reminderIndex = 0; reminderIndex < instance.reminders.length; reminderIndex++) {
        final reminder = instance.reminders[reminderIndex];
        final notificationTime = instance.inicio.subtract(Duration(minutes: reminder));

        // Solo programar si la notificación es futura
        if (notificationTime.isAfter(DateTime.now())) {
          // 🔥 NUEVO: ID único que combina evento + instancia + recordatorio
          final notificationId = _getRecurringEventNotificationId(
            evento.id,
            instanceIndex,
            reminderIndex,
          );

          String title;
          String body;

          if (instance.isBolo) {
            title = '🎸 ¡Bolo hoy!';
            body = '${instance.titulo}\n¡Prepara tu guitarra y el rider!';
            if (instance.lugar != null) {
              body += '\n📍 ${instance.lugar}';
            }
          } else if (instance.isReunion) {
            title = '📅 Reunión próximamente';
            body = instance.titulo;
            if (instance.lugar != null) {
              body += '\n📍 ${instance.lugar}';
            }
          } else {
            title = '📌 Evento próximamente';
            body = instance.titulo;
          }

          await _scheduleNotification(
            id: notificationId,
            title: title,
            body: body,
            scheduledDate: notificationTime,
            channelId: instance.isBolo ? 'bolo_channel' : 'evento_channel',
            payload: 'evento:${evento.id}:$instanceIndex',
          );

          totalScheduled++;
        }
      }
    }

    debugPrint('✅ Programadas $totalScheduled notificaciones para "${evento.titulo}"');
  }

  /// Programa notificaciones para una tarea
  /// 🔥 CORREGIDO: Ahora soporta tareas recurrentes
  Future<void> scheduleTaskNotifications(Tarea tarea) async {
    if (!_initialized) await initialize();

    // Cancelar notificaciones previas si existe
    await cancelTaskNotifications(tarea.id);

    // Si la tarea está completada, no programar
    if (tarea.completada) {
      return;
    }

    // 🔥 NUEVA LÓGICA: Verificar si la tarea tiene recurrencia
    List<Tarea> taskInstances;

    if (tarea.recurrence != null && tarea.recurrence!.type != RecurrenceType.none) {
      // Tarea recurrente: generar todas las instancias
      taskInstances = tarea.generateRecurringInstances();
      debugPrint('🔄 Tarea recurrente detectada: ${tarea.descripcion}');
      debugPrint('   Programando notificaciones para ${taskInstances.length} instancias');
    } else {
      // Tarea única: usar solo esta tarea
      taskInstances = [tarea];
    }

    // Programar notificaciones para cada instancia
    int totalScheduled = 0;
    for (var instanceIndex = 0; instanceIndex < taskInstances.length; instanceIndex++) {
      final instance = taskInstances[instanceIndex];

      // Si la instancia ya pasó, no programar
      if (instance.fechaCompleta.isBefore(DateTime.now())) {
        continue;
      }

      // Programar cada recordatorio para esta instancia
      for (var reminderIndex = 0; reminderIndex < instance.reminders.length; reminderIndex++) {
        final reminder = instance.reminders[reminderIndex];
        final notificationTime = instance.fechaCompleta.subtract(Duration(minutes: reminder));

        // Solo programar si la notificación es futura
        if (notificationTime.isAfter(DateTime.now())) {
          // 🔥 NUEVO: ID único que combina tarea + instancia + recordatorio
          final notificationId = _getRecurringTaskNotificationId(
            tarea.id,
            instanceIndex,
            reminderIndex,
          );

          await _scheduleNotification(
            id: notificationId,
            title: '✅ No olvides:',
            body: instance.descripcion,
            scheduledDate: notificationTime,
            channelId: 'tarea_channel',
            payload: 'tarea:${tarea.id}:$instanceIndex',
          );

          totalScheduled++;
        }
      }
    }

    debugPrint('✅ Programadas $totalScheduled notificaciones para tarea "${tarea.descripcion}"');
  }

  /// Programa una notificación individual
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channelId,
    String? payload,
  }) async {
    final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTZ,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == 'bolo_channel'
              ? 'Bolos y Conciertos'
              : channelId == 'tarea_channel'
                  ? 'Tareas'
                  : 'Eventos',
          channelDescription: 'Recordatorios',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Cancela todas las notificaciones de un evento (incluyendo instancias recurrentes)
  /// 🔥 MEJORADO: Ahora cancela notificaciones de todas las instancias
  Future<void> cancelEventNotifications(String eventId) async {
    // Cancelar notificaciones de hasta 100 instancias con hasta 10 recordatorios cada una
    // (100 instancias * 10 recordatorios = 1000 notificaciones posibles)
    for (var instanceIndex = 0; instanceIndex < 100; instanceIndex++) {
      for (var reminderIndex = 0; reminderIndex < 10; reminderIndex++) {
        final notificationId = _getRecurringEventNotificationId(
          eventId,
          instanceIndex,
          reminderIndex,
        );
        await _notifications.cancel(notificationId);
      }
    }
  }

  /// Cancela todas las notificaciones de una tarea (incluyendo instancias recurrentes)
  /// 🔥 MEJORADO: Ahora cancela notificaciones de todas las instancias
  Future<void> cancelTaskNotifications(String taskId) async {
    // Cancelar notificaciones de hasta 100 instancias con hasta 10 recordatorios cada una
    for (var instanceIndex = 0; instanceIndex < 100; instanceIndex++) {
      for (var reminderIndex = 0; reminderIndex < 10; reminderIndex++) {
        final notificationId = _getRecurringTaskNotificationId(
          taskId,
          instanceIndex,
          reminderIndex,
        );
        await _notifications.cancel(notificationId);
      }
    }
  }

  /// Cancela todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Obtiene las notificaciones pendientes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// 🔥 NUEVO: Genera un ID único para notificación de evento recurrente
  /// Combina: eventId + instanceIndex + reminderIndex
  int _getRecurringEventNotificationId(
    String eventId,
    int instanceIndex,
    int reminderIndex,
  ) {
    // Crear un string único combinando los tres parámetros
    final uniqueString = '${eventId}_${instanceIndex}_$reminderIndex';
    return uniqueString.hashCode.abs() % 2147483647;
  }

  /// 🔥 NUEVO: Genera un ID único para notificación de tarea recurrente
  /// Combina: taskId + instanceIndex + reminderIndex
  int _getRecurringTaskNotificationId(
    String taskId,
    int instanceIndex,
    int reminderIndex,
  ) {
    // Crear un string único combinando los tres parámetros
    // Añadimos 'T' para diferenciar de eventos
    final uniqueString = 'T_${taskId}_${instanceIndex}_$reminderIndex';
    return uniqueString.hashCode.abs() % 2147483647;
  }

  /// Genera un ID único para notificación de evento (legacy - mantener por compatibilidad)
  // Legacy helpers kept for compatibility; not referenced directly by current scheduling logic.
  // ignore: unused_element
  int _getEventNotificationId(String eventId, int reminderIndex) {
    return ('${eventId.hashCode}$reminderIndex').hashCode.abs() % 2147483647;
  }

  /// Genera un ID único para notificación de tarea (legacy - mantener por compatibilidad)
  // ignore: unused_element
  int _getTaskNotificationId(String taskId, int reminderIndex) {
    return ('${taskId.hashCode}${reminderIndex}1').hashCode.abs() % 2147483647;
  }

  /// Muestra una notificación inmediata (para testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 2147483647,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'evento_channel',
          'Eventos',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
