import 'package:flutter/material.dart';

class ViewScorePage extends StatelessWidget {
  final Map<String, dynamic> scoreData;

  const ViewScorePage({super.key, required this.scoreData});

  @override
  Widget build(BuildContext context) {
    final String? selectedUser = scoreData['usuari'];
    final List<dynamic>? scores = scoreData['puntuacions'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("VISUALITZAR PUNTUACIÓ"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 30), // Icona d'usuari
                const SizedBox(width: 10),
                Text(
                  selectedUser ?? 'Usuari desconegut',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Puntuacions:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (scores != null && scores.isNotEmpty)
              ListView.builder(
                shrinkWrap: true, // Permet que la llista ocupi només l'espai necessari
                itemCount: scores.length,
                itemBuilder: (context, index) {
                  final Map<String, dynamic> score = scores[index];
                  return ListTile(
                    leading: const Icon(Icons.star, color: Colors.yellow),
                    title: Text(
                      score['descripcio'] ?? 'Descripció no disponible',
                      style: const TextStyle(fontSize: 18),
                    ),
                    trailing: Text(
                      (score['quantitat'] != null && score['quantitat'] > 0) 
                        ? (double.parse(score['valor'].toString()) * double.parse(score['quantitat'].toString())).toStringAsFixed(2)
                        : double.parse(score['valor'].toString()).toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
              )
            else
              const Text(
                "No hi ha puntuacions assignades.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
