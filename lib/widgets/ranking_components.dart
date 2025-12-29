import 'dart:typed_data';
import 'package:flutter/material.dart';

const Color kDarkSurfaceColor = Color(0xFF2C2C2C); // Color de les targetes
const Color kPrimaryTextColor = Colors.white;
final Color kSecondaryTextColor = Colors.grey[400]!;

// Component per a una barra del Podi (1r, 2n, 3r)
class PodiumItem extends StatelessWidget {
  final Map<String, dynamic> user;
  final int position;
  final Uint8List? imageBytes;
  final double height;
  final Function(String) onImageTap;
  final Function(String) onMedalTap;
  final List<String> medals;

  const PodiumItem({
    super.key,
    required this.user,
    required this.position,
    this.imageBytes,
    required this.height,
    required this.onImageTap,
    required this.onMedalTap,
    required this.medals,
  });

  @override
  Widget build(BuildContext context) {
    Color podiumColor;
    if (position == 1)
      podiumColor = const Color(0xFFFFD700); // Or
    else if (position == 2)
      podiumColor = const Color(0xFFC0C0C0); // Plata
    else
      podiumColor = const Color(0xFFCD7F32); // Bronze

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Corona per al guanyador
        if (position == 1)
          const Icon(Icons.emoji_events, color: Colors.amber, size: 30),

        // Avatar
        GestureDetector(
          onTap: () => onImageTap(user['nom']),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: podiumColor, width: 3),
              boxShadow: [
                // Ombra més fosca
                BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: Offset(0, 4))
              ],
            ),
            child: Hero(
              tag: user['nom'],
              child: CircleAvatar(
                radius: position == 1 ? 45 : 35,
                backgroundImage: imageBytes != null
                    ? MemoryImage(imageBytes!)
                    : const AssetImage('assets/images/avatar_placeholder.png')
                        as ImageProvider,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Nom i Punts (Text blanc i gris clar)
        Text(
          user['nom'],
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: kPrimaryTextColor),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${user['puntuacio']} pts',
          style: TextStyle(color: kSecondaryTextColor, fontSize: 12),
        ),
        const SizedBox(height: 8),

        // La Barra del Podi
        Container(
          width: position == 1 ? 100 : 85,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              // Degradat lleugerament més intens sobre fons fosc
              colors: [
                podiumColor.withOpacity(0.9),
                podiumColor.withOpacity(0.4)
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Medalles
              if (medals.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: medals
                        .map((m) => GestureDetector(
                              onTap: () => onMedalTap(m),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: Image.asset('assets/images/$m',
                                    width: 25, height: 25),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              Text(
                '$position',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // El número sempre blanc
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Component per a la resta de la llista (del 4t en endavant)
class RankingTile extends StatefulWidget {
  final Map<String, dynamic> user;
  final int index;
  final Uint8List? imageBytes;
  final List<String> medals;
  final Function(String) onImageTap;
  final Function(String) onMedalTap;

  const RankingTile({
    super.key,
    required this.user,
    required this.index,
    this.imageBytes,
    required this.medals,
    required this.onImageTap,
    required this.onMedalTap,
  });

  @override
  State<RankingTile> createState() => _RankingTileState();
}

class _RankingTileState extends State<RankingTile>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: kDarkSurfaceColor, // Fons de la targeta fosc
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          // Ombra negra subtil
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '${widget.index + 1}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => widget.onImageTap(widget.user['nom']),
              child: Hero(
                tag: widget.user['nom'],
                child: CircleAvatar(
                  radius: 22,
                  backgroundImage: widget.imageBytes != null
                      ? MemoryImage(widget.imageBytes!)
                      : const AssetImage('assets/images/avatar_placeholder.png')
                          as ImageProvider,
                ),
              ),
            ),
          ],
        ),
        // Nom de l'usuari en blanc
        title: Text(
          widget.user['nom'],
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: kPrimaryTextColor),
        ),
        subtitle: widget.medals.isNotEmpty
            ? Row(
                children: widget.medals
                    .map((m) => GestureDetector(
                          onTap: () => widget.onMedalTap(m),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4, top: 4),
                            child: Image.asset('assets/images/$m',
                                width: 20, height: 20),
                          ),
                        ))
                    .toList(),
              )
            : null,
        // Puntuació amb fons més discret
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1), // Fons semitransparent blanc
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${widget.user['puntuacio']}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
