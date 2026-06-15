import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/producto_model.dart';
import 'package:intl/intl.dart';

class AgregarProductoScreen extends StatefulWidget {
  const AgregarProductoScreen({super.key});

  @override
  State<AgregarProductoScreen> createState() => _AgregarProductoScreenState();
}

class _AgregarProductoScreenState extends State<AgregarProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _categoriaSeleccionada;
  final Map<String, dynamic> _specsDinamicas = {};

  // Controladores de texto para atributos fijos
  final _idActivoController = TextEditingController();
  final _marcaController = TextEditingController(); 
  final _modeloController = TextEditingController();

  // Variables extras de Atributos Administrativos Condicionados
  final _fechaInstalacionController = TextEditingController();
  final _marcaEnsambladorController = TextEditingController();
  String? _fabricanteChipGPU;
  final _comentariosController = TextEditingController();
  final _imagenRealController = TextEditingController();

  // Estado para el control de flujos dinámicos de CPU
  String? _marcaCpuSeleccionada;
  String? _socketCpuSeleccionado;

  // Repositorio de Sockets por Marca de Ingeniería
  final List<String> _socketsAMD = ['AM4', 'AM5', 'sTRX4', 'sWRX8'];
  final List<String> _socketsIntel = [
    'LGA 1150',
    'LGA 1151',
    'LGA 1155',
    'LGA 1200',
    'LGA 1366',
    'LGA 1700',
    'LGA 1851',
    'LGA 2011',
    'LGA 2066',
    'LGA 4677',
  ];

  final List<Map<String, String>> _categorias = [
    // Internos
    {'value': 'procesador_cpu', 'label': '🖥️ Procesador (CPU)'},
    {'value': 'tarjeta_madre', 'label': '🖥️ Tarjeta Madre (Motherboard)'},
    {'value': 'memoria_ram', 'label': '📏 Memoria RAM'},
    {'value': 'ssd_storage', 'label': '💽 Almacenamiento SSD'},
    {'value': 'hdd_storage', 'label': '💾 Almacenamiento HDD'},
    {'value': 'tarjeta_grafica', 'label': '🎮 Tarjeta Gráfica (GPU)'},
    {'value': 'fuente_poder', 'label': '⚡ Fuente de Poder (PSU)'},
    {'value': 'gabinete_chasis', 'label': '🖥️ Gabinete / Chasis'},
    {'value': 'disipador_cpu', 'label': '❄️ Disipador de CPU'},
    {'value': 'ventiladores_chasis', 'label': '🌀 Ventiladores de Chasis'},
    // Externos
    {'value': 'monitor', 'label': '🖱️ Monitor'},
    {'value': 'teclado', 'label': '⌨️ Teclado'},
    {'value': 'mouse', 'label': '🖱️ Mouse'},
    {'value': 'auriculares_altavoces', 'label': '🎧 Auriculares y Audio'},
  ];

  @override
  void dispose() {
    _idActivoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _fechaInstalacionController.dispose();
    _marcaEnsambladorController.dispose();
    super.dispose();
  }

  void _limpiarFormulario() {
    _idActivoController.clear();
    _marcaController.clear();
    _modeloController.clear();
    _fechaInstalacionController.clear();
    _marcaEnsambladorController.clear();
    _specsDinamicas.clear();
    setState(() {
      _categoriaSeleccionada = null;
      _marcaCpuSeleccionada = null;
      _socketCpuSeleccionado = null;
      _fabricanteChipGPU = null;
    });
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _fechaInstalacionController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _guardarProductoEnFirestore() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final componentesInternos = [
        'procesador_cpu', 'tarjeta_madre', 'memoria_ram', 'ssd_storage', 
        'hdd_storage', 'tarjeta_grafica', 'fuente_poder', 'gabinete_chasis', 
        'disipador_cpu', 'ventiladores_chasis'
      ];
      String grupo = componentesInternos.contains(_categoriaSeleccionada) 
          ? 'componentes_internos' 
          : 'componentes_externos';

      // Construcción del mapa de Atributos Administrativos base
      Map<String, dynamic> atributosAdministrativos = {
        'modelo': _modeloController.text.trim(),
      };

      // Excepción ID Activo (oculto/opcional en PSU)
      if (_categoriaSeleccionada != 'fuente_poder') {
        atributosAdministrativos['id_activo'] = _idActivoController.text.trim();
      } else {
        atributosAdministrativos['id_activo'] = _idActivoController.text.trim().isNotEmpty 
            ? _idActivoController.text.trim() 
            : 'PSU-N/A';
      }

      // Excepciones Marca/GPU
      if (_categoriaSeleccionada == 'tarjeta_grafica') {
        atributosAdministrativos['marca_ensamblador'] = _marcaEnsambladorController.text.trim();
        atributosAdministrativos['fabricante_chip'] = _fabricanteChipGPU ?? '';
      } else {
        atributosAdministrativos['marca'] = _marcaController.text.trim();
      }

      // Excepciones Fecha de Instalación
      if (['memoria_ram', 'gabinete_chasis', 'disipador_cpu', 'ventiladores_chasis'].contains(_categoriaSeleccionada)) {
        atributosAdministrativos['fecha_instalacion'] = _fechaInstalacionController.text.trim();
      }

      // Comentarios e Imágenes
      atributosAdministrativos['comentarios'] = _comentariosController.text.trim();
      if (_imagenRealController.text.trim().isNotEmpty) {
        atributosAdministrativos['imagenes_reales'] = [_imagenRealController.text.trim()];
      } else {
        atributosAdministrativos['imagenes_reales'] = [];
      }

      final productoAEnviar = ProductoModel(
        id: '',
        grupo: grupo,
        categoria: _categoriaSeleccionada!,
        atributosAdministrativos: atributosAdministrativos,
        especificacionesTecnicas: _specsDinamicas.isEmpty
            ? {'configurado': false}
            : Map<String, dynamic>.from(_specsDinamicas),
      );

      await FirebaseFirestore.instance
          .collection('inventario')
          .add(productoAEnviar.toMap());

      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🛸 Componente registrado exitosamente en el inventario',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      _limpiarFormulario();
    } catch (error) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error en el servidor: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool mostrarFechaInstalacion = ['memoria_ram', 'gabinete_chasis', 'disipador_cpu', 'ventiladores_chasis'].contains(_categoriaSeleccionada);
    bool esGPU = _categoriaSeleccionada == 'tarjeta_grafica';
    bool esPSU = _categoriaSeleccionada == 'fuente_poder';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/img/icon_ovnicore.png', width: 30, height: 30),
            const SizedBox(width: 10),
            const Text('Nuevo Activo - OvniCore'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Selecciona la Categoría',
                  border: OutlineInputBorder(),
                ),
                value: _categoriaSeleccionada,
                items: _categorias
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat['value'],
                        child: Text(cat['label']!),
                      ),
                    )
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    _categoriaSeleccionada = newValue;
                    _specsDinamicas.clear();
                    _marcaCpuSeleccionada = null;
                    _socketCpuSeleccionado = null;
                    _fabricanteChipGPU = null;
                    _marcaController.clear();
                    _marcaEnsambladorController.clear();
                    _fechaInstalacionController.clear();
                    _comentariosController.clear();
                    _imagenRealController.clear();
                  });
                },
              ),
              const SizedBox(height: 24),

              if (_categoriaSeleccionada != null) ...[
                const Text(
                  'Atributos Administrativos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3AD8FF),
                  ),
                ),
                const SizedBox(height: 12),

                // ID Activo
                if (!esPSU)
                  TextFormField(
                    controller: _idActivoController,
                    decoration: const InputDecoration(
                      labelText: 'ID de Activo',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val!.isEmpty ? 'Campo obligatorio' : null,
                  )
                else
                  TextFormField(
                    controller: _idActivoController,
                    decoration: const InputDecoration(
                      labelText: 'ID de Activo (Opcional para Fuentes de Poder)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 12),

                // Marca vs Ensamblador y Fabricante (GPU)
                if (esGPU) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _marcaEnsambladorController,
                          decoration: const InputDecoration(
                            labelText: 'Marca del Ensamblador (ej: ASUS, MSI)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val!.isEmpty ? 'Campo obligatorio' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Fabricante del Chip',
                            border: OutlineInputBorder(),
                          ),
                          value: _fabricanteChipGPU,
                          items: const [
                            DropdownMenuItem(value: 'NVIDIA', child: Text('NVIDIA')),
                            DropdownMenuItem(value: 'AMD', child: Text('AMD')),
                            DropdownMenuItem(value: 'Intel', child: Text('Intel')),
                          ],
                          validator: (val) => val == null ? 'Seleccione fabricante' : null,
                          onChanged: (val) {
                            setState(() {
                              _fabricanteChipGPU = val;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ] else if (_categoriaSeleccionada == 'procesador_cpu') ...[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Marca del Procesador',
                      border: OutlineInputBorder(),
                    ),
                    value: _marcaCpuSeleccionada,
                    items: const [
                      DropdownMenuItem(value: 'AMD', child: Text('AMD')),
                      DropdownMenuItem(value: 'Intel', child: Text('Intel')),
                    ],
                    validator: (val) =>
                        val == null ? 'Seleccione una marca' : null,
                    onChanged: (val) {
                      setState(() {
                        _marcaCpuSeleccionada = val;
                        _marcaController.text = val ?? ''; 
                        _socketCpuSeleccionado = null; 
                        _specsDinamicas.remove('socket_compatible');
                      });
                    },
                  )
                ] else ...[
                  TextFormField(
                    controller: _marcaController,
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val!.isEmpty ? 'Campo obligatorio' : null,
                  ),
                ],
                const SizedBox(height: 12),

                // Modelo
                TextFormField(
                  controller: _modeloController,
                  decoration: const InputDecoration(
                    labelText: 'Modelo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val!.isEmpty ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 12),

                // Fecha de Instalación (Condicional)
                if (mostrarFechaInstalacion)
                  TextFormField(
                    controller: _fechaInstalacionController,
                    readOnly: true,
                    onTap: () => _seleccionarFecha(context),
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Instalación',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (val) => val!.isEmpty ? 'Seleccione fecha' : null,
                  ),

                if (mostrarFechaInstalacion) const SizedBox(height: 12),

                TextFormField(
                  controller: _comentariosController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Comentarios / Observaciones del Operador',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _imagenRealController,
                  decoration: const InputDecoration(
                    labelText: 'URL de Imagen Real del Componente',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Especificaciones Técnicas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007AFF),
                  ),
                ),
                const SizedBox(height: 12),
                _construirCamposTecnicosDinamicos(),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: const Color(0xFF3AD8FF),
                  foregroundColor: const Color(0xFF050B14),
                ),
                onPressed: _guardarProductoEnFirestore,
                child: const Text(
                  'Guardar Componente en Almacén',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }

  Widget _construirCamposTecnicosDinamicos() {
    switch (_categoriaSeleccionada) {
      case 'procesador_cpu':
        List<String> socketsDisponibles = [];
        if (_marcaCpuSeleccionada == 'AMD') {
          socketsDisponibles = _socketsAMD;
        } else if (_marcaCpuSeleccionada == 'Intel') {
          socketsDisponibles = _socketsIntel;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Socket Compatible',
                border: OutlineInputBorder(),
              ),
              value: _socketCpuSeleccionado,
              items: _marcaCpuSeleccionada == null
                  ? null
                  : socketsDisponibles
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
              hint: Text(
                _marcaCpuSeleccionada == null
                    ? '⚠️ Seleccione la marca primero'
                    : 'Seleccione el socket compatible',
              ),
              validator: (val) =>
                  val == null ? 'Seleccione un socket compatible' : null,
              onChanged: _marcaCpuSeleccionada == null
                  ? null
                  : (val) {
                      setState(() {
                        _socketCpuSeleccionado = val;
                        _specsDinamicas['socket_compatible'] = val;
                      });
                    },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Núcleos Físicos',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) =>
                        _specsDinamicas['cantidad_nucleos_fisicos'] =
                            int.tryParse(val) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hilos de Procesamiento',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) =>
                        _specsDinamicas['cantidad_hilos_procesamiento'] =
                            int.tryParse(val) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Frecuencia Base (GHz)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => _specsDinamicas['frecuencia_base_ghz'] =
                        double.tryParse(val) ?? 0.0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Frecuencia Turbo (GHz)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) =>
                        _specsDinamicas['frecuencia_turbo_ghz'] =
                            double.tryParse(val) ?? 0.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Consumo Energético (TDP en Watts)',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) =>
                  _specsDinamicas['consumo_energetico_tdp_watts'] =
                      int.tryParse(val) ?? 0,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('¿Posee Gráficos Integrados?'),
              value: _specsDinamicas['graficos_integrados'] ?? false,
              onChanged: (bool value) {
                setState(() {
                  _specsDinamicas['graficos_integrados'] = value;
                });
              },
            ),
          ],
        );

      case 'tarjeta_madre':
        List<String> todosLosSockets = [..._socketsAMD, ..._socketsIntel];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Factor de Forma',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ATX', child: Text('ATX')),
                DropdownMenuItem(value: 'Micro-ATX', child: Text('Micro-ATX')),
                DropdownMenuItem(value: 'Mini-ITX', child: Text('Mini-ITX')),
                DropdownMenuItem(value: 'E-ATX', child: Text('E-ATX')),
              ],
              validator: (val) =>
                  val == null ? 'Seleccione un factor de forma' : null,
              onChanged: (val) => _specsDinamicas['factor_forma'] = val,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Chipset (ej: B550, Z790)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => _specsDinamicas['chipset'] = val.trim(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Socket',
                      border: OutlineInputBorder(),
                    ),
                    items: todosLosSockets
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    validator: (val) => val == null ? 'Obligatorio' : null,
                    onChanged: (val) => _specsDinamicas['socket'] = val,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ranuras RAM',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) =>
                        _specsDinamicas['cantidad_ranuras_ram'] =
                            int.tryParse(val) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Memoria',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'DDR4', child: Text('DDR4')),
                      DropdownMenuItem(value: 'DDR5', child: Text('DDR5')),
                    ],
                    validator: (val) => val == null ? 'Obligatorio' : null,
                    onChanged: (val) =>
                        _specsDinamicas['tipo_memoria_soportada'] = val,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Puertos M.2 NVMe',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) =>
                        _specsDinamicas['puertos_m2_disponibles'] =
                            int.tryParse(val) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Puertos SATA III',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => _specsDinamicas['puertos_sata_iii'] =
                        int.tryParse(val) ?? 0,
                  ),
                ),
              ],
            ),
          ],
        );

      case 'memoria_ram':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacidad Total (GB)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['capacidad_total_gb'] = int.tryParse(val) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cantidad Módulos', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['cantidad_modulos'] = int.tryParse(val) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Tipo Memoria', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'DDR4', child: Text('DDR4')),
                      DropdownMenuItem(value: 'DDR5', child: Text('DDR5')),
                    ],
                    onChanged: (val) => _specsDinamicas['tipo_memoria'] = val,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Velocidad/Frecuencia (MHz)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['velocidad_frecuencia'] = int.tryParse(val) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Latencia CAS (CL)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['latencia_cas_cl'] = int.tryParse(val) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Voltaje de Operación (V)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['voltaje_operacion'] = double.tryParse(val) ?? 0.0,
                  ),
                ),
              ],
            ),
          ],
        );

      case 'ssd_storage':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Tipo/Tecnología', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'NVMe M.2', child: Text('NVMe M.2')),
                      DropdownMenuItem(value: 'SATA', child: Text('SATA')),
                    ],
                    onChanged: (val) => _specsDinamicas['tipo_tecnologia'] = val,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Interfaz (ej: PCIe 4.0)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['interfaz_conexion'] = val.trim(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Capacidad Total (ej: 1TB)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['capacidad_total'] = val.trim(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Vida Útil (TBW)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['vida_util_tbw'] = int.tryParse(val) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Velocidad Lectura (MB/s)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['velocidad_lectura_mb_s'] = int.tryParse(val) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Velocidad Escritura (MB/s)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['velocidad_escritura_mb_s'] = int.tryParse(val) ?? 0,
                  ),
                ),
              ],
            ),
          ],
        );

      case 'hdd_storage':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Interfaz (ej: SATA III)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['interfaz_conexion'] = val.trim(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Capacidad Total (ej: 2TB)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['capacidad_total'] = val.trim(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Factor de Forma', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: '3.5"', child: Text('3.5"')),
                      DropdownMenuItem(value: '2.5"', child: Text('2.5"')),
                    ],
                    onChanged: (val) => _specsDinamicas['factor_forma'] = val,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Velocidad RPM', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['velocidad_rotacion_rpm'] = int.tryParse(val) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Caché (MB)', border: OutlineInputBorder()),
              onChanged: (val) => _specsDinamicas['memoria_cache_mb'] = int.tryParse(val) ?? 0,
            ),
          ],
        );

      case 'tarjeta_grafica':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Arquitectura/Chip', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['arquitectura_chip'] = val.trim(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Interfaz/Puerto (ej: PCIe 4.0 x16)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['interfaz_puerto_pcie'] = val.trim(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacidad VRAM (GB)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['capacidad_vram_gb'] = int.tryParse(val) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Tipo VRAM', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'GDDR6', child: Text('GDDR6')),
                      DropdownMenuItem(value: 'GDDR6X', child: Text('GDDR6X')),
                    ],
                    onChanged: (val) => _specsDinamicas['tipo_vram'] = val,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Bus (Bits)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['interfaz_bus_bits'] = int.tryParse(val) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Puertos Video (ej: 3x DP, 1x HDMI)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['puertos_salida_video'] = val.trim(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Conectores Energía (ej: 2x 8-pin)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['conectores_alimentacion'] = val.trim(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Consumo Max (Watts)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['consumo_energetico_max_watts'] = int.tryParse(val) ?? 0,
                  ),
                ),
              ],
            ),
          ],
        );

      case 'fuente_poder':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Potencia Max (Watts)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['potencia_maxima_watts'] = int.tryParse(val) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Certificación', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: '80 Plus White', child: Text('80 Plus White')),
                      DropdownMenuItem(value: '80 Plus Bronze', child: Text('80 Plus Bronze')),
                      DropdownMenuItem(value: '80 Plus Silver', child: Text('80 Plus Silver')),
                      DropdownMenuItem(value: '80 Plus Gold', child: Text('80 Plus Gold')),
                      DropdownMenuItem(value: '80 Plus Platinum', child: Text('80 Plus Platinum')),
                      DropdownMenuItem(value: '80 Plus Titanium', child: Text('80 Plus Titanium')),
                    ],
                    onChanged: (val) => _specsDinamicas['certificacion_eficiencia'] = val,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Modularidad', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'No modular', child: Text('No modular')),
                      DropdownMenuItem(value: 'Semi-modular', child: Text('Semi-modular')),
                      DropdownMenuItem(value: 'Full modular', child: Text('Full modular')),
                    ],
                    onChanged: (val) => _specsDinamicas['tipo_modularidad'] = val,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Factor de Forma', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'ATX', child: Text('ATX')),
                      DropdownMenuItem(value: 'SFX', child: Text('SFX')),
                    ],
                    onChanged: (val) => _specsDinamicas['factor_forma'] = val,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Protecciones Activas (OVP, UVP, OPP...)', border: OutlineInputBorder()),
              onChanged: (val) => _specsDinamicas['protecciones_activas'] = val.trim(),
            ),
          ],
        );

      case 'gabinete_chasis':
        return Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Placas soportadas (ej: ATX, Micro-ATX)', border: OutlineInputBorder()),
              onChanged: (val) => _specsDinamicas['formatos_placa_soportados'] = val.trim(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Materiales (ej: Acero, Cristal)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['materiales_construccion'] = val.trim(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Bahías', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['bahias_unidades'] = val.trim(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max Altura Disipador (mm)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['altura_max_disipador_mm'] = int.tryParse(val) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max Longitud GPU (mm)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['longitud_max_gpu_mm'] = int.tryParse(val) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Puertos Panel Frontal (ej: 2x USB 3.0, Audio)', border: OutlineInputBorder()),
              onChanged: (val) => _specsDinamicas['puertos_panel_frontal'] = val.trim(),
            ),
          ],
        );

      case 'disipador_cpu':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Tipo Disipación', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Aire', child: Text('Aire')),
                      DropdownMenuItem(value: 'Líquida/AIO', child: Text('Líquida/AIO')),
                    ],
                    onChanged: (val) => _specsDinamicas['tipo_disipacion'] = val,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Sockets (ej: AM4, LGA 1700)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['sockets_compatibles'] = val.trim(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ventiladores Incluidos', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['cantidad_ventiladores'] = int.tryParse(val) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tamaño Radiador/Ventiladores (mm)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['tamano_radiador_ventiladores_mm'] = int.tryParse(val) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Material Bloque/Tubos', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['material_bloque'] = val.trim(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Altura/Grosor Total (mm)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['altura_total_bloque_mm'] = int.tryParse(val) ?? 0,
                  ),
                ),
              ],
            ),
          ],
        );

      case 'ventiladores_chasis':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Dimensiones (mm) [Ej. 120]', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['dimensiones_fisicas_mm'] = int.tryParse(val) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Tipo de Rodamiento', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Fluido', child: Text('Fluido')),
                      DropdownMenuItem(value: 'Magnético', child: Text('Magnético')),
                      DropdownMenuItem(value: 'Bolas', child: Text('Bolas')),
                    ],
                    onChanged: (val) => _specsDinamicas['tipo_rodamiento'] = val,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Flujo de Aire (CFM)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['flujo_aire_cfm'] = double.tryParse(val) ?? 0.0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Presión Estática (mmH2O)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['presion_estatica_mmh2o'] = double.tryParse(val) ?? 0.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Nivel Ruido (dBA)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['nivel_ruido_dba'] = double.tryParse(val) ?? 0.0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Conectores (ej: 4-pin PWM, 3-pin ARGB)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['conectores'] = val.trim(),
                  ),
                ),
              ],
            ),
          ],
        );

      case 'monitor':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Tamaño (Pulgadas)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['tamano_pulgadas'] = double.tryParse(val) ?? 0.0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Tipo de Panel', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'IPS', child: Text('IPS')),
                      DropdownMenuItem(value: 'VA', child: Text('VA')),
                      DropdownMenuItem(value: 'TN', child: Text('TN')),
                      DropdownMenuItem(value: 'OLED', child: Text('OLED')),
                    ],
                    onChanged: (val) => _specsDinamicas['tipo_panel'] = val,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Resolución (ej: 1920x1080)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['resolucion'] = val.trim(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Frecuencia Refresco (Hz)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['frecuencia_hz'] = int.tryParse(val) ?? 0,
                  ),
                ),
              ],
            ),
          ],
        );

      case 'teclado':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Mecánico', child: Text('Mecánico')),
                      DropdownMenuItem(value: 'Membrana', child: Text('Membrana')),
                    ],
                    onChanged: (val) => _specsDinamicas['tipo'] = val,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Conectividad', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Inalámbrico', child: Text('Inalámbrico')),
                      DropdownMenuItem(value: 'Alámbrico', child: Text('Alámbrico')),
                    ],
                    onChanged: (val) => _specsDinamicas['conectividad'] = val,
                  ),
                ),
              ],
            ),
          ],
        );

      case 'mouse':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'DPI Máximo', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['dpi_maximo'] = int.tryParse(val) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Conectividad', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Inalámbrico', child: Text('Inalámbrico')),
                      DropdownMenuItem(value: 'Alámbrico', child: Text('Alámbrico')),
                    ],
                    onChanged: (val) => _specsDinamicas['conectividad'] = val,
                  ),
                ),
              ],
            ),
          ],
        );

      case 'auriculares_altavoces':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Formato', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Auriculares (Headset)', child: Text('Auriculares (Headset)')),
                      DropdownMenuItem(value: 'Altavoces (Speakers)', child: Text('Altavoces (Speakers)')),
                    ],
                    onChanged: (val) => _specsDinamicas['formato'] = val,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Conectividad', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Bluetooth', child: Text('Bluetooth')),
                      DropdownMenuItem(value: 'USB', child: Text('USB')),
                      DropdownMenuItem(value: 'Jack 3.5mm', child: Text('Jack 3.5mm')),
                    ],
                    onChanged: (val) => _specsDinamicas['conectividad'] = val,
                  ),
                ),
              ],
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
