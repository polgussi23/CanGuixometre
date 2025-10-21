// A can_guix/pages/new_meal_advertise_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:can_guix/pages/do_advertise_page.dart';
import 'package:can_guix/services/api_service.dart';
import 'package:can_guix/services/user_provider.dart';
import 'package:http/http.dart' as http;

class NewMealAdvertisePage extends StatefulWidget {
  const NewMealAdvertisePage({Key? key}) : super(key: key);

  @override
  _NewMealAdvertisePageState createState() => _NewMealAdvertisePageState();
}

class _NewMealAdvertisePageState extends State<NewMealAdvertisePage> {
  int? _currentUserId;
  List<dynamic> _avisos = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfileAndAvisos();
  }

  Future<void> _loadUserProfileAndAvisos() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await userProvider.getUserInfo();
      setState(() {
        _currentUserId = userProvider.id;
      });
      await _fetchAvisos();
    } catch (e) {
      print("Error al carregar les dades de l'usuari o avisos: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al carregar les dades.')),
      );
    }
  }

  Future<void> _fetchAvisos() async {
    try {
      final response = await ApiService.getAvisosFuturs();
      if (response.statusCode == 200) {
        setState(() {
          _avisos = json.decode(response.body);
          _avisos.sort((a, b) {
            DateTime dateA = DateTime.parse(a['data_avis']).toLocal();
            DateTime dateB = DateTime.parse(b['data_avis']).toLocal();

            DateTime dateTimeA = dateA;
            DateTime dateTimeB = dateB;

            if (a['hora_avis'] != null) {
              final partsA = (a['hora_avis'] as String).split(':');
              dateTimeA = dateTimeA.add(Duration(
                  hours: int.parse(partsA[0]), minutes: int.parse(partsA[1])));
            }
            if (b['hora_avis'] != null) {
              final partsB = (b['hora_avis'] as String).split(':');
              dateTimeB = dateTimeB.add(Duration(
                  hours: int.parse(partsB[0]), minutes: int.parse(partsB[1])));
            }
            return dateTimeA.compareTo(dateTimeB);
          });
        });
      } else {
        print(
            'Error al obtenir avisos: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error al carregar avisos: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Excepció al obtenir avisos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No s\'ha pogut connectar amb el servidor.')),
      );
    }
  }

  String _formatDate(String dateString) {
    final DateTime date = DateTime.parse(dateString).toLocal();
    final DateTime now = DateTime.now().toLocal();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Avui';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Demà';
    } else {
      return DateFormat('dd MMM.yyyy', 'ca_ES').format(date);
    }
  }

  void _toggleParticipant(
      int idAvis, int idUsuari, bool isCurrentlyParticipating) async {
    try {
      http.Response response;
      if (isCurrentlyParticipating) {
        response = await ApiService.eliminarUsuariDeAvis(
          idAvis: idAvis,
          idUsuari: idUsuari,
        );
      } else {
        response = await ApiService.afegirUsuariAvisExistent(
          idAvis: idAvis,
          idUsuari: idUsuari,
        );
      }

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isCurrentlyParticipating
                  ? 'T\'has desapuntat correctament!'
                  : 'T\'has apuntat correctament!')),
        );
        _fetchAvisos(); // Recarregar els avisos per actualitzar la UI
      } else {
        final errorBody = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error: ${errorBody['message'] ?? 'Error desconegut'}')),
        );
        print(
            'Error en la operació de participar: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'No s\'ha pogut connectar per gestionar la participació.')),
      );
      print('Excepció en la operació de participar: $e');
    }
  }

  // NOVA FUNCIÓ: Mostrar diàleg de confirmació i eliminar avís
  Future<void> _confirmAndDeleteAvis(int idAvis, int idUsuariCreador) async {
    final bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmar Eliminació'),
              content: const Text(
                  'Estàs segur que vols eliminar aquest avís? Aquesta acció és irreversible.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel·lar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Eliminar',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false; // Retorna false si el diàleg es tanca sense selecció

    if (confirm) {
      try {
        final response = await ApiService.eliminarAvis(
          idAvis: idAvis,
          idUsuariCreador: idUsuariCreador,
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avís eliminat correctament!')),
          );
          _fetchAvisos(); // Recarregar els avisos per actualitzar la UI
        } else {
          final errorBody = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Error: ${errorBody['message'] ?? 'Error desconegut'}')),
          );
          print(
              'Error al eliminar avís: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No s\'ha pogut connectar per eliminar l\'avís.')),
        );
        print('Excepció al eliminar avís: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('VOLS ANAR A CAN GUIX?')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('VOLS ANAR A CAN GUIX?')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.lightGreenAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
              ),
              icon: const Icon(Icons.campaign),
              label: const Text("AVISA!"),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoAdvertisePage(),
                  ),
                );
                _fetchAvisos();
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text('Agenda',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: _avisos.isEmpty
                ? const Center(
                    child: Text('No hi ha avisos futurs disponibles.'))
                : ListView.separated(
                    itemCount: _avisos.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final av = _avisos[index];
                      final idAvis = av['id_avis'] as int;
                      final idUsuariCreadorAvis =
                          av['id_usuari_creador'] as int;
                      final dataAvis = av['data_avis'] as String;
                      final horaAvis = av['hora_avis'] as String?;
                      final tipusApat = av['tipus_apat'] as String;
                      final usuarisParticipants =
                          av['usuaris_participants'] as List<dynamic>;

                      final isParticipating = usuarisParticipants.any(
                        (p) => p['id_usuari'] == _currentUserId,
                      );

                      final participantNames = usuarisParticipants
                          .map((p) => p['nom_usuari_participant'] as String)
                          .whereType<String>()
                          .toList();

                      final isCurrentUserCreator =
                          _currentUserId == idUsuariCreadorAvis;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Assegura que el text principal també contrasti
                                  Text(
                                    _formatDate(dataAvis),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white), // Color ajustat
                                  ),
                                  Text(
                                    '${tipusApat.capitalize()}' +
                                        (horaAvis != null
                                            ? ' a les ${horaAvis.substring(0, 5)}'
                                            : ''),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70), // Color ajustat
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Creat per: ${av['nom_usuari_creador']}',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.white60),
                                  ),
                                  // Mostrar "Nota: missatge" si existe
                                  if (av['missatge'] != null && (av['missatge'] as String).trim().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Text(
                                        'Nota: ${av['missatge']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.amber,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  // --- INICI DELS CANVIS PER ALS PARTICIPANTS ---
                                  if (participantNames.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: RichText(
                                        text: TextSpan(
                                          text: 'S\'hi ha apuntat: ',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors
                                                  .white), // **COLOR AJUSTAT**
                                          children: <TextSpan>[
                                            TextSpan(
                                              text: participantNames.join(', '),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors
                                                    .lightBlueAccent, // Un blau clar pot destacar molt bé!
                                                fontSize:
                                                    15, // Una mica més gran
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: isParticipating,
                                        onChanged: (bool? newValue) {
                                          _toggleParticipant(idAvis,
                                              _currentUserId!, isParticipating);
                                        },
                                      ),
                                      const Text('Hi vull anar!'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrentUserCreator) // Només mostrar la paperera si és el creador
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _confirmAndDeleteAvis(
                                      idAvis, _currentUserId!);
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
