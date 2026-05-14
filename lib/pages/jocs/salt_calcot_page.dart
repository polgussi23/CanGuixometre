import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/user_provider.dart';
import '../../services/api_service.dart';

// ---------------------------------------------------------------------------
// CONSTANTS DEL JOC
// ---------------------------------------------------------------------------
const double _kGravetat = 0.0022; // Força amb què cau el calçot
const double _kForcaSalt = -0.028; // Impuls cap amunt en fer tap
const double _kVelocitatXInicial = 0.009; // Velocitat inicial dels obstacles
const double _kVelocitatXMaxima = 0.015; // Velocitat màxima
const double _kGapSizeInicial = 0.40; // 40% de la pantalla d'espai
const double _kGapSizeMinim = 0.22; // Forat mínim

// Ajusta aquestes mides si la teva imatge del calçot es veu molt aixafada o allargada
const double _kCalcotWidth = 45.0; 
const double _kCalcotHeight = 60.0;
// Augmentem l'amplada de l'obstacle per a més presència visual
const double _kObstacleWidth = 75.0; 
const int _kMsPerTick = 30; // ~33 fps

// ---------------------------------------------------------------------------
// MODEL: OBSTACLE
// ---------------------------------------------------------------------------
class Obstacle {
  double x; // Posició horitzontal (0.0 a 1.+)
  double gapY; // Centre del forat (0.0 a 1.0)
  bool processat; // Per saber si ja ens ha donat el punt

  Obstacle({
    required this.x,
    required this.gapY,
    this.processat = false,
  });
}

// ---------------------------------------------------------------------------
// PAGE
// ---------------------------------------------------------------------------
class SaltCalcotPage extends StatefulWidget {
  const SaltCalcotPage({super.key});

  @override
  State<SaltCalcotPage> createState() => _SaltCalcotPageState();
}

class _SaltCalcotPageState extends State<SaltCalcotPage> {
  // --- DADES DE L'USUARI ---
  int? _idUsuariActual;
  String _aliasUsuariActual = "Jugador";
  final TextEditingController _aliasController = TextEditingController();

  // --- COLORS RÚSTICS ---
  final Color _colorFons = const Color(0xFFD7CCC8);
  final Color _colorPissarra = const Color(0xFF263238);
  final Color _colorFustaFosca = const Color(0xFF5D4037);
  final Color _colorBotoActiu = const Color(0xFF8BC34A); // Verd calçot
  final Color _colorBotoInactiu = const Color(0xFF8D6E63);

  // --- ESTAT DEL JOC ---
  bool _jocComencat = false;
  bool _jocAcabat = false;
  int _punts = 0;
  
  // Físiques del jugador
  double _calcotY = 0.5; // Comença al centre (0.0 a 1.0)
  double _calcotVelY = 0.0;
  
  // Fons animat (Parallax)
  double _bgOffsetPx = 0.0; // Desplaçament en píxels del fons

  // Dificultat
  double _velocitatXActual = _kVelocitatXInicial;
  double _gapSizeActual = _kGapSizeInicial;

  List<Obstacle> _obstacles = [];

  Timer? _timerJoc;
  Timer? _timerSpawn;

  // Variables de la pantalla
  double _ampleJocActual = 400.0; 
  double _alcadaJocActual = 600.0;

  // --- RANKING ---
  List<Map<String, dynamic>> _ranking = [];
  bool _carregantRanking = true;
  bool _guardantPuntuacio = false;

  @override
  void initState() {
    super.initState();
    _carregarDadesRanking();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserProfile());
  }

  @override
  void dispose() {
    _timerJoc?.cancel();
    _timerSpawn?.cancel();
    _aliasController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // GESTIÓ USUARI & API
  // ===========================================================================
  Future<void> _loadUserProfile() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.getUserInfo();
      setState(() => _idUsuariActual = userProvider.id);
      if (_idUsuariActual != null) {
        final nom = await ApiService.getUserName(_idUsuariActual!);
        if (nom != null) {
          setState(() {
            _aliasUsuariActual = nom;
            _aliasController.text = nom;
          });
        }
      }
    } catch (e) {
      debugPrint("Error al carregar l'usuari: $e");
    }
  }

  Future<void> _carregarDadesRanking() async {
    setState(() => _carregantRanking = true);
    try {
      final dades = await ApiService.getSaltCalcotRanking();
      setState(() {
        _ranking = dades;
        _carregantRanking = false;
      });
    } catch (e) {
      debugPrint("Error carregant ranking: $e");
      setState(() => _carregantRanking = false);
    }
  }

  Future<void> _enviarPuntuacioAPI(String aliasFinal) async {
    if (_idUsuariActual == null) return;
    setState(() => _guardantPuntuacio = true);
    try {
      await ApiService.postResultatSaltCalcot(_idUsuariActual!, aliasFinal, _punts);
      if (mounted) {
        Navigator.pop(context);
        _resetJoc();
        _carregarDadesRanking();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Puntuació guardada correctament!")),
        );
      }
    } catch (e) {
      debugPrint("Error enviant puntuació: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error guardant la puntuació")),
        );
      }
    } finally {
      if (mounted) setState(() => _guardantPuntuacio = false);
    }
  }

  // ===========================================================================
  // LÒGICA DEL JOC
  // ===========================================================================

  void _iniciarJoc() {
    setState(() {
      _jocComencat = true;
      _jocAcabat = false;
      _punts = 0;
      _calcotY = 0.5;
      _calcotVelY = 0.0;
      _bgOffsetPx = 0.0;
      _obstacles = [];
      _velocitatXActual = _kVelocitatXInicial;
      _gapSizeActual = _kGapSizeInicial;
      _aliasController.text = _aliasUsuariActual;
    });

    _timerJoc?.cancel();
    _timerSpawn?.cancel();

    _timerJoc = Timer.periodic(const Duration(milliseconds: _kMsPerTick), (_) => _tick());
    _timerSpawn = Timer.periodic(const Duration(milliseconds: 1600), (_) => _spawnObstacle());
    
    // Fer el primer saltet automàtic a l'iniciar
    _saltar();
  }

  void _resetJoc() {
    _timerJoc?.cancel();
    _timerSpawn?.cancel();
    setState(() {
      _jocComencat = false;
      _jocAcabat = false;
      _punts = 0;
      _obstacles = [];
      _calcotY = 0.5;
    });
  }

  void _spawnObstacle() {
    if (!_jocComencat || _jocAcabat || !mounted) return;
    final rng = Random();
    
    // El forat pot estar entre el 25% i el 75% de l'alçada
    final gapY = 0.25 + rng.nextDouble() * 0.50; 

    setState(() {
      _obstacles.add(Obstacle(x: 1.2, gapY: gapY)); // Neix fora de la pantalla
    });
  }

  void _saltar() {
    if (!_jocComencat || _jocAcabat) return;
    setState(() {
      _calcotVelY = _kForcaSalt;
    });
  }

  void _tick() {
    if (!mounted || _jocAcabat || !_jocComencat) return;

    setState(() {
      // 1. Físiques del calçot
      _calcotVelY += _kGravetat;
      _calcotY += _calcotVelY;

      // 1.5 Lògica de l'animació del fons (Parallax effect)
      // Multipliquem per 0.5 perquè el fons es mogui a la meitat de velocitat que els obstacles
      double bgSpeedPx = (_velocitatXActual * _ampleJocActual) * 0.5;
      
      // Calculem quina amplada real en píxels té la imatge de fons segons l'alçada del joc.
      // Proporció original: 1390 amples x 752 alts
      double bgProporcio = 1390 / 752;
      double imgWidthEnPantalla = _alcadaJocActual * bgProporcio;
      
      // Movem l'offset i el reiniciem si supera l'amplada de la imatge per fer el bucle
      _bgOffsetPx = (_bgOffsetPx + bgSpeedPx) % imgWidthEnPantalla;

      // X fixa on es troba el calçot a la pantalla (al 20% de l'amplada)
      final calcotFixedX = _ampleJocActual * 0.2;

      // Rectangle de col·lisió del calçot (Fem la caixa de col·lisió una mica més petita pel marge de la imatge PNG)
      final calcotRect = Rect.fromCenter(
        center: Offset(calcotFixedX + _kCalcotWidth / 2, _calcotY * _alcadaJocActual),
        width: _kCalcotWidth * 0.65, 
        height: _kCalcotHeight * 0.75,
      );

      final aEliminar = <Obstacle>[];
      bool xoc = false;

      // 2. Moure i processar obstacles
      for (final obs in _obstacles) {
        obs.x -= _velocitatXActual;

        final obsX = obs.x * _ampleJocActual;
        final topObstacleBottom = (obs.gapY - _gapSizeActual / 2) * _alcadaJocActual;
        final bottomObstacleTop = (obs.gapY + _gapSizeActual / 2) * _alcadaJocActual;

        // Rectangle de la paret (Dalt)
        final topRect = Rect.fromLTRB(
          obsX, 0, obsX + _kObstacleWidth, topObstacleBottom
        );
        // Rectangle del foc (Baix)
        final bottomRect = Rect.fromLTRB(
          obsX, bottomObstacleTop, obsX + _kObstacleWidth, _alcadaJocActual
        );

        // Comprovar col·lisions
        if (calcotRect.overlaps(topRect) || calcotRect.overlaps(bottomRect)) {
          xoc = true;
        }

        // Puntuar si el passem
        if (!obs.processat && calcotFixedX > obsX + _kObstacleWidth) {
          obs.processat = true;
          _punts++;
          _incrementarDificultat();
        }

        // Netejar els que ja han sortit de la pantalla per l'esquerra
        if (obs.x < -0.3) {
          aEliminar.add(obs);
        }
      }

      _obstacles.removeWhere((i) => aEliminar.contains(i));

      // 3. Comprovar si cau a terra o se'n va pel cel
      if (_calcotY < 0.0 || _calcotY > 1.0) {
        xoc = true;
      }

      if (xoc) _acabarJoc();
    });
  }

  void _incrementarDificultat() {
    _gapSizeActual = max(_kGapSizeMinim, _kGapSizeInicial - (_punts * 0.005));
    _velocitatXActual = min(_kVelocitatXMaxima, _kVelocitatXInicial + (_punts * 0.0002));
  }

  void _acabarJoc() {
    _timerJoc?.cancel();
    _timerSpawn?.cancel();
    setState(() {
      _jocAcabat = true;
      _jocComencat = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarDialegFiJoc());
  }

  // ===========================================================================
  // DIÀLEG FI DE JOC
  // ===========================================================================

  void _mostrarDialegFiJoc() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFFFFF8E1),
          shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Column(
            children: [
              const Text(
                '🔥 CALÇOT CREMAT! 🔥',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 6),
              Text(
                '$_punts salts',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _colorFustaFosca,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Guardar rècord com a:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 110, 110, 110)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _aliasController,
                textAlign: TextAlign.center,
                style: TextStyle(color: _colorFustaFosca, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _colorFustaFosca),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _resetJoc();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('TORNAR-HI'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colorPissarra,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      ),
                      onPressed: _guardantPuntuacio
                          ? null
                          : () {
                              final alias = _aliasController.text.trim().isEmpty
                                      ? _aliasUsuariActual
                                      : _aliasController.text.trim();
                              _enviarPuntuacioAPI(alias);
                            },
                      icon: _guardantPuntuacio
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(_guardantPuntuacio ? 'GUARDANT...' : 'GUARDAR'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD PRINCIPAL 
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorFons,
      appBar: (_jocComencat)
          ? null
          : AppBar(
              backgroundColor: _colorPissarra,
              centerTitle: true,
              title: const Text(
                'EL SALT DEL CALÇOT',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: Colors.white,
                  fontFamily: 'RobotoCondensed',
                  letterSpacing: 1.5,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
      body: SafeArea(
        child: _jocComencat
            ? Column(
                children: [
                  _buildMarcador(),
                  Expanded(child: _buildAreaJoc()),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMarcador(),
                    SizedBox(height: 420, child: _buildAreaJoc()),
                    const SizedBox(height: 16),
                    _buildRankingRustic(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  // ===========================================================================
  // WIDGETS
  // ===========================================================================

  Widget _buildMarcador() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: _colorFustaFosca, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_rounded, color: _colorBotoActiu, size: 30),
          const SizedBox(width: 10),
          Text(
            'PUNTS: $_punts',
            style: TextStyle(
              color: _colorFustaFosca,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaJoc() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black, // Fons negre per si l'imatge no cobreix exactament tot algun frame
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colorFustaFosca, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _ampleJocActual = constraints.maxWidth;
            _alcadaJocActual = constraints.maxHeight;
            
            // Calculem l'amplada real de la imatge per empalmar-les bé en l'animació de fons
            double bgProporcio = 1390 / 752;
            double imgWidthEnPantalla = _alcadaJocActual * bgProporcio;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _saltar(),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  children: [
                    // --- FONS ANIMAT 1 ---
                    Positioned(
                      left: -_bgOffsetPx,
                      top: 0,
                      bottom: 0,
                      width: imgWidthEnPantalla,
                      child: Image.asset(
                        'assets/images/jocs/saltCalcot/saltCalcotBackground.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                    
                    // --- FONS ANIMAT 2 (Empalmat just al darrere per fer l'infinit) ---
                    Positioned(
                      left: imgWidthEnPantalla - _bgOffsetPx,
                      top: 0,
                      bottom: 0,
                      width: imgWidthEnPantalla,
                      child: Image.asset(
                        'assets/images/jocs/saltCalcot/saltCalcotBackground.png',
                        fit: BoxFit.fill,
                      ),
                    ),

                    // --- OBSTACLES ---
                    ..._obstacles.map((obs) => _buildObstacles(obs)),
                    
                    // --- JUGADOR (CALÇOT) ---
                    _buildCalcot(),

                    // --- PANTALLA INICI ---
                    if (!_jocComencat && !_jocAcabat)
                      _buildOverlayInici(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildObstacles(Obstacle obs) {
    final left = obs.x * _ampleJocActual;
    final topHeight = (obs.gapY - _gapSizeActual / 2) * _alcadaJocActual;
    final bottomHeight = _alcadaJocActual - ((obs.gapY + _gapSizeActual / 2) * _alcadaJocActual);

    return Stack(
      children: [
        // --- OBSTACLE DE DALT (Rajoles) ---
        Positioned(
          left: left,
          top: 0,
          child: Container(
            width: _kObstacleWidth,
            height: topHeight,
            decoration: BoxDecoration(
              // Mantenen els mateixos marges i ràdio de cantonada que abans, per estil rústic
              //border: Border.all(color: const Color(0xFF4E342E), width: 3),
              //borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(5)), // Ajust per el borde
              child: Image.asset(
                'assets/images/jocs/saltCalcot/rajoles.png',
                fit: BoxFit.cover, // Cobrir tot el espai assignedat
                alignment: Alignment.center,
              ),
            ),
          ),
        ),
        // --- OBSTACLE DE BAIX (Foc) ---
        Positioned(
          left: left,
          bottom: 0,
          child: Container(
            width: _kObstacleWidth,
            height: bottomHeight,
            decoration: BoxDecoration(
              // Mantenen els mateixos marges i ràdio de cantonada que abans
              //border: Border.all(color: const Color(0xFF3E2723), width: 3),
              //borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)), // Ajust per el borde
              child: Image.asset(
                'assets/images/jocs/saltCalcot/foc.png',
                fit: BoxFit.cover, // Cobrir tot el espai assignedat
                // Alignem la imatge a la part superior de l'obstacle, on hi ha el "foc" i la graella
                alignment: Alignment.topCenter, 
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalcot() {
    // El 20% de l'ample de la pantalla, centrat en el seu Y
    final left = _ampleJocActual * 0.2;
    final top = (_calcotY * _alcadaJocActual) - (_kCalcotHeight / 2);

    // Animació visual de rotació segons si puja o baixa
    final rotation = _calcotVelY * 8; 

    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: rotation,
        child: SizedBox(
          width: _kCalcotWidth,
          height: _kCalcotHeight,
          child: Image.asset(
            'assets/images/jocs/saltCalcot/calcot.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayInici() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🧅 EL SALT DEL CALÇOT 🧅',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'Toca la pantalla per fer saltar el calçot.\n\nEvita les teules de dalt i el foc de baix!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _colorBotoActiu,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: _iniciarJoc,
                  child: const Text(
                    '🎮  INICIAR SALT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankingRustic() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _colorPissarra,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _colorFustaFosca, width: 6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🏆 TOP CALÇOTAIRES',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          if (_carregantRanking)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else if (_ranking.isEmpty)
            const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                "Encara no hi ha rècords. Sigues el primer!",
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            ..._ranking.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final data = entry.value;
              final medalles = idx == 1 ? '🥇' : idx == 2 ? '🥈' : idx == 3 ? '🥉' : '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$medalles $idx. ${data['alias']}',
                      style: const TextStyle(color: Colors.white70, fontSize: 15, fontFamily: 'monospace'),
                    ),
                    Text(
                      "${data['puntuacio']} salts",
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              );
            }).toList(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}