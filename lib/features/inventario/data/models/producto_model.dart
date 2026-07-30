class ProductoModel {
  final String id;
  final String grupo; // Ej: "componentes_internos" o "componentes_externos"
  final String categoria; // Ej: "procesador_cpu", "tarjeta_madre", "monitor"

  // Aquí mapeamos la jerarquía exacta que diseñaste
  final Map<String, dynamic> atributosAdministrativos;
  final Map<String, dynamic> especificacionesTecnicas;

  ProductoModel({
    required this.id,
    required this.grupo,
    required this.categoria,
    required this.atributosAdministrativos,
    required this.especificacionesTecnicas,
  });

  /// Transforma este modelo a un Mapa listo para subirse a Cloud Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grupo': grupo,
      'categoria': categoria,
      'atributosAdministrativos': atributosAdministrativos,
      'atributos_administrativos': atributosAdministrativos,
      'especificacionesTecnicas': especificacionesTecnicas,
      'especificaciones_tecnicas': especificacionesTecnicas,
    };
  }

  /// Recibe un mapa de Firestore y lo transforma en un objeto usable por Flutter
  factory ProductoModel.fromMap(Map<String, dynamic> map, String documentId) {
    final Map<String, dynamic> adminMap = Map<String, dynamic>.from(
      map['atributosAdministrativos'] ?? map['atributos_administrativos'] ?? {},
    );
    final Map<String, dynamic> specsMap = Map<String, dynamic>.from(
      map['especificacionesTecnicas'] ?? map['especificaciones_tecnicas'] ?? {},
    );

    return ProductoModel(
      id: documentId,
      grupo: map['grupo'] ?? '',
      categoria: map['categoria'] ?? '',
      atributosAdministrativos: adminMap,
      especificacionesTecnicas: specsMap,
    );
  }
}
