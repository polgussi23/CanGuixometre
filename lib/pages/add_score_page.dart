import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddScorePage extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onScoresSelected; // Funció per passar els resultats a UploadPhotoPage

  const AddScorePage({super.key, required this.onScoresSelected});

  @override
  _AddScorePageState createState() => _AddScorePageState();
}

class _AddScorePageState extends State<AddScorePage> {
  String? selectedUser;
  List<dynamic> scoreOptions = [];
  Map<int, bool> selectedScores = {};
  List<String> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchScoreOptions();
  }

  Future<void> fetchUsers() async {
    List<String> data = await ApiService.getUsers();
    setState(() {
      users = data;
    });
  }

  Future<void> fetchScoreOptions() async {
    List<dynamic> data = await ApiService.getScoreOptions();
    setState(() {
      scoreOptions = data;
      selectedScores = { for (var item in data) item['id'] : false };
    });
  }

  void submitScore() async {
    List<Map<String, dynamic>> selectedParticipants = []; // Almacena la informació dels usuaris i puntuacions seleccionades
    selectedScores.forEach((key, value) {
      if (value) {
        var scoreDetail = scoreOptions.firstWhere((score) => score['id'] == key);
        selectedParticipants.add({
          'user': selectedUser,
          'score': scoreDetail['valor'],
          'description': scoreDetail['descripcio'],
        });
      }
    });

    // Passar els resultats a UploadPhotoPage
    widget.onScoresSelected(selectedParticipants);

    Navigator.of(context).pop(); // Tornar enrere a UploadPhotoPage
  }

  void createNewUser(BuildContext context) {
    final TextEditingController userController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Crear nou usuari'),
          content: TextField(
            controller: userController,
            decoration: InputDecoration(hintText: 'Nom del nou usuari'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await ApiService.createUser(userController.text);
                Navigator.of(context).pop();
                fetchUsers(); // Refrescar la llista d'usuaris
              },
              child: Text('Crear'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel·lar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AFEGIR PUNTUACIÓ")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      hint: Text('Selecciona un usuari'),
                      value: selectedUser,
                      items: users.map((user) {
                        return DropdownMenuItem(
                          value: user,
                          child: Text(user),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedUser = value;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      createNewUser(context);
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              ListView(
                shrinkWrap: true, // Permet que la llista ocupi només l'espai necessari
                physics: NeverScrollableScrollPhysics(), // Evita el desplaçament de la llista
                children: scoreOptions.map((option) {
                  return CheckboxListTile(
                    title: Text('${option['descripcio']} (${option['valor']} punts)'),
                    value: selectedScores[option['id']],
                    onChanged: (bool? value) {
                      setState(() {
                        selectedScores[option['id']] = value ?? false;
                      });
                    },
                  );
                }).toList(),
              ),
              ElevatedButton.icon(
                onPressed: selectedUser != null ? submitScore : null,
                icon: Icon(Icons.check), // Icona de check
                label: Text('Afegir puntuació'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black, backgroundColor: Colors.yellow, padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Color del text
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Cantos arrodonits
                  ),
                ),
              ),
              SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
