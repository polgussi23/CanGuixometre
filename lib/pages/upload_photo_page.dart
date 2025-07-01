//import 'package:can_guix/pages/main_page.dart';
import 'package:can_guix/pages/uploading_image_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
//import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
//import '../services/api_service.dart';
import 'package:image/image.dart' as img;
//import '../services/user_provider.dart';
import 'add_users_to_photo_page.dart';

class UploadPhotoPage extends StatefulWidget {
  final dynamic selectedImage;

  const UploadPhotoPage({super.key, required this.selectedImage});

  @override
  _UploadPhotoPageState createState() => _UploadPhotoPageState();
}

class _UploadPhotoPageState extends State<UploadPhotoPage> {
  bool _isUploading = false; // Estat per controlar el botó
  //List<List<Map<String, dynamic>>> participants = [];
  List<String> participants = [];
  DateTime _selectedDate = DateTime.now();

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

  void _addParticipant() async {
    // Recuperem els participants actualitzats des de la pàgina AddUsersToPhotoPage
    final updatedParticipants = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddUsersToPhotoPage(
          title: "QUÍ SURT A LA FOTO?",
          selectedParticipants: participants, // Passar la llista de participants
        ),
      ),
    );

    // Verifiquem que updatedParticipants no sigui nul
    if (updatedParticipants != null && updatedParticipants is List<String>) {
      setState(() {
        participants = updatedParticipants; // Actualitzem la llista amb els nous participants
      });
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      DateTime adjustedDate = pickedDate.add(Duration(hours: 2));
      setState(() {
        _selectedDate = adjustedDate;
      });
    }
  }

  Future<Uint8List> _getImageBytes(dynamic selectedImage) async {
    if (selectedImage is File) {
      return await selectedImage.readAsBytes();
    } else if (selectedImage is Future<Uint8List>) {
      return await selectedImage;
    } else {
      throw Exception('Imatge no vàlida');
    }
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PENJAR IMATGE')),
      body: AbsorbPointer(
        absorbing: _isUploading,
        child: Column(
          children: [
            FutureBuilder<Uint8List>(
              future: _getImageBytes(widget.selectedImage),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasData) {
                  return Image.memory(snapshot.data!, height: 300);
                } else {
                  return Text("No hi ha imatge seleccionada");
                }
              },
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text(
                "Data: ${DateFormat('dd-MM-yyyy').format(_selectedDate)}",
              ),
              trailing: IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: _pickDate, // Mostrar el DatePicker
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  String user = participants.elementAt(index);
                  return ListTile(
                    title: Text(user),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _addParticipant(),
              icon: Icon(Icons.person_add, color: Colors.black),
              label: Text('Afegir Usuaris', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => 
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => UploadingImagePage(
                        selectedImage: widget.selectedImage,
                        selectedDate: _selectedDate,
                        participants: participants,
                      ),
                    )),
                  label: Text('Pujar Imatge', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}