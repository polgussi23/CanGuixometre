class Carta {
  final int id;
  final String titol;
  final String descripcio;
  final String urlImatge;
  final String raresaNom;
  final int puntsValor; // <-- CAMP NOU QUE FALTAVA
  final bool isOwned;
  final int quantitat;
  final bool esNova;

  Carta({
    required this.id,
    required this.titol,
    required this.descripcio,
    required this.urlImatge,
    required this.raresaNom,
    required this.puntsValor, // <-- CAMP NOU QUE FALTAVA
    required this.isOwned,
    required this.quantitat,
    required this.esNova,
  });

  // Factory per crear una Carta des del JSON de l'API
  factory Carta.fromJson(Map<String, dynamic> json) {
    return Carta(
      // --- CORRECCIÓ ---
      // Fem servir int.parse() i .toString() per assegurar-nos
      // que convertim el valor a 'int', tant si arriba
      // com a 123 (número) o com a "123" (text).

      id: int.parse(json['carta_id'].toString()),
      titol: json['titol'],
      descripcio: json['descripcio'] ?? '',
      urlImatge: json['url_imatge'],
      raresaNom: json['raresa_nom'],
      puntsValor:
          int.parse(json['punts_valor'].toString()), // <-- CAMP NOU QUE FALTAVA

      // Per als booleans, comparem el text '1'
      isOwned: json['is_owned'].toString() == '1',
      quantitat: int.parse(json['quantitat'].toString()),
      esNova: json['es_nova'].toString() == '1',
    );
  }

  factory Carta.fromApi(Map<String, dynamic> json) {
    return Carta(
      id: int.parse(json['carta_id'].toString()),
      titol: json['titol'],
      descripcio: json['descripcio'] ?? '',
      urlImatge: json['url_imatge'],
      raresaNom: json['raresa_nom'],
      puntsValor: int.parse(json['punts_valor'].toString()),

      // Com que aquesta API només es crida quan acabem de guanyar
      // les cartes, podem omplir aquests valors per defecte:
      isOwned: true,
      quantitat: 1,
      esNova: true,
    );
  }
}
