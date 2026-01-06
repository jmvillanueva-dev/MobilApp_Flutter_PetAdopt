import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Servicio singleton para gestionar notificaciones locales
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

    // Configuración para Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Inicializar plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicitar permisos en Android 13+
    await _requestPermissions();

    _initialized = true;
    debugPrint('✅ NotificationService initialized');
  }

  /// Solicita permisos de notificación
  Future<void> _requestPermissions() async {
    // Android 13+ requiere permisos explícitos
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    // iOS siempre requiere permisos
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Maneja el tap en una notificación
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Navegar a la página de solicitudes cuando se implemente navegación global
  }

  /// Muestra una notificación de nueva solicitud (para refugios)
  Future<void> showNewRequestNotification({
    required String petName,
    required String adopterName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'adoption_requests',
      'Solicitudes de Adopción',
      channelDescription: 'Notificaciones de nuevas solicitudes de adopción',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // ID único
      '🐾 Nueva Solicitud de Adopción',
      '$adopterName quiere adoptar a $petName',
      details,
      payload: 'adoption_request',
    );
  }

  /// Muestra una notificación de cambio de estado (para adoptantes)
  Future<void> showStatusChangeNotification({
    required String petName,
    required String status,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'adoption_status',
      'Estado de Solicitudes',
      channelDescription:
          'Notificaciones de cambios en el estado de solicitudes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final emoji = status == 'aprobada' ? '✅' : '❌';
    final message = status == 'aprobada'
        ? 'Tu solicitud para adoptar a $petName fue aprobada'
        : 'Tu solicitud para adoptar a $petName fue rechazada';

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // ID único
      '$emoji Actualización de Solicitud',
      message,
      details,
      payload: 'status_change',
    );
  }

  /// Cancela todas las notificaciones
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
