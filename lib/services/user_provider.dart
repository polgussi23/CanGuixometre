import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  String? _nom;
  String? _usuari;
  String? _estat;
  int? _id;
  String? _token;

  String? get nom => _nom;
  String? get usuari => _usuari;
  String? get estat => _estat;
  int? get id => _id;
  String? get token => _token;

  // Carrega les dades de l'usuari des de SharedPreferences
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _nom = prefs.getString('nom');
    _usuari = prefs.getString('usuari');
    _estat = prefs.getString('estat');
    _id = prefs.getInt('id');
    _token = prefs.getString('authToken');
    notifyListeners();
  }

  // Desa les dades de l'usuari a SharedPreferences
  Future<void> saveUser(
      String nom, String usuari, String estat, int? id, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nom', nom);
    await prefs.setString('usuari', usuari);
    await prefs.setString('estat', estat);
    if (id != null) {
      await prefs.setInt('id', id);
    }
    await prefs.setString('authToken', token);
    _nom = nom;
    _usuari = usuari;
    _id = id;
    _token = token;
    notifyListeners();
  }

  // Fa logout i esborra les dades de SharedPreferences
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('nom');
    await prefs.remove('usuari');
    await prefs.remove('estat');
    await prefs.remove('id');
    _nom = null;
    _usuari = null;
    _estat = null;
    _id = null;
    _token = null;
    notifyListeners();
  }

  Map<String, dynamic> getUserInfo() {
    return {
      'nom': _nom,
      'usuari': _usuari,
      'estat': _estat,
      'id': _id,
      'token': _token,
    };
  }
}
