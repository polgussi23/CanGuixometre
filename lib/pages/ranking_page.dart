//import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'package:image_picker/image_picker.dart';
//import 'package:image_cropper/image_cropper.dart';
import '../services/api_service.dart';
import 'edit_user_page.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  _RankingPageState createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  List<dynamic> rankings = [];
  List<dynamic> usuarisBonus = [];
  Map<String, Uint8List> userProfileImages = {};

  @override
  void initState() {
    super.initState();
    fetchRankings();
    fetchUserProfileImages();
  }

  Future<void> fetchRankings() async {
    List<dynamic> data = await ApiService.getRankings();
    List<dynamic> ub = await ApiService.getBonusUsers();
    setState(() {
      rankings = data;
      usuarisBonus = ub;
    });
  }

  Future<void> fetchUserProfileImages() async {
    try {
      List<UserImageData> imagesData = await ApiService.getAllUserProfileImages();
      final Map<String, Uint8List> imagesMap = {};
      for (var image in imagesData) {
        imagesMap[image.user] = image.image;
      }
      setState(() {
        userProfileImages = imagesMap;
      });
    } catch (e) {
      print('Error al carregar les imatges dels usuaris: $e');
    }
  }

  void _showLargeImage(String userName) async {
    final largeImage = await ApiService.getUserProfileImage(userName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap:() => Navigator.pop(context),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
                children: [
                  Positioned.fill(
                    child: Center(
                      child: largeImage != null
                          ? Image.memory(largeImage)
                          : Image.asset('assets/images/avatar_placeholder.png'),
                    ),
                  ),
                ],
              ),
            ),
        );
      },
    );
  }

  List<String> _getMedalsForUser(String userName) {
    List<String> medals = [];
    for (var ub in usuarisBonus) {
      if (ub['nom'] == userName) {
        if (ub['descripcio'] == 'Més dies seguits') {
          medals.add('recordDies_coin.png');
        } else if (ub['descripcio'] == 'Més plats diferents provats de la carta') {
          medals.add('exploradorSabors_coin.png');
        }
      }
    }
    return medals;
  }

  void _showMedalPopup(String medalAsset) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.asset('assets/images/$medalAsset', width: 300, height: 300),
        ),
      ),
    );
  }

  Widget _buildPodiumMedal(String medalAsset, double left, double bottom) {
    return Positioned(
      left: left,
      bottom: bottom,
      child: GestureDetector(
        onTap: () => _showMedalPopup(medalAsset),
        child: Image.asset(
          'assets/images/$medalAsset',
          width: 48,  // Mida augmentada
          height: 48,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RANKING'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'el_meu_usuari') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditUserPage()),
                );
                fetchRankings();
                fetchUserProfileImages();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'el_meu_usuari',
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 10,),
                    Text('El meu Usuari'),
                  ],
                )
              ),
            ]
          )
        ]
      ),
      body: rankings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await fetchRankings();
                await fetchUserProfileImages();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (rankings.length >= 3)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 250,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // Primer lloc (Daurat)
                            Positioned(
                              bottom: 0,
                              child: Container(
                                width: 100,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 239, 191, 4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Stack(
                                  children: [
                                    _buildPodiumMedals(
                                      medals: _getMedalsForUser(rankings[0]['nom']),
                                      containerHeight: 150,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Segon lloc (Platejat)
                            Positioned(
                              left: 50,
                              bottom: 0,
                              child: Container(
                                width: 80,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 192, 192, 192),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Stack(
                                  children: [
                                    _buildPodiumMedals(
                                      medals: _getMedalsForUser(rankings[1]['nom']),
                                      containerHeight: 120,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Tercer lloc (Bronze)
                            Positioned(
                              right: 50,
                              bottom: 0,
                              child: Container(
                                width: 80,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 205, 127, 50),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Stack(
                                  children: [
                                    _buildPodiumMedals(
                                      medals: _getMedalsForUser(rankings[2]['nom']),
                                      containerHeight: 100,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Primer lloc - Avatar i info
                            Positioned(
                              bottom: 70,
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showLargeImage(rankings[0]['nom']),
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundImage: userProfileImages[rankings[0]['nom']] != null
                                          ? MemoryImage(userProfileImages[rankings[0]['nom']]!)
                                          : const AssetImage('assets/images/avatar_placeholder.png') as ImageProvider,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    rankings[0]['nom'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${rankings[0]['puntuacio']}',
                                    style: const TextStyle(fontSize: 20, color: Colors.black),
                                  ),
                                ],
                              ),
                            ),

                            // Segon lloc - Avatar i info
                            Positioned(
                              left: 50,
                              bottom: 50,
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showLargeImage(rankings[1]['nom']),
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundImage: userProfileImages[rankings[1]['nom']] != null
                                          ? MemoryImage(userProfileImages[rankings[1]['nom']]!)
                                          : const AssetImage('assets/images/avatar_placeholder.png') as ImageProvider,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    rankings[1]['nom'],
                                    style: const TextStyle(fontSize: 16, color: Colors.black),
                                  ),
                                  Text(
                                    '${rankings[1]['puntuacio']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Tercer lloc - Avatar i info
                            Positioned(
                              right: 50,
                              bottom: 30,
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showLargeImage(rankings[2]['nom']),
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundImage: userProfileImages[rankings[2]['nom']] != null
                                          ? MemoryImage(userProfileImages[rankings[2]['nom']]!)
                                          : const AssetImage('assets/images/avatar_placeholder.png') as ImageProvider,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    rankings[2]['nom'],
                                    style: const TextStyle(fontSize: 16, color: Colors.black),
                                  ),
                                  Text(
                                    '${rankings[2]['puntuacio']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Llista de la resta
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 16.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final actualIndex = index + 3;
                          final medals = _getMedalsForUser(rankings[actualIndex]['nom']);

                          return ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 50,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: Text(
                                      '${actualIndex + 1}',
                                      style: const TextStyle(fontSize: 24),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () => _showLargeImage(rankings[actualIndex]['nom']),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundImage: userProfileImages[rankings[actualIndex]['nom']] != null
                                        ? MemoryImage(userProfileImages[rankings[actualIndex]['nom']]!)
                                        : const AssetImage('assets/images/avatar_placeholder.png') as ImageProvider,
                                  ),
                                ),
                              ],
                            ),
                            title: Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Text(
                                rankings[actualIndex]['nom'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...medals.map((medal) => 
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: GestureDetector(
                                      onTap: () => _showMedalPopup(medal),
                                      child: Image.asset(
                                        'assets/images/$medal',
                                        width: 36,
                                        height: 36,
                                      ),
                                    ),
                                  ),
                                ).toList(),
                                const SizedBox(width: 16),
                                Text('${rankings[actualIndex]['puntuacio']}'),
                              ],
                            ),
                          );
                        },
                        childCount: rankings.length > 3 ? rankings.length - 3 : 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  Widget _buildPodiumMedals({required List<String> medals, required double containerHeight}) {
    if (medals.isEmpty) return const SizedBox.shrink();

    final medalSize = medals.length > 1 ? 32.0 : 40.0;
    
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: medals.map((medal) => 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: GestureDetector(
                onTap: () => _showMedalPopup(medal),
                child: Image.asset(
                  'assets/images/$medal',
                  width: medalSize,
                  height: medalSize,
                ),
              ),
            ),
          ).toList(),
        ),
      ),
    );
  }
}