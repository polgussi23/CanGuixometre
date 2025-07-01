import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditScorePage extends StatefulWidget {
  final Map<String, dynamic> scoreData;

  const EditScorePage({super.key, required this.scoreData});

  @override
  _EditScorePageState createState() => _EditScorePageState();
}

class _EditScorePageState extends State<EditScorePage> {
  Map<int, int> selectedExtraScores = {};
  int? selectedNoAccumulable;
  String? selectedUser;
  List<dynamic> noAccumulableOptions = [];
  List<dynamic> extraPointsOptions = [];

  @override
  void initState() {
    super.initState();
    fetchScoreOptions();
  }

  Future<void> fetchScoreOptions() async {
    selectedUser = widget.scoreData['usuari'];
    List<dynamic> data = await ApiService.getScoreOptions();

    setState(() {
      // Agrupa les puntuacions segons la categoria
      noAccumulableOptions = data.where((item) => item['categoria'] == 'no acumulable').toList();
      extraPointsOptions = data.where((item) => item['categoria'] == 'punts extres').toList();

      // Inicialitza les opcions seleccionades
      for (var item in data) {
        if (item['categoria'] == 'punts extres') {
          selectedExtraScores[item['id']] = 0;
          for (var entry in widget.scoreData['puntuacions']) {
            if (item['descripcio'] == entry['descripcio']) {
              selectedExtraScores[item['id']] = entry['quantitat'];
              break;
            }
          }
        } else if (item['categoria'] == 'no acumulable') {
          for (var entry in widget.scoreData['puntuacions']) {
            if (item['descripcio'] == entry['descripcio']) {
              selectedNoAccumulable = item['id'];
              break;
            }
          }
        }
      }
    });
  }

  void submitScore() {
    Map<String, dynamic> selectedParticipants = {'usuari': '', 'puntuacions': []};
    selectedParticipants['usuari'] = selectedUser;

    // Afegir puntuació "no acumulable"
    if (selectedNoAccumulable != null) {
      var selectedOption = noAccumulableOptions
          .firstWhere((option) => option['id'] == selectedNoAccumulable);
      selectedParticipants['puntuacions'].add({
        'descripcio': selectedOption['descripcio'],
        'valor': selectedOption['valor'],
      });
    }

    // Afegir puntuacions "punts extres"
    selectedExtraScores.forEach((key, value) {
      if (value>0) {
        var selectedOption = extraPointsOptions.firstWhere((option) => option['id'] == key);
        selectedParticipants['puntuacions'].add({
          'descripcio': selectedOption['descripcio'],
          'valor': selectedOption['valor'],
          'quantitat': value,
        });
      }
    });

    Navigator.of(context).pop(selectedParticipants);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("EDITAR PUNTUACIÓ")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Row(
                children: [
                  SizedBox(width: 15),
                  Icon(Icons.person, size: 30),
                  SizedBox(width: 8),
                  Text(
                    selectedUser ?? 'Ningú',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              // Opcions no acumulables
              ListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  
                  ...noAccumulableOptions.map((option) {
                    return RadioListTile<int>(
                      title: Text('${option['descripcio']} (${option['valor']} punts)'),
                      value: option['id'],
                      groupValue: selectedNoAccumulable,
                      onChanged: (int? value) {
                        setState(() {
                          selectedNoAccumulable = value;
                        });
                      },
                    );
                  }).toList(),
                ],
              ),
              // Opcions punts extres
              ListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  Text(
                    'Punts Extres',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ...extraPointsOptions.map((option) {
                    if (option['descripcio'].startsWith('Acompanyants')) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Usar Expanded per a que el Text ocupi el que faci falta
                          Expanded(
                            child: Text(
                              '${option['descripcio']} (${option['valor']} punts)',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    selectedExtraScores[option['id']] =
                                        (selectedExtraScores[option['id']] ?? 0) > 0
                                            ? selectedExtraScores[option['id']]! - 1
                                            : 0;
                                  });
                                },
                              ),
                              Text(
                                '${selectedExtraScores[option['id']] ?? 0}',
                                style: TextStyle(fontSize: 16),
                              ),
                              IconButton(
                                icon: Icon(Icons.add, color: Colors.green),
                                onPressed: () {
                                  setState(() {
                                    selectedExtraScores[option['id']] =
                                        (selectedExtraScores[option['id']] ?? 0) + 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      return CheckboxListTile(
                        title: Text('${option['descripcio']} (${option['valor']} punts)'),
                        value: (selectedExtraScores[option['id']] ?? 0) > 0,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedExtraScores[option['id']] = 1;
                            } else {
                              selectedExtraScores[option['id']] = 0;
                            }
                          });
                        },
                      );
                    }
                  }).toList(),
                ],
              ),


              ElevatedButton.icon(
                onPressed: selectedUser != null ? submitScore : null,
                icon: Icon(Icons.check),
                label: Text('Afegir puntuació'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.yellow,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
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
