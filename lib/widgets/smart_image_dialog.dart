import 'dart:typed_data';
import 'package:can_guix/services/api_service.dart';
import 'package:flutter/material.dart';

class SmartImageDialog extends StatefulWidget {
  final String userName;
  final Uint8List? lowResImage;
  final String heroTag;

  const SmartImageDialog({
    super.key,
    required this.userName,
    required this.lowResImage,
    required this.heroTag,
  });

  @override
  _SmartImageDialogState createState() => _SmartImageDialogState();
}

class _SmartImageDialogState extends State<SmartImageDialog> {
  Uint8List? highResImage;
  String? description;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadExtraData();
  }

  Future<void> _loadExtraData() async {
    // Carreguem en paral·lel la imatge HD i la descripció
    final results = await Future.wait([
      ApiService.getUserProfileImage(
          widget.userName), // Assegura't que torna la HD
      ApiService.getUserEstat(widget.userName),
    ]);

    if (mounted) {
      setState(() {
        highResImage = results[0] as Uint8List?;
        // Si ApiService torna una llista o map, ajusta aquí. Assumeixo que torna String.
        description = results[1] as String?;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // La imatge a mostrar: Si tenim la HD la posem, si no, la LowRes
    final imageToShow = highResImage ?? widget.lowResImage;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Important per veure el fons enfosquit
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // FOTO AMB HERO
                Hero(
                  tag: widget.heroTag,
                  child: Container(
                    constraints:
                        const BoxConstraints(maxWidth: 350, maxHeight: 350),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 15)
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imageToShow != null
                          ? Image.memory(
                              imageToShow,
                              fit: BoxFit.cover,
                              // Aquest frameBuilder ajuda a fer la transició suau si vols
                              frameBuilder: (context, child, frame,
                                  wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded) return child;
                                return AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  child: child,
                                );
                              },
                            )
                          : Image.asset('assets/images/avatar_placeholder.png'),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // DESCRIPCIÓ DE L'USUARI
                // Fem una animació de FadeIn perquè aparegui elegantment un cop carregada
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: loading ? 0.0 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.userName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        if (description != null && description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '"$description"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                              fontSize: 16,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          const Text(
                            "Sense estat...",
                            style:
                                TextStyle(color: Colors.white38, fontSize: 14),
                          )
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
