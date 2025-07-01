import 'package:can_guix/pages/edit_score_page.dart';
//import 'package:can_guix/pages/main_page.dart';
import 'package:can_guix/services/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'view_score_page.dart';
import 'edit_users_to_photo_page.dart';
//import 'add_score_page.dart';

class EditPhotoPage extends StatefulWidget {
  final ImageData selectedImage;

  const EditPhotoPage({super.key, required this.selectedImage});

  @override
  _EditPhotoPageState createState() => _EditPhotoPageState();
}

class _EditPhotoPageState extends State<EditPhotoPage> {
  bool _isUploading = false; // Estat per controlar el botó
  //List<List<Map<String, dynamic>>> participants = [];
  List<Map<String, dynamic>> participants = [];

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      // Carrega les puntuacions des de la API
      //List<List<Map<String, dynamic>>> scores = await ApiService.getScoresFromImage(widget.selectedImage.name);
      List<Map<String, dynamic>> scores = await ApiService.getScoresFromImage(widget.selectedImage.name);
      setState(() {
        participants = scores; // Actualitza l'estat amb les puntuacions obtingudes
      });
    } catch (e) {
      print("Error al carregar participants: $e");
      // Aquí pots afegir un missatge d'error o gestió addicional si ho desitges
    }
  }

  bool participantInList(String currentUser) {
    // Comprova si l'usuari connectat està a la llista de participants
    for (var participant in participants) {
      if (participant['usuari'] == currentUser) {
        return true;
      }
    }
    return false;
  }

  Map<String, num> calculateTotalScores() {
    Map<String, num> totalScores = {};

    for (var participant in participants) {
      String user = participant['usuari']; // Nom de l'usuari
      for (var scoreEntry in participant['puntuacions']) {
        num score;
        if(scoreEntry['quantitat']!=null){score = num.parse(scoreEntry['valor'])*scoreEntry['quantitat'];}
        else{score = num.parse(scoreEntry['valor']);} // Puntuació 

        // Afegeix la puntuació al total
        totalScores[user] = (totalScores[user] ?? 0) + score; // Suma la puntuació
      }
      if(participant['puntuacions'].isEmpty){totalScores[user]=0;}
    }

    return totalScores; // Retorna el map amb les puntuacions totals
  }

  void viewScoreUser(String user) async {
    Map<String, dynamic> userScores = {};
    for (var participant in participants) {
      if (participant['usuari'] == user) {
        userScores = participant;
        break;
      }
    }

    await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewScorePage(
              scoreData: userScores,
            ),
          ),
    );
  }

  void editUsers() async{
    final selectedUsers = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUsersToPhotoPage(
          selectedParticipants: participants
        ),
      ),
    );
    if(selectedUsers != null){
      setState(() {
        participants=selectedUsers;
      });
      List<String> usuaris = [];
      for (var u in selectedUsers){
        usuaris.add(u['usuari']);
      }
      await ApiService.updateUsersImage(usuaris, widget.selectedImage.name);
    }
  }

  void editScoreUser(String? user) async {
    //List<Map<String, dynamic>> userScores = [];
    Map<String, dynamic> userScores = {};
    for (var participant in participants) {
      if (participant['usuari'] == user) {
        userScores = participant;
        break;
      }
    }

    final updatedScores = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditScorePage(
          scoreData: userScores,
        ),
      ),
    );

    if (updatedScores != null) {
      setState(() {
        for (int i = 0; i < participants.length; i++) {
          if (participants[i]['usuari'] == user) {
            participants[i] = updatedScores; // Actualitza l'element a la llista
            break; // Pots sortir del bucle un cop trobat
          }
        }
      });
      List<String> puntuacions = [];
      for(var p in updatedScores['puntuacions']){
        if(p['quantitat']!=null){
          for(int i=0; i<p['quantitat']; i++){
            puntuacions.add(p['descripcio']);
          }
        }
        else{puntuacions.add(p['descripcio']);}
      }
      await _updateScores(updatedScores['usuari'], puntuacions);
    }
  }

  Future<void> _updateScores(String usuari, List<String> puntuacions) async {
    setState(() {
      _isUploading = true;
    });

    try {
      await ApiService.updateScoreUserImage(usuari, puntuacions, widget.selectedImage.name);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Puntuacions actualitzades correctament!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error actualitzant les puntuacions: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, num> totalScores = calculateTotalScores();
    
    // Simulem l'usuari connectat
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    String? currentUser = userProvider.nom;
    
    // Comprovem si l'usuari connectat és el propietari de la foto
    bool isOwner = widget.selectedImage.usuari == currentUser;
    bool isParticipant = participantInList(currentUser!);

    return Scaffold(
      appBar: AppBar(title: const Text('PUNTUACIONS')),
      body: AbsorbPointer(
        absorbing: _isUploading,
        child: Column(
          children: [
            Image.memory(widget.selectedImage.image, height: 300),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: totalScores.length,
                itemBuilder: (context, index) {
                  String user = totalScores.keys.elementAt(index);
                  num totalScore = totalScores[user]!;
                  return ListTile(
                    title: Text(user),
                    subtitle: Text('Puntuació: $totalScore'),
                    onTap: () => viewScoreUser(user), // Vista detallada de l'usuari
                  );
                },
              ),
            ),
            // Mostra el botó "Afegir Usuari" només si l'usuari actual és el propietari de la foto
            if (isOwner) 
              ElevatedButton.icon(
                onPressed: () {
                  // Navegar a la pàgina EditUsersToPhotoPage amb la llista d'usuaris
                  editUsers();
                },
                icon: const Icon(Icons.person_add, color: Colors.black), // Icona per afegir
                label: const Text('Afegir Usuari', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow, // Color de fons
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Arrodonir les vores
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (isParticipant)
              ElevatedButton.icon(
                onPressed: () {
                  // Funció per editar la puntuació de l'usuari actual
                  editScoreUser(currentUser);
                },
                icon: const Icon(Icons.edit, color: Colors.white), // Icona d'editar
                label: const Text(
                  'Editar la meva puntuació',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Color de fons
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Arrodonir les vores
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
