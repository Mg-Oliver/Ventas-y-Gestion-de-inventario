import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../data/models/producto_model.dart';
import '../../data/services/compatibilidad_service.dart';

class PcBuilderScreen extends StatefulWidget {
  const PcBuilderScreen({super.key});

  @override
  State<PcBuilderScreen> createState() => _PcBuilderScreenState();
}

class _PcBuilderScreenState extends State<PcBuilderScreen> {
  final Map<String, ProductoModel?> _ensamble = {
    'procesador_cpu': null,
    'tarjeta_madre': null,
    'memoria_ram': null,
    'almacenamiento_ssd_hdd': null,
    'tarjeta_grafica': null,
    'fuente_poder': null,
    'gabinete_chasis': null,
    'disipador_cpu': null,
  };

  final Map<String, Map<String, dynamic>> _secciones = {
    'procesador_cpu': {'nombre': 'Procesador (CPU)', 'icono': Icons.developer_board, 'color': Colors.cyanAccent},
    'tarjeta_madre': {'nombre': 'Tarjeta Madre (Motherboard)', 'icono': Icons.dns, 'color': Colors.blueAccent},
    'memoria_ram': {'nombre': 'Memoria RAM', 'icono': Icons.memory, 'color': Colors.purpleAccent},
    'almacenamiento_ssd_hdd': {'nombre': 'Almacenamiento (SSD / HDD)', 'icono': Icons.storage, 'color': Colors.greenAccent},
    'tarjeta_grafica': {'nombre': 'Tarjeta Gráfica (GPU)', 'icono': Icons.videogame_asset, 'color': Colors.orangeAccent},
    'fuente_poder': {'nombre': 'Fuente de Poder (PSU)', 'icono': Icons.bolt, 'color': Colors.yellowAccent},
    'gabinete_chasis': {'nombre': 'Gabinete (Chasís)', 'icono': Icons.computer, 'color': Colors.tealAccent},
    'disipador_cpu': {'nombre': 'Disipador CPU / Refrigeración', 'icono': Icons.ac_unit, 'color': Colors.lightBlueAccent},
  };

  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  Map<String, ProductoModel> get _ensambleActivo {
    final Map<String, ProductoModel> activo = {};
    _ensamble.forEach((k, v) {
      if (v != null) activo[k] = v;
    });
    return activo;
  }

  @override
  Widget build(BuildContext context) {
    final metricas = CompatibilidadService.calcularMetricasEnsamble(_ensambleActivo);

    return Scaffold(
      backgroundColor: const Color(0xFF050B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1726),
        title: const Row(
          children: [
            Icon(Icons.build_circle, color: Color(0xFF3AD8FF)),
            SizedBox(width: 10),
            Text(
              'Armador de PC (PC Builder)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          if (_ensambleActivo.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _ensamble.updateAll((key, value) => null);
                });
              },
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 20),
              label: const Text('Limpiar Todo', style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('inventario').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar inventario', style: TextStyle(color: Colors.white)));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3AD8FF)));
          }

          final todosLosDocs = snapshot.data!.docs;
          final inventarioCompleto = todosLosDocs.map((doc) {
            return ProductoModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).where((prod) {
            final estado = (prod.atributosAdministrativos['estado_componente'] ?? '').toString().toLowerCase();
            return prod.grupo.toLowerCase() != 'eliminado' &&
                prod.categoria.toLowerCase() != 'eliminado' &&
                estado != 'eliminado' &&
                estado != 'vendido';
          }).toList();

          return Column(
            children: [
              // PANEL DE MÉTRICAS / PCPARTPICKER SUMMARY
              _buildResumenPcpartpicker(metricas),

              // LISTA DE SECCIONES DEL ENSAMBLE
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _secciones.length,
                  itemBuilder: (context, index) {
                    final key = _secciones.keys.elementAt(index);
                    final info = _secciones[key]!;
                    final componenteSeleccionado = _ensamble[key];

                    return _buildTarjetaSeccion(
                      key: key,
                      nombreSeccion: info['nombre'] as String,
                      icono: info['icono'] as IconData,
                      colorAccento: info['color'] as Color,
                      seleccionado: componenteSeleccionado,
                      inventarioCompleto: inventarioCompleto,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResumenPcpartpicker(MetricasEnsamble metricas) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0E1726),
        border: Border(bottom: BorderSide(color: Color(0xFF3AD8FF), width: 1.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // COSTO TOTAL DE ENTRADA
              Expanded(
                child: _buildMetricCard(
                  'COSTO ENTRADA',
                  _currencyFormat.format(metricas.costoTotal),
                  Colors.blueAccent,
                  Icons.shopping_cart,
                ),
              ),
              const SizedBox(width: 8),
              // PRECIO DE VENTA RECOMENDADO
              Expanded(
                child: _buildMetricCard(
                  'PRECIO VENTA REC.',
                  _currencyFormat.format(metricas.precioVentaSugerido),
                  const Color(0xFF3AD8FF),
                  Icons.sell,
                ),
              ),
              const SizedBox(width: 8),
              // GANANCIA NETA ESTIMADA
              Expanded(
                child: _buildMetricCard(
                  'GANANCIA NETA',
                  _currencyFormat.format(metricas.gananciaNetaEstimada),
                  Colors.greenAccent,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 8),
              // CONSUMO WATTS ESTIMADO
              Expanded(
                child: _buildMetricCard(
                  'ENERGÍA ESTIMADA',
                  '${metricas.consumoWattsEstimado} W' +
                      (metricas.potenciaPsuDisponible > 0 ? ' / ${metricas.potenciaPsuDisponible}W' : ''),
                  metricas.potenciaSuficiente ? Colors.yellowAccent : Colors.redAccent,
                  Icons.electric_bolt,
                ),
              ),
            ],
          ),
          if (metricas.advertencias.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              children: metricas.advertencias.map((adv) {
                return Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          adv,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(String titulo, String valor, Color color, IconData icono) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF050B14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaSeccion({
    required String key,
    required String nombreSeccion,
    required IconData icono,
    required Color colorAccento,
    required ProductoModel? seleccionado,
    required List<ProductoModel> inventarioCompleto,
  }) {
    final bool tieneSeleccion = seleccionado != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1726),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tieneSeleccion ? colorAccento.withValues(alpha: 0.6) : Colors.white10,
          width: tieneSeleccion ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ICONO DE SECCIÓN
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorAccento.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: colorAccento, size: 24),
            ),
            const SizedBox(width: 14),

            // INFORMACIÓN DE SECCIÓN O COMPONENTE ELEGIDO
            Expanded(
              child: tieneSeleccion
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombreSeccion.toUpperCase(),
                          style: TextStyle(color: colorAccento, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${seleccionado.atributosAdministrativos['marca'] ?? ''} ${seleccionado.atributosAdministrativos['modelo'] ?? ''}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Compra: ${_currencyFormat.format(seleccionado.precioCompra)}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Venta: ${_currencyFormat.format(seleccionado.precioVenta)}',
                              style: TextStyle(color: colorAccento, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombreSeccion,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const Text(
                          'Sin seleccionar',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
            ),

            // BOTÓN DE ACCIÓN: SELECCIONAR O REMOVER
            if (tieneSeleccion)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                tooltip: 'Quitar del ensamble',
                onPressed: () {
                  setState(() {
                    _ensamble[key] = null;
                  });
                },
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3AD8FF).withValues(alpha: 0.15),
                  foregroundColor: const Color(0xFF3AD8FF),
                  side: const BorderSide(color: Color(0xFF3AD8FF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Elegir'),
                onPressed: () {
                  _mostrarModalSeleccionComponente(
                    keySeccion: key,
                    nombreSeccion: nombreSeccion,
                    inventarioCompleto: inventarioCompleto,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _mostrarModalSeleccionComponente({
    required String keySeccion,
    required String nombreSeccion,
    required List<ProductoModel> inventarioCompleto,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1726),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        // Filtrar productos pertenecientes a esta categoría
        final candidatosCategoria = inventarioCompleto.where((p) {
          final cat = p.categoria.toLowerCase().trim();
          final grupo = p.grupo.toLowerCase().trim();

          if (keySeccion == 'procesador_cpu') return cat.contains('cpu') || cat.contains('procesador') || grupo.contains('cpu');
          if (keySeccion == 'tarjeta_madre') return cat.contains('madre') || cat.contains('motherboard') || cat.contains('placa') || grupo.contains('madre');
          if (keySeccion == 'memoria_ram') return cat.contains('ram') || cat.contains('memoria') || grupo.contains('ram');
          if (keySeccion == 'almacenamiento_ssd_hdd') return cat.contains('ssd') || cat.contains('hdd') || cat.contains('almacenamiento') || grupo.contains('almacenamiento');
          if (keySeccion == 'tarjeta_grafica') return cat.contains('grafica') || cat.contains('gpu') || cat.contains('video') || grupo.contains('gpu');
          if (keySeccion == 'fuente_poder') return cat.contains('fuente') || cat.contains('psu') || cat.contains('poder') || grupo.contains('fuente');
          if (keySeccion == 'gabinete_chasis') return cat.contains('gabinete') || cat.contains('chasis') || cat.contains('case') || grupo.contains('gabinete');
          if (keySeccion == 'disipador_cpu') return cat.contains('disipador') || cat.contains('cooler') || cat.contains('refrigeracion') || grupo.contains('disipador');
          return false;
        }).toList();

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Seleccionar $nombreSeccion',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),

                  if (candidatosCategoria.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No hay componentes registrados en esta categoría.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: candidatosCategoria.length,
                        itemBuilder: (context, idx) {
                          final prod = candidatosCategoria[idx];
                          final evalComp = CompatibilidadService.esCompatibleConEnsamble(prod, _ensambleActivo);

                          final marca = prod.atributosAdministrativos['marca'] ?? '';
                          final modelo = prod.atributosAdministrativos['modelo'] ?? '';
                          final idActivo = prod.atributosAdministrativos['id_activo'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF050B14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: evalComp.esCompatible ? const Color(0xFF3AD8FF).withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                '$marca $modelo',
                                style: TextStyle(
                                  color: evalComp.esCompatible ? Colors.white : Colors.white60,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ID: $idActivo | Venta: ${_currencyFormat.format(prod.precioVenta)} | Costo: ${_currencyFormat.format(prod.precioCompra)}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  if (evalComp.esCompatible)
                                    const Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.greenAccent, size: 12),
                                        SizedBox(width: 4),
                                        Text('✓ Compatible con tu ensamble', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                                      ],
                                    )
                                  else
                                    Row(
                                      children: [
                                        const Icon(Icons.cancel, color: Colors.redAccent, size: 12),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Incompatible: ${evalComp.motivo}',
                                            style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: evalComp.esCompatible ? const Color(0xFF3AD8FF) : Colors.grey.shade800,
                                  foregroundColor: evalComp.esCompatible ? const Color(0xFF050B14) : Colors.grey,
                                ),
                                onPressed: evalComp.esCompatible
                                    ? () {
                                        setState(() {
                                          _ensamble[keySeccion] = prod;
                                        });
                                        Navigator.pop(context);
                                      }
                                    : null,
                                child: const Text('Elegir'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
