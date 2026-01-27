import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/evento.dart';
import '../models/recurrence_rule.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Callback para manejar la navegación desde notificaciones
  Function(String?)? onNotificationTapCallback;

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
      settings: initSettings,
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

    const briefingChannel = AndroidNotificationChannel(
      'briefing_channel',
      'Briefing Matutino',
      description: 'Notificación diaria para revisar tus tareas',
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

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(briefingChannel);
  }

  /// Maneja el tap en la notificación
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notificación tocada: ${response.payload}');

    // Llamar al callback si está registrado
    if (onNotificationTapCallback != null) {
      onNotificationTapCallback!(response.payload);
    }
  }

  /// Solicita permisos de notificación en iOS y métodos auxiliares para Android
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

  /// Solicita permiso para mostrar notificaciones en Android 13+
  Future<void> requestAndroidNotificationsPermission() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Solicita permiso para usar alarmas exactas en Android 14 (si la app lo necesita)
  Future<void> requestExactAlarmsPermission() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
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

  /// Programa notificaciones para una tarea representada por `Evento` (solo si tiene fecha)
  Future<void> scheduleTaskNotifications(Evento evento) async {
    if (!_initialized) await initialize();

    // Solo programar si es una tarea y tiene fecha
    if (!evento.isTask || !evento.hasDate) return;

    // Cancelar notificaciones previas si existe
    await cancelTaskNotifications(evento.id);

    // Si la tarea está completada, no programar
    if (evento.completada) {
      return;
    }

    // Obtener instancias (si tiene recurrencia)
    List<Evento> taskInstances;

    if (evento.recurrence != null && evento.recurrence!.type != RecurrenceType.none) {
      taskInstances = evento.generateRecurringInstances();
      debugPrint('🔄 Tarea recurrente detectada: ${evento.titulo}');
      debugPrint('   Programando notificaciones para ${taskInstances.length} instancias');
    } else {
      taskInstances = [evento];
    }

    // Programar notificaciones para cada instancia
    int totalScheduled = 0;
    for (var instanceIndex = 0; instanceIndex < taskInstances.length; instanceIndex++) {
      final instance = taskInstances[instanceIndex];

      // Si la instancia ya pasó, no programar
      if (instance.inicio.isBefore(DateTime.now())) {
        continue;
      }

      // Programar cada recordatorio para esta instancia
      for (var reminderIndex = 0; reminderIndex < instance.reminders.length; reminderIndex++) {
        final reminder = instance.reminders[reminderIndex];
        final notificationTime = instance.inicio.subtract(Duration(minutes: reminder));

        // Solo programar si la notificación es futura
        if (notificationTime.isAfter(DateTime.now())) {
          final notificationId = _getRecurringTaskNotificationId(
            evento.id,
            instanceIndex,
            reminderIndex,
          );

          await _scheduleNotification(
            id: notificationId,
            title: '✅ No olvides:',
            body: instance.titulo,
            scheduledDate: notificationTime,
            channelId: 'tarea_channel',
            payload: 'tarea:${evento.id}:$instanceIndex',
          );

          totalScheduled++;
        }
      }

      // Notificaciones automáticas: una semana y un día antes de la fecha máxima
      if (instance.hasDate) {
        final fechaMax = instance.inicio;
        final now = DateTime.now();
        final unaSemanaAntes = fechaMax.subtract(const Duration(days: 7));
        final unDiaAntes = fechaMax.subtract(const Duration(days: 1));
        if (unaSemanaAntes.isAfter(now)) {
          await _scheduleNotification(
            id: fechaMax.hashCode ^ 7000,
            title: '⏰ Tarea próxima a vencer',
            body: 'Queda 1 semana para: ${instance.titulo}',
            scheduledDate: unaSemanaAntes,
            channelId: 'tarea_channel',
            payload: 'tarea:${evento.id}:$instanceIndex',
          );
          totalScheduled++;
        }
        if (unDiaAntes.isAfter(now)) {
          await _scheduleNotification(
            id: fechaMax.hashCode ^ 1000,
            title: '⏰ Tarea próxima a vencer',
            body: 'Queda 1 día para: ${instance.titulo}',
            scheduledDate: unDiaAntes,
            channelId: 'tarea_channel',
            payload: 'tarea:${evento.id}:$instanceIndex',
          );
          totalScheduled++;
        }
      }
    }

    debugPrint('✅ Programadas $totalScheduled notificaciones para tarea "${evento.titulo}"');
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

    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTZ,
        notificationDetails: NotificationDetails(
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
        payload: payload,
      );
    } on PlatformException catch (e) {
      // Fallback: if exact alarms aren't permitted, schedule inexact to avoid crashing
      if (e.code == 'exact_alarms_not_permitted') {
        debugPrint('Exact alarms not permitted, scheduling inexact fallback for notification $id');
        await _notifications.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledTZ,
          notificationDetails: NotificationDetails(
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
          androidScheduleMode: AndroidScheduleMode.inexact,
          payload: payload,
        );
      } else {
        rethrow;
      }
    }
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
        try {
          await _notifications.cancel(id: notificationId);
        } catch (e) {
          // In tests or environments without a platform implementation this
          // may fail; ignore to avoid crashing the app/tests.
          debugPrint('Failed to cancel notification $notificationId: $e');
        }
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
        try {
          await _notifications.cancel(id: notificationId);
        } catch (e) {
          // In tests or environments without a platform implementation this
          // may fail; ignore to avoid crashing the app/tests.
          debugPrint('Failed to cancel notification $notificationId: $e');
        }
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
      id: DateTime.now().millisecondsSinceEpoch % 2147483647,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
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

  /// Programa el Briefing Matutino diario
  /// Se repite automáticamente cada día a la hora especificada
  Future<void> scheduleDailyBriefing(TimeOfDay time) async {
    if (!_initialized) await initialize();

    // Cancelar el briefing anterior si existe
    await cancelDailyBriefing();

    // Crear fecha/hora para hoy a la hora especificada
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Si la hora ya pasó hoy, programar para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);

    try {
      await _notifications.zonedSchedule(
        id: 99999, // ID único para el briefing matutino
        title: '📅 Briefing Matutino',
        body: '¡Buenos días! Toca aquí para ver tus eventos y tareas de hoy.',
        scheduledDate: scheduledTZ,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'briefing_channel',
            'Briefing Matutino',
            channelDescription: 'Notificación diaria para revisar tus tareas',
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
        matchDateTimeComponents: DateTimeComponents.time, // Repetir diariamente
        payload: 'briefing_matutino',
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        debugPrint('Exact alarms not permitted, scheduling inexact fallback for briefing');
        await _notifications.zonedSchedule(
          id: 99999,
          title: '📅 Briefing Matutino',
          body: '¡Buenos días! Toca aquí para ver tus eventos y tareas de hoy.',
          scheduledDate: scheduledTZ,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'briefing_channel',
              'Briefing Matutino',
              channelDescription: 'Notificación diaria para revisar tus tareas',
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
          androidScheduleMode: AndroidScheduleMode.inexact,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'briefing_matutino',
        );
      } else {
        rethrow;
      }
    }

    debugPrint('✅ Briefing Matutino programado para las ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
  }

  /// Cancela el Briefing Matutino
  Future<void> cancelDailyBriefing() async {
    try {
      await _notifications.cancel(id: 99999);
    } catch (e) {
      debugPrint('Failed to cancel briefing notification: $e');
    }
    debugPrint('🔕 Briefing Matutino cancelado');
  }
}
