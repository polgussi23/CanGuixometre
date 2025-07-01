import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Mètode per inicialitzar el servei:
  /// - Demana permisos (especialment important per a iOS).
  /// - Configura les notificacions locals per Android i iOS.
  /// - Configura els listeners per a notificacions en primer pla i quan l'usuari clica sobre elles.
  Future<void> initialize() async {
    // 1. Demanar permisos per a iOS (i també Android si cal)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Permís de notificació concedit.');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('Permís provisional concedit.');
    } else {
      debugPrint('Permís de notificació denegat.');
    }

    // 2. Inicialitzar notificacions locals per a Android/iOS
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (payload) async {
        // Gestiona la navegació o accions quan l'usuari toca la notificació
        debugPrint('Notificació seleccionada amb payload: $payload');
      },
    );

    // 3. Configurar el listener per a notificacions en primer pla
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Rebem notificació en primer pla: ${message.notification?.title}');
      // Mostrem una notificació local quan rebem una notificació mentre l'app està oberta
      _showLocalNotification(message);
    });

    // 4. Listener per quan l'usuari toca la notificació (app pot estar en segon pla o tancada)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notificació oberta per l\'usuari: ${message.notification?.title}');
      // Aquí pots gestionar la navegació o accions necessàries
    });
  }

  /// Mètode per obtenir el token del dispositiu.
  Future<String?> getDeviceToken() async {
    try {
      String? token = await _messaging.getToken();
      debugPrint("Token del dispositiu: $token");
      return token;
    } catch (e) {
      debugPrint("Error obtenint el token: $e");
      return null;
    }
  }

  /// Mètode privat per mostrar una notificació local utilitzant el plugin.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Ens assegurem que tenim notificació i que estem en Android (per aquest exemple)
    if (notification != null && android != null) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'your_channel_id', // Canvia-ho pel teu canal
        'your_channel_name', // Nom del canal
        channelDescription: 'your_channel_description', // Descripció del canal
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      await _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
        payload: 'Notificació', // Pots afegir informació addicional si cal
      );
    }
  }
}
