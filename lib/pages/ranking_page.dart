import 'dart:typed_data';
import 'package:can_guix/widgets/ranking_popup_button.dart';
import 'package:can_guix/widgets/smart_image_dialog.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/ranking_components.dart';
import 'package:animate_do/animate_do.dart';

const Color kDarkBackgroundColor = Color(0xFF1E1E1E);
const Color kDarkSurfaceColor = Color(0xFF2C2C2C);

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  _RankingPageState createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  List<dynamic> rankings = [];
  List<dynamic> usuarisBonus = [];
  Map<String, Uint8List> userProfileImages = {};
  DateTime? endDate;
  DateTime? startDate;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    await Future.wait([
      fetchRankings(),
      fetchUserProfileImages(),
      getEndDate(),
      getStartDate(),
    ]);
  }

  Future<void> fetchRankings() async {
    List<dynamic> data = await ApiService.getRankings();
    List<dynamic> ub = await ApiService.getBonusUsers();
    if (mounted) {
      setState(() {
        rankings = data;
        usuarisBonus = ub;
      });
    }
  }

  Future<void> fetchUserProfileImages() async {
    try {
      List<UserImageData> imagesData =
          await ApiService.getAllUserProfileImages();
      final Map<String, Uint8List> imagesMap = {};
      for (var image in imagesData) {
        imagesMap[image.user] = image.image;
      }
      if (mounted) {
        setState(() {
          userProfileImages = imagesMap;
        });
      }
    } catch (e) {
      print('Error imatges: $e');
    }
  }

  Future<void> getEndDate() async {
    try {
      List<dynamic> data = await ApiService.getEndDate();
      if (data.isNotEmpty && mounted) {
        setState(() {
          endDate = DateTime.parse(data[0]['date']);
        });
      }
    } catch (e) {
      print('Error data final: $e');
    }
  }

  Future<void> getStartDate() async {
    try {
      List<dynamic> data = await ApiService.getStartDate();
      if (data.isNotEmpty && mounted) {
        setState(() {
          startDate = DateTime.parse(data[0]['date']);
        });
      }
    } catch (e) {
      print('Error data inici: $e');
    }
  }

  String _titleText() {
  DateTime now = DateTime.now();
  DateTime avuiSenseHores = DateTime(now.year, now.month, now.day);

  // Retorna si falta qualsevol de les dues dates
  if (startDate == null || endDate == null) return 'RÀNQUING CAN GUIX';

  DateTime iniciSenseHores =
      DateTime(startDate!.year, startDate!.month, startDate!.day);

  if (iniciSenseHores.isAfter(avuiSenseHores)) {
    final dies = iniciSenseHores.difference(avuiSenseHores).inDays;
    if (dies == 1) return 'Comença demà!';
    return 'Queden $dies dies per començar';
  }

  if (iniciSenseHores.isAtSameMomentAs(avuiSenseHores)) {
    return '✨ COMENÇA AVUI! ✨';
  }

  DateTime fiSenseHores =
      DateTime(endDate!.year, endDate!.month, endDate!.day);
  final difference = fiSenseHores.difference(avuiSenseHores);

  if (difference.isNegative) return '🏆 FINALITZAT 🏆';
  if (difference.inDays == 0) return 'Últim dia!';
  return 'Queden ${difference.inDays} dies';
}

  List<String> _getMedalsForUser(String userName) {
    // La teva lògica original, intacta
    List<String> medals = [];
    for (var ub in usuarisBonus) {
      if (ub['nom'] == userName) {
        if (ub['descripcio'] == 'Més dies seguits') {
          medals.add('recordDies_coin.png');
        } else if (ub['descripcio'] ==
            'Més plats diferents provats de la carta') {
          medals.add('exploradorSabors_coin.png');
        }
      }
    }
    return medals;
  }

  // --- Popups i Diàlegs (UI Helpers) ---
  void _showLargeImage(String userName) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.85),
        barrierDismissible: true,
        pageBuilder: (context, _, __) {
          return SmartImageDialog(
            userName: userName,
            lowResImage:
                userProfileImages[userName], // Passem la foto petita inicial
            heroTag: userName,
          );
        },
      ),
    );
  }

  void _showMedalPopup(String medalAsset) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.asset('assets/images/$medalAsset', width: 250),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kDarkBackgroundColor,
        foregroundColor: Colors.white, // Text negre
        centerTitle: true,
        title: Text(
          _titleText(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          RankingPopupButton(
            onRefreshNeeded: _refreshData,
          ),
        ],
      ),
      body: rankings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: Colors.amber,
              child: CustomScrollView(
                slivers: [
                  // --- SECCIÓ PODI (TOP 3) ---
                  if (rankings.length >= 3)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 30, 16, 20),
                        decoration: const BoxDecoration(
                          color: kDarkSurfaceColor,
                          borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(30)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // 2n Lloc (Esquerra)
                            Expanded(
                                child: FadeInUp(
                              duration: Duration(milliseconds: 800),
                              delay: const Duration(milliseconds: 200),
                              child: PodiumItem(
                                user: rankings[1],
                                position: 2,
                                height: 110,
                                imageBytes:
                                    userProfileImages[rankings[1]['nom']],
                                medals: _getMedalsForUser(rankings[1]['nom']),
                                onImageTap: _showLargeImage,
                                onMedalTap: _showMedalPopup,
                              ),
                            )),
                            // 1r Lloc (Centre - Més gran)
                            Expanded(
                              flex: 1,
                              child: Transform.translate(
                                offset: const Offset(
                                    0, -10), // El teu ajustament original
                                child: FadeInUp(
                                  duration: const Duration(milliseconds: 800),
                                  delay: const Duration(milliseconds: 400),
                                  child: PodiumItem(
                                    user: rankings[0],
                                    position: 1,
                                    height: 150,
                                    imageBytes:
                                        userProfileImages[rankings[0]['nom']],
                                    medals:
                                        _getMedalsForUser(rankings[0]['nom']),
                                    onImageTap: _showLargeImage,
                                    onMedalTap: _showMedalPopup,
                                  ),
                                ),
                              ),
                            ),
                            // 3r Lloc (Dreta)
                            Expanded(
                                child: FadeInUp(
                              duration: Duration(milliseconds: 800),
                              child: PodiumItem(
                                user: rankings[2],
                                position: 3,
                                height: 90,
                                imageBytes:
                                    userProfileImages[rankings[2]['nom']],
                                medals: _getMedalsForUser(rankings[2]['nom']),
                                onImageTap: _showLargeImage,
                                onMedalTap: _showMedalPopup,
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),

                  // --- SECCIÓ LLISTA (DEL 4T AL FINAL) ---
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 20, bottom: 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final actualIndex = index + 3;
                          bool shouldAnimate = index < 6;

                          Widget tile = RankingTile(
                            user: rankings[actualIndex],
                            index: actualIndex,
                            imageBytes:
                                userProfileImages[rankings[actualIndex]['nom']],
                            medals:
                                _getMedalsForUser(rankings[actualIndex]['nom']),
                            onImageTap: _showLargeImage,
                            onMedalTap: _showMedalPopup,
                          );
                          if (shouldAnimate) {
                            return FadeInLeft(
                              duration: const Duration(milliseconds: 500),
                              delay: Duration(milliseconds: index * 50),
                              child: tile,
                            );
                          } else {
                            return tile;
                          }
                        },
                        childCount:
                            rankings.length > 3 ? rankings.length - 3 : 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
