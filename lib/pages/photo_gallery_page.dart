// photo_gallery_page.dart
//import 'dart:typed_data';
import 'package:can_guix/pages/edit_photo_page.dart';
import 'package:can_guix/pages/no_score_gallery_page.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'upload_photo_page.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:can_guix/services/user_provider.dart';
import 'package:provider/provider.dart';

class PhotoGalleryPage extends StatefulWidget {
  const PhotoGalleryPage({super.key});

  @override
  _PhotoGalleryPageState createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  final List<ImageData> uploadedImages = [];
  dynamic _selectedImage;
  bool isLoading = false;  // Indica si estem carregant imatges
  int currentPage = 1;  // Pàgina actual de la paginació
  int imagesPerPage = 16;
  List<int> imagesNoScore = [];
  
  @override
  void initState() {
    super.initState();
    _loadImages();  // Carregar les primeres imatges al iniciar la pàgina
    _imatgesSensePuntuacio();
  }

  Future<void> _loadImages() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<ImageData> newImages =  await ApiService.getImages(currentPage, imagesPerPage);
      //<Uint8List> newImages = await ApiService.getImages(currentPage, 5); // Funció per obtenir imatges
      setState(() {
        uploadedImages.addAll(newImages);
        currentPage++; // Incrementa la pàgina per a la pròxima càrrega
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  void showImageSourceOptions() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.camera),
              title: Text('Fer una foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Triar de la galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        );
      },
    );

    if (source != null) {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          if(!kIsWeb){
            _selectedImage = File(pickedFile.path);
          }else{
            _selectedImage = pickedFile.readAsBytes();
          }
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UploadPhotoPage(selectedImage: _selectedImage),
          ),
        );
      }
    }
  }

  Future<void> _imatgesSensePuntuacio() async{
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    //int n;
    await userProvider.getUserInfo();
    List<dynamic> response = await ApiService.getNonScoreImagesUser(userProvider.id);
    //nImgesNoScore = response.length;
    for(var imatges in response){
      //print(imatges);
      imagesNoScore.add(imatges['imatge_id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("GALERIA"),
            if (imagesNoScore.length > 0)
              Transform.translate(
                offset: Offset(-30, 0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => NoScoreGalleryPage(
                                      imagesList: imagesNoScore,
                                    )),
                          );
                        },
                        child: Icon(
                          Icons.warning,
                          color: Colors.yellow,
                          size: 34,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: -6,
                      child: Container(
                        padding: EdgeInsets.all(3),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                          maxWidth: 20,
                          maxHeight: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            imagesNoScore.length.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      body: Center(
        child: uploadedImages.isNotEmpty
            ? NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  // Cargar más imágenes cuando se muestre la décima foto (índice 9)
                  if (!isLoading &&
                      scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent -
                              (scrollInfo.metrics.viewportDimension / 2)) {
                    // Si estamos cerca del final, cargar más
                    _loadImages();
                    return true;
                  }
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      uploadedImages.clear();
                      currentPage = 1;
                    });
                    await _loadImages();
                    await _imatgesSensePuntuacio();
                  },
                  child: GridView.builder(
                    padding: EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: uploadedImages.length,
                    itemBuilder: (context, index) {
                      // Pre-cargar más imágenes cuando se muestre la décima foto
                      if (!isLoading &&
                          index == 9 &&
                          uploadedImages.length - 1 == index) {
                        _loadImages();
                      }
                      String formattedDate = DateFormat('dd/MM/yyyy')
                          .format(uploadedImages[index].createdAt);
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditPhotoPage(
                                  selectedImage: uploadedImages[index]),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.width * 0.4,
                              width: MediaQuery.of(context).size.width * 0.4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  uploadedImages[index].image,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              )
            : isLoading
                ? CircularProgressIndicator()
                : RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        uploadedImages.clear();
                        currentPage = 1;
                      });
                      await _loadImages();
                      await _imatgesSensePuntuacio();
                    },
                    child: ListView(
                      children: [
                        SizedBox(height: 200),
                        Center(child: Text('Encara no hi ha imatges pujades.')),
                      ],
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showImageSourceOptions(),
        tooltip: 'Pujar Imatge',
        backgroundColor: Color.fromARGB(255, 251, 255, 0),
        child: Icon(
          Icons.upload_file,
          color: Colors.black,
        ),
      ),
    );
  }
}
