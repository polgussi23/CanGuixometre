import 'package:can_guix/pages/edit_photo_page.dart';
import 'package:can_guix/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:can_guix/services/user_provider.dart';

class NoScoreGalleryPage extends StatefulWidget{
  final List<int> imagesList;
  
  const NoScoreGalleryPage({super.key, required this.imagesList});
  
  @override
  _NoScoreGallyerPage createState() => _NoScoreGallyerPage();
}

class _NoScoreGallyerPage extends State<NoScoreGalleryPage>{

  final List<ImageData> uploadedImages = [];
  late int userId;
  late List<ImageData> images;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  void _loadImages() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userId = userProvider.id!;

    print(widget.imagesList);
    images = await ApiService.getImagesFromId(widget.imagesList);

    for(var i in images){
      print(i.name);
    }
    setState(() {
      uploadedImages.addAll(images);
    });
    //uploadedImages.addAll;
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("GALERIA"),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: uploadedImages.length,
        itemBuilder: (context, index) {
          String formattedDate = DateFormat('dd/MM/yyyy').format(uploadedImages[index].createdAt);
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPhotoPage(selectedImage: uploadedImages[index]),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.width * 0.6,
                  width: MediaQuery.of(context).size.width * 0.6,
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
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 40), // Espai extra entre elements de la llista
              ],
            ),
          );
        },
      ),
    );
  }

}