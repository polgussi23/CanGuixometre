import 'package:can_guix/pages/edit_user_page.dart';
import 'package:can_guix/pages/jocs_page.dart';
import 'package:flutter/material.dart';

class RankingPopupButton extends StatelessWidget {
  final VoidCallback onRefreshNeeded;

  const RankingPopupButton({
    super.key,
    required this.onRefreshNeeded,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
          Icons.menu), // Pots posar Icons.settings o Icons.smoking_rooms
      onSelected: (value) async {
        // Aquí gestionem què passa quan cliques una opció
        if (value == 'editar') {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditUserPage()),
          );
          // Si necessites refrescar al tornar (com tenies al teu codi original):
          onRefreshNeeded();
        } else if (value == 'jocs') {
          // Naveguem a la pàgina de jocs (crearem un placeholder avall)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => JocsPage()),
          );
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          // Opció 1: Editar Usuari
          const PopupMenuItem<String>(
            value: 'editar',
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.white),
                SizedBox(width: 10),
                Text('Editar Usuari'),
              ],
            ),
          ),
          // Opció 2: Jocs
          const PopupMenuItem<String>(
            value: 'jocs',
            child: Row(
              children: [
                Icon(Icons.videogame_asset,
                    color: Colors.white), // Icona de jocs
                SizedBox(width: 10),
                Text('Jocs'),
              ],
            ),
          ),
        ];
      },
    );
  }
}
