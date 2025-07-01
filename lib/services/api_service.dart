import 'dart:convert';
import 'package:can_guix/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class ApiService {
  
  // ------------------------------- API PRO -------------------------------
  static String apiUrl = "https://polgussi.cat:3001"; //                 |
  // -----------------------------------------------------------------------

  // ------------------------------- API DEV -------------------------------
  //static String apiUrl = "https://polgussi.cat:4001"; //                   |
  // -----------------------------------------------------------------------

  void initState(){
    if (!kIsWeb){
      // ------------------------------- API PRO -------------------------------
      apiUrl = 'http://polgussi.cat:3000';// HTTP //                         |
      // -----------------------------------------------------------------------

      // ------------------------------- API DEV -------------------------------
      //apiUrl = 'http://polgussi.cat:4000'; //                                  |
      // -----------------------------------------------------------------------

    }
  }

  Future<Map<String, dynamic>> getVersion() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/api/version'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtenir la versió');
      }
    } catch (e) {
      throw Exception('Error en la connexió amb l\'API: $e');
    }
  }

  static Future<Map<String, dynamic>?> login(String usuari, String password) async {
    final url = Uri.parse('$apiUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'usuari': usuari,
          'contrasenya': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error durant el login: $e');
      return null;
    }
  }

  static Future<void> sendFirebaseToken() async {
    final url = Uri.parse('$apiUrl/fb_token');
    
    // Obtenir el token a Firebase
    NotificationService notificationService = NotificationService();
    String? token = await notificationService.getDeviceToken();
    //List<String> tokens = [];
    //tokens.add(token!);
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return;
      }
    } catch (e) {
      print('Error durant enviament de la notificació: $e');
      return;
    }
  }

  static Future<List<dynamic>> getRankings() async {
    final response = await http.get(Uri.parse('$apiUrl/puntuacions'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error carregant el rànquing');
    }
  }

  static Future<List<String>> getUsers() async {
    final response = await http.get(Uri.parse('$apiUrl/usuaris'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((user) => user['nom'].toString()).toList();
    } else {
      throw Exception('Error carregant usuaris');
    }
  }

  static Future<List<dynamic>> getBonusUsers() async {
    final response = await http.get(Uri.parse('$apiUrl/usuaris/bonus'));
    if(response.statusCode == 200){
      List<dynamic> data = json.decode(response.body);
      return data;
    }else{
      throw Exception('Error carregant usuaris amb bonus');
    }
  }

  static Future<String> getUserName(int id) async {
    final response = await http.get(Uri.parse('$apiUrl/usuari/$id'));
    if(response.statusCode == 200){
      List<dynamic> data = json.decode(response.body);
      String nom = data[0]['nom'];
      return nom;
    }else{
      throw Exception("Error carregant nom d'usuari");
    }
  }

  static Future<List<dynamic>> getScoreOptions() async {
    final response = await http.get(Uri.parse('$apiUrl/puntuacions_possibles'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error carregant puntuacions possibles');
    }
  }

  static Future<List<dynamic>> getNonScoreImagesUser(userId) async{
    final response = await http.get(Uri.parse('$apiUrl/imatges/noScore/$userId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error carregant imatges sense puntuacions de l\'usuari');
    }
  }

  static Future<List<ImageData>> getImages(int page, int limit) async {
    final response = await http.get(Uri.parse('$apiUrl/imatges?page=$page&limit=$limit'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      // Comprova si 'images' és null o no existeix
      if (jsonResponse['images'] == null || jsonResponse['images'] is! List) {
        return []; // Retorna una llista buida si 'images' és null
      }

      List<dynamic> imagesData = jsonResponse['images'];
      
      List<ImageData> imageDataList = imagesData.map((imgData) {
        final image = base64.decode(imgData['image']);
        final name = imgData['name'];
        final createdAt = DateTime.parse(imgData['created_at']);
        final usuari = imgData['user_name'];
        
        return ImageData(image: image, name: name, createdAt: createdAt, usuari: usuari);
      }).toList();

      // Ordena la llista per "name"
      imageDataList.sort((a, b) => b.name.compareTo(a.name));

      return imageDataList;
    } else {
      throw Exception('Failed to load images');
    }
  }

  static Future<List<ImageData>> getImagesFromId(List<int> id) async {
    final idsParams = id.join(', ');
    
    final response = await http.get(Uri.parse('$apiUrl/imatges/$idsParams'));

    if(response.statusCode==200){
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (jsonResponse['images'] == null || jsonResponse['images'] is! List) {
        return []; // Retorna una llista buida si 'images' és null
      }
    
      List<dynamic> imagesData = jsonResponse['images'];

      List<ImageData> imageDataList = imagesData.map((imgData) {
        final image = base64.decode(imgData['image']);
        final name = imgData['name'];
        final createdAt = DateTime.parse(imgData['created_at']);
        final usuari = imgData['user_name'];
        
        return ImageData(image: image, name: name, createdAt: createdAt, usuari: usuari);
      }).toList();

      // Ordena la llista per "name"
      imageDataList.sort((a, b) => b.name.compareTo(a.name));

      return imageDataList;
    }else{
      throw Exception("Error en carregar imatges");
    }

  }

  static Future<List<UserImageData>> getAllUserProfileImages() async {
    // Aquí utilitzem un endpoint que retorni totes les fotos dels usuaris
    final response = await http.get(Uri.parse('$apiUrl/user-profile-images'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      // Comprova si 'images' és null o no existeix
      if (jsonResponse['images'] == null || jsonResponse['images'] is! List) {
        return []; // Retorna una llista buida si 'images' és null
      }

      List<dynamic> userImagesData = jsonResponse['images'];

      return userImagesData.map((imgData) {
        // Suposant que el JSON conté les propietats 'image', 'name', i 'user_id'
        final image = base64.decode(imgData['image']);
        final name = imgData['name'];
        final user = imgData['username'];  // ID d'usuari associat amb la imatge

        return UserImageData(
          image: image,
          name: name,
          user: user,
        );
      }).toList();
    } else {
      throw Exception('Failed to load user images');
    }
  }

  static Future<Uint8List?> getUserProfileImage(String userName) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/users/$userName/profile-image'));

      if (response.statusCode == 200) {
        // Assumint que la imatge es retorna com a bytes
        return response.bodyBytes;
      } else {
        print('Error al carregar la imatge de perfil: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al carregar la imatge de perfil: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getScoresFromImage(String imgName) async {
    final response = await http.get(Uri.parse('$apiUrl/scores/image/$imgName'));

    if (response.statusCode == 200) {
      // Processar la resposta
      List<dynamic> data = json.decode(response.body);

      // Mapeig dels usuaris i puntuacions
      return data.map<Map<String, dynamic>>((item) {
        return {
          'usuari': item['usuari'],
          'puntuacions': (item['puntuacions'] as List<dynamic>).map<Map<String, dynamic>>((score) {
            return {
              'descripcio': score['descripcio'],
              'valor': score['valor'],
              'quantitat': score['quantitat'],
            };
          }).toList(),
        };
      }).toList();
    } else {
      // Llençar una excepció si la sol·licitud falla
      throw Exception('Error carregant les puntuacions: ${response.statusCode}');
    }
  }

  static Future<void> submitScore(String user, num score) async {
    final response = await http.post(
      Uri.parse('$apiUrl/puntuacions'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{'nom': user, 'puntuacio': score}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error afegint la puntuació');
    }
  }

  static Future<void> uploadScores(String user, List<String> descPuntuacions, String timestamp) async{
    final response = await http.post(
      Uri.parse('$apiUrl/puntuacions'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{'nom': user, 'puntuacio': descPuntuacions, 'imatge': timestamp}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error afegint la puntuació');
    }
  }

  static Future<void> createUser(String user) async {
    final response = await http.post(
      Uri.parse('$apiUrl/usuaris'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{'nom': user}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error creant el nou usuari');
    }
  }

  static Future<void> updateScores(List<List<Map<String, dynamic>>> participants, String name) async {
    final response = await http.post(
      Uri.parse('$apiUrl/scores/update'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'participants': participants,
        'timestamp': name,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error actualitzant les puntuacions: ${response.statusCode}');
    }
  }

  static Future<void> updateScoreUserImage(String usuari, List<String> puntuacions, String nomImg) async {
    final response = await http.post(
      Uri.parse('$apiUrl/scores/update-user'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'usuari': usuari,
        'puntuacions': puntuacions,
        'timestamp': nomImg,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error actualitzant les puntuacions: ${response.statusCode}');
    }
  }

  static Future<void> updateUsersImage(List<String> usuaris, String nomImg) async {
    final response = await http.post(
      Uri.parse('$apiUrl/imatge/update-users'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'usuaris': usuaris,
        'timestamp': nomImg,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error actualitzant les puntuacions: ${response.statusCode}');
    }
  }

  static Future<http.StreamedResponse> uploadImage(String timestamp, dynamic image, List<String> participants, int? userId) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiUrl/imatges'), // Endpoint de l'API
    );

    request.fields['imageName'] = timestamp; // Afegir el nom de la imatge
    request.fields['user_id'] = userId.toString();
    request.fields['participants'] = json.encode(participants);

    if (image is File) {
      // Android/iOS
      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );
    } else if (image is Uint8List) {
      // Web
      request.files.add(
        http.MultipartFile.fromBytes('image', image, filename: 'upload.jpg'),
      );
    } else {
      throw Exception('Tipus d\'imatge no suportat');
    }

    final response = await request.send();
    return response;
  }

  static Future<http.StreamedResponse> uploadImageWithParticipants(File image, List<String> participants, num score) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiUrl/imatges_participants'),
    );

    request.files.add(await http.MultipartFile.fromPath('image', image.path));
    request.fields['participants'] = jsonEncode(participants);
    request.fields['score'] = score.toString();

    final response = await request.send();
    return response;
  }

  static Future<http.StreamedResponse> uploadUserProfileImage(
    dynamic image,
    String nomUsuari,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiUrl/upload-profile-image'),
    );

    if (image is File) {
      // Android/iOS
      request.files.add(
        await http.MultipartFile.fromPath('profile_image', image.path),
      );
    } else if (image is Uint8List) {
      // Web
      request.files.add(
        http.MultipartFile.fromBytes('profile_image', image, filename: 'upload.jpg'),
      );
    } else {
      throw Exception('Tipus d\'imatge no suportat');
    }

    request.fields['usuari'] = nomUsuari;

    final response = await request.send();
    return response;
  }

  static Future<http.Response> editarNomUsuari(int? userId, String nomNou) async {
    final response = await http.post(
      Uri.parse('$apiUrl/usuari/$userId/edita-nom'),
      headers: {
        'Content-Type': 'application/json',  // Assegura't de posar el tipus de contingut com a JSON
      },
      body: json.encode({'nom': nomNou}),  // El cos de la petició serà un JSON amb el nou nom
    );

    return response;
  }

  // Funció per crear un nou avís (POST /avisos/nou)
  static Future<http.Response> crearNouAvis({
    required int idUsuariCreador,
    required String dataAvis, // Format 'YYYY-MM-DD'
    String? horaAvis,         // Format 'HH:MM:SS', pot ser null
    required String tipusApat,  // 'dinar' o 'sopar'
    List<String>? usuarisParticipants, // Llista d'IDs d'usuaris, pot ser buida o null
  }) async {
    final url = Uri.parse('$apiUrl/avisos/nou');

    final Map<String, dynamic> body = {
      'id_usuari_creador': idUsuariCreador,
      'data_avis': dataAvis,
      'tipus_apat': tipusApat,
    };

    // Afegim l'hora si no és null
    if (horaAvis != null && horaAvis.isNotEmpty) {
      body['hora_avis'] = horaAvis;
    } else {
      // Si és null o buida, s'envia com a null a l'API
      body['hora_avis'] = null;
    }

    // Afegim els participants si es proporcionen
    if (usuarisParticipants != null) {
      body['usuaris_participants'] = usuarisParticipants;
    } else {
      // Si no es proporcionen, s'envia un array buit per consistència amb l'API
      body['usuaris_participants'] = [];
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      return response;
    } catch (e) {
      print('Error al crear nou avís: $e');
      // Llançar una excepció per gestionar-la a la UI o en un nivell superior
      throw Exception('No s\'ha pogut connectar amb l\'API per crear l\'avís.');
    }
  }

  // Funció per eliminar un avís complet
  static Future<http.Response> eliminarAvis({required int idAvis, required int idUsuariCreador}) async {
    final url = Uri.parse('$apiUrl/avisos/$idAvis');

    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        // Enviem l'ID de l'usuari creador per a la validació al servidor
        body: json.encode({'id_usuari_creador': idUsuariCreador}), 
      );
      return response;
    } catch (e) {
      print('Error al eliminar l\'avís $idAvis: $e');
      throw Exception('No s\'ha pogut connectar amb l\'API per eliminar l\'avís.');
    }
  }


  // Funció per afegir un usuari a un avís existent (POST /avisos/:idAvis/afegir-usuari)
  static Future<http.Response> afegirUsuariAvisExistent({
    required int idAvis,
    required int idUsuari,
  }) async {
    final url = Uri.parse('$apiUrl/avisos/$idAvis/afegir-usuari');

    final Map<String, dynamic> body = {
      'id_usuari': idUsuari,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      return response;
    } catch (e) {
      print('Error al afegir usuari a avís existent: $e');
      throw Exception('No s\'ha pogut connectar amb l\'API per afegir l\'usuari.');
    }
  }

  // Funció per desapuntar un usuari d'un avís existent
  static Future<http.Response> eliminarUsuariDeAvis(
      {required int idAvis, required int idUsuari}) async {
    final url = Uri.parse('$apiUrl/avisos/$idAvis/eliminar-usuari');

    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_usuari': idUsuari}),
      );
      return response;
    } catch (e) {
      print('Error al eliminar usuari de l\'avís $idAvis: $e');
      throw Exception('No s\'ha pogut connectar amb l\'API per desapuntar l\'usuari.');
    }
  }

  // Funció per obtenir tots els avisos futurs (GET /avisos)
  static Future<http.Response> getAvisosFuturs() async {
    final url = Uri.parse('$apiUrl/avisos');

    try {
      final response = await http.get(url);
      return response;
    } catch (e) {
      print('Error al obtenir avisos futurs: $e');
      throw Exception('No s\'ha pogut connectar amb l\'API per obtenir els avisos.');
    }
  }

}

class ImageData {
  final Uint8List image;
  final String name;
  final DateTime createdAt;
  final String usuari;

  ImageData({required this.image, required this.name, required this.createdAt, required this.usuari});
}

class UserImageData {
  final Uint8List image;
  final String name;
  final String user;

  UserImageData({required this.image, required this.name, required this.user});
}