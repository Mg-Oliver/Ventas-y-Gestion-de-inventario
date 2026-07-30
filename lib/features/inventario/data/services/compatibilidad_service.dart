import '../models/producto_model.dart';

class ResultadoCompatibilidad {
  final bool esCompatible;
  final String motivo;

  ResultadoCompatibilidad({
    required this.esCompatible,
    this.motivo = 'Compatible',
  });
}

class MetricasEnsamble {
  final double costoTotal;
  final double precioVentaSugerido;
  final double gananciaNetaEstimada;
  final int consumoWattsEstimado;
  final int potenciaPsuDisponible;
  final bool potenciaSuficiente;
  final List<String> advertencias;

  MetricasEnsamble({
    required this.costoTotal,
    required this.precioVentaSugerido,
    required this.gananciaNetaEstimada,
    required this.consumoWattsEstimado,
    required this.potenciaPsuDisponible,
    required this.potenciaSuficiente,
    required this.advertencias,
  });
}

class CompatibilidadService {
  /// Evalúa la compatibilidad individual entre dos componentes [p1] y [p2].
  static ResultadoCompatibilidad evaluarCompatibilidad(ProductoModel p1, ProductoModel p2) {
    if (p1.id == p2.id) {
      return ResultadoCompatibilidad(esCompatible: false, motivo: 'Es el mismo componente');
    }

    final cat1 = _normalizarCategoria(p1);
    final cat2 = _normalizarCategoria(p2);

    // 1. CPU vs Tarjeta Madre
    if ((cat1 == 'procesador_cpu' && cat2 == 'tarjeta_madre') ||
        (cat1 == 'tarjeta_madre' && cat2 == 'procesador_cpu')) {
      final cpu = cat1 == 'procesador_cpu' ? p1 : p2;
      final mobo = cat1 == 'tarjeta_madre' ? p1 : p2;

      final socketCpu = _obtenerAttr(cpu, ['socket', 'sockets_compatibles', 'socket_compatible']).toUpperCase();
      final socketMobo = _obtenerAttr(mobo, ['socket', 'sockets_compatibles']).toUpperCase();

      if (socketCpu.isNotEmpty && socketMobo.isNotEmpty) {
        if (!_socketCoincide(socketCpu, socketMobo)) {
          return ResultadoCompatibilidad(
            esCompatible: false,
            motivo: 'Socket incompatible: CPU ($socketCpu) vs Tarjeta Madre ($socketMobo)',
          );
        }
      }
    }

    // 2. Memoria RAM vs Tarjeta Madre
    if ((cat1 == 'memoria_ram' && cat2 == 'tarjeta_madre') ||
        (cat1 == 'tarjeta_madre' && cat2 == 'memoria_ram')) {
      final ram = cat1 == 'memoria_ram' ? p1 : p2;
      final mobo = cat1 == 'tarjeta_madre' ? p1 : p2;

      final tipoRam = _obtenerAttr(ram, ['tipo_memoria', 'tipo']).toUpperCase();
      final tipoMobo = _obtenerAttr(mobo, ['tipo_memoria_soportada', 'tipo_memoria']).toUpperCase();

      if (tipoRam.isNotEmpty && tipoMobo.isNotEmpty) {
        if (!tipoMobo.contains(tipoRam) && !tipoRam.contains(tipoMobo)) {
          return ResultadoCompatibilidad(
            esCompatible: false,
            motivo: 'Tipo de Memoria incompatible: RAM ($tipoRam) vs Tarjeta Madre ($tipoMobo)',
          );
        }
      }
    }

    // 3. Disipador CPU vs CPU / Tarjeta Madre
    if ((cat1 == 'disipador_cpu' && (cat2 == 'procesador_cpu' || cat2 == 'tarjeta_madre')) ||
        ((cat1 == 'procesador_cpu' || cat1 == 'tarjeta_madre') && cat2 == 'disipador_cpu')) {
      final cooler = cat1 == 'disipador_cpu' ? p1 : p2;
      final baseComp = cat1 == 'disipador_cpu' ? p2 : p1;

      final socketCooler = _obtenerAttr(cooler, ['sockets_compatibles', 'socket']).toUpperCase();
      final socketBase = _obtenerAttr(baseComp, ['socket', 'sockets_compatibles']).toUpperCase();

      if (socketCooler.isNotEmpty && socketBase.isNotEmpty && !socketCooler.contains('UNIVERSAL')) {
        if (!_socketCoincide(socketCooler, socketBase)) {
          return ResultadoCompatibilidad(
            esCompatible: false,
            motivo: 'Socket de Disipador incompatible ($socketCooler vs $socketBase)',
          );
        }
      }
    }

    // 4. Tarjeta Gráfica vs Gabinete (Longitud física)
    if ((cat1 == 'tarjeta_grafica' && cat2 == 'gabinete_chasis') ||
        (cat1 == 'gabinete_chasis' && cat2 == 'tarjeta_grafica')) {
      final gpu = cat1 == 'tarjeta_grafica' ? p1 : p2;
      final gabinete = cat1 == 'gabinete_chasis' ? p1 : p2;

      final int longGpu = _obtenerInt(gpu, ['longitud_gpu_mm', 'longitud_mm']);
      final int maxGpuGabinete = _obtenerInt(gabinete, ['longitud_max_gpu_mm']);

      if (longGpu > 0 && maxGpuGabinete > 0 && longGpu > maxGpuGabinete) {
        return ResultadoCompatibilidad(
          esCompatible: false,
          motivo: 'La GPU es demasiado larga ($longGpu mm) para el Gabinete (máx $maxGpuGabinete mm)',
        );
      }
    }

    // 5. Disipador CPU vs Gabinete (Altura física)
    if ((cat1 == 'disipador_cpu' && cat2 == 'gabinete_chasis') ||
        (cat1 == 'gabinete_chasis' && cat2 == 'disipador_cpu')) {
      final cooler = cat1 == 'disipador_cpu' ? p1 : p2;
      final gabinete = cat1 == 'gabinete_chasis' ? p1 : p2;

      final int altCooler = _obtenerInt(cooler, ['altura_total_bloque_mm', 'altura_mm']);
      final int maxAltGabinete = _obtenerInt(gabinete, ['altura_max_disipador_mm']);

      if (altCooler > 0 && maxAltGabinete > 0 && altCooler > maxAltGabinete) {
        return ResultadoCompatibilidad(
          esCompatible: false,
          motivo: 'El disipador es muy alto ($altCooler mm) para el Gabinete (máx $maxAltGabinete mm)',
        );
      }
    }

    // 6. Tarjeta Madre vs Gabinete (Factor de forma)
    if ((cat1 == 'tarjeta_madre' && cat2 == 'gabinete_chasis') ||
        (cat1 == 'gabinete_chasis' && cat2 == 'tarjeta_madre')) {
      final mobo = cat1 == 'tarjeta_madre' ? p1 : p2;
      final gabinete = cat1 == 'gabinete_chasis' ? p1 : p2;

      final factorMobo = _obtenerAttr(mobo, ['factor_forma']).toUpperCase();
      final formatosGab = _obtenerAttr(gabinete, ['formatos_placa_soportados']).toUpperCase();

      if (factorMobo.isNotEmpty && formatosGab.isNotEmpty) {
        if (!formatosGab.contains(factorMobo)) {
          return ResultadoCompatibilidad(
            esCompatible: false,
            motivo: 'El gabinete no soporta tarjetas madre formato $factorMobo',
          );
        }
      }
    }

    return ResultadoCompatibilidad(esCompatible: true, motivo: 'Compatible');
  }

  /// Verifica si un componente candidato es compatible con todos los seleccionados en el ensamble.
  static ResultadoCompatibilidad esCompatibleConEnsamble(
    ProductoModel candidato,
    Map<String, ProductoModel> ensambleActual,
  ) {
    for (final entry in ensambleActual.entries) {
      final seleccionado = entry.value;
      final res = evaluarCompatibilidad(candidato, seleccionado);
      if (!res.esCompatible) {
        return res;
      }
    }
    return ResultadoCompatibilidad(esCompatible: true, motivo: 'Compatible con el ensamble actual');
  }

  /// Retorna todos los componentes en el inventario que son compatibles con un producto dado.
  static List<ProductoModel> obtenerCompatiblesEnInventario(
    ProductoModel producto,
    List<ProductoModel> inventarioCompleto,
  ) {
    return inventarioCompleto.where((item) {
      final estado = (item.atributosAdministrativos['estado_componente'] ?? '').toString().toLowerCase();
      if (item.grupo.toLowerCase() == 'eliminado' ||
          item.categoria.toLowerCase() == 'eliminado' ||
          estado == 'eliminado' ||
          estado == 'vendido') {
        return false;
      }
      return evaluarCompatibilidad(producto, item).esCompatible;
    }).toList();
  }

  /// Calcula costos, vatios y métricas del ensamble actual.
  static MetricasEnsamble calcularMetricasEnsamble(Map<String, ProductoModel> ensambleActual) {
    double costoTotal = 0.0;
    double precioVentaSugerido = 0.0;
    int consumoWatts = 100; // Margen base de consumo (Mobo, Fans, SSDs)
    int potenciaPsu = 0;
    List<String> advertencias = [];

    ensambleActual.forEach((categoria, prod) {
      costoTotal += prod.precioCompra;
      precioVentaSugerido += prod.precioVenta;

      final cat = _normalizarCategoria(prod);
      if (cat == 'procesador_cpu') {
        final tdp = _obtenerInt(prod, ['consumo_energetico_tdp_watts', 'tdp', 'consumo_watts']);
        consumoWatts += tdp > 0 ? tdp : 65;
      } else if (cat == 'tarjeta_grafica') {
        final consumoGpu = _obtenerInt(prod, ['consumo_energetico_max_watts', 'consumo_max_watts', 'tdp']);
        consumoWatts += consumoGpu > 0 ? consumoGpu : 150;
      } else if (cat == 'fuente_poder') {
        potenciaPsu = _obtenerInt(prod, ['potencia_maxima_watts', 'potencia_watts']);
      }
    });

    bool potenciaSuficiente = true;
    if (potenciaPsu > 0 && potenciaPsu < consumoWatts) {
      potenciaSuficiente = false;
      advertencias.add('¡Advertencia! La PSU ($potenciaPsu W) no cubre el consumo estimado ($consumoWatts W).');
    } else if (potenciaPsu > 0 && (potenciaPsu - consumoWatts) < 50) {
      advertencias.add('Atención: La PSU ($potenciaPsu W) opera muy cerca del límite ($consumoWatts W).');
    }

    final gananciaNeta = precioVentaSugerido - costoTotal;

    return MetricasEnsamble(
      costoTotal: costoTotal,
      precioVentaSugerido: precioVentaSugerido,
      gananciaNetaEstimada: gananciaNeta,
      consumoWattsEstimado: consumoWatts,
      potenciaPsuDisponible: potenciaPsu,
      potenciaSuficiente: potenciaSuficiente,
      advertencias: advertencias,
    );
  }

  // --- MÉTODOS AUXILIARES ---

  static String _normalizarCategoria(ProductoModel prod) {
    final cat = prod.categoria.toLowerCase().trim();
    if (cat.contains('cpu') || cat.contains('procesador')) return 'procesador_cpu';
    if (cat.contains('madre') || cat.contains('motherboard') || cat.contains('placa')) return 'tarjeta_madre';
    if (cat.contains('ram') || cat.contains('memoria')) return 'memoria_ram';
    if (cat.contains('ssd') || cat.contains('hdd') || cat.contains('almacenamiento')) return 'almacenamiento_ssd_hdd';
    if (cat.contains('grafica') || cat.contains('gpu') || cat.contains('video')) return 'tarjeta_grafica';
    if (cat.contains('fuente') || cat.contains('psu') || cat.contains('poder')) return 'fuente_poder';
    if (cat.contains('gabinete') || cat.contains('chasis') || cat.contains('case')) return 'gabinete_chasis';
    if (cat.contains('disipador') || cat.contains('cooler') || cat.contains('refrigeracion')) return 'disipador_cpu';
    if (cat.contains('ventilador') || cat.contains('fan')) return 'ventiladores_chasis';
    return cat;
  }

  static String _obtenerAttr(ProductoModel prod, List<String> claves) {
    for (final clave in claves) {
      if (prod.especificacionesTecnicas.containsKey(clave) &&
          prod.especificacionesTecnicas[clave] != null) {
        return prod.especificacionesTecnicas[clave].toString().trim();
      }
      if (prod.atributosAdministrativos.containsKey(clave) &&
          prod.atributosAdministrativos[clave] != null) {
        return prod.atributosAdministrativos[clave].toString().trim();
      }
    }
    return '';
  }

  static int _obtenerInt(ProductoModel prod, List<String> claves) {
    final strVal = _obtenerAttr(prod, claves);
    if (strVal.isEmpty) return 0;
    return int.tryParse(strVal.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  static bool _socketCoincide(String socket1, String socket2) {
    final s1 = socket1.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final s2 = socket2.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (s1.isEmpty || s2.isEmpty) return true;
    return s1.contains(s2) || s2.contains(s1);
  }
}
