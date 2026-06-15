import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/producto_model.dart';

class InventarioListScreen extends StatefulWidget {
  final String? categoriaFiltro;

  const InventarioListScreen({super.key, this.categoriaFiltro});

  @override
  State<InventarioListScreen> createState() => _InventarioListScreenState();
}

class _InventarioListScreenState extends State<InventarioListScreen> {
  final _searchController = TextEditingController();
  String _textoBusqueda = '';

  @override
  void initState() {
    super.initState();
    _textoBusqueda = '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _mostrarDialogoConfirmacion(
    BuildContext context,
    String idDocumento,
    String nombreProducto,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('¿Confirmar eliminación?'),
            ],
          ),
          content: Text(
            'Esta acción eliminará permanentemente el activo "$nombreProducto" de OvniCore.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'CANCELAR',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await FirebaseFirestore.instance
                      .collection('inventario')
                      .doc(idDocumento)
                      .delete();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🗑️ "$nombreProducto" eliminado.'),
                        backgroundColor: Colors.orange.shade800,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'SÍ, ELIMINAR',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.categoriaFiltro != null
        ? 'Inventario - ${widget.categoriaFiltro!.toUpperCase()}'
        : 'Almacén Global - OvniCore';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/img/icon_ovnicore.png', width: 30, height: 30),
            const SizedBox(width: 10),
            Text(titleText),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('inventario').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('❌ Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.data == null || snapshot.data!.docs.isEmpty)
            return const Center(child: Text('🛸 Almacén vacío.'));

          final todosLosProductos = snapshot.data!.docs.map((doc) {
            return ProductoModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

          // Filtrado local de búsqueda con doble condición defensiva
          final productosFiltrados = todosLosProductos.where((prod) {
            final coincideCategoria = widget.categoriaFiltro == null || 
                prod.categoria.trim().toLowerCase() == widget.categoriaFiltro!.trim().toLowerCase();

            final coincideTexto = _textoBusqueda.isEmpty ||
                (prod.atributosAdministrativos['marca'] ?? '').toString().toLowerCase().contains(_textoBusqueda) ||
                (prod.atributosAdministrativos['modelo'] ?? '').toString().toLowerCase().contains(_textoBusqueda) ||
                prod.categoria.toLowerCase().contains(_textoBusqueda);

            return coincideCategoria && coincideTexto;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por marca, modelo o categoría...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF3AD8FF)),
                    suffixIcon: _textoBusqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _textoBusqueda = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0E1726),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _textoBusqueda = value.toLowerCase();
                    });
                  },
                ),
              ),
              // Lista expandida de componentes
              Expanded(
                child: productosFiltrados.isEmpty
                    ? const Center(
                        child: Text('🔍 No se encontraron componentes.'),
                      )
                    : ListView.builder(
                        clipBehavior: Clip.none,
                        itemCount: productosFiltrados.length,
                        itemBuilder: (context, index) {
                          final prod = productosFiltrados[index];
                          final admin = prod.atributosAdministrativos;
                          final specs = prod.especificacionesTecnicas;
                          final isInterno =
                              prod.grupo == 'componentes_internos';
                          final esCritico = admin['id_activo'] == '001';

                          bool isHovered = false;
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return MouseRegion(
                                onEnter: (_) => setState(() => isHovered = true),
                                onExit: (_) => setState(() => isHovered = false),
                                child: AnimatedScale(
                                  scale: isHovered ? 1.02 : 1.0,
                                  duration: const Duration(milliseconds: 100),
                                  curve: Curves.easeOut,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 100),
                                    curve: Curves.easeOut,
                                    clipBehavior: Clip.none,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0E1726),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isHovered 
                                            ? const Color(0xFF3AD8FF) 
                                            : (esCritico ? const Color(0xFF3AD8FF) : const Color(0xFF007AFF).withOpacity(0.5)),
                                        width: isHovered ? 2.0 : 1.0,
                                      ),
                                      boxShadow: isHovered
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF3AD8FF).withOpacity(0.4),
                                                blurRadius: 12,
                                                spreadRadius: 1,
                                              )
                                            ]
                                          : [],
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        dividerColor: Colors.transparent, // Elimina la línea superior e inferior en hover
                                      ),
                                      child: ExpansionTile(
                                        iconColor: const Color(0xFF3AD8FF),
                                        collapsedIconColor: Colors.grey,
                                        leading: CircleAvatar(
                                          backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.2),
                                          child: Image.asset(
                                            'assets/img/${prod.categoria}.png',
                                            width: 28,
                                            height: 28,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                esCritico
                                                    ? Icons.warning_amber
                                                    : (isInterno
                                                          ? Icons.developer_board
                                                          : Icons.monitor),
                                                color: const Color(0xFF3AD8FF),
                                              );
                                            },
                                          ),
                                        ),
                                        title: Text(
                                          '${admin['marca']} ${admin['modelo']}',
                                          style: TextStyle(
                                            color: isHovered ? const Color(0xFF3AD8FF) : Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'ID: ${admin['id_activo']} | ${prod.categoria.toUpperCase()}',
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF050B14),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: const Color(0xFF007AFF).withOpacity(0.3)),
                                              ),
                                          child: Text(
                                            specs['socket'] != null || specs['socket_compatible'] != null
                                                ? '${specs['socket'] ?? specs['socket_compatible']}'
                                                : 'Periférico',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF3AD8FF),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          onPressed: () => _mostrarDialogoConfirmacion(
                                            context,
                                            prod.id,
                                            '${admin['marca']} ${admin['modelo']}',
                                          ),
                                        ),
                                      ],
                                    ),
                                    children: [
                                      // SUB-PANEL A: Especificaciones
                                      if (specs.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Wrap(
                                            spacing: 12,
                                            runSpacing: 12,
                                            children: specs.entries.map((entry) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF050B14),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.3)),
                                                ),
                                                child: Text(
                                                  '${entry.key.toUpperCase()}: ${entry.value}',
                                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      
                                      // SUB-PANEL B: Comentarios
                                      if (admin['comentarios'] != null && admin['comentarios'].toString().trim().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF050B14),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.comment, color: Colors.grey, size: 20),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    admin['comentarios'],
                                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                      // SUB-PANEL C: Imágenes Reales
                                      if (admin['imagenes_reales'] != null && (admin['imagenes_reales'] as List).isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: SizedBox(
                                            height: 120,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: (admin['imagenes_reales'] as List).length,
                                              itemBuilder: (context, imgIndex) {
                                                final url = (admin['imagenes_reales'] as List)[imgIndex].toString();
                                                return Padding(
                                                  padding: const EdgeInsets.only(right: 12.0),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Image.network(
                                                      url,
                                                      height: 120,
                                                      width: 160,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stack) => Container(
                                                        height: 120,
                                                        width: 160,
                                                        color: const Color(0xFF050B14),
                                                        child: const Center(
                                                          child: Icon(Icons.broken_image, color: Colors.redAccent),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
        ),
      ),
    );
  }
}
