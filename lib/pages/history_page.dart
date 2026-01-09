import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("CANGUIXÒMETRE"),
      ),
      body: SingleChildScrollView(
        // Afegim SingleChildScrollView aquí per a que sigui scrollejable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imatge a la part superior
            Container(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/canguixometre.png', // Ruta de la imatge
                height: 300, // Màxim height de 300
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 30), // Espai entre la imatge i el text
            // Explicació de la història
            Text(
              "En l'any de gràcia de 2023, en lo cor del bell poble d'Olot, es trobava un petit però acollidor hostal el nom del qual feia ressò en tots els racons de la comarca: Can Guix. Llur menjar no era el més deliciós del regne, però sí el més humil, així com els hostes, la Mercè i en Jaume.  \n \nEra freqüentat per grans i petits, homes i dones, locals i forasters, gossos i gats; lloc de reunió del poble, indret de grans celebracions. D'entre tots els seus visitants, hi havia un grup de vilatans que havia fet seva la posada, es podria dir que tan seva, que veien més la Mercè i en Jaume que la seva pròpia família. \n \nPerò un gran dubte es va apoderar de les seves ments: qui, d'entre l'elit de l'elit, era la persona més fidel a Can Guix? És per això que va néixer el Canguixòmetre, un concurs anual que a partir d'un sistema de punts establert, havia de designar qui es mereixia estar entre el millor dels millors. I així, companys i companyes, és com va néixer el tan famós Canguixòmetre, que aplega nombrosos concursants arreu de la comarca any rere any. \n \nSalut i Can Guix!",
              style: TextStyle(fontSize: 17),
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 40), // Espai entre la història i el Hall Of Fame
            Divider(thickness: 2), // Divisor
            SizedBox(height: 20), // Espai després del divisor
            // Hall of Fame Section
            Text(
              "🎉 Hall Of Fame 🎉",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.amber[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            // Guanyador de l'any 2024-2025
            Container(
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: true, // Tanca si cliques fora
                        barrierColor: Colors.black
                            .withOpacity(0.6), // Fons enfosquit (60% opacitat)
                        builder: (BuildContext context) {
                          return Dialog(
                            backgroundColor: Colors
                                .transparent, // Treiem el fons blanc del diàleg
                            insetPadding: const EdgeInsets.all(
                                10), // Marge per no tocar les vores
                            child: GestureDetector(
                              // Això permet tancar també si cliques la mateixa foto
                              onTap: () => Navigator.of(context).pop(),
                              child: Hero(
                                tag: 'foto_guanyador',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      16), // Opcional: vores rodones a la foto gran
                                  child: Image.asset(
                                    'assets/images/24-25.jpeg',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Hero(
                      tag: 'foto_guanyador', // Recorda: mateix tag que a dalt
                      child: CircleAvatar(
                        radius: 80,
                        backgroundImage: AssetImage('assets/images/24-25.jpeg'),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "🏆 Arnau",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[900],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "2024 - 2025",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "88.95 punts",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Guanyador de l'any 2023-2024
            Container(
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: true, // Tanca si cliques fora
                        barrierColor: Colors.black
                            .withOpacity(0.6), // Fons enfosquit (60% opacitat)
                        builder: (BuildContext context) {
                          return Dialog(
                            backgroundColor: Colors
                                .transparent, // Treiem el fons blanc del diàleg
                            insetPadding: const EdgeInsets.all(
                                10), // Marge per no tocar les vores
                            child: GestureDetector(
                              // Això permet tancar també si cliques la mateixa foto
                              onTap: () => Navigator.of(context).pop(),
                              child: Hero(
                                tag: 'foto_guanyador',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      16), // Opcional: vores rodones a la foto gran
                                  child: Image.asset(
                                    'assets/images/23-24.jpeg',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Hero(
                      tag: 'foto_guanyador', // Recorda: mateix tag que a dalt
                      child: CircleAvatar(
                        radius: 80,
                        backgroundImage: AssetImage('assets/images/23-24.jpeg'),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "🏆 Cesc",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[900],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "2023 - 2024",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "90.5 punts",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40), // Espai al final
          ],
        ),
      ),
    );
  }
}
