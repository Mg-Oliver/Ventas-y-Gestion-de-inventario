import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/producto_model.dart';
import '../../data/services/componentes_api_service.dart';
import '../../data/services/security_service.dart';
import '../../data/services/auditoria_service.dart';
import '../../data/services/auth_service.dart';
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
  final _otraMarcaController = TextEditingController();
  final _precioAdquisicionController = TextEditingController();
  final _precioObjetivoVentaController = TextEditingController();
  double _porcentajeMargenDeseadoForm = 30.0;
  final _botTrapHoneypotController = TextEditingController();

  bool _esPropiedadTodos = true;
  final Set<String> _propietariosSeleccionados = {'Miguel', 'Kevin', 'Diego', 'Edgardo'};
  final Map<String, TextEditingController> _aportesControllers = {};

  TextEditingController _obtenerControladorAporte(String user) {
    if (!_aportesControllers.containsKey(user)) {
      _aportesControllers[user] = TextEditingController();
    }
    return _aportesControllers[user]!;
  }

  // Controladores para Especificaciones Técnicas Autocompletadas de CPU
  final _cpuNucleosController = TextEditingController();
  final _cpuHilosController = TextEditingController();
  final _cpuFreqBaseController = TextEditingController();
  final _cpuFreqTurboController = TextEditingController();
  final _cpuTdpController = TextEditingController();
  final _cpuGraficosController = TextEditingController();
  bool _specsEditables = false;
  bool _esGratisSinCosto = false;
  String _estadoSeleccionado = 'Disponible';

  String? _marcaSeleccionada;
  bool _isSearchingImage = false;
  List<String> _obtenerMarcasPorCategoria(String? categoria) {
    switch (categoria) {
      case 'procesador_cpu':
        return [
          'AMD',
          'Intel',
          'Qualcomm',
          'Apple',
          'MediaTek',
          'ARM',
          'Otra marca',
        ];

      case 'tarjeta_madre':
        return [
          'ASUS',
          'MSI',
          'Gigabyte',
          'ASRock',
          'NZXT',
          'EVGA',
          'Biostar',
          'Huananzhi',
          'Machinist',
          'Maxsun',
          'Jginyue',
          'Onda',
          'ColorFul',
          'Otra marca',
        ];

      case 'memoria_ram':
        return [
          'Corsair',
          'Kingston',
          'Crucial',
          'G.Skill',
          'TeamGroup',
          'ADATA',
          'XPG',
          'Samsung',
          'HyperX',
          'Patriot',
          'Silicon Power',
          'GeIL',
          'Lexar',
          'PNY',
          'Kllisre',
          'Jingsha',
          'Netac',
          'Juhor',
          'Otra marca',
        ];

      case 'almacenamiento_ssd_hdd':
        return [
          'Samsung',
          'Western Digital',
          'Seagate',
          'Crucial',
          'Kingston',
          'ADATA',
          'XPG',
          'SanDisk',
          'Lexar',
          'TeamGroup',
          'PNY',
          'Corsair',
          'Sabrent',
          'Toshiba',
          'SK Hynix',
          'Netac',
          'Silicon Power',
          'Hikvision',
          'Fanxiang',
          'KingSpec',
          'Otra marca',
        ];

      case 'tarjeta_grafica':
        return [
          'ASUS',
          'MSI',
          'Gigabyte',
          'Zotac',
          'Sapphire',
          'PowerColor',
          'XFX',
          'ASRock',
          'PNY',
          'EVGA',
          'Palit',
          'Gainward',
          'Galax',
          'KFA2',
          'Inno3D',
          'ColorFul',
          'Manli',
          'Maxsun',
          'Sparkle',
          'Peladn',
          'Jingsha',
          'Intel',
          'AMD',
          'NVIDIA',
          'Otra marca',
        ];

      case 'fuente_poder':
        return [
          'Corsair',
          'EVGA',
          'Seasonic',
          'Thermaltake',
          'Cooler Master',
          'be quiet!',
          'DeepCool',
          'MSI',
          'Gigabyte',
          'ASUS',
          'XPG',
          'Redragon',
          'Cougar',
          'Gamdias',
          'AeroCool',
          'AZZA',
          'SilverStone',
          'Super Flower',
          'GameMax',
          'Apevia',
          'Otra marca',
        ];

      case 'gabinete_chasis':
        return [
          'Corsair',
          'NZXT',
          'Lian Li',
          'Cooler Master',
          'Thermaltake',
          'DeepCool',
          'Fractal Design',
          'Phanteks',
          'be quiet!',
          'HYTE',
          'Montech',
          'MSI',
          'ASUS',
          'Antec',
          'AeroCool',
          'Redragon',
          'GameMax',
          'Cougar',
          'Kolink',
          'BitFenix',
          'Otra marca',
        ];

      case 'disipador_cpu':
        return [
          'Noctua',
          'DeepCool',
          'Cooler Master',
          'Thermalright',
          'ARCTIC',
          'be quiet!',
          'Corsair',
          'NZXT',
          'Thermaltake',
          'ID-COOLING',
          'Valkyrie',
          'Zalman',
          'Cougar',
          'Lian Li',
          'Jonsbo',
          'UpHere',
          'Otra marca',
        ];

      case 'ventiladores_chasis':
        return [
          'Noctua',
          'ARCTIC',
          'Corsair',
          'Lian Li',
          'DeepCool',
          'be quiet!',
          'Thermalright',
          'Cooler Master',
          'Phanteks',
          'Thermaltake',
          'NZXT',
          'Antec',
          'InWin',
          'ID-COOLING',
          'UpHere',
          'AeroCool',
          'Otra marca',
        ];

      case 'monitor':
        return [
          'ASUS',
          'LG',
          'Samsung',
          'AOC',
          'BenQ',
          'Acer',
          'Dell',
          'MSI',
          'Gigabyte',
          'ViewSonic',
          'Philips',
          'HP',
          'Koorui',
          'Xiaomi',
          'Huawei',
          'Ozone',
          'Sceptre',
          'TCL',
          'Lenovo',
          'Otra marca',
        ];

      case 'teclado':
        return [
          'Logitech',
          'Razer',
          'Redragon',
          'Corsair',
          'HyperX',
          'Keychron',
          'SteelSeries',
          'Royal Kludge',
          'VSG',
          'Epomaker',
          'Glorious',
          'ASUS',
          'Ducky',
          'Terport',
          'Motospeed',
          'Akko',
          'Cougar',
          'Otra marca',
        ];

      case 'mouse':
        return [
          'Logitech',
          'Razer',
          'Redragon',
          'Corsair',
          'HyperX',
          'SteelSeries',
          'Glorious',
          'VSG',
          'ASUS',
          'Pulsar',
          'Lamzu',
          'Ninjutso',
          'VXE / VGN',
          'Attack Shark',
          'WLmouse',
          'Finalmouse',
          'Zowie',
          'Delux',
          'Otra marca',
        ];

      case 'auriculares_altavoces':
        return [
          'HyperX',
          'Razer',
          'Logitech',
          'Corsair',
          'Astro',
          'SteelSeries',
          'JBL',
          'Sony',
          'Sennheiser',
          'Audio-Technica',
          'Redragon',
          'VSG',
          'Fifine',
          'Fantech',
          'Edifier',
          'Baseus',
          'Bose',
          'Kz',
          'Tangzu',
          'Otra marca',
        ];

      default:
        return [
          'AMD',
          'Intel',
          'ASUS',
          'MSI',
          'Gigabyte',
          'Corsair',
          'Kingston',
          'Crucial',
          'Samsung',
          'Western Digital',
          'Logitech',
          'Razer',
          'Redragon',
          'HP',
          'Dell',
          'Lenovo',
          'Otra marca',
        ];
    }
  }

  final List<String> _opcionesImagenesApi = [];
  String? _imagenApiSeleccionada;

  Future<void> _buscarOpcionesImagenesApi() async {
    final marca = _categoriaSeleccionada == 'tarjeta_grafica'
        ? (_fabricanteChipGPU ?? _marcaEnsambladorController.text.trim())
        : (_marcaCpuSeleccionada ?? _marcaController.text.trim());
    final modelo = _modeloController.text.trim();

    if (marca.isEmpty && modelo.isEmpty) return;

    setState(() {
      _isSearchingImage = true;
      _opcionesImagenesApi.clear();
    });

    try {
      final imagenes = await ComponentesApiService.buscarListaImagenesComponente(marca, modelo);
      if (mounted) {
        setState(() {
          _opcionesImagenesApi.clear();
          _opcionesImagenesApi.addAll(imagenes);
          if (imagenes.isNotEmpty) {
            _imagenApiSeleccionada = imagenes.first;
            _imagenRealController.text = imagenes.first;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isSearchingImage = false);
    }
  }

  Future<void> _buscarImagenComponente() async {
    await _buscarOpcionesImagenesApi();
    if (_opcionesImagenesApi.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚡ ¡Se encontraron ${_opcionesImagenesApi.length} opciones de imágenes en la API!'),
          backgroundColor: const Color(0xFF007AFF),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔍 No se encontraron imágenes en la API para este modelo')),
      );
    }
  }

  // Estado para el control de flujos dinámicos de CPU
  String? _marcaCpuSeleccionada;
  String? _socketCpuSeleccionado;
  String? _tipoProcesadorSeleccionado;
  String? _modeloCpuSeleccionado;
  final _otroModeloCpuController = TextEditingController();

  final List<String> _tiposIntel = [
    'Core i3',
    'Core i5',
    'Core i7',
    'Core i9',
    'Core Ultra 5',
    'Core Ultra 7',
    'Core Ultra 9',
    'Xeon',
    'Pentium / Celeron',
    'Otro tipo',
  ];

  final List<String> _tiposAMD = [
    'Ryzen 3',
    'Ryzen 5',
    'Ryzen 7',
    'Ryzen 9',
    'Ryzen Threadripper',
    'EPYC',
    'Athlon',
    'Otro tipo',
  ];

  final Map<String, List<String>> _modelosPorTipo = {
    // INTEL CORE i3
    'Core i3': [
      'i3-14100F', 'i3-14100', 'i3-13100F', 'i3-13100', 'i3-12100F', 'i3-12100', 'i3-10325', 'i3-10320', 'i3-10305', 'i3-10300', 
      'i3-10105F', 'i3-10105', 'i3-10100F', 'i3-10100', 'i3-9350KF', 'i3-9320', 'i3-9300', 'i3-9100F', 'i3-9100', 'i3-8350K', 
      'i3-8300', 'i3-8100', 'i3-7350K', 'i3-7320', 'i3-7300', 'i3-7100', 'i3-6320', 'i3-6300', 'i3-6100', 'i3-4370', 
      'i3-4360', 'i3-4170', 'i3-4160', 'i3-4150', 'i3-4130', 'i3-3250', 'i3-3240', 'i3-3220', 'i3-2130', 'i3-2120', 'i3-2100', 'i3-540', 'i3-530', 'Otro modelo'
    ],
    // INTEL CORE i5
    'Core i5': [
      'i5-14600K', 'i5-14600KF', 'i5-14600', 'i5-14500', 'i5-14400F', 'i5-14400', 'i5-13600K', 'i5-13600KF', 'i5-13600', 'i5-13500', 
      'i5-13400F', 'i5-13400', 'i5-12600K', 'i5-12600KF', 'i5-12600', 'i5-12500', 'i5-12400F', 'i5-12400', 'i5-11600K', 'i5-11600KF', 
      'i5-11600', 'i5-11500', 'i5-11400F', 'i5-11400', 'i5-10600K', 'i5-10600KF', 'i5-10600', 'i5-10500', 'i5-10400F', 'i5-10400', 
      'i5-9600K', 'i5-9600KF', 'i5-9500', 'i5-9400F', 'i5-9400', 'i5-8600K', 'i5-8500', 'i5-8400', 'i5-7600K', 'i5-7600', 'i5-7500', 
      'i5-7400', 'i5-6600K', 'i5-6600', 'i5-6500', 'i5-6400', 'i5-4690K', 'i5-4690', 'i5-4590', 'i5-4460', 'i5-3570K', 'i5-3570', 'i5-3470', 'i5-2500K', 'i5-2500', 'i5-2400', 'i5-750', 'i5-650', 'Otro modelo'
    ],
    // INTEL CORE i7
    'Core i7': [
      'i7-14700K', 'i7-14700KF', 'i7-14700F', 'i7-14700', 'i7-13700K', 'i7-13700KF', 'i7-13700F', 'i7-13700', 'i7-12700K', 'i7-12700KF', 
      'i7-12700F', 'i7-12700', 'i7-11700K', 'i7-11700KF', 'i7-11700F', 'i7-11700', 'i7-10700K', 'i7-10700KF', 'i7-10700F', 'i7-10700', 
      'i7-9700K', 'i7-9700KF', 'i7-9700F', 'i7-9700', 'i7-8700K', 'i7-8700', 'i7-7700K', 'i7-7700', 'i7-6700K', 'i7-6700', 'i7-5960X', 
      'i7-5820K', 'i7-4790K', 'i7-4790', 'i7-4770K', 'i7-4770', 'i7-3770K', 'i7-3770', 'i7-2700K', 'i7-2600K', 'i7-920', 'Otro modelo'
    ],
    // INTEL CORE i9
    'Core i9': [
      'i9-14900KS', 'i9-14900K', 'i9-14900KF', 'i9-14900F', 'i9-14900', 'i9-13900KS', 'i9-13900K', 'i9-13900KF', 'i9-13900F', 'i9-13900', 
      'i9-12900KS', 'i9-12900K', 'i9-12900KF', 'i9-12900F', 'i9-12900', 'i9-11900K', 'i9-11900KF', 'i9-11900F', 'i9-11900', 'i9-10900K', 
      'i9-10900KF', 'i9-10900F', 'i9-10900', 'i9-9900KS', 'i9-9900K', 'i9-9900KF', 'i9-9900', 'i9-7980XE', 'i9-7900X', 'Otro modelo'
    ],
    // INTEL CORE ULTRA
    'Core Ultra 5': ['Ultra 5 245K', 'Ultra 5 245KF', 'Ultra 5 135H', 'Ultra 5 125H', 'Otro modelo'],
    'Core Ultra 7': ['Ultra 7 265K', 'Ultra 7 265KF', 'Ultra 7 165H', 'Ultra 7 155H', 'Otro modelo'],
    'Core Ultra 9': ['Ultra 9 285K', 'Ultra 9 185H', 'Otro modelo'],
    // INTEL XEON
    'Xeon': ['W-3495X', 'W-3475X', 'W-3375', 'W-2295', 'W-2195', 'Gold 6454H', 'Gold 6330', 'Gold 6248R', 'Silver 4314', 'Silver 4310', 'Silver 4210R', 'Bronze 3408U', 'E5-2699 v4', 'E5-2697 v4', 'E5-2690 v4', 'E5-2680 v4', 'E5-2670 v3', 'E5-2650 v3', 'E5-2620 v3', 'E3-1270 v6', 'E3-1230 v5', 'Otro modelo'],
    // INTEL PENTIUM / CELERON
    'Pentium / Celeron': ['Pentium Gold G7400', 'Pentium Gold G6605', 'Pentium Gold G6405', 'Pentium Gold G6400', 'Pentium Gold G5620', 'Pentium Gold G5420', 'Pentium G4560', 'Pentium G4400', 'Pentium G3258', 'Celeron G5925', 'Celeron G5905', 'Celeron G4930', 'Celeron G3930', 'Otro modelo'],

    // AMD RYZEN 3
    'Ryzen 3': ['5300G', '4100', '3300X', '3100', '3200G', '2200G', '1300X', '1200', 'Otro modelo'],
    // AMD RYZEN 5
    'Ryzen 5': [
      '9600X', '7600X', '7600', '7500F', '5600X3D', '5600X', '5600', '5600G', '5600GT', '5500GT', '5500', '4600G', 
      '4500', '3600XT', '3600X', '3600', '2600X', '2600', '1600X', '1600', '1500X', '1400', 'Otro modelo'
    ],
    // AMD RYZEN 7
    'Ryzen 7': [
      '9700X', '7800X3D', '7700X', '7700', '5800X3D', '5800X', '5700X3D', '5700X', '5700G', '5700', '3800XT', 
      '3800X', '3700X', '2700X', '2700', '1800X', '1700X', '1700', 'Otro modelo'
    ],
    // AMD RYZEN 9
    'Ryzen 9': [
      '9950X', '9900X', '7950X3D', '7950X', '7900X3D', '7900X', '7900', '5950X', '5900X', '3950X', '3900X', '3900XT', '3900', 'Otro modelo'
    ],
    // AMD THREADRIPPER
    'Ryzen Threadripper': [
      'PRO 7995WX', 'PRO 7985WX', 'PRO 7975WX', 'PRO 7965WX', '7980X', '7970X', '7960X', 'PRO 5995WX', 'PRO 5975WX', 
      'PRO 3995WX', '3990X', '3970X', '3960X', '2990WX', '2970WX', '2950X', '2920X', '1950X', '1920X', '1900X', 'Otro modelo'
    ],
    // AMD EPYC
    'EPYC': ['9654', '9554', '9354', '7763', '7713', '7543', '7443', '7313', '7003', 'Otro modelo'],
    // AMD ATHLON
    'Athlon': ['3000G', '240GE', '220GE', '200GE', 'Athlon X4 950', 'Athlon X4 860K', 'Otro modelo'],
  };

  void _actualizarModeloCpu() {
    if (_tipoProcesadorSeleccionado == null) {
      _modeloController.clear();
      return;
    }

    if (_tipoProcesadorSeleccionado == 'Otro tipo') {
      _modeloController.text = _otroModeloCpuController.text.trim();
    } else if (_modeloCpuSeleccionado == 'Otro modelo') {
      final prefix = _tipoProcesadorSeleccionado!;
      final customVal = _otroModeloCpuController.text.trim();
      _modeloController.text = customVal.isNotEmpty ? '$prefix $customVal' : prefix;
    } else if (_modeloCpuSeleccionado != null) {
      final line = _tipoProcesadorSeleccionado!;
      final mod = _modeloCpuSeleccionado!;
      if (mod.startsWith('i3-') || mod.startsWith('i5-') || mod.startsWith('i7-') || mod.startsWith('i9-') || mod.startsWith('Ultra ')) {
        _modeloController.text = mod;
      } else {
        _modeloController.text = '$line $mod';
      }
    }

    if (_modeloController.text.trim().isNotEmpty) {
      _buscarOpcionesImagenesApi();
      _autocompletarEspecificacionesCpu(_modeloController.text.trim());
    }
  }

  Future<void> _seleccionarImagenLocal() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final base64String = base64Encode(file.bytes!);
          final extension = file.extension ?? 'png';
          final dataUrl = 'data:image/$extension;base64,$base64String';

          setState(() {
            _imagenApiSeleccionada = null;
            _imagenRealController.text = dataUrl;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Imagen cargada correctamente'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al seleccionar la imagen: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _autocompletarEspecificacionesCpu(String modelo) {
    if (modelo.isEmpty) return;
    final modUpper = modelo.toUpperCase();

    String socket = 'LGA 1700';
    int nucleos = 8;
    int hilos = 16;
    double freqBase = 3.6;
    double freqTurbo = 5.0;
    int tdp = 65;
    bool igpu = true;

    if (modUpper.contains('KF') || modUpper.endsWith('F') || modUpper.contains('7500F')) {
      igpu = false;
    }

    if (modUpper.contains('I9') || modUpper.contains('9950') || modUpper.contains('7950')) {
      if (modUpper.contains('14900')) {
        socket = 'LGA 1700'; nucleos = 24; hilos = 32; freqBase = 3.2; freqTurbo = 6.0; tdp = 125;
      } else if (modUpper.contains('13900')) {
        socket = 'LGA 1700'; nucleos = 24; hilos = 32; freqBase = 3.0; freqTurbo = 5.8; tdp = 125;
      } else if (modUpper.contains('12900')) {
        socket = 'LGA 1700'; nucleos = 16; hilos = 24; freqBase = 3.2; freqTurbo = 5.2; tdp = 125;
      } else if (modUpper.contains('11900') || modUpper.contains('10900')) {
        socket = 'LGA 1200'; nucleos = 10; hilos = 20; freqBase = 3.5; freqTurbo = 5.3; tdp = 125;
      } else if (modUpper.contains('9900')) {
        socket = 'LGA 1151'; nucleos = 8; hilos = 16; freqBase = 3.6; freqTurbo = 5.0; tdp = 95;
      } else if (modUpper.contains('9950X')) {
        socket = 'AM5'; nucleos = 16; hilos = 32; freqBase = 4.3; freqTurbo = 5.7; tdp = 170; igpu = true;
      } else if (modUpper.contains('7950X3D')) {
        socket = 'AM5'; nucleos = 16; hilos = 32; freqBase = 4.2; freqTurbo = 5.7; tdp = 120; igpu = true;
      } else if (modUpper.contains('7950X')) {
        socket = 'AM5'; nucleos = 16; hilos = 32; freqBase = 4.5; freqTurbo = 5.7; tdp = 170; igpu = true;
      } else if (modUpper.contains('5950X')) {
        socket = 'AM4'; nucleos = 16; hilos = 32; freqBase = 3.4; freqTurbo = 4.9; tdp = 105; igpu = false;
      } else if (modUpper.contains('5900X')) {
        socket = 'AM4'; nucleos = 12; hilos = 24; freqBase = 3.7; freqTurbo = 4.8; tdp = 105; igpu = false;
      }
    } else if (modUpper.contains('I7') || modUpper.contains('9700') || modUpper.contains('7800') || modUpper.contains('7700') || modUpper.contains('5800') || modUpper.contains('5700') || modUpper.contains('3700') || modUpper.contains('2700')) {
      if (modUpper.contains('14700')) {
        socket = 'LGA 1700'; nucleos = 20; hilos = 28; freqBase = 3.4; freqTurbo = 5.6; tdp = 125;
      } else if (modUpper.contains('13700')) {
        socket = 'LGA 1700'; nucleos = 16; hilos = 24; freqBase = 3.4; freqTurbo = 5.4; tdp = 125;
      } else if (modUpper.contains('12700')) {
        socket = 'LGA 1700'; nucleos = 12; hilos = 20; freqBase = 3.6; freqTurbo = 5.0; tdp = 125;
      } else if (modUpper.contains('11700') || modUpper.contains('10700')) {
        socket = 'LGA 1200'; nucleos = 8; hilos = 16; freqBase = 2.9; freqTurbo = 4.9; tdp = 65;
      } else if (modUpper.contains('9700')) {
        socket = 'LGA 1151'; nucleos = 8; hilos = 8; freqBase = 3.6; freqTurbo = 4.9; tdp = 95;
      } else if (modUpper.contains('8700')) {
        socket = 'LGA 1151'; nucleos = 6; hilos = 12; freqBase = 3.7; freqTurbo = 4.7; tdp = 95;
      } else if (modUpper.contains('7800X3D')) {
        socket = 'AM5'; nucleos = 8; hilos = 16; freqBase = 4.2; freqTurbo = 5.0; tdp = 120; igpu = true;
      } else if (modUpper.contains('7700X') || modUpper.contains('9700X')) {
        socket = 'AM5'; nucleos = 8; hilos = 16; freqBase = 4.5; freqTurbo = 5.4; tdp = 105; igpu = true;
      } else if (modUpper.contains('5800X3D')) {
        socket = 'AM4'; nucleos = 8; hilos = 16; freqBase = 3.4; freqTurbo = 4.5; tdp = 105; igpu = false;
      } else if (modUpper.contains('5800X') || modUpper.contains('5700X')) {
        socket = 'AM4'; nucleos = 8; hilos = 16; freqBase = 3.8; freqTurbo = 4.7; tdp = 105; igpu = false;
      } else if (modUpper.contains('5700G')) {
        socket = 'AM4'; nucleos = 8; hilos = 16; freqBase = 3.8; freqTurbo = 4.6; tdp = 65; igpu = true;
      } else if (modUpper.contains('3700X') || modUpper.contains('2700X')) {
        socket = 'AM4'; nucleos = 8; hilos = 16; freqBase = 3.6; freqTurbo = 4.4; tdp = 65; igpu = false;
      }
    } else if (modUpper.contains('I5') || modUpper.contains('9600') || modUpper.contains('7600') || modUpper.contains('7500') || modUpper.contains('5600') || modUpper.contains('5500') || modUpper.contains('3600') || modUpper.contains('2600')) {
      if (modUpper.contains('14600')) {
        socket = 'LGA 1700'; nucleos = 14; hilos = 20; freqBase = 3.5; freqTurbo = 5.3; tdp = 125;
      } else if (modUpper.contains('13600')) {
        socket = 'LGA 1700'; nucleos = 14; hilos = 20; freqBase = 3.5; freqTurbo = 5.1; tdp = 125;
      } else if (modUpper.contains('13400') || modUpper.contains('14400')) {
        socket = 'LGA 1700'; nucleos = 10; hilos = 16; freqBase = 2.5; freqTurbo = 4.6; tdp = 65;
      } else if (modUpper.contains('12600')) {
        socket = 'LGA 1700'; nucleos = 10; hilos = 16; freqBase = 3.7; freqTurbo = 4.9; tdp = 125;
      } else if (modUpper.contains('12400')) {
        socket = 'LGA 1700'; nucleos = 6; hilos = 12; freqBase = 2.5; freqTurbo = 4.4; tdp = 65;
      } else if (modUpper.contains('11400') || modUpper.contains('10400')) {
        socket = 'LGA 1200'; nucleos = 6; hilos = 12; freqBase = 2.6; freqTurbo = 4.4; tdp = 65;
      } else if (modUpper.contains('9600X') || modUpper.contains('7600X')) {
        socket = 'AM5'; nucleos = 6; hilos = 12; freqBase = 4.7; freqTurbo = 5.3; tdp = 105; igpu = true;
      } else if (modUpper.contains('7600')) {
        socket = 'AM5'; nucleos = 6; hilos = 12; freqBase = 3.8; freqTurbo = 5.1; tdp = 65; igpu = true;
      } else if (modUpper.contains('7500F')) {
        socket = 'AM5'; nucleos = 6; hilos = 12; freqBase = 3.7; freqTurbo = 5.0; tdp = 65; igpu = false;
      } else if (modUpper.contains('5600G') || modUpper.contains('5600GT')) {
        socket = 'AM4'; nucleos = 6; hilos = 12; freqBase = 3.9; freqTurbo = 4.4; tdp = 65; igpu = true;
      } else if (modUpper.contains('5600') || modUpper.contains('5500')) {
        socket = 'AM4'; nucleos = 6; hilos = 12; freqBase = 3.5; freqTurbo = 4.4; tdp = 65; igpu = false;
      } else if (modUpper.contains('3600') || modUpper.contains('2600')) {
        socket = 'AM4'; nucleos = 6; hilos = 12; freqBase = 3.6; freqTurbo = 4.2; tdp = 65; igpu = false;
      }
    } else if (modUpper.contains('I3') || modUpper.contains('5300') || modUpper.contains('4100') || modUpper.contains('3300') || modUpper.contains('3100') || modUpper.contains('3200')) {
      if (modUpper.contains('14100') || modUpper.contains('13100') || modUpper.contains('12100')) {
        socket = 'LGA 1700'; nucleos = 4; hilos = 8; freqBase = 3.4; freqTurbo = 4.5; tdp = 60;
      } else if (modUpper.contains('10100') || modUpper.contains('10105')) {
        socket = 'LGA 1200'; nucleos = 4; hilos = 8; freqBase = 3.7; freqTurbo = 4.4; tdp = 65;
      } else if (modUpper.contains('3200G') || modUpper.contains('2200G') || modUpper.contains('5300G')) {
        socket = 'AM4'; nucleos = 4; hilos = 4; freqBase = 3.6; freqTurbo = 4.0; tdp = 65; igpu = true;
      } else if (modUpper.contains('4100') || modUpper.contains('3100') || modUpper.contains('3300')) {
        socket = 'AM4'; nucleos = 4; hilos = 8; freqBase = 3.8; freqTurbo = 4.0; tdp = 65; igpu = false;
      }
    } else if (modUpper.contains('ULTRA 9')) {
      socket = 'LGA 1851'; nucleos = 24; hilos = 24; freqBase = 3.7; freqTurbo = 5.7; tdp = 125; igpu = true;
    } else if (modUpper.contains('ULTRA 7')) {
      socket = 'LGA 1851'; nucleos = 20; hilos = 20; freqBase = 3.9; freqTurbo = 5.5; tdp = 125; igpu = true;
    } else if (modUpper.contains('ULTRA 5')) {
      socket = 'LGA 1851'; nucleos = 14; hilos = 14; freqBase = 4.2; freqTurbo = 5.2; tdp = 125; igpu = true;
    }

    _socketCpuSeleccionado = socket;
    _specsDinamicas['socket_compatible'] = socket;

    _cpuNucleosController.text = nucleos.toString();
    _specsDinamicas['cantidad_nucleos_fisicos'] = nucleos;

    _cpuHilosController.text = hilos.toString();
    _specsDinamicas['cantidad_hilos_procesamiento'] = hilos;

    _cpuFreqBaseController.text = freqBase.toString();
    _specsDinamicas['frecuencia_base_ghz'] = freqBase;

    _cpuFreqTurboController.text = freqTurbo.toString();
    _specsDinamicas['frecuencia_turbo_ghz'] = freqTurbo;

    _cpuTdpController.text = tdp.toString();
    _specsDinamicas['consumo_energetico_tdp_watts'] = tdp;

    final igpuText = igpu ? 'Sí' : 'No';
    _cpuGraficosController.text = igpuText;
    _specsDinamicas['graficos_integrados'] = igpuText;
  }

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
    {'value': 'almacenamiento_ssd_hdd', 'label': '💾 Almacenamiento (SSD / HDD)'},
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
  void initState() {
    super.initState();
    _actualizarIdActivoSecuencial(null);
  }

  @override
  void dispose() {
    _idActivoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _fechaInstalacionController.dispose();
    _marcaEnsambladorController.dispose();
    _otraMarcaController.dispose();
    _otroModeloCpuController.dispose();
    _cpuNucleosController.dispose();
    _cpuHilosController.dispose();
    _cpuFreqBaseController.dispose();
    _cpuFreqTurboController.dispose();
    _cpuTdpController.dispose();
    _cpuGraficosController.dispose();
    _precioAdquisicionController.dispose();
    _precioObjetivoVentaController.dispose();
    for (final c in _aportesControllers.values) {
      c.dispose();
    }
    _botTrapHoneypotController.dispose();
    super.dispose();
  }

  Future<String> _generarIdActivoSecuencial(String? categoria) async {
    final String prefijo;
    switch (categoria) {
      case 'procesador':
        prefijo = 'CPU';
        break;
      case 'tarjeta_grafica':
        prefijo = 'GPU';
        break;
      case 'memoria_ram':
        prefijo = 'RAM';
        break;
      case 'almacenamiento':
      case 'almacenamiento_ssd_hdd':
        prefijo = 'SSD';
        break;
      case 'placa_madre':
      case 'tarjeta_madre':
        prefijo = 'MB';
        break;
      case 'fuente_poder':
        prefijo = 'PSU';
        break;
      case 'gabinete_chasis':
        prefijo = 'CASE';
        break;
      case 'disipador_cpu':
        prefijo = 'COOL';
        break;
      case 'ventiladores_chasis':
        prefijo = 'FAN';
        break;
      case 'monitor':
        prefijo = 'MON';
        break;
      case 'teclado':
        prefijo = 'KB';
        break;
      case 'mouse':
        prefijo = 'MS';
        break;
      case 'auriculares_altavoces':
        prefijo = 'AUDIO';
        break;
      default:
        prefijo = 'ACT';
    }

    try {
      final snap = await FirebaseFirestore.instance.collection('inventario').get();
      int maxSecuencia = 0;

      for (final doc in snap.docs) {
        final data = doc.data();
        final catDoc = (data['categoria'] ?? '').toString();
        final admin = data['atributosAdministrativos'] as Map<String, dynamic>? ?? {};
        final idActivo = (admin['id_activo'] ?? '').toString().toUpperCase();

        if (catDoc == categoria || idActivo.startsWith('$prefijo-')) {
          final match = RegExp(r'(\d+)').firstMatch(idActivo);
          if (match != null) {
            final numVal = int.tryParse(match.group(1)!) ?? 0;
            if (numVal > maxSecuencia) {
              maxSecuencia = numVal;
            }
          } else {
            maxSecuencia++;
          }
        }
      }

      final siguienteNumero = maxSecuencia + 1;
      return '$prefijo-${siguienteNumero.toString().padLeft(3, '0')}';
    } catch (_) {
      return '$prefijo-001';
    }
  }

  Future<void> _actualizarIdActivoSecuencial(String? categoria) async {
    final nuevoId = await _generarIdActivoSecuencial(categoria);
    if (mounted) {
      setState(() {
        _idActivoController.text = nuevoId;
      });
    }
  }

  void _limpiarFormulario() {
    _actualizarIdActivoSecuencial(null);
    _marcaController.clear();
    _modeloController.clear();
    _fechaInstalacionController.clear();
    _marcaEnsambladorController.clear();
    _otraMarcaController.clear();
    _otroModeloCpuController.clear();
    _cpuNucleosController.clear();
    _cpuHilosController.clear();
    _cpuFreqBaseController.clear();
    _cpuFreqTurboController.clear();
    _cpuTdpController.clear();
    _cpuGraficosController.clear();
    _precioAdquisicionController.clear();
    _precioObjetivoVentaController.clear();
    _opcionesImagenesApi.clear();
    _imagenApiSeleccionada = null;
    _specsDinamicas.clear();
    setState(() {
      _categoriaSeleccionada = null;
      _marcaCpuSeleccionada = null;
      _socketCpuSeleccionado = null;
      _fabricanteChipGPU = null;
      _marcaSeleccionada = null;
      _tipoProcesadorSeleccionado = null;
      _modeloCpuSeleccionado = null;
      _estadoSeleccionado = 'Disponible';
      _esPropiedadTodos = true;
      _propietariosSeleccionados.addAll(['Miguel', 'Kevin', 'Diego', 'Edgardo']);
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

  Future<bool> _mostrarDesafioCaptcha(BuildContext context) async {
    final rand = Random();
    final a = rand.nextInt(10) + 1;
    final b = rand.nextInt(10) + 1;
    final respuestaCorrecta = a + b;
    final respuestaController = TextEditingController();
    String? errorTexto;

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
                  Icon(Icons.shield, color: Color(0xFF3AD8FF)),
                  SizedBox(width: 10),
                  Text(
                    'Verificación Anti-Bot',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Se detectaron múltiples envíos rápidos. Por favor resuelve este problema matemático para confirmar que eres humano:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF050B14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿Cuánto es $a + $b ?',
                          style: const TextStyle(
                            color: Color(0xFF3AD8FF),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: respuestaController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Ingresa tu respuesta',
                      labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                      errorText: errorTexto,
                      filled: true,
                      fillColor: const Color(0xFF050B14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF007AFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF3AD8FF), width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3AD8FF),
                    foregroundColor: const Color(0xFF050B14),
                  ),
                  onPressed: () {
                    final valInt = int.tryParse(respuestaController.text.trim());
                    if (valInt == respuestaCorrecta) {
                      Navigator.pop(dialogContext, true);
                    } else {
                      setStateModal(() {
                        errorTexto = '❌ Respuesta incorrecta. Intenta de nuevo.';
                      });
                    }
                  },
                  child: const Text('Verificar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    return resultado ?? false;
  }

  Future<void> _guardarProductoEnFirestore() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Verificación Trampa Honeypot Anti-Bot
    if (SecurityService.esAtaqueBotDetectado(_botTrapHoneypotController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛑 Operación bloqueada por el sistema de protección Anti-Bot.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 2. Verificación de Rate Limiting
    final errorRateLimit = SecurityService.validarRateLimit();
    if (errorRateLimit != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorRateLimit),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // 3. Verificación de Seguridad en la URL de Imagen
    final urlImg = _imagenRealController.text.trim();
    if (!SecurityService.esUrlImagenSegura(urlImg)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ La URL de la imagen ingresada no es válida o contiene código no seguro.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 4. Verificación CAPTCHA si hay envíos repetidos recientes
    if (SecurityService.requiereVerificacionCaptcha()) {
      final esHumano = await _mostrarDesafioCaptcha(context);
      if (!esHumano) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Verificación Anti-Bot no superada. Registro cancelado.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final componentesInternos = [
        'procesador_cpu', 'tarjeta_madre', 'memoria_ram', 'almacenamiento_ssd_hdd',
        'ssd_storage', 'hdd_storage', 'tarjeta_grafica', 'fuente_poder', 'gabinete_chasis', 
        'disipador_cpu', 'ventiladores_chasis'
      ];
      String grupo = componentesInternos.contains(_categoriaSeleccionada) 
          ? 'componentes_internos' 
          : 'componentes_externos';

      // Sanitizar texto contra inyecciones XSS / Scripts
      final modeloSanitizado = SecurityService.sanitizarTexto(_modeloController.text);
      final marcaSanitizada = SecurityService.sanitizarTexto(_marcaController.text);
      final marcaEnsambladorSanitizada = SecurityService.sanitizarTexto(_marcaEnsambladorController.text);
      final comentariosSanitizados = SecurityService.sanitizarTexto(_comentariosController.text);
      final String idActivoSanitizado = await _generarIdActivoSecuencial(_categoriaSeleccionada);

      final double precioParsed = double.tryParse(_precioAdquisicionController.text.trim().replaceAll(',', '.')) ?? 0.0;
      final double precioObjetivoParsed = double.tryParse(_precioObjetivoVentaController.text.trim().replaceAll(',', '.')) ?? (precioParsed > 0 ? precioParsed * 1.30 : 0.0);

      final propietariosLista = _esPropiedadTodos
          ? ['Todos (OvniCore)']
          : _propietariosSeleccionados.toList();

      final listPropietariosActivos = _esPropiedadTodos
          ? ['Miguel', 'Kevin', 'Diego', 'Edgardo']
          : _propietariosSeleccionados.toList();

      final Map<String, double> aportesMap = {};
      for (final p in listPropietariosActivos) {
        final ctrl = _aportesControllers[p];
        final val = ctrl != null ? double.tryParse(ctrl.text.trim().replaceAll(',', '.')) ?? 0.0 : 0.0;
        aportesMap[p] = val;
      }

      final double sumaAportes = aportesMap.values.fold(0.0, (a, b) => a + b);

      // VALIDACIÓN DE CONTROL DE ERRORES: Los aportes no pueden superar el precio de compra
      if (precioParsed > 0 && listPropietariosActivos.length > 1 && sumaAportes > (precioParsed + 0.01)) {
        final exceso = sumaAportes - precioParsed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: La suma de aportes (\$${sumaAportes.toStringAsFixed(2)}) excede el precio de compra (\$${precioParsed.toStringAsFixed(2)}) por +\$${exceso.toStringAsFixed(2)} USD.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      if (sumaAportes <= 0 && precioParsed > 0 && listPropietariosActivos.isNotEmpty) {
        final cuotaIgual = precioParsed / listPropietariosActivos.length;
        for (final p in listPropietariosActivos) {
          aportesMap[p] = cuotaIgual;
        }
      }

      final ahora = DateTime.now();
      final fechaHoraRegistro = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')} ${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}:${ahora.second.toString().padLeft(2, '0')}';
      Map<String, dynamic> atributosAdministrativos = {
        'modelo': modeloSanitizado,
        'fecha_registro': fechaHoraRegistro,
        'registrado_por': AuthService.usuarioActual.nombre,
        'estado_componente': _estadoSeleccionado,
        'precio_adquisicion': precioParsed,
        'precio_objetivo_venta': precioObjetivoParsed,
        'propietarios': propietariosLista,
        'aportes_propietarios': aportesMap,
      };

      // Excepción ID Activo
      if (_categoriaSeleccionada != 'fuente_poder') {
        atributosAdministrativos['id_activo'] = idActivoSanitizado;
      } else {
        atributosAdministrativos['id_activo'] = idActivoSanitizado.isNotEmpty 
            ? idActivoSanitizado 
            : 'PSU-N/A';
      }

      // Excepciones Marca/GPU
      if (_categoriaSeleccionada == 'tarjeta_grafica') {
        atributosAdministrativos['marca_ensamblador'] = marcaEnsambladorSanitizada;
        atributosAdministrativos['fabricante_chip'] = _fabricanteChipGPU ?? '';
      } else {
        atributosAdministrativos['marca'] = marcaSanitizada;
      }

      // Excepciones Fecha de Instalación
      if (['memoria_ram', 'gabinete_chasis', 'disipador_cpu', 'ventiladores_chasis'].contains(_categoriaSeleccionada)) {
        atributosAdministrativos['fecha_instalacion'] = _fechaInstalacionController.text.trim();
      }

      // Comentarios e Imágenes Sanitizadas
      atributosAdministrativos['comentarios'] = comentariosSanitizados;
      if (urlImg.isNotEmpty) {
        atributosAdministrativos['imagenes_reales'] = [urlImg];
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

      final docRef = await FirebaseFirestore.instance.collection('inventario').add(productoAEnviar.toMap());
      SecurityService.registrarEnvioExitoso();

      // Registrar auditoría de creación con el usuario actual
      await AuditoriaService.registrarAccion(
        tipoAccion: 'CREACIÓN',
        componenteId: docRef.id,
        componenteNombre: '$marcaSanitizada $modeloSanitizado'.trim(),
        categoria: _categoriaSeleccionada!,
        detalles: 'Registrado por ${AuthService.usuarioActual.nombre}',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Producto guardado exitosamente en la base de datos'),
            backgroundColor: Colors.green,
          ),
        );
        _limpiarFormulario();
      }
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

  Widget _buildCustomDropdown<T>({
    required String labelText,
    required T? value,
    required List<DropdownMenuItem<T>>? items,
    required ValueChanged<T?>? onChanged,
    FormFieldValidator<T>? validator,
    Widget? hint,
    double? menuMaxHeight = 320,
  }) {
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (FormFieldState<T> state) {
        final hasError = state.hasError;
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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                PopupMenuButton<T>(
                  enabled: items != null && items.isNotEmpty && onChanged != null,
                  tooltip: labelText,
                  offset: const Offset(0, 54), // Desplaza la lista para que abra estrictamente DEBAJO de la casilla
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
                    return items.map((item) {
                      return PopupMenuItem<T>(
                        value: item.value,
                        height: 40,
                        child: item.child,
                      );
                    }).toList();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF050B14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasError
                            ? Colors.redAccent
                            : const Color(0xFF007AFF).withValues(alpha: 0.4),
                        width: hasError ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                labelText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF3AD8FF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              displayChild ?? (hint ?? Text('Seleccionar', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14))),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF3AD8FF),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 6),
                    child: Text(
                      state.errorText!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSeccionPropietarios() {
    final usuarios = ['Miguel', 'Kevin', 'Diego', 'Edgardo'];
    final listActivos = _esPropiedadTodos ? usuarios : _propietariosSeleccionados.toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1726),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.group, color: Color(0xFF3AD8FF), size: 18),
                  SizedBox(width: 8),
                  Text(
                    '👥 Propietario(s) del Componente',
                    style: TextStyle(color: Color(0xFF3AD8FF), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (listActivos.length > 1)
                TextButton.icon(
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                  icon: const Icon(Icons.balance, size: 14, color: Colors.amberAccent),
                  label: const Text('Dividir por Igual', style: TextStyle(fontSize: 11, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final total = double.tryParse(_precioAdquisicionController.text.trim().replaceAll(',', '.')) ?? 0.0;
                    if (total > 0 && listActivos.isNotEmpty) {
                      final cuota = total / listActivos.length;
                      setState(() {
                        for (final u in listActivos) {
                          _obtenerControladorAporte(u).text = cuota.toStringAsFixed(2);
                        }
                      });
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilterChip(
                selected: _esPropiedadTodos,
                label: const Text('🏢 Todos (OvniCore)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                selectedColor: const Color(0xFF3AD8FF),
                backgroundColor: const Color(0xFF050B14),
                onSelected: (val) {
                  setState(() {
                    _esPropiedadTodos = val;
                    if (val) {
                      _propietariosSeleccionados.addAll(usuarios);
                    } else {
                      _propietariosSeleccionados.clear();
                      _propietariosSeleccionados.add(AuthService.usuarioActual.nombre);
                    }
                  });
                },
              ),
            ],
          ),
          if (!_esPropiedadTodos) ...[
            const SizedBox(height: 8),
            const Text(
              'Selecciona los integrantes propietarios:',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: usuarios.map((user) {
                final isSelected = _propietariosSeleccionados.contains(user);
                return FilterChip(
                  selected: isSelected,
                  label: Text(
                    user,
                    style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  backgroundColor: const Color(0xFF050B14),
                  selectedColor: const Color(0xFF3AD8FF),
                  side: BorderSide(color: isSelected ? const Color(0xFF3AD8FF) : Colors.grey.withValues(alpha: 0.3)),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _propietariosSeleccionados.add(user);
                      } else {
                        if (_propietariosSeleccionados.length > 1) {
                          _propietariosSeleccionados.remove(user);
                        }
                      }
                      _esPropiedadTodos = _propietariosSeleccionados.length == usuarios.length;
                    });
                  },
                );
              }).toList(),
            ),
          ],
          if (listActivos.length > 1) ...[
            const SizedBox(height: 14),
            const Text(r'💰 Aporte Financiero de cada Integrante (USD $):', style: TextStyle(color: Color(0xFF3AD8FF), fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Column(
              children: listActivos.map((user) {
                final ctrl = _obtenerControladorAporte(user);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(user, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Aporte USD (Ej: 50.00)',
                            prefixIcon: const Icon(Icons.attach_money, size: 14, color: Color(0xFF3AD8FF)),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            fillColor: const Color(0xFF050B14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            // BADGE EN TIEMPO REAL DE CONTROL DE ERRORES FINANCIEROS
            Builder(
              builder: (context) {
                final double precioTotal = double.tryParse(_precioAdquisicionController.text.trim().replaceAll(',', '.')) ?? 0.0;
                double sumaAportes = 0.0;
                for (final u in listActivos) {
                  final ctrl = _obtenerControladorAporte(u);
                  sumaAportes += double.tryParse(ctrl.text.trim().replaceAll(',', '.')) ?? 0.0;
                }

                if (precioTotal <= 0 || sumaAportes <= 0) return const SizedBox.shrink();

                final double diff = sumaAportes - precioTotal;
                final bool esExceso = diff > 0.01;
                final bool esFaltante = diff < -0.01;

                if (esExceso) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '⛔ Error: La suma de aportes (\$${sumaAportes.toStringAsFixed(2)}) supera el Precio de Compra (\$${precioTotal.toStringAsFixed(2)}) por +\$${diff.toStringAsFixed(2)} USD.',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (esFaltante) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orangeAccent),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ℹ️ Suma de aportes (\$${sumaAportes.toStringAsFixed(2)}). Faltan \$${(-diff).toStringAsFixed(2)} USD para completar el costo total (\$${precioTotal.toStringAsFixed(2)}).',
                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.greenAccent),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '✅ Suma de aportes cuadra exactamente con el Precio de Compra.',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeccionPrecioObjetivoVenta() {
    final double precioCompra = double.tryParse(_precioAdquisicionController.text.trim().replaceAll(',', '.')) ?? 0.0;
    final double precioObjetivo = double.tryParse(_precioObjetivoVentaController.text.trim().replaceAll(',', '.')) ?? (precioCompra > 0 ? precioCompra * (1 + (_porcentajeMargenDeseadoForm / 100)) : 0.0);
    final double gananciaProyectada = precioObjetivo - precioCompra;
    final double pctProyectado = precioCompra > 0 ? (gananciaProyectada / precioCompra) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1726),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.stars, color: Colors.purpleAccent, size: 18),
              SizedBox(width: 8),
              Text(
                '🎯 Precio Sugerido y Objetivo de Venta',
                style: TextStyle(color: Colors.purpleAccent, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _precioObjetivoVentaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.purpleAccent, fontSize: 14, fontWeight: FontWeight.bold),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: r'Precio Objetivo de Venta (USD $)',
              labelStyle: const TextStyle(color: Colors.purpleAccent, fontSize: 12),
              hintText: precioCompra > 0 ? 'Sugerido: \$${(precioCompra * 1.3).toStringAsFixed(2)}' : 'Ej: 200.00',
              prefixIcon: const Icon(Icons.sell, color: Colors.purpleAccent),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Seleccionar margen de ganancia sugerido:', style: TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [15, 25, 30, 40, 50, 75, 100].map((pct) {
              final isSelected = _porcentajeMargenDeseadoForm.toInt() == pct;
              return ChoiceChip(
                selected: isSelected,
                label: Text('$pct%', style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                selectedColor: Colors.purpleAccent,
                backgroundColor: const Color(0xFF050B14),
                onSelected: (selected) {
                  if (selected && precioCompra > 0) {
                    setState(() {
                      _porcentajeMargenDeseadoForm = pct.toDouble();
                      final sugerido = precioCompra * (1 + (pct / 100));
                      _precioObjetivoVentaController.text = sugerido.toStringAsFixed(2);
                    });
                  }
                },
              );
            }).toList(),
          ),
          if (precioCompra > 0 && precioObjetivo > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF050B14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: gananciaProyectada >= 0 ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📈 Proyección de Ganancia Neta:',
                    style: TextStyle(color: gananciaProyectada >= 0 ? Colors.greenAccent : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${gananciaProyectada >= 0 ? '+' : ''}\$ ${gananciaProyectada.toStringAsFixed(2)} USD (${gananciaProyectada >= 0 ? '+' : ''}${pctProyectado.toStringAsFixed(1)}%)',
                    style: TextStyle(color: gananciaProyectada >= 0 ? Colors.greenAccent : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool mostrarFechaInstalacion = ['memoria_ram', 'gabinete_chasis', 'disipador_cpu', 'ventiladores_chasis'].contains(_categoriaSeleccionada);
    bool esGPU = _categoriaSeleccionada == 'tarjeta_grafica';

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
              // 🛡️ Trampa Honeypot Anti-Bot (Invisible para humanos, interactuada por bots automatizados)
              Opacity(
                opacity: 0.0,
                child: SizedBox(
                  height: 0,
                  width: 0,
                  child: TextFormField(
                    controller: _botTrapHoneypotController,
                    focusNode: FocusNode(skipTraversal: true),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
              ),
              _buildCustomDropdown<String>(
                labelText: 'Selecciona la Categoría',
                value: _categoriaSeleccionada,
                items: _categorias
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat['value'],
                        child: Text(cat['label']!, style: const TextStyle(color: Colors.white)),
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
                    _marcaSeleccionada = null;
                    _otraMarcaController.clear();
                    _marcaController.clear();
                    _marcaEnsambladorController.clear();
                    _fechaInstalacionController.clear();
                    _comentariosController.clear();
                    _imagenRealController.clear();
                  });
                  _actualizarIdActivoSecuencial(newValue);
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

                // ID Activo Único Automático & Estado del Componente
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _idActivoController,
                        readOnly: true,
                        style: const TextStyle(color: Color(0xFF3AD8FF), fontWeight: FontWeight.bold, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'ID Único de Activo (Generado Automáticamente)',
                          labelStyle: const TextStyle(color: Color(0xFF3AD8FF), fontSize: 12),
                          prefixIcon: const Icon(Icons.lock, color: Color(0xFF3AD8FF), size: 18),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.refresh, color: Color(0xFF3AD8FF), size: 20),
                            tooltip: 'Recalcular secuencia de ID de activo',
                            onPressed: () {
                              _actualizarIdActivoSecuencial(_categoriaSeleccionada);
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _buildCustomDropdown<String>(
                        labelText: 'Estado Inicial',
                        value: _estadoSeleccionado,
                        items: const [
                          DropdownMenuItem(value: 'Disponible', child: Text('🟢 Disponible (Stock)', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'En Uso', child: Text('🔵 En Uso (Asignado)', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'Por Probar', child: Text('🟡 Por Probar (Sin Verificar)', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'En Mantenimiento', child: Text('🟠 En Mantenimiento', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'Defectuoso', child: Text('🔴 Defectuoso (Scrap)', style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _estadoSeleccionado = val;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Precio de Adquisición / Compra con opción Costo $0 (Donación / Regalo)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _precioAdquisicionController,
                        enabled: !_esGratisSinCosto,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          color: _esGratisSinCosto ? Colors.greenAccent : Colors.white,
                          fontSize: 13,
                          fontWeight: _esGratisSinCosto ? FontWeight.bold : FontWeight.normal,
                        ),
                        onChanged: (val) {
                          final double pCompra = double.tryParse(val.trim().replaceAll(',', '.')) ?? 0.0;
                          if (pCompra > 0 && _precioObjetivoVentaController.text.isEmpty) {
                            _precioObjetivoVentaController.text = (pCompra * 1.30).toStringAsFixed(2);
                          }
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          labelText: _esGratisSinCosto
                              ? r'Precio de Compra: $0.00 (Regalo / Donación)'
                              : r'Precio de Compra / Adquisición (USD $)',
                          labelStyle: TextStyle(
                            color: _esGratisSinCosto ? Colors.greenAccent : Colors.grey,
                            fontSize: 12,
                          ),
                          hintText: _esGratisSinCosto ? '0.00' : 'Ej: 150.00',
                          prefixIcon: Icon(
                            _esGratisSinCosto ? Icons.card_giftcard : Icons.attach_money,
                            color: _esGratisSinCosto ? Colors.greenAccent : const Color(0xFF3AD8FF),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      selected: _esGratisSinCosto,
                      avatar: Icon(
                        Icons.card_giftcard,
                        size: 16,
                        color: _esGratisSinCosto ? const Color(0xFF050B14) : Colors.greenAccent,
                      ),
                      label: const Text(r'Costo $0 (Regalo / Donación)'),
                      labelStyle: TextStyle(
                        color: _esGratisSinCosto ? const Color(0xFF050B14) : Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      selectedColor: Colors.greenAccent,
                      backgroundColor: const Color(0xFF050B14),
                      side: BorderSide(
                        color: _esGratisSinCosto ? Colors.greenAccent : Colors.greenAccent.withValues(alpha: 0.5),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _esGratisSinCosto = selected;
                          if (selected) {
                            _precioAdquisicionController.text = '0';
                          } else {
                            _precioAdquisicionController.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Precio Sugerido y Objetivo de Venta Personalizado
                _buildSeccionPrecioObjetivoVenta(),
                const SizedBox(height: 12),

                // Sección de Propietarios
                _buildSeccionPropietarios(),
                const SizedBox(height: 12),

                // Marca vs Ensamblador y Fabricante (GPU)
                if (esGPU) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildCustomDropdown<String>(
                          labelText: 'Marca del Ensamblador',
                          value: _marcaSeleccionada,
                          items: _obtenerMarcasPorCategoria('tarjeta_grafica').map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: Colors.white)))).toList(),
                          validator: (val) => val == null ? 'Seleccione marca' : null,
                          onChanged: (val) {
                            setState(() {
                              _marcaSeleccionada = val;
                              if (val != 'Otra marca') {
                                _marcaEnsambladorController.text = val ?? '';
                                _otraMarcaController.clear();
                              } else {
                                _marcaEnsambladorController.text = _otraMarcaController.text.trim();
                              }
                            });
                          },
                        ),
                      ),
                      if (_marcaSeleccionada == 'Otra marca') ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _otraMarcaController,
                            decoration: const InputDecoration(
                              labelText: 'Escriba la marca',
                              hintText: 'Ej: KFA2, Galax, etc.',
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (_marcaSeleccionada == 'Otra marca' && (val == null || val.trim().isEmpty)) {
                                return 'Ingrese la marca';
                              }
                              return null;
                            },
                            onChanged: (val) {
                              _marcaEnsambladorController.text = val.trim();
                            },
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCustomDropdown<String>(
                          labelText: 'Fabricante del Chip',
                          value: _fabricanteChipGPU,
                          items: const [
                            DropdownMenuItem(value: 'NVIDIA', child: Text('NVIDIA', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'AMD', child: Text('AMD', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'Intel', child: Text('Intel', style: TextStyle(color: Colors.white))),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildCustomDropdown<String>(
                          labelText: 'Marca del Procesador',
                          value: _marcaSeleccionada,
                          items: const [
                            DropdownMenuItem(value: 'AMD', child: Text('AMD', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'Intel', child: Text('Intel', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'Otra marca', child: Text('Otra marca', style: TextStyle(color: Colors.white))),
                          ],
                          validator: (val) => val == null ? 'Seleccione marca' : null,
                          onChanged: (val) {
                            setState(() {
                              _marcaSeleccionada = val;
                              if (val != 'Otra marca') {
                                _marcaCpuSeleccionada = val;
                                _marcaController.text = val ?? '';
                                _otraMarcaController.clear();
                              } else {
                                _marcaCpuSeleccionada = 'Otra';
                                _marcaController.text = _otraMarcaController.text.trim();
                              }
                              _socketCpuSeleccionado = null;
                              _specsDinamicas.remove('socket_compatible');
                            });
                          },
                        ),
                      ),
                      if (_marcaSeleccionada == 'Otra marca') ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _otraMarcaController,
                            decoration: const InputDecoration(
                              labelText: 'Escriba la marca',
                              hintText: 'Ej: Qualcomm, Apple, etc.',
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (_marcaSeleccionada == 'Otra marca' && (val == null || val.trim().isEmpty)) {
                                return 'Ingrese la marca';
                              }
                              return null;
                            },
                            onChanged: (val) {
                              _marcaController.text = val.trim();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildCustomDropdown<String>(
                          labelText: 'Marca del Componente',
                          value: _marcaSeleccionada,
                          items: _obtenerMarcasPorCategoria(_categoriaSeleccionada).map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: Colors.white)))).toList(),
                          validator: (val) => val == null ? 'Seleccione marca' : null,
                          onChanged: (val) {
                            setState(() {
                              _marcaSeleccionada = val;
                              if (val != 'Otra marca') {
                                _marcaController.text = val ?? '';
                                _otraMarcaController.clear();
                              } else {
                                _marcaController.text = _otraMarcaController.text.trim();
                              }
                            });
                          },
                        ),
                      ),
                      if (_marcaSeleccionada == 'Otra marca') ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _otraMarcaController,
                            decoration: const InputDecoration(
                              labelText: 'Escriba la marca',
                              hintText: 'Ingrese el nombre de la marca',
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (_marcaSeleccionada == 'Otra marca' && (val == null || val.trim().isEmpty)) {
                                return 'Ingrese el nombre de la marca';
                              }
                              return null;
                            },
                            onChanged: (val) {
                              _marcaController.text = val.trim();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 12),

                // Modelo (Cascada para Procesadores vs Campo Estándar para Otros)
                if (_categoriaSeleccionada == 'procesador_cpu') ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildCustomDropdown<String>(
                          labelText: 'Tipo / Línea de Procesador',
                          value: _tipoProcesadorSeleccionado,
                          items: (_marcaSeleccionada == 'Intel' || _marcaCpuSeleccionada == 'Intel')
                              ? _tiposIntel.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white)))).toList()
                              : (_marcaSeleccionada == 'AMD' || _marcaCpuSeleccionada == 'AMD')
                                  ? _tiposAMD.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white)))).toList()
                                  : [..._tiposIntel, ..._tiposAMD, 'Otro tipo']
                                      .toSet()
                                      .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white))))
                                      .toList(),
                          validator: (val) => val == null ? 'Seleccione tipo' : null,
                          onChanged: (val) {
                            setState(() {
                              _tipoProcesadorSeleccionado = val;
                              _modeloCpuSeleccionado = null;
                              _otroModeloCpuController.clear();
                              _actualizarModeloCpu();
                            });
                          },
                        ),
                      ),
                      if (_tipoProcesadorSeleccionado != null && _tipoProcesadorSeleccionado != 'Otro tipo') ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCustomDropdown<String>(
                            labelText: 'Modelo Específico',
                            value: _modeloCpuSeleccionado,
                            items: (_modelosPorTipo[_tipoProcesadorSeleccionado] ?? ['Otro modelo'])
                                .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: Colors.white))))
                                .toList(),
                            validator: (val) => val == null ? 'Seleccione modelo' : null,
                            onChanged: (val) {
                              setState(() {
                                _modeloCpuSeleccionado = val;
                                _actualizarModeloCpu();
                              });
                            },
                          ),
                        ),
                      ],
                      if (_tipoProcesadorSeleccionado == 'Otro tipo' || _modeloCpuSeleccionado == 'Otro modelo') ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _otroModeloCpuController,
                            decoration: const InputDecoration(
                              labelText: 'Escriba el modelo',
                              hintText: 'Ej: i7-13700K, 7800X3D, etc.',
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if ((_tipoProcesadorSeleccionado == 'Otro tipo' || _modeloCpuSeleccionado == 'Otro modelo') &&
                                  (val == null || val.trim().isEmpty)) {
                                return 'Ingrese el modelo';
                              }
                              return null;
                            },
                            onChanged: (val) {
                              _actualizarModeloCpu();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else ...[
                  TextFormField(
                    controller: _modeloController,
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val!.isEmpty ? 'Campo obligatorio' : null,
                  ),
                ],
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

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _imagenRealController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'URL de Imagen Real del Componente',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: _isSearchingImage ? null : _buscarImagenComponente,
                        icon: _isSearchingImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.travel_explore),
                        label: const Text('Buscar en API'),
                      ),
                    ),
                  ],
                ),

                // Galería interactiva de opciones de imágenes encontradas por la API
                if (_isSearchingImage) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E1726),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF3AD8FF).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3AD8FF)),
                        ),
                        SizedBox(width: 12),
                        Text(
                          '⚡ Buscando opciones de imágenes reales en la API...',
                          style: TextStyle(color: Color(0xFF3AD8FF), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ] else if (_opcionesImagenesApi.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    '🖼️ Selecciona la imagen real más adecuada de la API:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3AD8FF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _opcionesImagenesApi.length,
                      itemBuilder: (context, index) {
                        final url = _opcionesImagenesApi[index];
                        final isSelected = (_imagenRealController.text.trim() == url) || (_imagenApiSeleccionada == url);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _imagenApiSeleccionada = url;
                              _imagenRealController.text = url;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF3AD8FF) : Colors.transparent,
                                width: isSelected ? 3.0 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF3AD8FF).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    url,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Center(
                                      child: Icon(Icons.broken_image, color: Colors.grey, size: 30),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF3AD8FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, size: 14, color: Colors.black),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: Color(0xFF007AFF), height: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        'O SUBE TU PROPIA IMAGEN / ENLACE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: Color(0xFF007AFF), height: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _imagenRealController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'URL de imagen personalizada (opcional)',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          hintText: 'https://ejemplo.com/mi_imagen.jpg',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0E1726),
                          prefixIcon: const Icon(Icons.link, color: Color(0xFF3AD8FF), size: 20),
                          suffixIcon: _imagenRealController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _imagenRealController.clear();
                                      _imagenApiSeleccionada = null;
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF007AFF)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF3AD8FF), width: 1.5),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _imagenApiSeleccionada = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Subir Imagen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: _seleccionarImagenLocal,
                    ),
                  ],
                ),
                if (_imagenRealController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E1726),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3AD8FF).withValues(alpha: 0.4)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _imagenRealController.text.trim(),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              '❌ No se pudo cargar la vista previa de la imagen',
                              style: TextStyle(color: Colors.redAccent, fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],

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

  void _actualizarResumenPuertosGabinete() {
    List<String> partes = [];
    final u2 = _specsDinamicas['puertos_usb_2_0'] ?? 0;
    final u3 = _specsDinamicas['puertos_usb_3_0'] ?? 0;
    final uc = _specsDinamicas['puertos_usb_c'] ?? 0;
    final hdmi = _specsDinamicas['puertos_hdmi_frontal'] ?? 0;
    final dp = _specsDinamicas['puertos_dp_frontal'] ?? 0;
    final audio = _specsDinamicas['conector_audio_frontal'];
    final botones = _specsDinamicas['botones_panel_frontal'];

    if (u3 > 0) partes.add('${u3}x USB 3.0');
    if (uc > 0) partes.add('${uc}x USB-C');
    if (u2 > 0) partes.add('${u2}x USB 2.0');
    if (hdmi > 0) partes.add('${hdmi}x HDMI');
    if (dp > 0) partes.add('${dp}x DisplayPort');
    if (audio != null && audio.toString().isNotEmpty) partes.add(audio.toString());
    if (botones != null && botones.toString().isNotEmpty) partes.add(botones.toString());

    _specsDinamicas['puertos_panel_frontal'] = partes.isNotEmpty ? partes.join(', ') : 'Sin especificar';
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
            SwitchListTile(
              title: const Text('Editar especificaciones manualmente'),
              subtitle: const Text('Habilita la edición manual de las especificaciones de la CPU', style: TextStyle(fontSize: 11)),
              value: _specsEditables,
              activeColor: const Color(0xFF3AD8FF),
              onChanged: (bool value) {
                setState(() {
                  _specsEditables = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildCustomDropdown<String>(
              labelText: 'Socket Compatible',
              value: _socketCpuSeleccionado,
              items: _marcaCpuSeleccionada == null
                  ? null
                  : socketsDisponibles
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white))))
                        .toList(),
              hint: Text(
                _marcaCpuSeleccionada == null
                    ? '?? Seleccione la marca primero'
                    : 'Seleccione el socket compatible',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
              validator: (val) =>
                  val == null ? 'Seleccione un socket compatible' : null,
              onChanged: (_marcaCpuSeleccionada == null || !_specsEditables)
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
                    controller: _cpuNucleosController,
                    keyboardType: TextInputType.number,
                    readOnly: !_specsEditables,
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
                    controller: _cpuHilosController,
                    keyboardType: TextInputType.number,
                    readOnly: !_specsEditables,
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
                    controller: _cpuFreqBaseController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    readOnly: !_specsEditables,
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
                    controller: _cpuFreqTurboController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    readOnly: !_specsEditables,
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
              controller: _cpuTdpController,
              keyboardType: TextInputType.number,
              readOnly: !_specsEditables,
              decoration: const InputDecoration(
                labelText: 'Consumo Energético (TDP en Watts)',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) =>
                  _specsDinamicas['consumo_energetico_tdp_watts'] =
                      int.tryParse(val) ?? 0,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cpuGraficosController,
              readOnly: !_specsEditables,
              decoration: const InputDecoration(
                labelText: 'Gráficos Integrados',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) =>
                  _specsDinamicas['graficos_integrados'] = val,
            ),
          ],
        );

      case 'tarjeta_madre':
        List<String> todosLosSockets = [..._socketsAMD, ..._socketsIntel];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomDropdown<String>(
              labelText: 'Factor de Forma',
              value: _specsDinamicas['factor_forma'],
              items: const [
                DropdownMenuItem(value: 'ATX', child: Text('ATX', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'Micro-ATX', child: Text('Micro-ATX', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'Mini-ITX', child: Text('Mini-ITX', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'E-ATX', child: Text('E-ATX', style: TextStyle(color: Colors.white))),
              ],
              validator: (val) =>
                  val == null ? 'Seleccione un factor de forma' : null,
              onChanged: (val) => setState(() => _specsDinamicas['factor_forma'] = val),
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
                  child: _buildCustomDropdown<String>(
                    labelText: 'Socket',
                    value: _specsDinamicas['socket'],
                    items: todosLosSockets
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white))))
                        .toList(),
                    validator: (val) => val == null ? 'Obligatorio' : null,
                    onChanged: (val) => setState(() => _specsDinamicas['socket'] = val),
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
                  child: _buildCustomDropdown<String>(
                    labelText: 'Tipo de Memoria',
                    value: _specsDinamicas['tipo_memoria_soportada'],
                    items: const [
                      DropdownMenuItem(value: 'DDR5', child: Text('DDR5', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'DDR4', child: Text('DDR4', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'DDR3', child: Text('DDR3', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'DDR2', child: Text('DDR2', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'DDR4 / DDR3 (Combo)', child: Text('DDR4 / DDR3 (Combo)', style: TextStyle(color: Colors.white))),
                    ],
                    validator: (val) => val == null ? 'Obligatorio' : null,
                    onChanged: (val) =>
                        setState(() => _specsDinamicas['tipo_memoria_soportada'] = val),
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
                  child: _buildCustomDropdown<String>(
                    labelText: 'Tipo Memoria',
                    value: _specsDinamicas['tipo_memoria'],
                    items: const [
                      DropdownMenuItem(value: 'DDR5', child: Text('DDR5', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'DDR4', child: Text('DDR4', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'DDR3', child: Text('DDR3', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'DDR2', child: Text('DDR2', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'DDR', child: Text('DDR (Legacy)', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) => setState(() => _specsDinamicas['tipo_memoria'] = val),
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

      case 'almacenamiento_ssd_hdd':
      case 'ssd_storage':
      case 'hdd_storage':
        final String tipoActual = _specsDinamicas['tipo_tecnologia'] ??
            (_categoriaSeleccionada == 'hdd_storage' ? 'HDD' : 'SSD');
        final bool esHdd = tipoActual == 'HDD' || _categoriaSeleccionada == 'hdd_storage';
        final bool esNvme = tipoActual == 'NVMe M.2' || tipoActual == 'NVMe';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildCustomDropdown<String>(
                    labelText: 'Tipo de Almacenamiento',
                    value: _specsDinamicas['tipo_tecnologia'] ?? (_categoriaSeleccionada == 'hdd_storage' ? 'HDD' : 'SSD'),
                    items: const [
                      DropdownMenuItem(value: 'SSD', child: Text('SSD (SATA 2.5")', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'HDD', child: Text('HDD (Disco Duro)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'NVMe M.2', child: Text('NVMe M.2 (PCIe)', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _specsDinamicas['tipo_tecnologia'] = val;
                          if (val == 'HDD') {
                            _specsDinamicas['factor_forma'] = '3.5"';
                            _specsDinamicas['interfaz_conexion'] = 'SATA III (6 Gb/s)';
                          } else if (val == 'NVMe M.2') {
                            _specsDinamicas['factor_forma'] = 'M.2 2280';
                            _specsDinamicas['interfaz_conexion'] = 'PCIe 4.0 x4';
                          } else {
                            _specsDinamicas['factor_forma'] = '2.5"';
                            _specsDinamicas['interfaz_conexion'] = 'SATA III (6 Gb/s)';
                          }
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCustomDropdown<String>(
                    labelText: 'Interfaz de Conexión',
                    value: _specsDinamicas['interfaz_conexion'] ??
                        (esNvme ? 'PCIe 4.0 x4' : 'SATA III (6 Gb/s)'),
                    items: const [
                      DropdownMenuItem(value: 'SATA III (6 Gb/s)', child: Text('SATA III (6 Gb/s)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'PCIe 4.0 x4', child: Text('PCIe 4.0 x4', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'PCIe 3.0 x4', child: Text('PCIe 3.0 x4', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'PCIe 5.0 x4', child: Text('PCIe 5.0 x4', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'SATA II', child: Text('SATA II', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'USB 3.2 / Type-C', child: Text('USB 3.2 / Type-C', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) => setState(() => _specsDinamicas['interfaz_conexion'] = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCustomDropdown<String>(
                    labelText: esHdd ? 'Tamaño Disco Duro' : 'Factor de Forma / Tamaño',
                    value: _specsDinamicas['factor_forma'] ??
                        (esHdd ? '3.5"' : (esNvme ? 'M.2 2280' : '2.5"')),
                    items: const [
                      DropdownMenuItem(value: '3.5"', child: Text('3.5" (Desktop / PC)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '2.5"', child: Text('2.5" (Laptop / SFF)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'M.2 2280', child: Text('M.2 2280', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'M.2 2230', child: Text('M.2 2230', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) => setState(() => _specsDinamicas['factor_forma'] = val),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Capacidad Total (ej: 512GB, 1TB)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['capacidad_total'] = val.trim(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (esHdd) ...[
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Velocidad RPM (ej: 7200, 5400)', border: OutlineInputBorder()),
                      onChanged: (val) => _specsDinamicas['velocidad_rotacion_rpm'] = int.tryParse(val) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Caché (MB)', border: OutlineInputBorder()),
                      onChanged: (val) => _specsDinamicas['memoria_cache_mb'] = int.tryParse(val) ?? 0,
                    ),
                  ),
                ] else ...[
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
              ],
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
                  child: _buildCustomDropdown<String>(
                    labelText: 'Tipo VRAM',
                    value: _specsDinamicas['tipo_vram'],
                    items: const [
                      DropdownMenuItem(value: 'GDDR7', child: Text('GDDR7', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'GDDR6X', child: Text('GDDR6X', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'GDDR6', child: Text('GDDR6', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'GDDR5X', child: Text('GDDR5X', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'GDDR5', child: Text('GDDR5', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'GDDR4', child: Text('GDDR4', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'GDDR3', child: Text('GDDR3', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'HBM3', child: Text('HBM3 / HBM3e', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'HBM2', child: Text('HBM2 / HBM2e', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'HBM', child: Text('HBM', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'DDR4', child: Text('DDR4 (Compartida)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'DDR5', child: Text('DDR5 (Compartida)', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) => setState(() => _specsDinamicas['tipo_vram'] = val),
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
                  child: _buildCustomDropdown<String>(
                    labelText: 'Certificación',
                    value: _specsDinamicas['certificacion_eficiencia'],
                    items: const [
                      DropdownMenuItem(value: 'Sin Certificación', child: Text('Sin Certificación (Genérica)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '80 Plus White', child: Text('80 Plus White / Standard', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '80 Plus Bronze', child: Text('80 Plus Bronze', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '80 Plus Silver', child: Text('80 Plus Silver', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '80 Plus Gold', child: Text('80 Plus Gold', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '80 Plus Platinum', child: Text('80 Plus Platinum', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '80 Plus Titanium', child: Text('80 Plus Titanium', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Cybenetics Bronze', child: Text('Cybenetics Bronze', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Cybenetics Gold', child: Text('Cybenetics Gold / Platinum', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) => setState(() => _specsDinamicas['certificacion_eficiencia'] = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCustomDropdown<String>(
                    labelText: 'Modularidad',
                    value: _specsDinamicas['tipo_modularidad'],
                    items: const [
                      DropdownMenuItem(value: 'No modular', child: Text('No modular', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Semi-modular', child: Text('Semi-modular', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Full modular', child: Text('Full modular', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) => setState(() => _specsDinamicas['tipo_modularidad'] = val),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCustomDropdown<String>(
                    labelText: 'Factor de Forma',
                    value: _specsDinamicas['factor_forma'],
                    items: const [
                      DropdownMenuItem(value: 'ATX', child: Text('ATX', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'SFX', child: Text('SFX', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) => setState(() => _specsDinamicas['factor_forma'] = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCustomDropdown<String>(
              labelText: 'Protecciones Activas',
              value: _specsDinamicas['protecciones_activas'],
              items: const [
                DropdownMenuItem(value: 'OVP / UVP / OPP / SCP / OCP / OTP', child: Text('OVP / UVP / OPP / SCP / OCP / OTP (Protección Completa)', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'OVP / UVP / OPP / SCP', child: Text('OVP / UVP / OPP / SCP (Estándar)', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'OVP / OPP / SCP', child: Text('OVP / OPP / SCP (Básica Avanzada)', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'OVP / SCP', child: Text('OVP / SCP (Básica)', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'Sin Protecciones', child: Text('Sin Protecciones Documentadas', style: TextStyle(color: Colors.white))),
              ],
              onChanged: (val) => setState(() => _specsDinamicas['protecciones_activas'] = val),
            ),
          ],
        );

      case 'gabinete_chasis':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Placas soportadas (ej: ATX, Micro-ATX, Mini-ITX)', border: OutlineInputBorder()),
              onChanged: (val) => _specsDinamicas['formatos_placa_soportados'] = val.trim(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Materiales (ej: Acero SPCC, Cristal Templado)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['materiales_construccion'] = val.trim(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Bahías (ej: 2x 3.5", 2x 2.5")', border: OutlineInputBorder()),
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF050B14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3AD8FF).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.usb_rounded, color: Color(0xFF3AD8FF), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Panel Frontal / Conectores de I/O',
                        style: TextStyle(color: Color(0xFF3AD8FF), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Cant. USB 2.0', border: OutlineInputBorder()),
                          onChanged: (val) {
                            _specsDinamicas['puertos_usb_2_0'] = int.tryParse(val) ?? 0;
                            _actualizarResumenPuertosGabinete();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Cant. USB 3.0 / 3.2', border: OutlineInputBorder()),
                          onChanged: (val) {
                            _specsDinamicas['puertos_usb_3_0'] = int.tryParse(val) ?? 0;
                            _actualizarResumenPuertosGabinete();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Cant. USB Type-C', border: OutlineInputBorder()),
                          onChanged: (val) {
                            _specsDinamicas['puertos_usb_c'] = int.tryParse(val) ?? 0;
                            _actualizarResumenPuertosGabinete();
                          },
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
                          decoration: const InputDecoration(labelText: 'Cant. HDMI Frontal', border: OutlineInputBorder()),
                          onChanged: (val) {
                            _specsDinamicas['puertos_hdmi_frontal'] = int.tryParse(val) ?? 0;
                            _actualizarResumenPuertosGabinete();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Cant. DisplayPort Frontal', border: OutlineInputBorder()),
                          onChanged: (val) {
                            _specsDinamicas['puertos_dp_frontal'] = int.tryParse(val) ?? 0;
                            _actualizarResumenPuertosGabinete();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCustomDropdown<String>(
                          labelText: 'Conector de Audio',
                          value: _specsDinamicas['conector_audio_frontal'],
                          items: const [
                            DropdownMenuItem(value: '1x Combo Audio/Mic (Jack 3.5mm)', child: Text('1x Combo Audio/Mic', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: '2x HD Audio (Audio + Mic separado)', child: Text('2x HD Audio (Audio + Mic)', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'Sin Audio Frontal', child: Text('Sin Audio Frontal', style: TextStyle(color: Colors.white))),
                          ],
                          onChanged: (val) {
                            setState(() => _specsDinamicas['conector_audio_frontal'] = val);
                            _actualizarResumenPuertosGabinete();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCustomDropdown<String>(
                          labelText: 'Botones / Controladores',
                          value: _specsDinamicas['botones_panel_frontal'],
                          items: const [
                            DropdownMenuItem(value: 'Power + Reset', child: Text('Power + Reset', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'Power + Reset + Botón RGB', child: Text('Power + Reset + Botón RGB', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'Power + Botón LED', child: Text('Power + Botón LED', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'Solo Botón Power', child: Text('Solo Botón Power', style: TextStyle(color: Colors.white))),
                          ],
                          onChanged: (val) {
                            setState(() => _specsDinamicas['botones_panel_frontal'] = val);
                            _actualizarResumenPuertosGabinete();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

      case 'disipador_cpu':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildCustomDropdown<String>(
                    labelText: 'Tipo Disipación',
                    value: _specsDinamicas['tipo_disipacion'],
                    items: const [
                      DropdownMenuItem(value: 'Aire', child: Text('Aire', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Líquida/AIO', child: Text('Líquida/AIO', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) => setState(() => _specsDinamicas['tipo_disipacion'] = val),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCustomDropdown<String>(
                    labelText: 'Sockets Compatibles',
                    value: _specsDinamicas['sockets_compatibles'],
                    items: const [
                      DropdownMenuItem(value: 'Universal (LGA 1700/1200 + AM5/AM4)', child: Text('Universal (LGA1700/1200 + AM5/AM4)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Intel LGA 1700 / 1200 / 115X', child: Text('Intel LGA 1700 / 1200 / 115X', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'AMD AM5 / AM4', child: Text('AMD AM5 / AM4', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Intel LGA 2066 / 2011 (HEDT)', child: Text('Intel LGA 2066 / 2011 (HEDT)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'AMD TR4 / sTRX4 (Threadripper)', child: Text('AMD TR4 / sTRX4 (Threadripper)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Sockets Antiguos / Específicos', child: Text('Sockets Antiguos / Específicos', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) => setState(() => _specsDinamicas['sockets_compatibles'] = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCustomDropdown<String>(
                    labelText: 'Ventiladores Incluidos',
                    value: _specsDinamicas['cantidad_ventiladores'] != null ? '${_specsDinamicas['cantidad_ventiladores']} Ventilador(es)' : null,
                    items: const [
                      DropdownMenuItem(value: '0 Ventilador(es)', child: Text('0 (Pasivo / Sin Ventilador)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '1 Ventilador(es)', child: Text('1 Ventilador', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '2 Ventilador(es)', child: Text('2 Ventiladores (Push-Pull)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '3 Ventilador(es)', child: Text('3 Ventiladores', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '4 Ventilador(es)', child: Text('4 Ventiladores', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        final cant = int.tryParse(val.split(' ')[0]) ?? 0;
                        setState(() => _specsDinamicas['cantidad_ventiladores'] = cant);
                      }
                    },
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
                  child: _buildCustomDropdown<String>(
                    labelText: 'Tipo de Rodamiento (Opcional)',
                    value: _specsDinamicas['tipo_rodamiento'],
                    items: const [
                      DropdownMenuItem(value: 'Fluido', child: Text('Fluido (Fluid Dynamic)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Magnético', child: Text('Levitación Magnética', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Bolas', child: Text('Doble Rodamiento de Bolas', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Sleeve', child: Text('Sleeve Bearing (Genérico)', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) => setState(() => _specsDinamicas['tipo_rodamiento'] = val),
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
                    decoration: const InputDecoration(labelText: 'Flujo de Aire (CFM) [Opcional]', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['flujo_aire_cfm'] = double.tryParse(val) ?? 0.0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Presión Estática (mmH2O) [Opcional]', border: OutlineInputBorder()),
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
                    decoration: const InputDecoration(labelText: 'Nivel Ruido (dBA) [Opcional]', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['nivel_ruido_dba'] = double.tryParse(val) ?? 0.0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCustomDropdown<String>(
                    labelText: 'Conectores',
                    value: _specsDinamicas['conectores'],
                    items: const [
                      DropdownMenuItem(value: '4-Pin PWM', child: Text('4-Pin PWM (Control Inteligente)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '3-Pin DC', child: Text('3-Pin DC (Control por Voltaje)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '4-Pin PWM + 3-Pin 5V ARGB', child: Text('4-Pin PWM + 3-Pin 5V ARGB', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '4-Pin PWM + 4-Pin 12V RGB', child: Text('4-Pin PWM + 4-Pin 12V RGB', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Molex 4-Pin', child: Text('Molex 4-Pin (Directo a PSU)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Conector Propietario (Hub)', child: Text('Conector Propietario (Hub)', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) => setState(() => _specsDinamicas['conectores'] = val),
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
                  child: _buildCustomDropdown<String>(
                    labelText: 'Tipo de Panel',
                    value: _specsDinamicas['tipo_panel'],
                    items: const [
                      DropdownMenuItem(value: 'IPS', child: Text('IPS', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'VA', child: Text('VA', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'TN', child: Text('TN', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'OLED', child: Text('OLED', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) => setState(() => _specsDinamicas['tipo_panel'] = val),
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
        final List<String> conectividadesTeclado = [
          'USB Alámbrico',
          'Inalámbrico 2.4GHz (Dongle USB)',
          'Bluetooth',
          'Bluetooth Multi-Dispositivo',
        ];
        final List<String> seleccionadasTeclado = (_specsDinamicas['conectividad'] ?? '')
            .toString()
            .split(', ')
            .where((s) => s.isNotEmpty)
            .toList();

        final String? tipoTecladoSel = _specsDinamicas['tipo'];
        final bool esSwitchable = tipoTecladoSel == 'Mecánico' ||
            tipoTecladoSel == 'Óptico' ||
            tipoTecladoSel == 'Magnético (Efecto Hall)' ||
            tipoTecladoSel == 'Semimecánico';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildCustomDropdown<String>(
                    labelText: 'Tipo de Teclado',
                    value: _specsDinamicas['tipo'],
                    items: const [
                      DropdownMenuItem(value: 'Mecánico', child: Text('Mecánico', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Membrana', child: Text('Membrana', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Óptico', child: Text('Óptico', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Magnético (Efecto Hall)', child: Text('Magnético (Efecto Hall / Rapid Trigger)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Semimecánico', child: Text('Semimecánico (Mecha-Membrane)', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) => setState(() => _specsDinamicas['tipo'] = val),
                  ),
                ),
                if (esSwitchable) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCustomDropdown<String>(
                      labelText: 'Color / Tipo de Switches',
                      value: _specsDinamicas['tipo_switch_color'],
                      items: const [
                        DropdownMenuItem(value: 'Blue (Azul - Clicki)', child: Text('🔵 Blue (Azul - Clicki)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'Red (Rojo - Lineal)', child: Text('🔴 Red (Rojo - Lineal)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'Brown (Marrón - Táctil)', child: Text('🟤 Brown (Marrón - Táctil)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'Yellow (Amarillo - Rápido)', child: Text('🟡 Yellow (Amarillo - Rápido)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'White (Blanco - Clicki Rápido)', child: Text('⚪ White (Blanco - Clicki Rápido)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'Purple (Púrpura - Óptico Clicki)', child: Text('🟣 Purple (Púrpura - Óptico Clicki)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'Green (Verde - Táctil Clicki)', child: Text('🟢 Green (Verde - Táctil Clicki)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'Black (Negro - Lineal Pesado)', child: Text('⚫ Black (Negro - Lineal Pesado)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'Magnético / Hall Effect', child: Text('🧲 Magnético / Hall Effect (Rapid Trigger)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'Custom / Otro Switch', child: Text('Custom / Otro Switch', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (val) => setState(() => _specsDinamicas['tipo_switch_color'] = val),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Conectividad (Seleccione una o más opciones):',
              style: TextStyle(color: Color(0xFF3AD8FF), fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: conectividadesTeclado.map((opcion) {
                final bool estaSeleccionado = seleccionadasTeclado.contains(opcion);
                return FilterChip(
                  selected: estaSeleccionado,
                  label: Text(opcion),
                  labelStyle: TextStyle(
                    color: estaSeleccionado ? const Color(0xFF050B14) : Colors.white,
                    fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  selectedColor: const Color(0xFF3AD8FF),
                  backgroundColor: const Color(0xFF0E1726),
                  checkmarkColor: const Color(0xFF050B14),
                  side: BorderSide(
                    color: estaSeleccionado ? const Color(0xFF3AD8FF) : Colors.white24,
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        if (!seleccionadasTeclado.contains(opcion)) seleccionadasTeclado.add(opcion);
                      } else {
                        seleccionadasTeclado.remove(opcion);
                      }
                      _specsDinamicas['conectividad'] = seleccionadasTeclado.isNotEmpty ? seleccionadasTeclado.join(', ') : null;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );

      case 'mouse':
        final List<String> conectividadesMouse = [
          'USB Alámbrico',
          'Inalámbrico 2.4GHz (Dongle USB)',
          'Bluetooth',
          'Bluetooth Multi-Dispositivo',
        ];
        final List<String> seleccionadasMouse = (_specsDinamicas['conectividad'] ?? '')
            .toString()
            .split(', ')
            .where((s) => s.isNotEmpty)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'DPI Máximo (ej: 26000)', border: OutlineInputBorder()),
                    onChanged: (val) => _specsDinamicas['dpi_maximo'] = int.tryParse(val) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCustomDropdown<String>(
                    labelText: 'Modelo / Tipo de Sensor',
                    value: _specsDinamicas['modelo_sensor'],
                    items: const [
                      DropdownMenuItem(value: 'PAW 3395 (PixArt 26K DPI)', child: Text('PAW 3395 (PixArt 26K DPI)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'PAW 3370 (PixArt 19K DPI)', child: Text('PAW 3370 (PixArt 19K DPI)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'HERO 25K (Logitech)', child: Text('HERO 25K (Logitech)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'HERO 16K (Logitech)', child: Text('HERO 16K (Logitech)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Focus Pro 30K (Razer)', child: Text('Focus Pro 30K (Razer)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Focus+ 20K (Razer)', child: Text('Focus+ 20K (Razer)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'PMW 3389 / 3360 (PixArt High-End)', child: Text('PMW 3389 / 3360 (PixArt High-End)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'PAW 3311 / 3327 (PixArt Mid-Range)', child: Text('PAW 3311 / 3327 (PixArt Mid-Range)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Sensor Óptico Genérico', child: Text('Sensor Óptico Genérico', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Sensor Láser', child: Text('Sensor Láser', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) => setState(() => _specsDinamicas['modelo_sensor'] = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Conectividad (Seleccione una o más opciones):',
              style: TextStyle(color: Color(0xFF3AD8FF), fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: conectividadesMouse.map((opcion) {
                final bool estaSeleccionado = seleccionadasMouse.contains(opcion);
                return FilterChip(
                  selected: estaSeleccionado,
                  label: Text(opcion),
                  labelStyle: TextStyle(
                    color: estaSeleccionado ? const Color(0xFF050B14) : Colors.white,
                    fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  selectedColor: const Color(0xFF3AD8FF),
                  backgroundColor: const Color(0xFF0E1726),
                  checkmarkColor: const Color(0xFF050B14),
                  side: BorderSide(
                    color: estaSeleccionado ? const Color(0xFF3AD8FF) : Colors.white24,
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        if (!seleccionadasMouse.contains(opcion)) seleccionadasMouse.add(opcion);
                      } else {
                        seleccionadasMouse.remove(opcion);
                      }
                      _specsDinamicas['conectividad'] = seleccionadasMouse.isNotEmpty ? seleccionadasMouse.join(', ') : null;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );

      case 'auriculares_altavoces':
        final List<String> conectividadesAudio = [
          'Bluetooth',
          'Inalámbrico 2.4GHz (Dongle USB/USB-C)',
          'Jack 3.5mm (Combo TRRS)',
          'Doble Jack 3.5mm (Audio + Mic)',
          'USB-A Digital',
          'USB-C Digital',
          'Jack 6.35mm (1/4" Pro)',
          'Cable Óptico / SPDIF',
        ];
        final List<String> seleccionadasAudio = (_specsDinamicas['conectividad'] ?? '')
            .toString()
            .split(', ')
            .where((s) => s.isNotEmpty)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomDropdown<String>(
              labelText: 'Formato de Audio',
              value: _specsDinamicas['formato'],
              items: const [
                DropdownMenuItem(value: 'Auriculares (Headset/Over-Ear)', child: Text('Auriculares (Headset / Over-Ear)', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'Audífonos In-Ear (TWS / IEM)', child: Text('Audífonos In-Ear (TWS / IEM)', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'Altavoces (Speakers 2.0 / 2.1)', child: Text('Altavoces (Speakers 2.0 / 2.1)', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'Barra de Sonido (Soundbar)', child: Text('Barra de Sonido (Soundbar)', style: TextStyle(color: Colors.white))),
              ],
              onChanged: (val) => setState(() => _specsDinamicas['formato'] = val),
            ),
            const SizedBox(height: 12),
            const Text(
              'Conectividad (Seleccione una o más opciones):',
              style: TextStyle(color: Color(0xFF3AD8FF), fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: conectividadesAudio.map((opcion) {
                final bool estaSeleccionado = seleccionadasAudio.contains(opcion);
                return FilterChip(
                  selected: estaSeleccionado,
                  label: Text(opcion),
                  labelStyle: TextStyle(
                    color: estaSeleccionado ? const Color(0xFF050B14) : Colors.white,
                    fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  selectedColor: const Color(0xFF3AD8FF),
                  backgroundColor: const Color(0xFF0E1726),
                  checkmarkColor: const Color(0xFF050B14),
                  side: BorderSide(
                    color: estaSeleccionado ? const Color(0xFF3AD8FF) : Colors.white24,
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        if (!seleccionadasAudio.contains(opcion)) seleccionadasAudio.add(opcion);
                      } else {
                        seleccionadasAudio.remove(opcion);
                      }
                      _specsDinamicas['conectividad'] = seleccionadasAudio.isNotEmpty ? seleccionadasAudio.join(', ') : null;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
