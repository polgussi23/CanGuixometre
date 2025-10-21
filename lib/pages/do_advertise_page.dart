import 'dart:convert'; // Necessari per json.decode per obtenir l'ID d'usuari
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'add_users_to_photo_page.dart'; // Importa la pàgina de selecció
import 'package:can_guix/services/api_service.dart'; // Importa el servei API
import 'package:can_guix/services/user_provider.dart'; // Importa el proveïdor d'usuari

class DoAdvertisePage extends StatefulWidget {
  @override
  _DoAdvertisePageState createState() => _DoAdvertisePageState();
}

class _DoAdvertisePageState extends State<DoAdvertisePage> {
  DateTime selectedDate = DateTime.now();
  String selectedMeal = 'sopar';
  List<String> participants =
      []; // Aquesta llista conté els noms dels participants
  TimeOfDay? selectedTime; // Nuevo campo para la hora
  bool noTimeSelected = false; // Para la opción "aun no lo tengo claro"

  // Obtenim l'ID de l'usuari actual mitjançant UserProvider
  int? _currentUserId;

  // Nuevo campo para el mensaje
  String message = "";

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  void _loadCurrentUserId() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.id;
    setState(() {
      _currentUserId = userId;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(
          2100), // No hi ha límit real, però cal posar una data molt futura
      locale: const Locale('ca', 'ES'),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Localizations.override(
          context: context,
          locale: const Locale('ca', 'ES'),
          child: Builder(
            builder: (context) {
              return Theme(
                data: Theme.of(context),
                child: child!,
              );
            },
          ),
        );
      },
      helpText: 'Tria hora',
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        noTimeSelected =
            false; // Si l'usuari selecciona una hora, desactivem "noTimeSelected"
      });
    }
  }

  Future<void> _selectParticipants() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddUsersToPhotoPage(
          title: "QUÍ VE SEGUR?",
          selectedParticipants: participants, // Passa els noms actuals
        ),
      ),
    );

    // Assumint que AddUsersToPhotoPage ja retorna List<String> (noms)
    if (result != null && result is List<String>) {
      setState(() {
        participants = result; // Actualitza la llista de noms de participants
      });
      print('Participants seleccionats (noms): $participants');
    }
  }

  // Funció per pujar el nou avís a l'API
  void _uploadNewAdvertise() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Error: No s\'ha pogut obtenir l\'ID de l\'usuari creador.')),
      );
      return;
    }

    // Format de la data per a l'API (AAAA-MM-DD)
    final String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Format de l'hora per a l'API (HH:MM:SS) o null
    String? formattedTime;
    if (selectedTime != null && !noTimeSelected) {
      formattedTime =
          '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00';
    } else {
      formattedTime =
          null; // No enviar hora si és "Encara no ho tinc clar" o "No seleccionada"
    }

    try {
      final response = await ApiService.crearNouAvis(
        idUsuariCreador: _currentUserId!,
        dataAvis: formattedDate,
        horaAvis: formattedTime,
        tipusApat: selectedMeal,
        usuarisParticipants: participants,
        missatge: message, // <-- Añade esto si tu API lo acepta
      );

      if (response.statusCode == 201) {
        // Avís creat correctament
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avís creat correctament!')),
        );
        Navigator.pop(context); // Tornar a la pantalla anterior
      } else {
        // Error en la creació de l'avís
        final errorBody = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error: ${errorBody['message'] ?? 'Error desconegut'}')),
        );
        print('Error al crear avís: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Error de xarxa o excepció llançada per AvisosApiService
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No s\'ha pogut connectar amb el servidor: $e')),
      );
      print('Excepció al crear avís: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String horaText;
    if (noTimeSelected) {
      horaText = "Encara no ho tinc clar";
    } else if (selectedTime != null) {
      final hour = selectedTime!.hour.toString().padLeft(2, '0');
      final minute = selectedTime!.minute.toString().padLeft(2, '0');
      horaText = "$hour:$minute";
    } else {
      horaText = "No seleccionada";
    }

    return Scaffold(
      appBar: AppBar(title: Text('Avís de nou àpat')),
      body: SingleChildScrollView(
        // <-- Envuelve el contenido aquí
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Escull un dia:', style: TextStyle(fontSize: 16)),
              Row(
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(selectedDate),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _selectDate(context),
                    child: Text('Canvia'),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text('Escull hora:', style: TextStyle(fontSize: 16)),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      horaText,
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _selectTime(context),
                      child: Text('Tria hora'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedTime = null;
                    noTimeSelected = true;
                  });
                },
                child: Text("Encara no ho tinc clar"),
              ),

              SizedBox(height: 24),
              Text('Escull àpat:', style: TextStyle(fontSize: 16)),
              Row(
                children: [
                  ChoiceChip(
                    label: Text('Esmorzar',
                        style: TextStyle(
                            color: selectedMeal == 'esmorzar'
                                ? Colors.black
                                : null)),
                    selected: selectedMeal == 'esmorzar',
                    selectedColor: Colors.lightBlue[100],
                    checkmarkColor: Colors.black,
                    onSelected: (selected) {
                      setState(() {
                        selectedMeal = 'esmorzar';
                      });
                    },
                  ),
                  SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Dinar',
                        style: TextStyle(
                            color:
                                selectedMeal == 'dinar' ? Colors.black : null)),
                    selected: selectedMeal == 'dinar',
                    selectedColor: Colors.lightBlue[100],
                    checkmarkColor: Colors.black,
                    onSelected: (selected) {
                      setState(() {
                        selectedMeal = 'dinar';
                      });
                    },
                  ),
                  SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Sopar',
                        style: TextStyle(
                            color:
                                selectedMeal == 'sopar' ? Colors.black : null)),
                    selected: selectedMeal == 'sopar',
                    selectedColor: Colors.lightBlue[100],
                    checkmarkColor: Colors.black,
                    onSelected: (selected) {
                      setState(() {
                        selectedMeal = 'sopar';
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text('Saps qui vindrà segur?', style: TextStyle(fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30),
                ),
                icon: Icon(Icons.group),
                label: Text('Digues qui vindrà'),
                onPressed: _selectParticipants,
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children:
                    participants.map((p) => Chip(label: Text(p))).toList(),
              ),
              SizedBox(height: 24),
              // NUEVO APARTADO
              Text('Vols dir alguna cosa?', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              TextField(
                maxLength: 50,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Escriu aquí (màxim 50 caràcters)',
                  counterText: '', // Oculta el contador
                ),
                onChanged: (value) {
                  setState(() {
                    message = value;
                  });
                },
              ),
              SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _uploadNewAdvertise, // Cridem la nova funció aquí
                  child: Text('Confirmar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
