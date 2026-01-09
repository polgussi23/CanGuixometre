import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:can_guix/services/api_service.dart';
import 'package:can_guix/services/user_provider.dart';
import 'package:can_guix/pages/crop_scree.dart';

class EditUserPage extends StatefulWidget {
  const EditUserPage({Key? key}) : super(key: key);

  @override
  _EditUserPageState createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  late TextEditingController _nameController;
  late TextEditingController _estatController;
  late Uint8List? _profileImage;
  late int? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Carregar les dades de l'usuari al principi
    _loadUserProfile(userProvider);
  }

  Future<void> _loadUserProfile(UserProvider userProvider) async {
    try {
      // Espera que el provider carregui les dades de l'usuari
      await userProvider
          .getUserInfo(); // Si tens una funció per carregar les dades

      //final nom = userProvider.nom;
      _userId = userProvider.id;
      final nom = await ApiService.getUserName(_userId!);
      final estat = await ApiService.getUserEstat(nom!);

      // Carregar la imatge de perfil
      await _loadUserProfileImage(nom.toString());
      //_nameController = TextEditingController(text: userProvider.nom);
      _nameController = TextEditingController(text: nom);
      _estatController = TextEditingController(text: estat);
    } catch (e) {
      print("Error al carregar les dades de l'usuari: $e");
    }
  }

  // Funció per carregar la imatge de perfil
  Future<void> _loadUserProfileImage(String username) async {
    try {
      final imageBytes = await ApiService.getUserProfileImage(username);
      if (imageBytes != null) {
        setState(() {
          _profileImage = imageBytes;
        });
      } else {
        setState(() {
          _profileImage = null;
        });
      }
    } catch (e) {
      print('Error al carregar la imatge de perfil: $e');
      setState(() {
        _profileImage = null;
      });
    } finally {
      setState(() {
        _isLoading = false; // Finalitza el loading quan tot estigui carregat
      });
    }
  }

  Future<void> _pickImage(String userName) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Fer una foto'),
                onTap: () {
                  Navigator.of(context).pop();
                  _selectImage(ImageSource.camera, userName);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Seleccionar de la galeria'),
                onTap: () {
                  Navigator.of(context).pop();
                  _selectImage(ImageSource.gallery, userName);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectImage(ImageSource source, String userName) async {
    final picker = ImagePicker();

    if (!kIsWeb) {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        File? croppedFile = await _cropImage(File(pickedFile.path));
        if (croppedFile != null) {
          await _uploadImage(croppedFile, userName);
        }
      }
    } else {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        await _uploadImageWeb(bytes, userName);
      }
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    // 1. Obrim la pantalla de retallar que hem creat
    final Uint8List? croppedBytes = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CropScreen(imageFile: imageFile),
      ),
    );

    // 2. Si l'usuari cancel·la, tornem null
    if (croppedBytes == null) {
      return null;
    }

    // 3. Convertim els bytes que ens retorna el widget en un FILE
    // Això és necessari perquè el teu mètode _uploadImage espera un File.
    try {
      final tempDir = await getTemporaryDirectory();
      final destPath =
          '${tempDir.path}/retallada_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(destPath);
      await file.writeAsBytes(croppedBytes);
      return file;
    } catch (e) {
      print("Error guardant la imatge retallada: $e");
      return null;
    }
  }

  Future<void> _uploadImage(File imageFile, String userName) async {
    final response =
        await ApiService.uploadUserProfileImage(imageFile, userName);
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Imatge pujada correctament!')));
      // Actualitzar la pàgina per carregar la nova imatge
      setState(() {
        _isLoading = true; // Inicia la càrrega
      });
      await _loadUserProfile(Provider.of<UserProvider>(context,
          listen: false)); // Tornar a carregar les dades de l'usuari
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al pujar la imatge')));
    }
  }

  Future<void> _uploadImageWeb(Uint8List imageBytes, String userName) async {
    final response =
        await ApiService.uploadUserProfileImage(imageBytes, userName);
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Imatge pujada correctament!')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al pujar la imatge')));
    }
  }

  void _editName() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edita el Nom'),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Nom'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tanca el diàleg
              },
              child: Text('Cancel·lar'),
            ),
            TextButton(
              onPressed: () async {
                // Guarda el nou nom si cal
                final userProvider =
                    Provider.of<UserProvider>(context, listen: false);
                final statusCode = await ApiService.editarNomUsuari(
                    _userId, _nameController.text);
                if (statusCode.statusCode == 200) {
                  await userProvider.saveUser(
                    _nameController.text,
                    userProvider.usuari.toString(),
                    userProvider.estat.toString(),
                    userProvider.id,
                    userProvider.token.toString(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Nom canviat correctament!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al canviar el nom :(')));
                }
                Navigator.of(context).pop();
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _editEstat() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edita l'estat"),
          content: TextField(
            controller: _estatController,
            decoration: InputDecoration(labelText: 'Estat'),
            maxLength: 200,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tanca el diàleg
              },
              child: Text('Cancel·lar'),
            ),
            TextButton(
              onPressed: () async {
                // Guarda el nou nom si cal
                final userProvider =
                    Provider.of<UserProvider>(context, listen: false);
                final statusCode = await ApiService.editarEstatUsuari(
                    _userId, _estatController.text);
                if (statusCode.statusCode == 200) {
                  await userProvider.saveUser(
                    _estatController.text,
                    userProvider.usuari.toString(),
                    userProvider.estat.toString(),
                    userProvider.id,
                    userProvider.token.toString(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Estat canviat correctament!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error al canviar l'estat :(")));
                }
                Navigator.of(context).pop();
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('PERFIL')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('PERFIL')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mostrar la imatge de perfil i el llapis
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                _profileImage != null
                    ? CircleAvatar(
                        radius: 50,
                        backgroundImage: MemoryImage(_profileImage!),
                      )
                    : CircleAvatar(
                        radius: 50,
                        child:
                            Image.asset('assets/images/avatar_placeholder.png'),
                      ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 19,
                    backgroundColor: const Color.fromARGB(190, 165, 165, 165),
                    child: IconButton(
                      icon: Icon(Icons.edit),
                      color: const Color.fromARGB(255, 26, 26, 26),
                      onPressed: () {
                        _pickImage(userProvider.nom.toString());
                      },
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            // Editar el nom
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _editName();
                  },
                ),
                Text("Nom",
                    style: TextStyle(
                        color: Color.fromARGB(186, 207, 207, 207),
                        fontSize: 16)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _nameController.text,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            // Edita l'estat
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _editEstat();
                  },
                ),
                Text("Estat",
                    style: TextStyle(
                        color: Color.fromARGB(186, 207, 207, 207),
                        fontSize: 16)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _estatController.text,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            Spacer(), // Espai flexible per empènyer el botó cap a la part inferior
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.redAccent, // Color del text/icona
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: Icon(Icons.logout),
                label: Text("Tancar sessió"),
                onPressed: () {
                  userProvider.logout();
                  Navigator.of(context)
                      .pushReplacementNamed('/login'); // Exemple de redirecció
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
