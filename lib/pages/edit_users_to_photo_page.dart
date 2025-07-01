import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditUsersToPhotoPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedParticipants; // Llista de participants com a Map<String, dynamic>

  const EditUsersToPhotoPage({super.key, required this.selectedParticipants});

  @override
  _EditUsersToPhotoPageState createState() => _EditUsersToPhotoPageState();
}

class _EditUsersToPhotoPageState extends State<EditUsersToPhotoPage> {
  List<Map<String, dynamic>> users = [];
  Map<String, bool> selectedUsers = {}; // Per marcar quins usuaris estan seleccionats
  
  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    // Suponem que el servei retorna una llista d'usuari en format [Map<String, dynamic>]
    //List<Map<String, dynamic>> data = await ApiService.getUsers();
    List<String> allUsers = await ApiService.getUsers();
    List<Map<String, dynamic>> data = [];
    for (var u in allUsers){
      List<Map<String, dynamic>> puntuacions = [];
      data.add({'usuari': u, 'puntuacions': puntuacions});
    }
    setState(() {
      users = data;

      // Inicialitzar l'estat de selecció a partir dels participants actuals
      selectedUsers = {
        for (var user in data)
          user['usuari']: widget.selectedParticipants.any((participant) =>
              participant['usuari'] == user['usuari']) // Comprovar si l'usuari està seleccionat
      };
    });
  }

  void submitUsers() {
    // Filtrar els usuaris seleccionats i retornar-los
    List<Map<String, dynamic>> selected = selectedUsers.entries
        .where((entry) => entry.value) // Filtrar només els usuaris seleccionats
        .map((entry) => users.firstWhere((user) => user['usuari'] == entry.key)) // Recuperar el Map complet
        .toList();
    Navigator.of(context).pop(selected); // Tornar enrere amb els usuaris seleccionats
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QUÍ SURT A LA FOTO?")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              ListView(
                shrinkWrap: true, // Permet que la llista ocupi només l'espai necessari
                physics: const NeverScrollableScrollPhysics(), // Evita el desplaçament de la llista
                children: users.map((user) {
                  return CheckboxListTile(
                    title: Text(user['usuari']), // Nom de l'usuari
                    value: selectedUsers[user['usuari']], // Comprovem si l'usuari està seleccionat
                    onChanged: (bool? value) {
                      setState(() {
                        selectedUsers[user['usuari']] = value ?? false;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton.icon(
          onPressed: selectedUsers.containsValue(true) ? submitUsers : null,
          icon: const Icon(Icons.check), // Icona de check
          label: const Text('Afegir usuaris'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.yellow,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Color del text
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Cantos arrodonits
            ),
          ),
        ),
      ),
    );
  }
}
