import 'package:can_guix/pages/new_meal_advertise_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'ranking_page.dart';
import 'photo_gallery_page.dart';
import 'history_page.dart';
//import 'edit_user_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    RankingPage(),
    PhotoGalleryPage(),
    HistoryPage(),
    NewMealAdvertisePage(),
  ];

  // Versió actual de l'app
  final currentVersion = "1.3.2"; // VERSIÓ ACTUAL APP

  final ApiService _apiService = ApiService(); // Instància de ApiService

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      checkForUpdates(); // Comprovar actualitzacions quan es carrega la pàgina
      ApiService.sendFirebaseToken();
    }
  }

  Future<void> checkForUpdates() async {
    try {
      // Cridar el mètode getVersion des de ApiService
      final data = await _apiService.getVersion();
      String latestVersion = data['version'];

      if (latestVersion != currentVersion) {
        _showUpdateDialog();
      }
    } catch (e) {
      print("Error al fer la comprovació d'actualització: $e");
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Nova versió disponible"),
          content: Text("Hi ha una nova versió de l'app disponible.\n"),
          actions: <Widget>[
            TextButton(
              child: Text("Descarregar"),
              onPressed: () {
                Navigator.of(context).pop();
                openGooglePlay(); // Redirigeix a l'usuari per descarregar l'APK
              },
            ),
            TextButton(
              child: Text("Després"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> openGooglePlay() async {
    // Canvia "com.example.app" pel package id de la teva aplicació
    const String packageId = 'cat.polgussi.can_guix';

    // Primer intentem amb el protocol 'market://'
    final Uri marketUri = Uri.parse('market://details?id=$packageId');
    // També tenim l'enllaç web com a fallback
    final Uri webUri =
        Uri.parse('https://play.google.com/store/apps/details?id=$packageId');

    // Comprovem si és possible obrir l'URI amb market://
    if (await canLaunchUrl(marketUri)) {
      await launchUrl(marketUri);
    } else if (await canLaunchUrl(webUri)) {
      // Fallback al web si no funciona el market://
      await launchUrl(webUri);
    } else {
      throw 'No es pot obrir el Google Play Store.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Colors.orange, // Ícon seleccionat de color taronja
          unselectedItemColor:
              Colors.white, // Ícon no seleccionat de color negre
          //backgroundColor: Colors.white, // Fons del BottomNavigationBar blanc
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.leaderboard), label: 'Ranking'),
            BottomNavigationBarItem(icon: Icon(Icons.image), label: 'Galeria'),
            BottomNavigationBarItem(
                icon: Icon(Icons.menu_book), label: 'Història'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month), label: 'Agenda'),
          ],
        ));
  }
}
