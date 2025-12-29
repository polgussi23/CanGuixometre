import 'package:can_guix/pages/pack_opening_page.dart';
import 'package:flutter/material.dart';
// Importa el teu ApiService i el model Carta
import 'package:can_guix/services/api_service.dart';
import 'package:can_guix/models/carta.dart';
// Importa CachedNetworkImage per a les imatges
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:can_guix/services/user_provider.dart';

class CollectionPage extends StatefulWidget {
  @override
  _CollectionPageState createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  // --- APLIQUEM EL PATRÓ DE 'EditUserPage' ---
  bool _isLoading = true;
  String _errorMessage = '';

  // Les dades ja no són un 'Future', sinó llistes normals
  List<Carta> _cartes = [];
  int _sobresDisponibles = 0;

  late String _userIdString;
  // ------------------------------------------

  @override
  void initState() {
    super.initState();
    // Cridem la funció asíncrona que ho carregarà tot,
    // passant-li el provider.
    _inicialitzarDades(Provider.of<UserProvider>(context, listen: false));
  }

  /// Aquesta funció fa el mateix que la teva '_loadUserProfile'
  /// 1. Espera que el provider tingui les dades.
  /// 2. Agafa l'ID.
  /// 3. Crida les APIs.
  /// 4. Actualitza l'estat i treu el 'loading'.
  Future<void> _inicialitzarDades(UserProvider userProvider) async {
    try {
      // 1. ESPEREM QUE EL PROVIDER ES CARREGUI
      // (Això és el que fa la teva EditUserPage amb 'await userProvider.getUserInfo()')
      // Si 'getUserInfo' és la funció que carrega, l'hem de cridar.
      // Si el teu provider carrega automàticament, aquesta línia pot no ser necessària,
      // però la posem per seguir el patró de EditUserPage.
      await userProvider.getUserInfo();

      // 2. Obtenim l'ID (ara ja no hauria de ser nul)
      final int? userId = userProvider.id;

      if (userId == null) {
        throw Exception('Usuari no autenticat.');
      }

      _userIdString = userId.toString();

      // 3. Cridem les APIs
      // Fem les dues crides alhora per més velocitat
      final [cartesResult, sobresResult] = await Future.wait([
        ApiService.getEstatColleccio(_userIdString),
        ApiService.getSobresUsuari(_userIdString),
      ]);

      // 4. Processem els resultats
      final List<Carta> cartes =
          (cartesResult as List).map((json) => Carta.fromJson(json)).toList();

      final int sobres =
          (sobresResult as Map<String, dynamic>)['quantitat'] ?? 0;

      // 5. Actualitzem l'estat i marquem com a carregat
      setState(() {
        _isLoading = false;
        _cartes = cartes;
        _sobresDisponibles = sobres;
      });
    } catch (e) {
      // Si alguna cosa falla, ho guardem per mostrar l'error
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Color _getColorForRaresa(String raresaNom) {
    switch (raresaNom) {
      case 'COMÚ':
        return Colors.blue;
      case 'INUSUAL':
        return Colors.green;
      case 'RARO':
        return Colors.red;
      case 'LLEGENDARI':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  // --- EL MÈTODE 'build' S'HA DE MODIFICAR ---
  // Ja no fem servir un FutureBuilder, sinó el booleà '_isLoading'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          //title: Text('La meva Col·lecció'),
          ),
      body: _buildBody(), // Hem mogut el cos a una funció pròpia

      // El FloatingActionButton ara llegeix la variable local
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sobresDisponibles > 0 ? _anarAObrirSobre : null,
        icon: Icon(Icons.mail_outline),
        label: Text('Obrir Sobre ($_sobresDisponibles)'),
        backgroundColor: _sobresDisponibles > 0 ? Colors.blue : Colors.grey,
      ),
    );
  }

  /// Construeix el cos de la pàgina segons l'estat de càrrega
  Widget _buildBody() {
    if (_isLoading) {
      // 1. ESTAT DE CÀRREGA
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      // 2. ESTAT D'ERROR
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $_errorMessage'),
        ),
      );
    }

    if (_cartes.isEmpty) {
      // 3. ESTAT BUID (L'API no ha tornat cartes)
      return Center(child: Text('No s\'han trobat cartes.'));
    }

    // 4. ESTAT CORRECTE (Dades carregades)

    // Calculem el comptador
    int cartesPossuides = _cartes.where((c) => c.isOwned).length;

    // Filtrem les llistes
    final List<Carta> llegendaris =
        _cartes.where((c) => c.raresaNom == 'Llegendari').toList();
    final List<Carta> rares =
        _cartes.where((c) => c.raresaNom == 'Raro').toList();
    final List<Carta> inusuals =
        _cartes.where((c) => c.raresaNom == 'Inusual').toList();
    final List<Carta> comuns =
        _cartes.where((c) => c.raresaNom == 'Comú').toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- TÍTOL/COMPTADOR RESTAURAT ---
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 0), // Ajustem padding
            child: Center(
              // El centrem
              child: Text(
                'COMPLETAT: $cartesPossuides / ${_cartes.length}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // O el color que prefereixis
                    ),
              ),
            ),
          ),
          // --- FI DEL TÍTOL ---

          _buildSeccioRaresa('COMÚ', comuns),
          _buildSeccioRaresa('INUSUAL', inusuals),
          _buildSeccioRaresa('RARO', rares),
          _buildSeccioRaresa('LLEGENDARI', llegendaris),
          SizedBox(height: 80),
        ],
      ),
    );
  }

  /// Construeix una secció amb un títol i una graella de cartes.
  Widget _buildSeccioRaresa(String raresaNom, List<Carta> llistaCartes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Títol de la secció
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            raresaNom.toUpperCase(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getColorForRaresa(
                      raresaNom), // <-- APLIQUEM EL COLOR AQUÍ
                ),
          ),
        ),

        // Graella de cartes per a aquesta secció
        GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.7,
          ),
          itemCount: llistaCartes.length,
          itemBuilder: (context, index) {
            final carta = llistaCartes[index];
            return _buildCartaWidget(carta);
          },
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
        ),
      ],
    );
  }

  Widget _buildCartaWidget(Carta carta) {
    return GestureDetector(
      onTap: () {
        // Quan fem clic:
        // 1. Mostrem el diàleg
        _mostrarDetallCarta(context, carta);

        // 2. Si era nova, la marquem com a vista
        if (carta.esNova) {
          _marcarCartaComVista(carta);
        }
      },
      child: Card(
        // Li traiem el color per defecte per a la silueta
        color: carta.isOwned ? Theme.of(context).cardColor : Colors.transparent,
        elevation: carta.isOwned ? 2 : 0, // Sense ombra per a les siluetes
        child: Stack(
          children: [
            if (carta.isOwned)
              // Si la tenim, mostrem la imatge
              Center(
                child: CachedNetworkImage(
                  imageUrl: carta.urlImatge,
                  fit: BoxFit.cover,
                ),
              )
            else
              // Si NO la tenim, mostrem la silueta
              Center(
                child: Image.asset(
                  'assets/images/silueta_carta.png',
                  fit: BoxFit.cover,
                ),
              ),
            if (carta.esNova)
              // L'etiqueta "NOVA!"
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('NOVA',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            if (carta.quantitat > 1)
              // El comptador de duplicats
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Text('x${carta.quantitat}',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Mostra un diàleg amb la informació de la carta
  void _mostrarDetallCarta(BuildContext context, Carta carta) {
    showDialog(
      context: context,
      // Permet tancar el diàleg tocant fora
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        // --- CANVIS PER MOSTRAR NOMÉS LA IMATGE ---

        // Fons transparent perquè només es vegi la imatge
        backgroundColor: Colors.transparent,
        elevation: 0, // Sense ombra

        // Treiem tot el padding intern de l'AlertDialog
        contentPadding: const EdgeInsets.all(0),

        content: GestureDetector(
          // Permet tancar el diàleg tocant la pròpia imatge
          onTap: () => Navigator.of(ctx).pop(),
          child: Container(
            // Calculem la mida de la carta en gran
            // (ex: 80% de l'ample de la pantalla)
            width: MediaQuery.of(context).size.width * 0.8,
            // Mantenim l'aspect ratio (0.7)
            height: (MediaQuery.of(context).size.width * 0.8) / 0.7,

            child: carta.isOwned
                ? CachedNetworkImage(
                    imageUrl: carta.urlImatge,
                    fit: BoxFit.contain, // 'Contain' per veure-la sencera
                  )
                : Image.asset(
                    'assets/images/silueta_carta.png',
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ),
    );
  }

  /// Actualitza l'estat local i crida l'API
  void _marcarCartaComVista(Carta carta) {
    // 1. Actualització Optimista de la UI
    // (Actualitzem l'estat local a l'instant, no esperem l'API)
    setState(() {
      final index = _cartes.indexWhere((c) => c.id == carta.id);
      if (index != -1) {
        // Creem una nova instància de la carta amb 'esNova = false'
        // És important crear una nova instància per a la gestió d'estat
        _cartes[index] = Carta(
          id: carta.id,
          titol: carta.titol,
          descripcio: carta.descripcio,
          urlImatge: carta.urlImatge,
          raresaNom: carta.raresaNom,
          puntsValor: carta.puntsValor,
          isOwned: carta.isOwned,
          quantitat: carta.quantitat,
          esNova: false, // <-- L'ÚNIC CANVI
        );
      }
    });

    // 2. Cridem a l'API en segon pla (Fire-and-forget)
    // No cal 'await' perquè l'usuari no ha d'esperar
    ApiService.marcarCartesVistes(_userIdString, [carta.id]).catchError((e) {
      // Si falla, podríem (opcionalment) tornar a posar l'etiqueta "NOVA"
      // o simplement imprimir un error a la consola.
      print("Error al marcar la carta com a vista: $e");
    });
  }

  void _anarAObrirSobre() {
    // Naveguem a la nova pantalla
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PackOpeningPage()),
    ).then((_) {
      // --- MOLT IMPORTANT ---
      // Aquesta funció s'executa quan tornem de PackOpeningPage.
      // Recarreguem les dades per veure les cartes noves!

      // Reiniciem l'estat per mostrar el 'loading'
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      // Cridem la funció que ho carrega tot de nou
      _inicialitzarDades(Provider.of<UserProvider>(context, listen: false));
    });
  }
}
