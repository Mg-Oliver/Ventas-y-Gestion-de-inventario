import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/auditoria_service.dart';

class HistorialAuditoriaScreen extends StatefulWidget {
  const HistorialAuditoriaScreen({super.key});

  @override
  State<HistorialAuditoriaScreen> createState() => _HistorialAuditoriaScreenState();
}

class _HistorialAuditoriaScreenState extends State<HistorialAuditoriaScreen> {
  String _filtroTipo = 'TODOS';
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
            Icon(Icons.history, color: Color(0xFF3AD8FF)),
            SizedBox(width: 10),
            Text(
              'Historial de Auditoría y Movimientos',
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
            // BARRA DE FILTROS Y BÚSQUEDA DE AUDITORÍA
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Buscar en el historial por componente...',
                      labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF3AD8FF)),
                      filled: true,
                      fillColor: const Color(0xFF050B14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF007AFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3AD8FF), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildFilterChip('TODOS', 'Todos'),
                const SizedBox(width: 8),
                _buildFilterChip('CREACIÓN', 'Creaciones', color: Colors.greenAccent),
                const SizedBox(width: 8),
                _buildFilterChip('ELIMINACIÓN', 'Eliminaciones', color: Colors.redAccent),
              ],
            ),
            const SizedBox(height: 20),

            // LISTA DE AUDITORÍA EN TIEMPO REAL
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: AuditoriaService.obtenerHistorialStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF3AD8FF)),
                    );
                  }

                  List<Map<String, dynamic>> registros = [];

                  if (snapshot.hasData && snapshot.data != null) {
                    for (final doc in snapshot.data!.docs) {
                      final rawData = doc.data() as Map<String, dynamic>;
                      if (rawData['grupo'] == 'eliminado' || rawData['categoria'] == 'eliminado') continue;
                      final admin = rawData['atributosAdministrativos'] as Map<String, dynamic>? ?? {};
                      
                      final esAuditoria = rawData['grupo'] == 'auditoria_movimientos' ||
                          (rawData.containsKey('tipo_accion') && rawData['tipo_accion'] != 'ELIMINADO') ||
                          (admin.containsKey('tipo_accion') && admin['tipo_accion'] != 'ELIMINADO');

                      if (esAuditoria) {
                        registros.add({
                          'tipo_accion': rawData['tipo_accion'] ?? admin['tipo_accion'] ?? 'ACCIÓN',
                          'componente_nombre': rawData['componente_nombre'] ?? admin['componente_nombre'] ?? 'Componente',
                          'categoria': rawData['categoria'] ?? admin['categoria'] ?? '',
                          'fecha_hora': rawData['fecha_hora'] ?? admin['fecha_hora'] ?? '',
                          'detalles': rawData['detalles'] ?? admin['detalles'] ?? 'Sin detalles',
                        });
                      }
                    }
                  }

                  // Si la colección no devolvió aún datos o hubo restricción, fusionar con el registro local
                  for (final regLocal in AuditoriaService.registrosLocales) {
                    final existe = registros.any((r) =>
                        r['componente_nombre'] == regLocal['componente_nombre'] &&
                        r['fecha_hora'] == regLocal['fecha_hora']);
                    if (!existe) {
                      registros.add(regLocal);
                    }
                  }

                  final queryText = _searchController.text.trim().toLowerCase();

                  final filtrados = registros.where((data) {
                    final tipo = (data['tipo_accion'] ?? '').toString().toUpperCase();
                    final nombre = (data['componente_nombre'] ?? '').toString().toLowerCase();
                    final cat = (data['categoria'] ?? '').toString().toLowerCase();

                    final cumpleTipo = _filtroTipo == 'TODOS' || tipo == _filtroTipo;
                    final cumpleTexto = queryText.isEmpty || nombre.contains(queryText) || cat.contains(queryText);

                    return cumpleTipo && cumpleTexto;
                  }).toList();

                  // Ordenar cronológicamente en memoria (del más reciente al más antiguo)
                  filtrados.sort((a, b) {
                    final fechaA = (a['fecha_hora'] ?? '').toString();
                    final fechaB = (b['fecha_hora'] ?? '').toString();
                    return fechaB.compareTo(fechaA);
                  });

                  if (filtrados.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.history_toggle_off, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No hay registros de auditoría disponibles.',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtrados.length,
                    itemBuilder: (context, index) {
                      final data = filtrados[index];
                      final tipoAccion = (data['tipo_accion'] ?? 'ACCIÓN').toString();
                      final nombreComp = (data['componente_nombre'] ?? 'Componente').toString();
                      final categoriaComp = (data['categoria'] ?? '').toString().replaceAll('_', ' ').toUpperCase();
                      final fechaHora = (data['fecha_hora'] ?? 'Fecha N/A').toString();
                      final detalles = (data['detalles'] ?? '').toString();

                      Color colorTipo = Colors.blueAccent;
                      IconData iconoTipo = Icons.info;

                      if (tipoAccion == 'CREACIÓN') {
                        colorTipo = Colors.greenAccent;
                        iconoTipo = Icons.add_circle_outline;
                      } else if (tipoAccion == 'ELIMINACIÓN') {
                        colorTipo = Colors.redAccent;
                        iconoTipo = Icons.delete_forever;
                      } else if (tipoAccion == 'EDICIÓN') {
                        colorTipo = Colors.orangeAccent;
                        iconoTipo = Icons.edit_note;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF050B14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: colorTipo.withValues(alpha: 0.15),
                              radius: 22,
                              child: Icon(iconoTipo, color: colorTipo, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: colorTipo.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: colorTipo.withValues(alpha: 0.5)),
                                        ),
                                        child: Text(
                                          tipoAccion,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: colorTipo,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          nombreComp,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        fechaHora,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Categoría: $categoriaComp',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF3AD8FF)),
                                  ),
                                  if (detalles.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      detalles,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String tipo, String label, {Color? color}) {
    final bool isSelected = _filtroTipo == tipo;
    final chipColor = color ?? const Color(0xFF3AD8FF);

    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF050B14) : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: const Color(0xFF050B14),
      selectedColor: chipColor,
      side: BorderSide(color: isSelected ? chipColor : Colors.grey.withValues(alpha: 0.3)),
      onSelected: (selected) {
        setState(() {
          _filtroTipo = tipo;
        });
      },
    );
  }
}
