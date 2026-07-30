import 'package:cloud_firestore/cloud_firestore.dart';

class AuditoriaService {
  static final CollectionReference _inventarioRef =
      FirebaseFirestore.instance.collection('inventario');

  // Memoria caché local para respaldo inmediato
  static final List<Map<String, dynamic>> _registrosLocales = [];

  static List<Map<String, dynamic>> get registrosLocales => List.unmodifiable(_registrosLocales);

  /// Registra una nueva acción en la bitácora de auditoría dentro de la colección 'inventario'
  static Future<void> registrarAccion({
    required String tipoAccion, // 'CREACIÓN', 'ELIMINACIÓN', 'EDICIÓN', 'VENTA'
    required String componenteId,
    required String componenteNombre,
    required String categoria,
    String? detalles,
  }) async {
    final ahora = DateTime.now();
    final fechaHoraFormat =
        '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')} ${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}:${ahora.second.toString().padLeft(2, '0')}';

    final registroMap = {
      'grupo': 'auditoria_movimientos',
      'tipo_accion': tipoAccion,
      'componente_id': componenteId,
      'componente_nombre': componenteNombre,
      'categoria': categoria,
      'fecha_hora': fechaHoraFormat,
      'detalles': detalles ?? 'Acción realizada en el sistema',
      'atributosAdministrativos': {
        'tipo_accion': tipoAccion,
        'componente_id': componenteId,
        'componente_nombre': componenteNombre,
        'categoria': categoria,
        'fecha_hora': fechaHoraFormat,
        'detalles': detalles ?? 'Acción realizada en el sistema',
      },
    };

    // Guardar en memoria local inmediatamente
    _registrosLocales.insert(0, registroMap);

    try {
      await _inventarioRef.add(registroMap);
    } catch (e) {
      // Si ocurre error en red, permanece en la memoria local
    }
  }

  /// Retorna un Stream con la colección 'inventario' permitida por la base de datos
  static Stream<QuerySnapshot> obtenerHistorialStream() {
    return _inventarioRef.snapshots();
  }
}
