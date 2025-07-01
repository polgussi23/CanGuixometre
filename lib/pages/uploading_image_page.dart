import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:can_guix/pages/main_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart'; // Assegura't que el path sigui correcte
import '../services/user_provider.dart';
import 'package:image/image.dart' as img;

class UploadingImagePage extends StatefulWidget {
  final dynamic selectedImage;
  final DateTime selectedDate;
  final List<String> participants;

  const UploadingImagePage({
    super.key,
    required this.selectedImage,
    required this.selectedDate,
    required this.participants,
  });

  @override
  State<UploadingImagePage> createState() => _UploadingImagePageState();
}

class _UploadingImagePageState extends State<UploadingImagePage> {
  int _dotCount = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startDotAnimation();
    _uploadImage(); // En iniciar la pàgina, començarà a pujar la imatge
  }

  void _startDotAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _dotCount = (_dotCount + 1) % 4; // Alterna entre 0 i 3 punts
      });
    });
  }

  Future<void> _uploadImage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    String timestamp = widget.selectedDate.millisecondsSinceEpoch.toString();
    Uint8List? compressedImage = await _compressImage(widget.selectedImage);

    if (compressedImage != null) {
      final response = await ApiService.uploadImage(
        timestamp,
        compressedImage,
        widget.participants,
        userProvider.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.statusCode == 201
                ? 'Imatge pujada correctament'
                : 'Error en pujar la imatge',
          ),
        ),
      );
    }

    // Espera una mica per donar temps a veure l'animació abans de tornar
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainPage()), // Redirigeix a la pàgina principal
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/uploading_image.json',
              width: 300,
              height: 300,
            ),
            const SizedBox(height: 20),
            Text(
              'PUJANT FOTO${'.' * _dotCount}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> _compressImage(dynamic imageInput) async {
    Uint8List? imageBytes;

    if (imageInput is File) {
      imageBytes = await imageInput.readAsBytes();
    } else if (imageInput is Future<Uint8List>) {
      imageBytes = await imageInput;
    } else if (imageInput is Uint8List) {
      imageBytes = imageInput;
    } else {
      throw ArgumentError('Tipus d\'entrada no suportat. Ha de ser File, Future<Uint8List> o Uint8List.');
    }

    img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage != null) {
      final compressedImage = img.encodeJpg(originalImage, quality: 30);
      return Uint8List.fromList(compressedImage);
    }
    return null;
  }
}
