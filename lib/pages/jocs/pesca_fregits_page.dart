import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/user_provider.dart';
import '../../services/api_service.dart';

// ---------------------------------------------------------------------------
// CONSTANTS DEL JOC
// ---------------------------------------------------------------------------
const double _kAmplFregidoraRatio = 0.16; // 16% de l'ample de l'àrea
const double _kAmplItemRatio = 0.13; // 13% de l'ample de l'àrea

// Sistema de dificultat progressiu (fosc/ocult)
const double _kVelocitatInicial = 0.0030; // unitats per tick
const double _kVelocitatMaxima = 0.0150; // sostre de velocitat
const double _kIncrementVelocitat = 0.0001; // +velocitat molt suau cada nivell
const int _kCapturesPerNivell = 2; // escalem més ràpid internament
const int _kMsSpawnInicial = 1200; // interval spawn inicial (ms)
const int _kMsSpawnMinim = 250; // gairebé pluja de fregits
const int _kMsSpawnDecrement = 25; // ms menys a cada pas

const int _kMsPerTick = 33; // ~30 fps
const double _kZonaFregidoraY = 0.84; // y (ratio) on comença la zona de captura
const int _kPuntsCapturaBase = 10;

// ---------------------------------------------------------------------------
// MODEL: ITEM CAIENT
// ---------------------------------------------------------------------------
class ItemCaient {
  double x; // 0.0–1.0  (centre, ratio de l'ample)
  double y; // 0.0–1.0  (ratio de l'alçada, marca la part SUPERIOR de l'ítem)
  final String emoji;
  final bool esBo; 
  bool processat;

  ItemCaient({
    required this.x,
    required this.y,
    required this.emoji,
    required this.esBo,
    this.processat = false,
  });
}

// ---------------------------------------------------------------------------
// PAGE
// ---------------------------------------------------------------------------
class PescaFregitsPage extends StatefulWidget {
  const PescaFregitsPage({super.key});

  @override
  State<PescaFregitsPage> createState() => _PescaFregitsPageState();
}

class _PescaFregitsPageState extends State<PescaFregitsPage> {
  // --- DADES DE L'USUARI ---
  int? _idUsuariActual;
  String _aliasUsuariActual = "Jugador";
  final TextEditingController _aliasController = TextEditingController();

  // --- COLORS RÚSTICS ---
  final Color _colorFons = const Color(0xFFD7CCC8);
  final Color _colorPissarra = const Color(0xFF263238);
  final Color _colorFustaFosca = const Color(0xFF5D4037);
  final Color _colorBotoActiu = const Color(0xFFFFB300);
  final Color _colorBotoInactiu = const Color(0xFF8D6E63);

  // --- ESTAT DEL JOC ---
  bool _jocComencat = false;
  bool _jocAcabat = false;
  int _punts = 0;
  int _vides = 3;
  double _fregidoraX = 0.5; // centre (ratio 0.0–1.0)
  List<ItemCaient> _items = [];
  double _velocitat = _kVelocitatInicial;
  int _itemsCapturats = 0;
  int _nivelDificultat = 0; // Ocult de cara a l'usuari
  int _msSpawnActual = _kMsSpawnInicial; 

  Timer? _timerJoc;
  Timer? _timerSpawn;

  // Variables per calcular col·lisions en base a la pantalla real
  double _ampleJocActual = 400.0; 
  double _alcadaJocActual = 600.0;

  // --- RANKING ---
  List<Map<String, dynamic>> _ranking = [];
  bool _carregantRanking = true;
  bool _guardantPuntuacio = false;

  // --- CATÀLEG D'ITEMS ---
  final List<String> _emojisBons = ['🍟', '🍗', '🦐', '🐟', '🍩', '🥚', '🧅', '🍤'];
  final List<String> _emojisDolents = ['🥦', '🍎', '🥕', '🍌', '🥗', '🥝', '🍇', '🥬'];

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
      final dades = await ApiService.getPescaFregitsRanking();
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
      await ApiService.postResultatPescaFregits(
          _idUsuariActual!, aliasFinal, _punts);
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
      _vides = 3;
      _fregidoraX = 0.5;
      _items = [];
      _velocitat = _kVelocitatInicial;
      _itemsCapturats = 0;
      _nivelDificultat = 0;
      _msSpawnActual = _kMsSpawnInicial;
      _aliasController.text = _aliasUsuariActual;
    });

    _timerJoc?.cancel();
    _timerSpawn?.cancel();

    _timerJoc = Timer.periodic(
        const Duration(milliseconds: _kMsPerTick), (_) => _tick());
    _reiniciarSpawnTimer();

    Future.delayed(const Duration(milliseconds: 400), _spawnItem);
  }

  void _resetJoc() {
    _timerJoc?.cancel();
    _timerSpawn?.cancel();
    setState(() {
      _jocComencat = false;
      _jocAcabat = false;
      _punts = 0;
      _vides = 3;
      _items = [];
      _fregidoraX = 0.5;
      _velocitat = _kVelocitatInicial;
      _itemsCapturats = 0;
      _nivelDificultat = 0;
      _msSpawnActual = _kMsSpawnInicial;
    });
  }

  void _reiniciarSpawnTimer() {
    _timerSpawn?.cancel();
    _timerSpawn = Timer.periodic(
        Duration(milliseconds: _msSpawnActual), (_) => _spawnItem());
  }

  void _actualitzarDificultat() {
    final nouNivel = _itemsCapturats ~/ _kCapturesPerNivell;
    if (nouNivel <= _nivelDificultat) return;

    _nivelDificultat = nouNivel;

    _velocitat = (_kVelocitatInicial + _nivelDificultat * _kIncrementVelocitat)
        .clamp(_kVelocitatInicial, _kVelocitatMaxima);

    final nouMs = (_kMsSpawnInicial - _nivelDificultat * _kMsSpawnDecrement)
        .clamp(_kMsSpawnMinim, _kMsSpawnInicial);

    if (nouMs != _msSpawnActual) {
      _msSpawnActual = nouMs;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reiniciarSpawnTimer());
    }
  }

  void _spawnItem() {
    if (!_jocComencat || _jocAcabat || !mounted) return;
    final rng = Random();
    final esBo = rng.nextDouble() < 0.62; 
    final llista = esBo ? _emojisBons : _emojisDolents;
    final emoji = llista[rng.nextInt(llista.length)];

    final x = (_kAmplItemRatio / 2 + 0.02) +
        rng.nextDouble() * (1.0 - _kAmplItemRatio - 0.04);

    setState(() {
      _items.add(ItemCaient(x: x, y: 0.0, emoji: emoji, esBo: esBo));
    });
  }

  void _tick() {
    if (!mounted || _jocAcabat || !_jocComencat) return;

    bool acabar = false;
    final ampleJoc = _ampleJocActual;
    final alcadaJoc = _alcadaJocActual;

    setState(() {
      final aEliminar = <ItemCaient>[];

      for (final item in _items) {
        if (item.processat) {
          aEliminar.add(item);
          continue;
        }

        item.y += _velocitat;

        // Calculem la posició exacta de la part INFERIOR de l'ítem
        final midaItem = ampleJoc * _kAmplItemRatio;
        final itemBottomY = item.y + (midaItem / alcadaJoc);

        // Si la base de l'ítem toca la línia de captura desapareix immediatament
        if (itemBottomY >= _kZonaFregidoraY) {
          final dist = (item.x - _fregidoraX).abs();
          final raza = _kAmplFregidoraRatio / 2 + _kAmplItemRatio / 2;
          final agafat = dist < raza;

          if (agafat && item.esBo) {
            _punts += _kPuntsCapturaBase;
            _itemsCapturats++;
            _actualitzarDificultat();
          } else if (agafat && !item.esBo) {
            _vides--;
          } else if (!agafat && item.esBo) {
            _vides--;
          }

          item.processat = true;
          aEliminar.add(item);
        }
      }

      _items.removeWhere((i) => aEliminar.contains(i));

      if (_vides <= 0) {
        _vides = 0;
        acabar = true;
      }
    });

    if (acabar) _acabarJoc();
  }

  void _acabarJoc() {
    _timerJoc?.cancel();
    _timerSpawn?.cancel();
    setState(() {
      _jocAcabat = true;
      _jocComencat = false;
      _items = [];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarDialegFiJoc());
  }

  void _moureFregidora(double dx, double areaAmple) {
    if (!_jocComencat) return;
    setState(() {
      _fregidoraX += dx / areaAmple;
      _fregidoraX = _fregidoraX.clamp(
        _kAmplFregidoraRatio / 2,
        1.0 - _kAmplFregidoraRatio / 2,
      );
    });
  }

  void _saltar(double tapX, double areaAmple) {
    if (!_jocComencat) return;
    setState(() {
      _fregidoraX = (tapX / areaAmple).clamp(
        _kAmplFregidoraRatio / 2,
        1.0 - _kAmplFregidoraRatio / 2,
      );
    });
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
          shape:
              BeveledRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Column(
            children: [
              const Text(
                '🍟 JOC ACABAT! 🍟',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 6),
              Text(
                '$_punts punts',
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
              Text(
                'Fregits capturats: $_itemsCapturats',
                style: TextStyle(color: _colorBotoInactiu, fontSize: 15),
              ),
              const SizedBox(height: 14),
              const Text(
                'Guardar rècord com a:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 110, 110, 110)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _aliasController,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _colorFustaFosca,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: _colorFustaFosca, thickness: 2),
              const SizedBox(height: 10),
              _buildMiniRanking(),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                      ),
                      onPressed: _guardantPuntuacio
                          ? null
                          : () {
                              final alias =
                                  _aliasController.text.trim().isEmpty
                                      ? _aliasUsuariActual
                                      : _aliasController.text.trim();
                              _enviarPuntuacioAPI(alias);
                            },
                      icon: _guardantPuntuacio
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(_guardantPuntuacio
                          ? 'GUARDANT...'
                          : 'GUARDAR'),
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
  // BUILD PRINCIPAL (Amb el control de Pantalla Completa)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    // Si el joc està actiu, amaguem l'AppBar per a la pantalla completa
    return Scaffold(
      backgroundColor: _colorFons,
      appBar: (_jocComencat)
          ? null
          : AppBar(
              backgroundColor: _colorPissarra,
              centerTitle: true,
              title: const Text(
                'PESCA FREGITS',
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
                  // Expanded fa que l'àrea de joc ocupi tota la resta de la pantalla
                  Expanded(child: _buildAreaJoc()),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMarcador(),
                    // A la pantalla d'inici li donem una alçada fixa de previsualització
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: List.generate(3, (i) {
              return Text(
                i < _vides ? '❤️' : '🖤',
                style: const TextStyle(fontSize: 22),
              );
            }),
          ),
          Container(height: 30, width: 2, color: _colorFustaFosca),
          Row(
            children: [
              Icon(Icons.star_rounded, color: _colorBotoActiu, size: 24),
              const SizedBox(width: 6),
              Text(
                '$_punts',
                style: TextStyle(
                  color: _colorFustaFosca,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAreaJoc() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
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
            // Guardem les mides actuals per la lògica de col·lisions (_tick)
            _ampleJocActual = constraints.maxWidth;
            _alcadaJocActual = constraints.maxHeight;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (d) =>
                  _moureFregidora(d.delta.dx, _ampleJocActual),
              onTapDown: (d) => _saltar(d.localPosition.dx, _ampleJocActual),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF1A1A2E),
                              Color(0xFF16213E),
                              Color(0xFF0F3460),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: _alcadaJocActual * _kZonaFregidoraY,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1.5,
                        color: Colors.white12,
                      ),
                    ),

                    Positioned(
                      top: _alcadaJocActual * _kZonaFregidoraY,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x00F57C00),
                              Color(0x44F57C00),
                            ],
                          ),
                        ),
                      ),
                    ),

                    ..._items.map((item) => _buildItem(item, _ampleJocActual, _alcadaJocActual)),

                    _buildFregidora(_ampleJocActual, _alcadaJocActual),

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

  Widget _buildItem(ItemCaient item, double ampleJoc, double alcadaJoc) {
    final mida = ampleJoc * _kAmplItemRatio;
    final left = item.x * ampleJoc - mida / 2;
    final top = item.y * alcadaJoc;

    final colorBorde =
        item.esBo ? Colors.orange.withOpacity(0.7) : Colors.green.withOpacity(0.7);
    final colorFonsItem =
        item.esBo ? Colors.orange.withOpacity(0.15) : Colors.green.withOpacity(0.1);

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: mida,
        height: mida,
        decoration: BoxDecoration(
          color: colorFonsItem,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorBorde, width: 1.5),
        ),
        child: Center(
          child: Text(
            item.emoji,
            style: TextStyle(fontSize: mida * 0.60),
          ),
        ),
      ),
    );
  }

  Widget _buildFregidora(double ampleJoc, double alcadaJoc) {
    final amplePx = ampleJoc * _kAmplFregidoraRatio;
    final left = _fregidoraX * ampleJoc - amplePx / 2;

    return Positioned(
      left: left,
      top: alcadaJoc * _kZonaFregidoraY, // Ara s'alinea per la part superior amb la línia de captura
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNansa(amplePx * 0.22),
              SizedBox(width: amplePx * 0.56),
              _buildNansa(amplePx * 0.22),
            ],
          ),
          Container(
            width: amplePx,
            height: amplePx * 0.55,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFB300), Color(0xFFE65100)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              border: Border.all(color: const Color(0xFF4E342E), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                ..._buildReixetaFregidora(amplePx),
                Center(
                  child: Text(
                    '🧺',
                    style: TextStyle(fontSize: amplePx * 0.32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNansa(double ample) {
    return Container(
      width: ample,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  List<Widget> _buildReixetaFregidora(double amplePx) {
    return List.generate(3, (i) {
      return Positioned(
        left: amplePx * 0.25 * (i + 1) - 1,
        top: 4,
        bottom: 4,
        child: Container(
          width: 1,
          color: Colors.black26,
        ),
      );
    });
  }

  Widget _buildOverlayInici() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🍟 PESCA FREGITS 🍟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: const [
                      _ReglaItem(
                          emoji: '🍗',
                          text: 'Agafa els fregits taronges',
                          bo: true),
                      SizedBox(height: 8),
                      _ReglaItem(
                          emoji: '🥦',
                          text: 'Evita les verdures verdes',
                          bo: false),
                      SizedBox(height: 8),
                      _ReglaItem(
                          emoji: '👆',
                          text: 'Toca o arrossega per moure la fregidora',
                          bo: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: _iniciarJoc,
                  child: const Text(
                    '🎮  INICIAR JOC',
                    style: TextStyle(
                      color: Colors.black,
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

  Widget _buildMiniRanking() {
    if (_carregantRanking) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_ranking.isEmpty) {
      return Text(
        'Sigues el primer en entrar al rànking!',
        style: TextStyle(color: _colorBotoInactiu),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '🏆 TOP PESCADORS',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: _colorFustaFosca, fontSize: 14),
        ),
        const SizedBox(height: 6),
        ..._ranking.take(5).toList().asMap().entries.map((e) {
          final idx = e.key + 1;
          final data = e.value;
          final medalles = idx == 1
              ? '🥇'
              : idx == 2
                  ? '🥈'
                  : idx == 3
                      ? '🥉'
                      : '$idx.';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$medalles ${data['alias']}',
                    style: const TextStyle(fontSize: 14)),
                Text('${data['puntuacio']} pts',
                    style: TextStyle(
                        color: _colorBotoActiu,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          );
        }).toList(),
      ],
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
            '🏆 TOP PESCADORS DE FREGITS',
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
              final medalles = idx == 1
                  ? '🥇'
                  : idx == 2
                      ? '🥈'
                      : idx == 3
                          ? '🥉'
                          : '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$medalles $idx. ${data['alias']}',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontFamily: 'monospace'),
                    ),
                    Text(
                      "${data['puntuacio']} pts",
                      style: const TextStyle(
                          color: Colors.yellowAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
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

// ===========================================================================
// WIDGET AUXILIAR
// ===========================================================================
class _ReglaItem extends StatelessWidget {
  final String emoji;
  final String text;
  final bool bo;

  const _ReglaItem({
    required this.emoji,
    required this.text,
    required this.bo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bo
                ? Colors.orange.withOpacity(0.2)
                : Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: bo
                  ? Colors.orange.withOpacity(0.8)
                  : Colors.green.withOpacity(0.8),
            ),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }
}