// A 'screens/pack_opening_page.dart'

import 'dart:math' as math;
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:can_guix/services/user_provider.dart';
import 'package:can_guix/services/api_service.dart';
import 'package:can_guix/models/carta.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flip_card/flip_card.dart';
//import 'package:lottie/lottie.dart';

class PackOpeningPage extends StatefulWidget {
  const PackOpeningPage({Key? key}) : super(key: key);

  @override
  State<PackOpeningPage> createState() => _PackOpeningPageState();
}

class _PackOpeningPageState extends State<PackOpeningPage>
    with TickerProviderStateMixin {
  // 1. ESTATS DE L'ANIMACIÓ
  bool _isLoading = true;
  bool _isPackBursted = false; // El sobre ha explotat?
  bool _cardsAreFanned = false; // Les cartes s'han mostrat en ventall?
  bool _cardsAreStacked = false; // Les cartes s'han apilat?
  int _tapCount = 0;

  List<Carta> _cartesGuanyades = [];

  // --- VARIABLES D'ANIMACIÓ ---
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  double _tapScale = 1.0;

  List<FlipCardController> _flipControllers = [];

  // --- ESTAT DE LA PILA DE CARTES ---
  int _currentCardIndex = 0; // Quina carta és a dalt (0-4)
  bool _isCardRevealed = false; // La carta de dalt està girada?
  bool _isCardDismissed = false; // La carta de dalt ha marxat?

  int? _glowingCardIndex; // Índex de la carta llegendària

  //final math.Random _random = math.Random();

  Color _getColorForRaresa(String raresaNom) {
    switch (raresaNom) {
      case 'Comú':
        return Colors.blue;
      case 'Inusual':
        return Colors.green;
      case 'Raro':
        return Colors.red;
      case 'Llegendari':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    _breathingController.repeat(reverse: true);

    _iniciarObertura(Provider.of<UserProvider>(context, listen: false));
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  Future<void> _iniciarObertura(UserProvider userProvider) async {
    try {
      final String userId = userProvider.id.toString();
      final List<dynamic> jsonCartes = await ApiService.obrirSobre(userId);

      if (!mounted) return;

      setState(() {
        _cartesGuanyades =
            jsonCartes.map((json) => Carta.fromApi(json)).toList();
        _flipControllers =
            List.generate(_cartesGuanyades.length, (_) => FlipCardController());
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      Navigator.of(context).pop();
    }
  }

  void _onPackTapped() {
    if (_isLoading || _isPackBursted) return;

    setState(() {
      _tapCount++;
      _tapScale = 1.2;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        _tapScale = 1.0;
      });
    });

    if (_tapCount >= 3) {
      _breathingController.stop();
      Future.delayed(const Duration(milliseconds: 200), _burstPack);
    }
  }

  /// Pas 2: El sobre explota
  void _burstPack() {
    if (!mounted) return;
    setState(() {
      _isPackBursted = true; // Amaga el sobre, mostra el "BOOM"
    });

    // Temps per a l'animació "BOOM"
    Future.delayed(const Duration(milliseconds: 500), () {
      _fanOutCards(); // Mostra el ventall
    });
  }

  /// Pas 3: Les cartes apareixen en ventall
  void _fanOutCards() {
    if (!mounted) return;
    setState(() {
      _cardsAreFanned = true; // Activa l'animació del ventall
    });

    // Esperem un moment per veure el ventall
    Future.delayed(const Duration(milliseconds: 2000), () {
      _stackCards(); // Anima les cartes a la pila
    });
  }

  /// Pas 4: Les cartes s'apilen
  void _stackCards() {
    if (!mounted) return;
    setState(() {
      _cardsAreStacked = true; // Activa l'animació d'apilar
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obrint Sobre...'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isPackBursted && _currentCardIndex >= _cartesGuanyades.length)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tancar',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            )
        ],
      ),
      body: Center(
        child: _buildAnimationStages(),
      ),
    );
  }

  /// AQUEST ÉS EL WIDGET PRINCIPAL DE L'ANIMACIÓ
  Widget _buildAnimationStages() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    return Stack(
      alignment: Alignment.center,

      // --- ORDRE DE LA PILA CORREGIT ---
      children: [
        // 1. El sobre (al FONS de la pila)
        AnimatedOpacity(
          opacity: _isPackBursted ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: _buildPack(),
        ),

        // 2. El "BOOM!" (al MIG)
        // L'embolcallem amb IgnorePointer per assegurar-nos
        // que no intercepta clics MAI.
        if (_isPackBursted && !_cardsAreFanned)
          const IgnorePointer(
            ignoring: true,
            child: Text('BOOM!',
                style: TextStyle(fontSize: 50, color: Colors.white)),
          ),

        // 3. Les cartes (A DALT de tot, ara SÍ rebran els clics)
        if (_isPackBursted) _buildCardAnimation(),
      ],
    );
  }

  Widget _buildPack() {
    return ScaleTransition(
      scale: _breathingAnimation,
      child: AnimatedScale(
        scale: _tapScale,
        duration: const Duration(milliseconds: 100),
        child: GestureDetector(
          onTap: _onPackTapped,
          child: Image.asset(
            'assets/images/sobre_tancat.png',
            width: 250,
          ),
        ),
      ),
    );
  }

  // --- NOVA FUNCIÓ PRINCIPAL PER A LES CARTES ---
  /// Aquest widget conté les 5 cartes i gestiona el seu estat
  /// (Ventall -> Pila -> Girar)
  Widget _buildCardAnimation() {
    final screenSize = MediaQuery.of(context).size;

    const double cardWidth = 250.0; // Has canviat la mida a 350
    const double cardHeight = cardWidth / 0.7;

    List<Widget> stackedCards = [];

    for (int index = _cartesGuanyades.length - 1; index >= 0; index--) {
      final carta = _cartesGuanyades[index];
      final controller = _flipControllers[index];
      final bool isCurrent = (index == _currentCardIndex);
      final bool isDismissed = (index < _currentCardIndex);

      // --- CÀLCULS DE POSICIÓ (igual que abans) ---
      final double fanWidth =
          (120.0 * _cartesGuanyades.length) - (_cartesGuanyades.length * 40.0);
      final double fanStartLeft = (screenSize.width - fanWidth) / 2;
      final double fanLeft = fanStartLeft + (index * (120.0 - 40.0));
      final double fanTop = (screenSize.height / 2) - (120.0 / 0.7 / 1.5);
      final double fanRotation =
          (index - (_cartesGuanyades.length / 2) + 0.5) * (math.pi / 60);

      final double stackLeft = (screenSize.width / 2) - (cardWidth / 2);
      final double stackTop = (screenSize.height / 2) -
          (cardHeight / 1.5) +
          (index * 2.0); // Lleugera separació

      double targetLeft;
      double targetTop;
      double targetRotation;
      double targetWidth;
      double targetHeight;

      if (_cardsAreStacked) {
        if (isDismissed) {
          targetLeft = screenSize.width;
        } else if (isCurrent && _isCardDismissed) {
          targetLeft = screenSize.width;
        } else {
          targetLeft = stackLeft;
        }
        targetTop = stackTop;
        targetRotation = 0;
        targetWidth = cardWidth;
        targetHeight = cardHeight;
      } else if (_cardsAreFanned) {
        targetLeft = fanLeft;
        targetTop = fanTop;
        targetRotation = fanRotation;
        targetWidth = 120.0;
        targetHeight = 120.0 / 0.7;
      } else {
        targetLeft = stackLeft;
        targetTop = stackTop;
        targetRotation = 0;
        targetWidth = cardWidth;
        targetHeight = cardHeight;
      }

      final bool isGlowingLegendary = (_glowingCardIndex == index);

      // --- CANVI CLAU: LÒGICA DEL BRILLO ---

      // 1. Obtenim el color de la raresa de la carta
      final Color raresaColor = _getColorForRaresa(carta.raresaNom);

      // 2. Creem una llista d'ombres (buida per defecte)
      List<BoxShadow> sombras = [];

      if (_cardsAreFanned && !_cardsAreStacked) {
        // 3. FASE DE VENTALL: Afegim el brillo de la raresa
        sombras = [
          BoxShadow(
            color: raresaColor.withOpacity(0.9),
            blurRadius: 15.0, // Més petit per a la carta petita
            spreadRadius: 3.0,
          ),
        ];
      } else if (_cardsAreStacked && isGlowingLegendary) {
        // 4. FASE DE PILA: Mantenim el brillo Llegendari
        sombras = [
          BoxShadow(
            color: Colors.amber.withOpacity(0.8),
            blurRadius: 30.0,
            spreadRadius: 8.0,
          ),
        ];
      }
      // --- FI DEL CANVI CLAU ---

      stackedCards.add(
        AnimatedPositioned(
          duration: Duration(milliseconds: _cardsAreStacked ? 500 : 800),
          curve: _cardsAreStacked ? Curves.easeIn : Curves.easeOutBack,
          left: targetLeft,
          top: targetTop,
          child: AnimatedRotation(
            turns: targetRotation,
            duration: const Duration(milliseconds: 300),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: targetWidth,
              height: targetHeight,

              // 5. Apliquem les 'sombras' que acabem de calcular
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: sombras, // <-- LÍNIA ACTUALITZADA
              ),

              child: Stack(
                children: [
                  FlipCard(
                    controller: controller,
                    flipOnTouch: false,
                    front: _buildCardBack(
                      width: targetWidth,
                      onTap: () {
                        if (isCurrent && _cardsAreStacked && !_isCardRevealed) {
                          controller.toggleCard();
                          setState(() {
                            _isCardRevealed = true;
                          });
                          if (carta.raresaNom == "Llegendari") {
                            _showLegendaryEffect(index);
                          }
                        }
                      },
                    ),
                    back: _buildCardFront(
                      carta,
                      width: targetWidth,
                      onTap: () {
                        if (isCurrent && _cardsAreStacked && _isCardRevealed) {
                          _dismissCurrentCard();
                        }
                      },
                    ),
                  ),

                  // Els teus sparkles per a la llegendària (ja funcionen)
                  //if (isGlowingLegendary && _isCardRevealed)
                  //_buildSparkleOverlay(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: stackedCards,
    );
  }

  /// Funció per moure a la següent carta
  void _dismissCurrentCard() {
    setState(() {
      _isCardDismissed = true; // Inicia l'animació de sortida
      _glowingCardIndex = null; // Desactiva l'efecte de brillantor
    });

    // Esperem que acabi l'animació de sortida
    Future.delayed(Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (_currentCardIndex == _cartesGuanyades.length - 1) {
        // SÍ: Tanquem la pàgina d'obertura de sobres
        Navigator.of(context).pop();
      } else {
        // NO: Passem a la següent carta
        setState(() {
          _currentCardIndex++;
          _isCardDismissed = false;
          _isCardRevealed = false;
        });
      }
    });
  }

  /// El cul de la carta (ARA REP 'onTap')
  Widget _buildCardBack({required double width, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        'assets/images/carta_cul.png',
        width: width,
        fit: BoxFit.contain,
      ),
    );
  }

  /// La cara de la carta (ARA REP 'onTap')
  Widget _buildCardFront(Carta carta,
      {required double width, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: CachedNetworkImage(
        imageUrl: carta.urlImatge,
        width: width,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: width,
          color: Colors.grey[800],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }

  void _showLegendaryEffect(int index) {
    // 1. Activem l'estat de "brillar" per a aquesta carta
    setState(() {
      _glowingCardIndex = index;
    });
  }
}
