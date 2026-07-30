import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/producto_model.dart';

class RegistroVentasScreen extends StatefulWidget {
  const RegistroVentasScreen({super.key});

  @override
  State<RegistroVentasScreen> createState() => _RegistroVentasScreenState();
}

class _RegistroVentasScreenState extends State<RegistroVentasScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1726),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1726),
        title: Row(
          children: const [
            Icon(Icons.monetization_on, color: Colors.purpleAccent),
            SizedBox(width: 10),
            Text(
              'Registro de Ventas y Finanzas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        elevation: 0,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // BARRA DE BÚSQUEDA
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Buscar producto vendido, vendedor o propietario...',
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.purpleAccent),
                filled: true,
                fillColor: const Color(0xFF050B14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF007AFF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.purpleAccent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // STREAM EN TIEMPO REAL DE PRODUCTOS VENDIDOS
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('inventario').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.purpleAccent),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar ventas: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final todosLosProductos = docs.map((doc) => ProductoModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

                  // Filtrar únicamente los productos cuyo estado sea "Vendido"
                  final vendidos = todosLosProductos.where((prod) {
                    final admin = prod.atributosAdministrativos;
                    final estado = (admin['estado_componente'] ?? '').toString();
                    return estado == 'Vendido';
                  }).toList();

                  // Aplicar búsqueda por texto
                  final queryText = _searchController.text.trim().toLowerCase();
                  final filtrados = vendidos.where((prod) {
                    final admin = prod.atributosAdministrativos;
                    final modelo = (admin['modelo'] ?? '').toString().toLowerCase();
                    final marca = (admin['marca'] ?? '').toString().toLowerCase();
                    final fechaVenta = (admin['fecha_venta'] ?? '').toString().toLowerCase();
                    final propietarios = (admin['propietarios'] as List?)?.join(', ').toLowerCase() ?? '';

                    return queryText.isEmpty ||
                        modelo.contains(queryText) ||
                        marca.contains(queryText) ||
                        fechaVenta.contains(queryText) ||
                        propietarios.contains(queryText);
                  }).toList();

                  // Calcular Métricas KPIs de Ventas
                  double totalRecaudado = 0.0;
                  double totalGanancia = 0.0;

                  for (final p in vendidos) {
                    final admin = p.atributosAdministrativos;
                    totalRecaudado += double.tryParse((admin['precio_venta'] ?? '0').toString()) ?? 0.0;
                    totalGanancia += double.tryParse((admin['ganancia_neta'] ?? '0').toString()) ?? 0.0;
                  }

                  if (vendidos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.sell_outlined, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Aún no hay productos registrados como vendidos.',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // TARJETAS DE MÉTRICAS / KPIS DE VENTAS
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Unidades Vendidas',
                              '${vendidos.length} piezas',
                              Icons.shopping_bag,
                              const Color(0xFF3AD8FF),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              'Total Recaudado',
                              '\$ ${totalRecaudado.toStringAsFixed(2)} USD',
                              Icons.attach_money,
                              Colors.purpleAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              'Ganancia Neta Total',
                              '${totalGanancia >= 0 ? '+' : ''}\$ ${totalGanancia.toStringAsFixed(2)} USD',
                              Icons.trending_up,
                              totalGanancia >= 0 ? Colors.greenAccent : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // LISTADO DE TARJETAS DE VENTAS DETALLADAS
                      Expanded(
                        child: ListView.builder(
                          itemCount: filtrados.length,
                          itemBuilder: (context, index) {
                            final prod = filtrados[index];
                            final admin = prod.atributosAdministrativos;
                            final marca = (admin['marca'] ?? '').toString();
                            final modelo = (admin['modelo'] ?? '').toString();
                            final precioCompra = double.tryParse((admin['precio_adquisicion'] ?? '0').toString()) ?? 0.0;
                            final precioVenta = double.tryParse((admin['precio_venta'] ?? '0').toString()) ?? 0.0;
                            final gananciaNeta = double.tryParse((admin['ganancia_neta'] ?? '0').toString()) ?? (precioVenta - precioCompra);
                            final porcentajeGanancia = double.tryParse((admin['porcentaje_ganancia'] ?? '0').toString()) ?? (precioCompra > 0 ? (gananciaNeta / precioCompra) * 100 : 0.0);
                            final fechaVenta = (admin['fecha_venta'] ?? 'Fecha N/A').toString();
                            final propietarios = (admin['propietarios'] as List?)?.join(', ') ?? 'Todos (OvniCore)';
                            final bool esGanancia = gananciaNeta >= 0;

                            // Reparto por propietarios si existe
                            final repartoRaw = admin['reparto_propietarios'] as Map<String, dynamic>?;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF050B14),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Encabezado Nombre + Badge Vendido
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.sell, color: Colors.purpleAccent, size: 22),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$marca $modelo'.trim(),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Categoría: ${prod.categoria.replaceAll('_', ' ').toUpperCase()} | ID: ${admin['id_activo'] ?? 'N/A'}',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '📅 $fechaVenta',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Divider(color: Color(0xFF0E1726), height: 1),
                                  const SizedBox(height: 14),

                                  // Filas Financieras: Compra vs Venta vs Ganancia
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('🏷️ Precio Compra', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                            const SizedBox(height: 2),
                                            Text(
                                              '\$ ${precioCompra.toStringAsFixed(2)} USD',
                                              style: const TextStyle(color: Color(0xFF3AD8FF), fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('💲 Precio Venta Real', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                            const SizedBox(height: 2),
                                            Text(
                                              '\$ ${precioVenta.toStringAsFixed(2)} USD',
                                              style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              esGanancia ? '📈 Ganancia Neta' : '📉 Pérdida Neta',
                                              style: TextStyle(color: esGanancia ? Colors.greenAccent : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${esGanancia ? '+' : ''}\$ ${gananciaNeta.toStringAsFixed(2)} USD (${esGanancia ? '+' : ''}${porcentajeGanancia.toStringAsFixed(1)}%)',
                                              style: TextStyle(color: esGanancia ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '👥 Propietarios de la Pieza: $propietarios',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),

                                  // Reparto de dinero si hubo múltiples aportantes
                                  if (repartoRaw != null && repartoRaw.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0E1726),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.2)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('💵 PAGO Y REPARTO ENTRE INTEGRANTES:', style: TextStyle(color: Color(0xFF3AD8FF), fontSize: 11, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 6,
                                            children: repartoRaw.entries.map((e) {
                                              final dueno = e.key;
                                              final datos = e.value as Map<String, dynamic>? ?? {};
                                              final recibe = double.tryParse((datos['recibe'] ?? '0').toString()) ?? 0.0;
                                              final ganInd = double.tryParse((datos['ganancia'] ?? '0').toString()) ?? 0.0;

                                              return Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('$dueno: ', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                                  Text(
                                                    'Recibe \$${recibe.toStringAsFixed(2)} (Ganancia: \$${ganInd.toStringAsFixed(2)})',
                                                    style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF050B14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            radius: 20,
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
