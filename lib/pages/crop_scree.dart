import 'dart:io';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

class CropScreen extends StatefulWidget {
  final File imageFile;

  const CropScreen({super.key, required this.imageFile});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final _cropController = CropController();
  Uint8List? _imageData;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadAllImage();
  }

  // Convertim el fitxer a bytes per al paquet de retallar
  Future<void> _loadAllImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    setState(() {
      _imageData = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title:
            const Text('Ajustar Imatge', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _imageData == null
                ? const Center(child: CircularProgressIndicator())
                : Crop(
                    image: _imageData!,
                    controller: _cropController,

                    // --- AQUESTA ÉS LA PART CORREGIDA ---
                    onCropped: (result) {
                      // Ara el codi s'executa directament, sense crear un altre Crop
                      if (result is CropSuccess) {
                        Navigator.of(context).pop(result.croppedImage);
                      } else {
                        print("Error al retallar la imatge");
                        Navigator.of(context).pop(null);
                      }

                      // Si vols, pots treure el loading aquí si fallés alguna cosa,
                      // però com que fem pop, la pantalla es tanca igualment.
                    },
                    // ------------------------------------

                    aspectRatio: 1 / 1,
                    baseColor: Colors.black,
                    maskColor: Colors.black.withOpacity(0.7),
                    radius: 20,
                    interactive: true,
                  ),
          ),
          // --- ZONA DEL BOTÓ INFERIOR ---
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () {
                        setState(() {
                          _isProcessing = true;
                        });
                        _cropController.crop();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('CONFIRMAR RETALL',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
