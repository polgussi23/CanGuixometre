import 'dart:io';

import 'package:can_guix/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/main_page.dart';
import 'pages/login_page.dart';
import 'services/user_provider.dart';
//import 'package:http/http.dart' as http;


class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega l'estat inicial de l'usuari per determinar la pàgina inicial
  final prefs = await SharedPreferences.getInstance();
  //await prefs.remove('authToken'); // Eliminar per a guardar la sessió!!!
  final token = prefs.getString('authToken');

  // Inicialitza el servei de notificacions
  if (!kIsWeb) {
    await Firebase.initializeApp();
    NotificationService notificationService = NotificationService();
    await notificationService.initialize();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
      ],
      child: MyApp(isLoggedIn: token != null),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CanGuixòmetre',
      theme: ThemeData.dark(),
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => MainPage(),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate, // Utilitza-ho si teniu widgets d'estil iOS (Cupertino)
      ],
      supportedLocales: const [
        Locale('en', 'US'), // Anglès
        Locale('es', 'ES'), // Castellà
        Locale('ca', 'ES'), // Català (el que necessites per al date picker)
        // Afegeix aquí qualsevol altre idioma que la teva app suporti
      ],
    );
  }
}
