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
      'atributos_administrativos': atributosAdministrativos,
      'especificaciones_tecnicas': especificacionesTecnicas,
    };
  }

  /// Recibe un mapa de Firestore y lo transforma en un objeto usable por Flutter
  factory ProductoModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductoModel(
      id: documentId,
      grupo: map['grupo'] ?? '',
      categoria: map['categoria'] ?? '',
      // El operador Cast asegura que los mapas mantengan el tipado correcto
      atributosAdministrativos: Map<String, dynamic>.from(
        map['atributos_administrativos'] ?? {},
      ),
      especificacionesTecnicas: Map<String, dynamic>.from(
        map['especificaciones_tecnicas'] ?? {},
      ),
    );
  }
}
