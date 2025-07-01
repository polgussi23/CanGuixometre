import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddUsersToPhotoPage extends StatefulWidget {
  //final Function(List<String>) selectedParticipants; // Funció per passar els usuaris seleccionats a UploadPhotoPage
  final List<String> selectedParticipants;
  final String title;

  const AddUsersToPhotoPage({super.key, required this.selectedParticipants, required this.title});

  @override
  _AddUsersToPhotoPageState createState() => _AddUsersToPhotoPageState();
}

class _AddUsersToPhotoPageState extends State<AddUsersToPhotoPage> {
  List<String> users = [];
  Map<String, bool> selectedUsers = {}; // Per marcar quins usuaris estan seleccionats
  
  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    List<String> data = await ApiService.getUsers();
    setState(() {
      users = data;
      selectedUsers = {for (var user in data) user: widget.selectedParticipants.contains(user)}; // Inicialitzar tots els usuaris com a no seleccionats
    });
  }

  void submitUsers() {
    List<String> selected = selectedUsers.entries
        .where((entry) => entry.value) // Filtrar només els usuaris seleccionats
        .map((entry) => entry.key)
        .toList();

    //widget.selectedParticipants(selected); // Passar els usuaris seleccionats a UploadPhotoPage
    Navigator.of(context).pop(selected); // Tornar enrere
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              ListView(
                shrinkWrap: true, // Permet que la llista ocupi només l'espai necessari
                physics: NeverScrollableScrollPhysics(), // Evita el desplaçament de la llista
                children: users.map((user) {
                  return CheckboxListTile(
                    title: Text(user),
                    value: selectedUsers[user],
                    onChanged: (bool? value) {
                      setState(() {
                        selectedUsers[user] = value ?? false;
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
          icon: Icon(Icons.check), // Icona de check
          label: Text('Afegir usuaris'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.yellow,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Color del text
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Cantos arrodonits
            ),
          ),
        ),
      ),
    );
  }
}
