import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/evento.dart';
import '../models/tarea.dart';

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
    print('Notificación tocada: ${response.payload}');
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
  Future<void> scheduleEventNotifications(Evento evento) async {
    if (!_initialized) await initialize();

    // Cancelar notificaciones previas si existe
    await cancelEventNotifications(evento.id);

    // Si el evento ya pasó, no programar notificaciones
    if (evento.inicio.isBefore(DateTime.now())) return;

    for (var i = 0; i < evento.reminders.length; i++) {
      final reminder = evento.reminders[i];
      final notificationTime = evento.inicio.subtract(Duration(minutes: reminder));

      // Solo programar si la notificación es futura
      if (notificationTime.isAfter(DateTime.now())) {
        final notificationId = _getEventNotificationId(evento.id, i);

        String title;
        String body;

        if (evento.isBolo) {
          title = '🎸 ¡Bolo hoy!';
          body = '${evento.titulo}\n¡Prepara tu guitarra y el rider!';
          if (evento.lugar != null) {
            body += '\n📍 ${evento.lugar}';
          }
        } else if (evento.isReunion) {
          title = '📅 Reunión próximamente';
          body = evento.titulo;
          if (evento.lugar != null) {
            body += '\n📍 ${evento.lugar}';
          }
        } else {
          title = '📌 Evento próximamente';
          body = evento.titulo;
        }

        await _scheduleNotification(
          id: notificationId,
          title: title,
          body: body,
          scheduledDate: notificationTime,
          channelId: evento.isBolo ? 'bolo_channel' : 'evento_channel',
          payload: 'evento:${evento.id}',
        );
      }
    }
  }

  /// Programa notificaciones para una tarea
  Future<void> scheduleTaskNotifications(Tarea tarea) async {
    if (!_initialized) await initialize();

    // Cancelar notificaciones previas si existe
    await cancelTaskNotifications(tarea.id);

    // Si la tarea está completada o ya pasó, no programar
    if (tarea.completada || tarea.fechaCompleta.isBefore(DateTime.now())) {
      return;
    }

    for (var i = 0; i < tarea.reminders.length; i++) {
      final reminder = tarea.reminders[i];
      final notificationTime = tarea.fechaCompleta.subtract(Duration(minutes: reminder));

      // Solo programar si la notificación es futura
      if (notificationTime.isAfter(DateTime.now())) {
        final notificationId = _getTaskNotificationId(tarea.id, i);

        await _scheduleNotification(
          id: notificationId,
          title: '✅ No olvides:',
          body: tarea.descripcion,
          scheduledDate: notificationTime,
          channelId: 'tarea_channel',
          payload: 'tarea:${tarea.id}',
        );
      }
    }
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

  /// Cancela todas las notificaciones de un evento
  Future<void> cancelEventNotifications(String eventId) async {
    // Cancelar hasta 10 recordatorios posibles (más que suficiente)
    for (var i = 0; i < 10; i++) {
      await _notifications.cancel(_getEventNotificationId(eventId, i));
    }
  }

  /// Cancela todas las notificaciones de una tarea
  Future<void> cancelTaskNotifications(String taskId) async {
    // Cancelar hasta 10 recordatorios posibles
    for (var i = 0; i < 10; i++) {
      await _notifications.cancel(_getTaskNotificationId(taskId, i));
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

  /// Genera un ID único para notificación de evento
  int _getEventNotificationId(String eventId, int reminderIndex) {
    return ('${eventId.hashCode}$reminderIndex').hashCode.abs() % 2147483647;
  }

  /// Genera un ID único para notificación de tarea
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
