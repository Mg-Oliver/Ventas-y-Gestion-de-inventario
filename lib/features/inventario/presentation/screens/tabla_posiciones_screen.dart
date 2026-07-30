import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/producto_model.dart';

class TablaPosicionesScreen extends StatefulWidget {
  const TablaPosicionesScreen({super.key});

  @override
  State<TablaPosicionesScreen> createState() => _TablaPosicionesScreenState();
}

class _TablaPosicionesScreenState extends State<TablaPosicionesScreen> {
  final List<String> _integrantes = ['Miguel', 'Kevin', 'Diego', 'Edgardo'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1726),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1726),
        title: Row(
          children: const [
            Icon(Icons.emoji_events, color: Colors.amberAccent),
            SizedBox(width: 10),
            Text(
              'Tabla de Posiciones y Podio de Ventas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('inventario').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amberAccent),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al calcular el ranking: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final todosLosProductos = docs.map((doc) => ProductoModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

          // Inicializar contadores por integrante
          Map<String, double> gananciasPorUser = {for (var u in _integrantes) u: 0.0};
          Map<String, double> recaudadoPorUser = {for (var u in _integrantes) u: 0.0};
          Map<String, int> ventasConteoUser = {for (var u in _integrantes) u: 0};

          // Procesar solo productos con estado "Vendido"
          for (final prod in todosLosProductos) {
            final admin = prod.atributosAdministrativos;
            final estado = (admin['estado_componente'] ?? '').toString();
            if (estado != 'Vendido') continue;

            final repartoRaw = admin['reparto_propietarios'] as Map<String, dynamic>?;
            final propietariosList = admin['propietarios'] as List<dynamic>?;
            final double gananciaTotalProd = double.tryParse((admin['ganancia_neta'] ?? '0').toString()) ?? 0.0;
            final double ventaTotalProd = double.tryParse((admin['precio_venta'] ?? '0').toString()) ?? 0.0;

            if (repartoRaw != null && repartoRaw.isNotEmpty) {
              // Si existe reparto específico calculado
              repartoRaw.forEach((user, datos) {
                if (gananciasPorUser.containsKey(user)) {
                  final mapData = datos as Map<String, dynamic>? ?? {};
                  final double ganInd = double.tryParse((mapData['ganancia'] ?? '0').toString()) ?? 0.0;
                  final double recInd = double.tryParse((mapData['recibe'] ?? '0').toString()) ?? 0.0;

                  gananciasPorUser[user] = (gananciasPorUser[user] ?? 0.0) + ganInd;
                  recaudadoPorUser[user] = (recaudadoPorUser[user] ?? 0.0) + recInd;
                  ventasConteoUser[user] = (ventasConteoUser[user] ?? 0) + 1;
                }
              });
            } else if (propietariosList != null && propietariosList.isNotEmpty) {
              // Si no hay reparto guardado, dividimos equitativamente entre sus dueños
              final duenos = propietariosList.contains('Todos (OvniCore)')
                  ? _integrantes
                  : propietariosList.map((e) => e.toString()).where((e) => _integrantes.contains(e)).toList();

              if (duenos.isNotEmpty) {
                final cuotaGanancia = gananciaTotalProd / duenos.length;
                final cuotaVenta = ventaTotalProd / duenos.length;

                for (final user in duenos) {
                  if (gananciasPorUser.containsKey(user)) {
                    gananciasPorUser[user] = (gananciasPorUser[user] ?? 0.0) + cuotaGanancia;
                    recaudadoPorUser[user] = (recaudadoPorUser[user] ?? 0.0) + cuotaVenta;
                    ventasConteoUser[user] = (ventasConteoUser[user] ?? 0) + 1;
                  }
                }
              }
            }
          }

          // Crear lista ordenada de rankings
          List<Map<String, dynamic>> ranking = _integrantes.map((user) {
            return {
              'nombre': user,
              'ganancia': gananciasPorUser[user] ?? 0.0,
              'recaudado': recaudadoPorUser[user] ?? 0.0,
              'ventas': ventasConteoUser[user] ?? 0,
            };
          }).toList();

          // Ordenar por Ganancia descendente
          ranking.sort((a, b) => (b['ganancia'] as double).compareTo(a['ganancia'] as double));

          final primerLugar = ranking.isNotEmpty ? ranking[0] : null;
          final segundoLugar = ranking.length > 1 ? ranking[1] : null;
          final tercerLugar = ranking.length > 2 ? ranking[2] : null;
          final cuartoLugarRestantes = ranking.length > 3 ? ranking.sublist(3) : <Map<String, dynamic>>[];

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  '🏆 PODIO DE GANANCIAS EN VENTAS',
                  style: TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Basado en las utilidades netas individuales generadas por la venta de componentes',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 24),

                // ESTRUCTURA DEL PODIO (2º LUGAR, 1º LUGAR, 3º LUGAR)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 2º LUGAR (PLATA)
                    if (segundoLugar != null)
                      _buildPodioCard(
                        puesto: 2,
                        nombre: segundoLugar['nombre'],
                        ganancia: segundoLugar['ganancia'],
                        recaudado: segundoLugar['recaudado'],
                        ventas: segundoLugar['ventas'],
                        colorPodio: const Color(0xFFC0C0C0),
                        alturaBase: 140,
                        icono: Icons.filter_2,
                      ),
                    const SizedBox(width: 16),

                    // 1º LUGAR (ORO)
                    if (primerLugar != null)
                      _buildPodioCard(
                        puesto: 1,
                        nombre: primerLugar['nombre'],
                        ganancia: primerLugar['ganancia'],
                        recaudado: primerLugar['recaudado'],
                        ventas: primerLugar['ventas'],
                        colorPodio: const Color(0xFFFFD700),
                        alturaBase: 180,
                        icono: Icons.workspace_premium,
                        esCampeon: true,
                      ),
                    const SizedBox(width: 16),

                    // 3º LUGAR (BRONCE)
                    if (tercerLugar != null)
                      _buildPodioCard(
                        puesto: 3,
                        nombre: tercerLugar['nombre'],
                        ganancia: tercerLugar['ganancia'],
                        recaudado: tercerLugar['recaudado'],
                        ventas: tercerLugar['ventas'],
                        colorPodio: const Color(0xFFCD7F32),
                        alturaBase: 110,
                        icono: Icons.filter_3,
                      ),
                  ],
                ),
                const SizedBox(height: 30),

                // SECCIÓN 4º PUESTO Y RESTANTES EN MODO LISTA
                if (cuartoLugarRestantes.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: const [
                        Icon(Icons.format_list_numbered, color: Color(0xFF3AD8FF), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'LISTA DE CLASIFICACIÓN (4º LUGAR Y SIGUIENTES)',
                          style: TextStyle(color: Color(0xFF3AD8FF), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cuartoLugarRestantes.length,
                      itemBuilder: (context, index) {
                        final item = cuartoLugarRestantes[index];
                        final puestoReal = index + 4;
                        final nombre = item['nombre'].toString();
                        final double ganancia = item['ganancia'] as double;
                        final double recaudado = item['recaudado'] as double;
                        final int ventas = item['ventas'] as int;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF050B14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.2),
                                radius: 18,
                                child: Text(
                                  '$puestoRealº',
                                  style: const TextStyle(color: Color(0xFF3AD8FF), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombre,
                                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '$ventas ventas realizadas | Recaudado: \$${recaudado.toStringAsFixed(2)} USD',
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Ganancia acumulada:', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                  Text(
                                    '\$ ${ganancia.toStringAsFixed(2)} USD',
                                    style: TextStyle(
                                      color: ganancia >= 0 ? Colors.greenAccent : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPodioCard({
    required int puesto,
    required String nombre,
    required double ganancia,
    required double recaudado,
    required int ventas,
    required Color colorPodio,
    required double alturaBase,
    required IconData icono,
    bool esCampeon = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Corona para 1º Lugar
        if (esCampeon)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Icon(Icons.stars, color: Colors.amberAccent, size: 28),
          ),

        // Nombre e Invertido/Ganado
        Text(
          nombre,
          style: TextStyle(
            fontSize: esCampeon ? 17 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '+\$ ${ganancia.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: esCampeon ? 16 : 13,
            fontWeight: FontWeight.bold,
            color: colorPodio,
          ),
        ),
        const SizedBox(height: 8),

        // Bloque del Podio Escalonado
        Container(
          width: esCampeon ? 160 : 130,
          height: alturaBase,
          decoration: BoxDecoration(
            color: colorPodio.withValues(alpha: 0.15),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
            ),
            border: Border.all(color: colorPodio, width: esCampeon ? 2 : 1.5),
            boxShadow: esCampeon
                ? [
                    BoxShadow(
                      color: colorPodio.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: esCampeon ? 36 : 28, color: colorPodio),
              const SizedBox(height: 4),
              Text(
                '$puestoº LUGAR',
                style: TextStyle(
                  color: colorPodio,
                  fontWeight: FontWeight.bold,
                  fontSize: esCampeon ? 13 : 11,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$ventas ventas',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
