import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/producto_model.dart';
import '../../data/services/auditoria_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/compatibilidad_service.dart';

class InventarioListScreen extends StatefulWidget {
  final String? categoriaFiltro;

  const InventarioListScreen({super.key, this.categoriaFiltro});

  @override
  State<InventarioListScreen> createState() => _InventarioListScreenState();
}

class _InventarioListScreenState extends State<InventarioListScreen> {
  final _searchController = TextEditingController();
  String _textoBusqueda = '';
  String? _categoriaFiltroSeleccionada;
  String? _marcaFiltroSeleccionada;
  String? _estadoFiltroSeleccionado;
  String _ordenSeleccionado = 'nombre_asc';

  final Map<String, String> _categoriasNombres = {
    'procesador_cpu': 'Procesadores (CPU)',
    'tarjeta_madre': 'Tarjetas Madre',
    'memoria_ram': 'Memoria RAM',
    'almacenamiento_ssd_hdd': 'Almacenamiento (SSD / HDD)',
    'tarjeta_grafica': 'Tarjetas Gráficas (GPU)',
    'fuente_poder': 'Fuentes de Poder',
    'gabinete_chasis': 'Gabinetes / Chasis',
    'disipador_cpu': 'Disipadores CPU',
    'ventiladores_chasis': 'Ventiladores',
    'monitor': 'Monitores',
    'teclado': 'Teclados',
    'mouse': 'Mouses',
    'auriculares_altavoces': 'Auriculares y Audio',
  };

  @override
  void initState() {
    super.initState();
    _textoBusqueda = '';
    _categoriaFiltroSeleccionada = widget.categoriaFiltro;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<String> _marcasPopulares = [
    'Intel', 'AMD', 'NVIDIA', 'ASUS', 'MSI', 'Gigabyte', 'EVGA', 'Corsair',
    'Kingston', 'Crucial', 'Samsung', 'Western Digital', 'Seagate', 'SanDisk',
    'ADATA', 'XPG', 'G.Skill', 'TeamGroup', 'PNY', 'Zotac', 'Sapphire',
    'PowerColor', 'XFX', 'ASRock', 'Cooler Master', 'Thermaltake', 'Noctua',
    'be quiet!', 'Lian Li', 'NZXT', 'DeepCool', 'Phanteks', 'Fractal Design',
    'Logitech', 'Razer', 'Redragon', 'HyperX', 'SteelSeries', 'BenQ', 'Acer',
    'AOC', 'Dell', 'HP', 'Lenovo', 'LG', 'ViewSonic', 'TUF Gaming', 'ROG'
  ];

  Widget _buildCustomDropdown<T>({
    required String labelText,
    required T? value,
    required List<DropdownMenuItem<T>>? items,
    required ValueChanged<T?>? onChanged,
    Widget? hint,
    double? menuMaxHeight = 320,
  }) {
    return FormField<T>(
      initialValue: value,
      builder: (FormFieldState<T> state) {
        Widget? displayChild;
        if (items != null && value != null) {
          for (final item in items) {
            if (item.value == value) {
              displayChild = item.child;
              break;
            }
          }
        }

        return LayoutBuilder(
          builder: (context, boxConstraints) {
            final fieldWidth = boxConstraints.maxWidth;

            return PopupMenuButton<T>(
              enabled: items != null && items.isNotEmpty && onChanged != null,
              tooltip: labelText,
              offset: const Offset(0, 54),
              color: const Color(0xFF0E1726),
              constraints: BoxConstraints(
                minWidth: fieldWidth,
                maxWidth: fieldWidth,
                maxHeight: menuMaxHeight ?? 320,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF3AD8FF), width: 1),
              ),
              onSelected: (T newValue) {
                state.didChange(newValue);
                if (onChanged != null) onChanged(newValue);
              },
              itemBuilder: (BuildContext context) {
                if (items == null) return [];
                return items.map((DropdownMenuItem<T> item) {
                  return PopupMenuItem<T>(
                    value: item.value,
                    child: item.child,
                  );
                }).toList();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF050B14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: displayChild ??
                          hint ??
                          Text(
                            labelText,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF3AD8FF)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEstadoBadge(String? estado) {
    final est = estado ?? 'Disponible';
    Color col = Colors.greenAccent;
    IconData ico = Icons.check_circle_outline;

    if (est == 'En Uso') {
      col = const Color(0xFF007AFF);
      ico = Icons.devices;
    } else if (est == 'Por Probar') {
      col = Colors.amberAccent;
      ico = Icons.help_outline;
    } else if (est == 'En Mantenimiento') {
      col = Colors.orangeAccent;
      ico = Icons.build;
    } else if (est == 'Defectuoso') {
      col = Colors.redAccent;
      ico = Icons.error_outline;
    } else if (est == 'Vendido') {
      col = Colors.purpleAccent;
      ico = Icons.sell;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ico, size: 12, color: col),
          const SizedBox(width: 4),
          Text(
            est.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: col),
          ),
        ],
      ),
    );
  }

  bool _puedeModificarProducto(ProductoModel prod) {
    // 1. Miguel (Admin Principal) posee permisos globales de administración
    if (AuthService.usuarioActual.esAdmin) return true;

    final admin = prod.atributosAdministrativos;
    final String usuarioActual = AuthService.usuarioActual.nombre.trim().toLowerCase();

    // 2. Verificar si el usuario activo está en la lista de Propietarios del activo
    final List<dynamic>? propietarios = admin['propietarios'] as List<dynamic>?;
    if (propietarios != null && propietarios.isNotEmpty) {
      if (propietarios.contains('Todos (OvniCore)')) return true;

      final duenosLower = propietarios.map((e) => e.toString().trim().toLowerCase()).toList();
      if (duenosLower.contains(usuarioActual)) return true;
    }

    // 3. Verificar si el usuario activo fue quien registró el componente
    final registradoPor = (admin['registrado_por'] ?? '').toString().trim().toLowerCase();
    if (registradoPor.isNotEmpty && registradoPor == usuarioActual) return true;

    return false;
  }

  void _cambiarEstadoProducto(BuildContext context, ProductoModel prod) {
    final admin = prod.atributosAdministrativos;

    if (!_puedeModificarProducto(prod)) {
      final List<dynamic>? propietarios = admin['propietarios'] as List<dynamic>?;
      final String duenosStr = (propietarios != null && propietarios.isNotEmpty)
          ? propietarios.join(', ')
          : (admin['registrado_por'] ?? 'su dueño').toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔒 Permiso Denegado: Solo los propietarios del activo ($duenosStr) o Miguel (Admin) pueden modificar o cambiar el estado de este componente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    String estadoActual = (admin['estado_componente'] ?? 'Disponible').toString();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0E1726),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF3AD8FF), width: 1.5),
              ),
              title: Row(
                children: const [
                  Icon(Icons.published_with_changes, color: Color(0xFF3AD8FF)),
                  SizedBox(width: 10),
                  Text('Cambiar Estado del Activo', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activo: ${admin['marca'] ?? ''} ${admin['modelo'] ?? ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    _buildCustomDropdown<String>(
                      labelText: 'Nuevo Estado',
                      value: estadoActual,
                      items: const [
                        DropdownMenuItem(value: 'Disponible', child: Text('🟢 Disponible (Stock)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'En Uso', child: Text('🔵 En Uso (Asignado)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'Por Probar', child: Text('🟡 Por Probar (Sin Verificar)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'En Mantenimiento', child: Text('🟠 En Mantenimiento', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'Defectuoso', child: Text('🔴 Defectuoso (Scrap)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'Vendido', child: Text('🟣 Vendido (Completado)', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (nuevo) {
                        if (nuevo != null) {
                          setStateModal(() {
                            estadoActual = nuevo;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3AD8FF),
                    foregroundColor: const Color(0xFF050B14),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    if (estadoActual == 'Vendido') {
                      _mostrarModalRegistroVenta(context, prod);
                      return;
                    }

                    try {
                      admin['estado_componente'] = estadoActual;
                      await FirebaseFirestore.instance
                          .collection('inventario')
                          .doc(prod.id)
                          .update({
                            'atributosAdministrativos': admin,
                            'atributos_administrativos': admin,
                          });

                      // Registrar auditoría de edición de estado
                      await AuditoriaService.registrarAccion(
                        tipoAccion: 'EDICIÓN',
                        componenteId: prod.id,
                        componenteNombre: '${admin['marca'] ?? ''} ${admin['modelo'] ?? ''}',
                        categoria: prod.categoria,
                        detalles: 'Estado del componente cambiado a "$estadoActual" por ${AuthService.usuarioActual.nombre}',
                      );

                      if (context.mounted) {
                        Navigator.pop(context); // cerrar modal de detalles
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ Estado actualizado a "$estadoActual"'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Error al actualizar estado: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarModalRegistroVenta(BuildContext context, ProductoModel prod) {
    final admin = prod.atributosAdministrativos;

    if (!_puedeModificarProducto(prod)) {
      final List<dynamic>? propietarios = admin['propietarios'] as List<dynamic>?;
      final String duenosStr = (propietarios != null && propietarios.isNotEmpty)
          ? propietarios.join(', ')
          : (admin['registrado_por'] ?? 'su dueño').toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔒 Permiso Denegado: Solo los propietarios del activo ($duenosStr) o Miguel (Admin) pueden colocarlo como VENDIDO.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final double precioCompra = double.tryParse((admin['precio_adquisicion'] ?? '0').toString()) ?? 0.0;
    final TextEditingController precioVentaController = TextEditingController(
      text: (admin['precio_venta'] ?? (precioCompra > 0 ? (precioCompra * 1.3).toStringAsFixed(2) : '')).toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final double precioVenta = double.tryParse(precioVentaController.text.trim().replaceAll(',', '.')) ?? 0.0;
            final double gananciaNeta = precioVenta - precioCompra;
            final double porcentajeGanancia = precioCompra > 0 ? (gananciaNeta / precioCompra) * 100 : 0.0;
            final bool esGanancia = gananciaNeta >= 0;

            final Map<String, dynamic>? aportesRaw = admin['aportes_propietarios'] as Map<String, dynamic>?;
            final List<dynamic>? propietarios = admin['propietarios'] as List<dynamic>?;
            final List<String> listaDuenos = (propietarios != null && propietarios.isNotEmpty)
                ? (propietarios.contains('Todos (OvniCore)') ? ['Miguel', 'Kevin', 'Diego', 'Edgardo'] : propietarios.map((e) => e.toString()).toList())
                : ['Todos (OvniCore)'];

            Map<String, double> aportesMap = {};
            if (aportesRaw != null && aportesRaw.isNotEmpty) {
              aportesRaw.forEach((k, v) {
                aportesMap[k] = double.tryParse(v.toString()) ?? 0.0;
              });
            }

            final double sumaAportes = aportesMap.values.fold(0.0, (a, b) => a + b);
            final double baseCalculo = sumaAportes > 0 ? sumaAportes : (precioCompra > 0 ? precioCompra : 1.0);

            Map<String, Map<String, double>> distribucion = {};
            for (final dueno in listaDuenos) {
              final double aporteIndividual = aportesMap[dueno] ?? (baseCalculo / listaDuenos.length);
              final double proporcion = baseCalculo > 0 ? (aporteIndividual / baseCalculo) : (1.0 / listaDuenos.length);
              final double cobroTotal = precioVenta * proporcion;
              final double gananciaIndiv = gananciaNeta * proporcion;

              distribucion[dueno] = {
                'aporte': aporteIndividual,
                'cobro': cobroTotal,
                'ganancia': gananciaIndiv,
                'porcentaje': proporcion * 100,
              };
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0E1726),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.purpleAccent, width: 2),
              ),
              title: Row(
                children: const [
                  Icon(Icons.monetization_on, color: Colors.purpleAccent),
                  SizedBox(width: 10),
                  Text('Registro de Venta y Margen', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Componente: ${admin['marca'] ?? ''} ${admin['modelo'] ?? ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Ficha de Precio de Compra
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF050B14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('🏷️ Precio de Compra:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Text('\$ ${precioCompra.toStringAsFixed(2)} USD', style: const TextStyle(color: Color(0xFF3AD8FF), fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Input de Precio de Venta
                    TextField(
                      controller: precioVentaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      onChanged: (_) => setStateModal(() {}),
                      decoration: const InputDecoration(
                        labelText: r'Precio Final de Venta (USD $)',
                        labelStyle: TextStyle(color: Colors.purpleAccent, fontSize: 12),
                        prefixIcon: Icon(Icons.attach_money, color: Colors.purpleAccent),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tarjeta de Cálculo de Ganancia
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: esGanancia ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: esGanancia ? Colors.greenAccent : Colors.redAccent, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                esGanancia ? '📈 Ganancia Neta Total:' : '📉 Pérdida Neta Total:',
                                style: TextStyle(color: esGanancia ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                '${esGanancia ? '+' : ''}\$ ${gananciaNeta.toStringAsFixed(2)} USD',
                                style: TextStyle(color: esGanancia ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('📊 Porcentaje de Rentabilidad:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(
                                '${esGanancia ? '+' : ''}${porcentajeGanancia.toStringAsFixed(2)}%',
                                style: TextStyle(color: esGanancia ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Desglose de Reparto por Integrante si hay más de 1 propietario
                    if (listaDuenos.length > 1) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF050B14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF3AD8FF).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.pie_chart, color: Color(0xFF3AD8FF), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  '💵 Reparto de Ingresos por Integrante',
                                  style: TextStyle(color: Color(0xFF3AD8FF), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children: distribucion.entries.map((e) {
                                final user = e.key;
                                final info = e.value;
                                final aporte = info['aporte']!;
                                final cobro = info['cobro']!;
                                final gan = info['ganancia']!;
                                final pct = info['porcentaje']!;
                                final esPos = gan >= 0;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0E1726),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(user, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                          Text('Aportó: \$${aporte.toStringAsFixed(2)} (${pct.toStringAsFixed(1)}%)', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Recibe: \$${cobro.toStringAsFixed(2)} USD',
                                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            'Ganancia: ${esPos ? '+' : ''}\$${gan.toStringAsFixed(2)}',
                                            style: TextStyle(color: esPos ? const Color(0xFF3AD8FF) : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    try {
                      final ahora = DateTime.now();
                      final fechaVenta = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')} ${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';

                      admin['estado_componente'] = 'Vendido';
                      admin['precio_venta'] = precioVenta;
                      admin['ganancia_neta'] = gananciaNeta;
                      admin['porcentaje_ganancia'] = porcentajeGanancia;
                      admin['fecha_venta'] = fechaVenta;
                      admin['reparto_propietarios'] = distribucion.map((k, v) => MapEntry(k, {
                            'aporte': v['aporte'],
                            'recibe': v['cobro'],
                            'ganancia': v['ganancia'],
                            'porcentaje': v['porcentaje'],
                          }));

                      await FirebaseFirestore.instance
                          .collection('inventario')
                          .doc(prod.id)
                          .update({
                            'atributosAdministrativos': admin,
                            'atributos_administrativos': admin,
                          });

                      // Registrar auditoría de venta
                      await AuditoriaService.registrarAccion(
                        tipoAccion: 'EDICIÓN',
                        componenteId: prod.id,
                        componenteNombre: '${admin['marca'] ?? ''} ${admin['modelo'] ?? ''}',
                        categoria: prod.categoria,
                        detalles: 'Vendido por \$${precioVenta.toStringAsFixed(2)} (Ganancia: ${esGanancia ? '+' : ''}${porcentajeGanancia.toStringAsFixed(1)}% / ${esGanancia ? '+' : ''}\$${gananciaNeta.toStringAsFixed(2)}) por ${AuthService.usuarioActual.nombre}',
                      );

                      if (context.mounted) {
                        Navigator.pop(context); // cerrar modal de detalles si abierto
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎉 Componente registrado como VENDIDO por \$${precioVenta.toStringAsFixed(2)} USD!'),
                            backgroundColor: Colors.purpleAccent,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Error al registrar venta: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Confirmar Venta', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCalculadoraPrecioRecomendado(ProductoModel prod) {
    final admin = prod.atributosAdministrativos;
    final double precioCompra = double.tryParse((admin['precio_adquisicion'] ?? '0').toString()) ?? 0.0;
    final String estado = (admin['estado_componente'] ?? '').toString();
    final bool esVendido = estado == 'Vendido';
    double porcentajeDeseado = 30.0;

    return StatefulBuilder(
      builder: (context, setStateCalc) {
        final double precioRecomendado = precioCompra * (1 + (porcentajeDeseado / 100));
        final double gananciaEstimada = precioRecomendado - precioCompra;

        if (esVendido) {
          final double precioVentaReal = double.tryParse((admin['precio_venta'] ?? '0').toString()) ?? 0.0;
          final double gananciaReal = double.tryParse((admin['ganancia_neta'] ?? '0').toString()) ?? (precioVentaReal - precioCompra);
          final double pctReal = double.tryParse((admin['porcentaje_ganancia'] ?? '0').toString()) ?? (precioCompra > 0 ? (gananciaReal / precioCompra) * 100 : 0.0);
          final bool esGanancia = gananciaReal >= 0;

          return Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purpleAccent, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.sell, color: Colors.purpleAccent, size: 18),
                    SizedBox(width: 8),
                    Text('💰 RESUMEN DE VENTA REALIZADA', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Precio de Venta Real:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('\$ ${precioVentaReal.toStringAsFixed(2)} USD', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ganancia Obtenida:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '${esGanancia ? '+' : ''}\$ ${gananciaReal.toStringAsFixed(2)} USD (${esGanancia ? '+' : ''}${pctReal.toStringAsFixed(1)}%)',
                      style: TextStyle(color: esGanancia ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                if (admin['fecha_venta'] != null) ...[
                  const SizedBox(height: 4),
                  Text('Fecha de Venta: ${admin['fecha_venta']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF050B14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3AD8FF).withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.calculate, color: Color(0xFF3AD8FF), size: 18),
                      SizedBox(width: 8),
                      Text('💡 PRECIO RECOMENDADO DE VENTA', style: TextStyle(color: Color(0xFF3AD8FF), fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Text(
                    'Margen: ${porcentajeDeseado.toInt()}%',
                    style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (precioCompra <= 0)
                const Text('⚠️ Ingrese un precio de compra al editar para calcular el precio recomendado.', style: TextStyle(color: Colors.grey, fontSize: 11))
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Precio Recomendado:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '\$ ${precioRecomendado.toStringAsFixed(2)} USD',
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ganancia Estimada:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '+\$ ${gananciaEstimada.toStringAsFixed(2)} USD',
                      style: const TextStyle(color: Color(0xFF3AD8FF), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Ajustar porcentaje de ganancia deseado:', style: TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [15, 25, 30, 40, 50, 75, 100].map((pct) {
                          final isSelected = porcentajeDeseado.toInt() == pct;
                          return ChoiceChip(
                            selected: isSelected,
                            label: Text('$pct%', style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                            selectedColor: Colors.amberAccent,
                            backgroundColor: const Color(0xFF0E1726),
                            onSelected: (selected) {
                              if (selected) {
                                setStateCalc(() {
                                  porcentajeDeseado = pct.toDouble();
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 75,
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        onChanged: (val) {
                          final parsed = double.tryParse(val.replaceAll(',', '.'));
                          if (parsed != null && parsed >= 0) {
                            setStateCalc(() {
                              porcentajeDeseado = parsed;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: '% Personalizado',
                          hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _mostrarDetallesProductoEnLista(BuildContext context, ProductoModel prod) {
    final admin = prod.atributosAdministrativos;
    final specs = prod.especificacionesTecnicas;
    final imagenes = (admin['imagenes_reales'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final fechaHora = admin['fecha_registro'] ?? admin['fecha_instalacion'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0E1726),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF3AD8FF), width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.list_alt, color: Color(0xFF3AD8FF)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${admin['marca'] ?? ''} ${admin['modelo'] ?? ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen destacada del componente / Sticker
                  if (imagenes.isNotEmpty && imagenes.first.trim().isNotEmpty)
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        height: 160,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF050B14),
                          border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.3)),
                        ),
                        child: Image.network(
                          imagenes.first,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.memory, size: 60, color: Color(0xFF3AD8FF)),
                        ),
                      ),
                    ),

                  // SECCIÓN 1: Atributos Generales (Lista)
                  const Text(
                    '📋 INFORMACIÓN GENERAL',
                    style: TextStyle(color: Color(0xFF3AD8FF), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildItemLista(Icons.category, 'Categoría', prod.categoria.replaceAll('_', ' ').toUpperCase()),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.2),
                          foregroundColor: const Color(0xFF3AD8FF),
                          side: const BorderSide(color: Color(0xFF3AD8FF), width: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        icon: const Icon(Icons.published_with_changes, size: 14),
                        label: const Text('Cambiar Estado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => _cambiarEstadoProducto(context, prod),
                      ),
                    ],
                  ),
                  _buildItemLista(Icons.verified, 'Estado Operativo', (admin['estado_componente'] ?? 'Disponible').toString()),
                  _buildItemLista(Icons.person, 'Registrado Por', (admin['registrado_por'] ?? 'Sistema / Previo').toString()),
                  _buildItemLista(Icons.attach_money, 'Precio de Compra (USD)', admin['precio_adquisicion'] != null ? '\$ ${admin['precio_adquisicion']}' : 'No registrado'),
                  if (admin['precio_objetivo_venta'] != null && (double.tryParse(admin['precio_objetivo_venta'].toString()) ?? 0.0) > 0)
                    _buildItemLista(Icons.stars, 'Precio Objetivo de Venta (Deseado)', '\$ ${admin['precio_objetivo_venta']} USD'),
                  _buildItemLista(Icons.group, 'Propietario(s)', (admin['propietarios'] as List?)?.join(', ') ?? 'Todos (OvniCore)'),
                  _buildItemLista(Icons.branding_watermark, 'Marca', (admin['marca'] ?? 'N/A').toString()),
                  _buildItemLista(Icons.devices, 'Modelo', (admin['modelo'] ?? 'N/A').toString()),
                  _buildItemLista(Icons.qr_code, 'ID de Activo', (admin['id_activo'] ?? 'N/A').toString()),
                  _buildCalculadoraPrecioRecomendado(prod),
                  if (admin['ubicacion'] != null)
                    _buildItemLista(Icons.location_on, 'Ubicación', admin['ubicacion'].toString()),
                  _buildItemLista(
                    Icons.access_time_filled,
                    'Fecha y Hora de Registro',
                    (fechaHora != null && fechaHora.toString().trim().isNotEmpty)
                        ? fechaHora.toString()
                        : 'No registrada',
                  ),
                  if (admin['comentarios'] != null && admin['comentarios'].toString().trim().isNotEmpty)
                    _buildItemLista(Icons.comment, 'Comentarios', admin['comentarios'].toString()),

                  const Divider(color: Color(0xFF007AFF), height: 24),

                  // SECCIÓN 2: Especificaciones Técnicas (Lista)
                  const Text(
                    '⚡ ESPECIFICACIONES TÉCNICAS',
                    style: TextStyle(color: Color(0xFF3AD8FF), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 8),
                  if (specs.isEmpty)
                    const Text('No hay especificaciones técnicas detalladas.', style: TextStyle(color: Colors.grey, fontSize: 12))
                  else
                    ...specs.entries.map((entry) {
                      final claveLimpia = entry.key.replaceAll('_', ' ').toUpperCase();
                      return _buildItemLista(Icons.tune, claveLimpia, '${entry.value}');
                    }),

                  const Divider(color: Color(0xFF007AFF), height: 24),

                  // SECCIÓN 3: Compatibilidades Detectadas en Stock
                  _buildSeccionCompatibilidadesStock(prod),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemLista(IconData icon, String titulo, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF050B14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF3AD8FF)),
          const SizedBox(width: 10),
          Text(
            '$titulo: ',
            style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionCompatibilidadesStock(ProductoModel prod) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('inventario').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs;
        final todosLosProds = docs.map((doc) {
          return ProductoModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        final compatibles = CompatibilidadService.obtenerCompatiblesEnInventario(prod, todosLosProds);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF050B14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3AD8FF).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.extension, color: Color(0xFF3AD8FF), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '🧩 COMPATIBILIDADES EN STOCK (${compatibles.length})',
                    style: const TextStyle(color: Color(0xFF3AD8FF), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (compatibles.isEmpty)
                const Text(
                  'No se detectaron piezas compatibles en el inventario actual.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                )
              else
                Column(
                  children: compatibles.take(6).map((item) {
                    final marca = item.atributosAdministrativos['marca'] ?? '';
                    final modelo = item.atributosAdministrativos['modelo'] ?? '';
                    final cat = item.categoria.replaceAll('_', ' ').toUpperCase();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E1726),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$marca $modelo',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  cat,
                                  style: const TextStyle(color: Color(0xFF3AD8FF), fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              '✓ Compatible',
                              style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  void _abrirDialogoFiltros(BuildContext context, List<String> marcasDisponibles) {
    final todasLasMarcas = [..._marcasPopulares, ...marcasDisponibles].toSet().toList()..sort();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final hayFiltrosActivos = _categoriaFiltroSeleccionada != null || _marcaFiltroSeleccionada != null || _estadoFiltroSeleccionado != null;

            return AlertDialog(
              backgroundColor: const Color(0xFF0E1726),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF3AD8FF), width: 1.5),
              ),
              title: Row(
                children: [
                  const Icon(Icons.tune, color: Color(0xFF3AD8FF)),
                  const SizedBox(width: 10),
                  const Text(
                    'Filtros de Búsqueda',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Categoría
                    const Text('Categoría', style: TextStyle(color: Color(0xFF3AD8FF), fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _buildCustomDropdown<String?>(
                      labelText: 'Categoría',
                      value: _categoriaFiltroSeleccionada,
                      hint: const Text('Todas las Categorías', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todas las Categorías', style: TextStyle(color: Colors.grey)),
                        ),
                        ..._categoriasNombres.entries.map((e) => DropdownMenuItem<String?>(
                          value: e.key,
                          child: Text(e.value, style: const TextStyle(color: Colors.white)),
                        )),
                      ],
                      onChanged: (val) {
                        setStateModal(() {});
                        setState(() {
                          _categoriaFiltroSeleccionada = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. Marca
                    const Text('Marca', style: TextStyle(color: Color(0xFF3AD8FF), fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _buildCustomDropdown<String?>(
                      labelText: 'Marca',
                      value: _marcaFiltroSeleccionada,
                      hint: const Text('Todas las Marcas', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todas las Marcas', style: TextStyle(color: Colors.grey)),
                        ),
                        ...todasLasMarcas.map((m) => DropdownMenuItem<String?>(
                          value: m,
                          child: Text(m, style: const TextStyle(color: Colors.white)),
                        )),
                      ],
                      onChanged: (val) {
                        setStateModal(() {});
                        setState(() {
                          _marcaFiltroSeleccionada = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. Estado
                    const Text('Estado del Componente', style: TextStyle(color: Color(0xFF3AD8FF), fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _buildCustomDropdown<String?>(
                      labelText: 'Estado del Componente',
                      value: _estadoFiltroSeleccionado,
                      hint: const Text('Todos los Estados', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      items: const [
                        DropdownMenuItem<String?>(value: null, child: Text('Todos los Estados', style: TextStyle(color: Colors.grey))),
                        DropdownMenuItem<String?>(value: 'Disponible', child: Text('🟢 Disponible', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem<String?>(value: 'En Uso', child: Text('🔵 En Uso', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem<String?>(value: 'Por Probar', child: Text('🟡 Por Probar', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem<String?>(value: 'En Mantenimiento', child: Text('🟠 En Mantenimiento', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem<String?>(value: 'Defectuoso', child: Text('🔴 Defectuoso', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem<String?>(value: 'Vendido', child: Text('🟣 Vendido', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (val) {
                        setStateModal(() {});
                        setState(() {
                          _estadoFiltroSeleccionado = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 4. Ordenamiento
                    const Text('Ordenar Por', style: TextStyle(color: Color(0xFF3AD8FF), fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _buildCustomDropdown<String>(
                      labelText: 'Ordenar Por',
                      value: _ordenSeleccionado,
                      items: const [
                        DropdownMenuItem(value: 'nombre_asc', child: Text('Modelo (A-Z)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'nombre_desc', child: Text('Modelo (Z-A)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'marca_asc', child: Text('Marca (A-Z)', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setStateModal(() {});
                          setState(() {
                            _ordenSeleccionado = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                if (hayFiltrosActivos)
                  TextButton.icon(
                    icon: const Icon(Icons.clear, size: 16, color: Colors.redAccent),
                    label: const Text('Limpiar Filtros', style: TextStyle(color: Colors.redAccent)),
                    onPressed: () {
                      setStateModal(() {});
                      setState(() {
                        _categoriaFiltroSeleccionada = null;
                        _marcaFiltroSeleccionada = null;
                        _estadoFiltroSeleccionado = null;
                      });
                    },
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3AD8FF),
                    foregroundColor: const Color(0xFF050B14),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Aplicar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoConfirmacion(
    BuildContext context,
    String idDocumento,
    String nombreProducto, {
    String categoria = 'General',
  }) {
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

                  // Registrar auditoría de eliminación
                  await AuditoriaService.registrarAccion(
                    tipoAccion: 'ELIMINACIÓN',
                    componenteId: idDocumento,
                    componenteNombre: nombreProducto,
                    categoria: categoria,
                    detalles: 'Eliminado del inventario por ${AuthService.usuarioActual.nombre}',
                  );

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
        ? (widget.categoriaFiltro!.toLowerCase() == 'almacenamiento_ssd_hdd'
            ? 'Inventario - ALMACENAMIENTO (SSD / HDD)'
            : 'Inventario - ${widget.categoriaFiltro!.replaceAll('_', ' ').toUpperCase()}')
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

          // Marcas disponibles extraídas dinámicamente de los productos
          final marcasDisponibles = todosLosProductos
              .map((p) => (p.atributosAdministrativos['marca'] ?? '').toString().trim())
              .where((m) => m.isNotEmpty)
              .toSet()
              .toList()..sort();

          final productosFiltrados = todosLosProductos.where((prod) {
            final admin = prod.atributosAdministrativos;
            final estadoComp = (admin['estado_componente'] ?? 'Disponible').toString();
            if (prod.grupo.toLowerCase() == 'eliminado' ||
                estadoComp.toLowerCase() == 'eliminado' ||
                prod.categoria.toLowerCase() == 'eliminado') {
              return false;
            }

            final queryText = _textoBusqueda.toLowerCase();
            final marcaComp = (admin['marca'] ?? '').toString();
            final modeloComp = (admin['modelo'] ?? '').toString();
            final idActivo = (admin['id_activo'] ?? '').toString();

            // Filtro por texto
            final cumpleQuery = queryText.isEmpty ||
                modeloComp.toLowerCase().contains(queryText) ||
                marcaComp.toLowerCase().contains(queryText) ||
                idActivo.toLowerCase().contains(queryText);

            // Filtro por categoría
            bool cumpleCategoria = true;
            if (_categoriaFiltroSeleccionada != null && _categoriaFiltroSeleccionada!.isNotEmpty) {
              final catFiltro = _categoriaFiltroSeleccionada!.trim().toLowerCase();
              if (catFiltro == 'almacenamiento_ssd_hdd') {
                final cat = prod.categoria.trim().toLowerCase();
                cumpleCategoria = cat == 'almacenamiento_ssd_hdd' || cat == 'ssd_storage' || cat == 'hdd_storage';
              } else {
                cumpleCategoria = prod.categoria.trim().toLowerCase() == catFiltro;
              }
            }

            // Filtro por marca
            final cumpleMarca = _marcaFiltroSeleccionada == null ||
                marcaComp.toLowerCase() == _marcaFiltroSeleccionada!.toLowerCase();

            // Filtro por estado (Por defecto los productos VENDIDOS se quitan de la lista de componentes disponibles)
            final bool esVendido = estadoComp.toLowerCase() == 'vendido';
            final cumpleEstado = _estadoFiltroSeleccionado == null
                ? !esVendido
                : estadoComp.toLowerCase() == _estadoFiltroSeleccionado!.toLowerCase();

            return cumpleQuery && cumpleCategoria && cumpleMarca && cumpleEstado;
          }).toList();

          // Ordenamiento dinámico
          if (_ordenSeleccionado == 'nombre_asc') {
            productosFiltrados.sort((a, b) {
              final mA = (a.atributosAdministrativos['modelo'] ?? '').toString();
              final mB = (b.atributosAdministrativos['modelo'] ?? '').toString();
              return mA.toLowerCase().compareTo(mB.toLowerCase());
            });
          } else if (_ordenSeleccionado == 'nombre_desc') {
            productosFiltrados.sort((a, b) {
              final mA = (a.atributosAdministrativos['modelo'] ?? '').toString();
              final mB = (b.atributosAdministrativos['modelo'] ?? '').toString();
              return mB.toLowerCase().compareTo(mA.toLowerCase());
            });
          } else if (_ordenSeleccionado == 'marca_asc') {
            productosFiltrados.sort((a, b) {
              final mA = (a.atributosAdministrativos['marca'] ?? '').toString();
              final mB = (b.atributosAdministrativos['marca'] ?? '').toString();
              return mA.toLowerCase().compareTo(mB.toLowerCase());
            });
          }

          return Column(
            children: [
              // Barra de Búsqueda con Símbolo de Filtros
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Expanded(
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
                    const SizedBox(width: 12),
                    // BOTÓN DE SÍMBOLO DE FILTROS (Icons.tune)
                    InkWell(
                      onTap: () => _abrirDialogoFiltros(context, marcasDisponibles),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1726),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (_categoriaFiltroSeleccionada != null || _marcaFiltroSeleccionada != null || _estadoFiltroSeleccionado != null)
                                ? const Color(0xFF3AD8FF)
                                : const Color(0xFF007AFF).withValues(alpha: 0.4),
                            width: (_categoriaFiltroSeleccionada != null || _marcaFiltroSeleccionada != null || _estadoFiltroSeleccionado != null) ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.tune,
                              color: Color(0xFF3AD8FF),
                              size: 22,
                            ),
                            if (_categoriaFiltroSeleccionada != null || _marcaFiltroSeleccionada != null || _estadoFiltroSeleccionado != null)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3AD8FF),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                          final isInterno = prod.grupo == 'componentes_internos';
                          final esCritico = admin['id_activo'] == '001';

                          bool isHovered = false;
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return MouseRegion(
                                onEnter: (_) => setState(() => isHovered = true),
                                onExit: (_) => setState(() => isHovered = false),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0E1726),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isHovered 
                                          ? const Color(0xFF3AD8FF) 
                                          : (esCritico ? const Color(0xFF3AD8FF) : const Color(0xFF007AFF).withValues(alpha: 0.3)),
                                      width: isHovered ? 1.8 : 1.0,
                                    ),
                                    boxShadow: isHovered
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF3AD8FF).withValues(alpha: 0.2),
                                              blurRadius: 10,
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: InkWell(
                                    onTap: () => _mostrarDetallesProductoEnLista(context, prod),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                                            radius: 22,
                                            child: ClipOval(
                                              child: (admin['imagenes_reales'] != null &&
                                                      (admin['imagenes_reales'] as List).isNotEmpty &&
                                                      (admin['imagenes_reales'][0] as String).trim().isNotEmpty)
                                                  ? Image.network(
                                                    (admin['imagenes_reales'][0] as String).trim(),
                                                    width: 36,
                                                    height: 36,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Icon(
                                                        esCritico ? Icons.warning_amber : (isInterno ? Icons.developer_board : Icons.monitor),
                                                        color: const Color(0xFF3AD8FF),
                                                      );
                                                    },
                                                  )
                                                  : Icon(
                                                    esCritico ? Icons.warning_amber : (isInterno ? Icons.developer_board : Icons.monitor),
                                                    color: const Color(0xFF3AD8FF),
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        '${admin['marca'] ?? ''} ${admin['modelo'] ?? ''}'.trim(),
                                                        style: TextStyle(
                                                          color: isHovered ? const Color(0xFF3AD8FF) : Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    _buildEstadoBadge(admin['estado_componente']?.toString()),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    Text(
                                                      'ID: ${admin['id_activo'] ?? 'N/A'}',
                                                      style: const TextStyle(color: Color(0xFF3AD8FF), fontSize: 11, fontWeight: FontWeight.bold),
                                                    ),
                                                    Text('•', style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                                                    Text(
                                                      prod.categoria.replaceAll('_', ' ').toUpperCase(),
                                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                                    ),
                                                    if (admin['precio_adquisicion'] != null && (admin['precio_adquisicion'] as num) > 0) ...[
                                                      Text('•', style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                                                      Text(
                                                        '\$ ${admin['precio_adquisicion']}',
                                                        style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                    Text('•', style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                                                    Text(
                                                      'Prop: ${(admin['propietarios'] as List?)?.join(', ') ?? 'Todos'}',
                                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.list_alt, color: Color(0xFF3AD8FF), size: 20),
                                                tooltip: 'Ver detalles completos',
                                                onPressed: () => _mostrarDetallesProductoEnLista(context, prod),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                                tooltip: 'Eliminar activo',
                                                onPressed: () => _mostrarDialogoConfirmacion(
                                                  context,
                                                  prod.id,
                                                  '${admin['marca'] ?? ''} ${admin['modelo'] ?? ''}',
                                                  categoria: prod.categoria,
                                                ),
                                              ),
                                            ],
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
