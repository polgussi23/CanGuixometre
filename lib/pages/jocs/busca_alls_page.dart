import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

class BuscaAllsPage extends StatefulWidget {
  const BuscaAllsPage({super.key});

  @override
  State<BuscaAllsPage> createState() => _BuscaAllsPageState();
}

class _BuscaAllsPageState extends State<BuscaAllsPage> {
  // --- RUTES D'IMATGES ---
  String casellaTapada = 'assets/images/jocs/buscaAlls/casellaTapada.png';
  String casellaDestapada = 'assets/images/jocs/buscaAlls/casellaDestapada.png';
  String imatgeAll = 'assets/images/jocs/buscaAlls/all.png';
  String imatgeMorter = 'assets/images/jocs/buscaAlls/recipient_allioli.png';

  // --- VARIABLES D'ESTAT ---
  bool _jocComencat = false;
  bool _modeMorter = false;
  final int _totalBombes = 10;
  int _nMortersPosats = 0;
  List<Casella> _tauler = [];
  Timer? _timer;
  int _segons = 0;

  // --- COLORS RÚSTICS ---
  final Color _colorFons = const Color(0xFFD7CCC8); // Color estovalles
  final Color _colorPissarra = const Color(0xFF263238); // Gris pissarra fosc
  final Color _colorFustaFosca = const Color(0xFF5D4037); // Marc tauler
  final Color _colorBotoActiu = const Color(0xFFFFB300);
  final Color _colorBotoInactiu = const Color(0xFF8D6E63);

  // --- DADES FICTÍCIES PEL RÀNKING (Més endavant ho faràs real) ---
  final List<Map<String, dynamic>> _rankingExemple = [
    {'nom': 'El "Ràpid" González', 'temps': 12},
    {'nom': 'La Iaia Maria', 'temps': 15},
    {'nom': 'Pep el del Bar', 'temps': 28},
    {'nom': 'Tu (casi)', 'temps': 45},
  ];

  @override
  void initState() {
    super.initState();
    _inicialitzarTaulerBuit();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ==========================================
  // ============ LÒGICA DEL JOC ============
  // ==========================================

  void _inicialitzarTaulerBuit() {
    _tauler.clear();
    for (int i = 0; i < 64; i++) {
      int x = i % 8;
      int y = i ~/ 8;
      _tauler.add(Casella(x: x, y: y));
    }
  }

  void _resetJoc() {
    _aturarTimer();
    setState(() {
      _nMortersPosats = 0;
      _segons = 0;
      _inicialitzarTaulerBuit();
      _jocComencat = false;
      _modeMorter = false;
    });
  }

  void _iniciarTimer() {
    _segons = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _segons++;
      });
    });
  }

  void _aturarTimer() {
    _timer?.cancel();
  }

  void colocaBombes(Casella cInicial) {
    List<Casella> casellesSegures = calcularCasellesSegures(cInicial);
    List<Casella> casellesBombes = [];
    int i = 0;
    while (i < _totalBombes) {
      int indexAleatori = Random().nextInt(64);
      Casella c = _tauler[indexAleatori];
      if (!casellesSegures.contains(c) && !casellesBombes.contains(c)) {
        casellesBombes.add(c);
        c.teAll = true;
        i++;
      }
    }
  }

  List<Casella> calcularCasellesSegures(Casella cInicial) {
    List<Casella> caselles = [];
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        int x = cInicial.x + i;
        int y = cInicial.y + j;
        if (x >= 0 && x < 8 && y >= 0 && y < 8) {
          int index = y * 8 + x;
          caselles.add(_tauler[index]);
        }
      }
    }
    return caselles;
  }

  void calcularNumeros() {
    for (var casella in _tauler) {
      if (casella.teAll) continue;
      int bombesAlVoltant = 0;
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          if (i == 0 && j == 0) continue;
          int veiX = casella.x + i;
          int veiY = casella.y + j;
          if (veiX >= 0 && veiX < 8 && veiY >= 0 && veiY < 8) {
            int indexVei = veiY * 8 + veiX;
            if (_tauler[indexVei].teAll) bombesAlVoltant++;
          }
        }
      }
      casella.numero = bombesAlVoltant;
    }
  }

  void _destaparRecursiu(int x, int y) {
    if (x < 0 || x >= 8 || y < 0 || y >= 8) return;
    int index = y * 8 + x;
    Casella c = _tauler[index];
    if (c.estaDestapada || c.teAll || c.teMorter) return;
    setState(() {
      c.estaDestapada = true;
    });
    if (c.numero > 0) return;
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i != 0 || j != 0) _destaparRecursiu(x + i, y + j);
      }
    }
  }

  void _gestionarClic(Casella casellaActual) {
    if (_modeMorter) {
      if (!casellaActual.estaDestapada) {
        setState(() {
          if (!casellaActual.teMorter) {
            if (_nMortersPosats < _totalBombes) {
              casellaActual.teMorter = true;
              _nMortersPosats++;
            }
          } else {
            casellaActual.teMorter = false;
            _nMortersPosats--;
          }
        });
      }
      return;
    }

    if (casellaActual.teMorter) return;

    if (!_jocComencat) {
      colocaBombes(casellaActual);
      calcularNumeros();
      _jocComencat = true;
      _iniciarTimer();
    }

    if (casellaActual.teAll) {
      setState(() {
        casellaActual.estaDestapada = true;
        _destaparBombes();
        _aturarTimer();
      });
      _mostrarDialegFinal(false);
    } else if (casellaActual.numero > 0) {
      setState(() {
        casellaActual.estaDestapada = true;
      });
      comprovarVictoria();
    } else {
      _destaparRecursiu(casellaActual.x, casellaActual.y);
      comprovarVictoria();
    }
  }

  void _destaparBombes() {
    for (var c in _tauler) {
      if (c.teAll) c.estaDestapada = true;
    }
  }

  void comprovarVictoria() {
    int totalCasellesSegures = _tauler.where((c) => !c.teAll).length;
    int destapadesActuals =
        _tauler.where((c) => !c.teAll && c.estaDestapada).length;

    if (totalCasellesSegures == destapadesActuals) {
      _aturarTimer();
      setState(() {
        for (var c in _tauler) {
          if (c.teAll) c.teMorter = true;
        }
        _nMortersPosats = 10;
      });
      _mostrarDialegFinal(true);
    }
  }

  void _mostrarDialegFinal(bool victoria) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E1),
        shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          victoria ? "🎉 ARA SÍ! 🎉" : "💥 CAGADA PASTOR! 💥",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _colorFustaFosca,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              victoria
                  ? "Has trobat tots els alls. Ja pots fer l'allioli!"
                  : "Has trinxat un all que no tocava.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18, color: Color.fromARGB(255, 105, 105, 105)),
            ),
            const SizedBox(height: 20),
            Divider(color: _colorFustaFosca, thickness: 2),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_bottom, color: _colorFustaFosca),
                const SizedBox(width: 8),
                Text(
                  "Temps total: $_segons s",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _colorFustaFosca),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colorPissarra,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _resetJoc();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("TORNAR-HI",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ==========================================
  // ============ INTERFÍCIE (UI) ============
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorFons,
      appBar: AppBar(
        backgroundColor: _colorPissarra,
        centerTitle: true,
        title: const Text(
          "BUSCA ALLS",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Colors.white,
            fontFamily: 'RobotoCondensed',
            letterSpacing: 1.5,
          ),
        ),
      ),
      // --- IMPORTANT: SingleChildScrollView per permetre scroll ---
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 1. MARCADOR
              _buildMarcadorRustic(),

              // 2. TAULER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _colorFustaFosca,
                      border:
                          Border.all(color: const Color(0xFF3E2723), width: 4),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 5,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: _buildGridView(),
                  ),
                ),
              ),

              // 3. BOTONERA
              const SizedBox(height: 15),
              _buildBotoneraInferior(),

              // 4. EL RÀNKING (NOU)
              const SizedBox(height: 25),
              _buildRankingRustic(),
              const SizedBox(height: 30), // Marge final
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET RÀNKING NOU ---
  Widget _buildRankingRustic() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _colorPissarra, // Pissarra negra
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _colorFustaFosca, width: 6), // Marc de fusta
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(3, 3),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            "TOP CAÇADORS D'ALLS",
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Chalkboard', // Si no existeix fa fallback
              fontWeight: FontWeight.bold,
              fontSize: 20,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          // Llista de jugadors
          ..._rankingExemple.asMap().entries.map((entry) {
            int idx = entry.key + 1;
            var data = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$idx. ${data['nom']}",
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontFamily: 'monospace'),
                  ),
                  Text(
                    "${data['temps']}s",
                    style: const TextStyle(
                        color: Colors.yellowAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 10),
          const Text(
            "(Avui)",
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMarcadorRustic() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: _colorFustaFosca, width: 2),
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(2, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              Image.asset(imatgeMorter, height: 32),
              const SizedBox(width: 10),
              Text(
                '${_totalBombes - _nMortersPosats}',
                style: TextStyle(
                  color: _colorFustaFosca,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          Container(height: 30, width: 2, color: _colorFustaFosca),
          Row(
            children: [
              Icon(Icons.hourglass_empty, color: _colorFustaFosca, size: 30),
              const SizedBox(width: 10),
              Text(
                '$_segons',
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

  Widget _buildGridView() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 64,
      itemBuilder: (context, index) {
        Casella casella = _tauler[index];
        return GestureDetector(
          onTap: () => _gestionarClic(casella),
          child: _construirContingutVisual(casella),
        );
      },
    );
  }

  Widget _buildBotoneraInferior() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Expanded(
            child: _buildBotoRustic(
              actiu: !_modeMorter,
              icona: Icons.back_hand,
              text: "COLLIR",
              onTap: () => setState(() => _modeMorter = false),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildBotoRustic(
              actiu: _modeMorter,
              imatgePersonalitzada: imatgeMorter,
              text: "POSAR MORTER",
              onTap: () => setState(() => _modeMorter = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotoRustic({
    required bool actiu,
    IconData? icona,
    String? imatgePersonalitzada,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: actiu ? _colorBotoActiu : _colorBotoInactiu,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color:
                actiu ? Colors.yellowAccent.withOpacity(0.5) : Colors.black38,
            width: actiu ? 3 : 2,
          ),
          boxShadow: actiu
              ? [
                  BoxShadow(
                      color: _colorBotoActiu.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1)
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imatgePersonalitzada != null)
              Image.asset(imatgePersonalitzada,
                  height: 30, color: actiu ? Colors.black : Colors.black54)
            else
              Icon(icona,
                  size: 30, color: actiu ? Colors.black : Colors.black54),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: actiu ? Colors.black : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirContingutVisual(Casella c) {
    if (!c.estaDestapada) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(casellaTapada, fit: BoxFit.cover),
          if (c.teMorter)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.asset(imatgeMorter),
            ),
        ],
      );
    }

    if (c.teAll) {
      return Container(
        color: Colors.red[300],
        padding: const EdgeInsets.all(4.0),
        child: Image.asset(imatgeAll),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(casellaDestapada, fit: BoxFit.cover),
        Center(
          child: Text(
            c.numero > 0 ? '${c.numero}' : '',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: _getColorNumero(c.numero),
              shadows: const [
                Shadow(
                    offset: Offset(1.5, 1.5),
                    color: Colors.black45,
                    blurRadius: 0)
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorNumero(int n) {
    switch (n) {
      case 1:
        return Colors.blue[900]!;
      case 2:
        return Colors.green[800]!;
      case 3:
        return Colors.red[900]!;
      case 4:
        return Colors.purple[900]!;
      case 5:
        return Colors.brown[800]!;
      case 6:
        return Colors.teal[800]!;
      case 7:
        return Colors.black;
      case 8:
        return Colors.grey[800]!;
      default:
        return Colors.black;
    }
  }
}

class Casella {
  final int x;
  final int y;
  bool estaDestapada;
  bool teAll;
  int numero;
  bool teMorter;

  Casella({
    required this.x,
    required this.y,
    this.estaDestapada = false,
    this.teAll = false,
    this.numero = 0,
    this.teMorter = false,
  });
}
