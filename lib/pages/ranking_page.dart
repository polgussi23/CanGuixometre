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
  List<dynamic> monthlyRankings = [];
  List<dynamic> usuarisBonus = [];
  Map<String, Uint8List> userProfileImages = {};
  DateTime? endDate;
  DateTime? startDate;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() => _currentPage = page);
      }
    });
    _refreshData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await Future.wait([
      fetchRankings(),
      fetchMonthlyRankings(),
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

  Future<void> fetchMonthlyRankings() async {
    try {
      List<dynamic> data = await ApiService.getMonthRanking();
      if (mounted) {
        setState(() => monthlyRankings = data);
      }
    } catch (e) {
      print('Error rànquing mensual: $e');
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
        setState(() => userProfileImages = imagesMap);
      }
    } catch (e) {
      print('Error imatges: $e');
    }
  }

  Future<void> getEndDate() async {
    try {
      List<dynamic> data = await ApiService.getEndDate();
      if (data.isNotEmpty && mounted) {
        setState(() => endDate = DateTime.parse(data[0]['date']));
      }
    } catch (e) {
      print('Error data final: $e');
    }
  }

  Future<void> getStartDate() async {
    try {
      List<dynamic> data = await ApiService.getStartDate();
      if (data.isNotEmpty && mounted) {
        setState(() => startDate = DateTime.parse(data[0]['date']));
      }
    } catch (e) {
      print('Error data inici: $e');
    }
  }

  String _titleText() {
    if (_currentPage == 1) {
      final now = DateTime.now();
      final mesAnterior = DateTime(now.year, now.month - 1);
      final nomMes = _nomMes(mesAnterior.month);
      return 'RÀNQUING ${nomMes.toUpperCase()}';
    }

    DateTime now = DateTime.now();
    DateTime avuiSenseHores = DateTime(now.year, now.month, now.day);
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

  String _nomMes(int mes) {
    const mesos = [
      '', 'Gener', 'Febrer', 'Març', 'Abril', 'Maig', 'Juny',
      'Juliol', 'Agost', 'Setembre', 'Octubre', 'Novembre', 'Desembre'
    ];
    return mesos[mes];
  }

  List<String> _getMedalsForUser(String userName) {
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

  void _showLargeImage(String userName) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.85),
        barrierDismissible: true,
        pageBuilder: (context, _, __) {
          return SmartImageDialog(
            userName: userName,
            lowResImage: userProfileImages[userName],
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

  // --- Rànquing genèric (global o mensual) ---
  Widget _buildRankingBody(List<dynamic> data, {bool showMedals = true}) {
    if (data.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Colors.amber,
      child: CustomScrollView(
        slivers: [
          if (data.length >= 3)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 30, 16, 20),
                decoration: const BoxDecoration(
                  color: kDarkSurfaceColor,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 200),
                        child: PodiumItem(
                          user: data[1],
                          position: 2,
                          height: 110,
                          imageBytes: userProfileImages[data[1]['nom']],
                          medals: showMedals
                              ? _getMedalsForUser(data[1]['nom'])
                              : [],
                          onImageTap: _showLargeImage,
                          onMedalTap: _showMedalPopup,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Transform.translate(
                        offset: const Offset(0, -10),
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          delay: const Duration(milliseconds: 400),
                          child: PodiumItem(
                            user: data[0],
                            position: 1,
                            height: 150,
                            imageBytes: userProfileImages[data[0]['nom']],
                            medals: showMedals
                                ? _getMedalsForUser(data[0]['nom'])
                                : [],
                            onImageTap: _showLargeImage,
                            onMedalTap: _showMedalPopup,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        child: PodiumItem(
                          user: data[2],
                          position: 3,
                          height: 90,
                          imageBytes: userProfileImages[data[2]['nom']],
                          medals: showMedals
                              ? _getMedalsForUser(data[2]['nom'])
                              : [],
                          onImageTap: _showLargeImage,
                          onMedalTap: _showMedalPopup,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 20, bottom: 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final actualIndex = index + 3;
                  final bool shouldAnimate = index < 6;
                  Widget tile = RankingTile(
                    user: data[actualIndex],
                    index: actualIndex,
                    imageBytes: userProfileImages[data[actualIndex]['nom']],
                    medals: showMedals
                        ? _getMedalsForUser(data[actualIndex]['nom'])
                        : [],
                    onImageTap: _showLargeImage,
                    onMedalTap: _showMedalPopup,
                  );
                  if (shouldAnimate) {
                    return FadeInLeft(
                      duration: const Duration(milliseconds: 500),
                      delay: Duration(milliseconds: index * 50),
                      child: tile,
                    );
                  }
                  return tile;
                },
                childCount: data.length > 3 ? data.length - 3 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

 // Afegeix aquest widget nou
Widget _buildTabSelector() {
  return Container(
    margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: kDarkSurfaceColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        _buildTab(index: 0, label: '🌍 Global'),
        _buildTab(index: 1, label: '📅 Mensual'),
      ],
    ),
  );
}

Widget _buildTab({required int index, required String label}) {
  final bool isActive = _currentPage == index;
  return Expanded(
    child: GestureDetector(
      onTap: () => _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isActive ? Colors.black : Colors.white54,
          ),
        ),
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
        foregroundColor: Colors.white,
        centerTitle: true,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _titleText(),
            key: ValueKey(_currentPage),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        actions: [
          RankingPopupButton(onRefreshNeeded: _refreshData),
        ],
      ),
      body: Column(
        children: [
          _buildTabSelector(),   // <-- Pestanyes a dalt
          Expanded(
            child: PageView(
              controller: _pageController,
              children: [
                _buildRankingBody(rankings, showMedals: true),
                _buildRankingBody(monthlyRankings, showMedals: false),
              ],
            ),
          ),
          // Elimina _buildPageIndicator() d'aquí
        ],
      ),
    );
  }
}