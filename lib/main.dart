import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/inventario/data/models/producto_model.dart';
import 'features/inventario/presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicialización manual explícita para Web para destruir el error configuration-not-found
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCsNGtvAbxIE98YgXC53xNqfrJL-_z_YCc',
        authDomain: 'base-de-datos-ovnicore.firebaseapp.com',
        projectId: 'base-de-datos-ovnicore',
        storageBucket: 'base-de-datos-ovnicore.firebasestorage.app',
        messagingSenderId: '342410021995',
        appId: '1:342410021995:web:20671c62f0e4373217352e',
      ),
    );

    // Desactivar persistencia de Firestore para evitar que el IndexedDB corrupto en Web
    // congele los streams de Firestore (como la verificación de roles o carga de catálogo)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  } catch (e) {
    // Si Firebase falla, lo atrapamos aquí para evitar que bloquee el renderizado de la UI
    print("⚠️ Error crítico de inicialización de Firebase: $e");
  }

  // Al estar fuera del bloque try-catch, runApp se ejecutará SÍ O SÍ, matando la carga infinita
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OvniCore Inventario',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050B14),
        cardColor: const Color(0xFF0E1726),
        canvasColor: const Color(0xFF0E1726),
        dialogBackgroundColor: const Color(0xFF0E1726),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0E1726),
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3AD8FF),
          secondary: Color(0xFF007AFF),
          surface: Color(0xFF0E1726),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF050B14),
          labelStyle: const TextStyle(color: Color(0xFF3AD8FF), fontWeight: FontWeight.w500),
          floatingLabelStyle: const TextStyle(color: Color(0xFF3AD8FF), fontWeight: FontWeight.bold),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFF007AFF).withValues(alpha: 0.4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFF007AFF).withValues(alpha: 0.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF3AD8FF), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Función asíncrona para inyectar el primer producto
  Future<void> _inyectarProcesadorPrueba(BuildContext context) async {
    try {
      // 1. Instanciamos el modelo con los datos exactos de tu lista
      final nuevoCpu = ProductoModel(
        id: '', // Firestore generará este ID automáticamente
        grupo: 'componentes_internos',
        categoria: 'procesador_cpu',
        atributosAdministrativos: {
          'id_activo': 'ACT-CPU-001',
          'marca': 'AMD',
          'modelo': 'Ryzen 5 5600X',
          'numero_serie': 'SN-AMD-5600X-99',
          'estado_conservacion': 'Nuevo',
          'precio_adquisicion': 189.50, // Recuerda usar siempre punto decimal
        },
        especificacionesTecnicas: {
          'socket_compatible': 'AM4',
          'cantidad_nucleos_fisicos': 6,
          'cantidad_hilos_procesamiento': 12,
          'frecuencia_base_ghz': 3.7,
          'frecuencia_turbo_ghz': 4.6,
          'consumo_energetico_tdp_watts': 65,
          'graficos_integrados': false, // Booleano para el Sí/No
        },
      );

      // 2. Conectamos con Firestore y subimos el mapa
      final coleccion = FirebaseFirestore.instance.collection('inventario');
      await coleccion.add(nuevoCpu.toMap());

      // 3. Feedback visual (Principio HCI: Mantener al usuario informado)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🛸 ¡Procesador inyectado con éxito en OvniCore!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Cultura del Debugging: Si algo falla, lo atrapamos aquí
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al inyectar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OvniCore Panel de Pruebas')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'La base de datos está lista.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Inyectar Procesador (CPU) de Prueba'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              onPressed: () => _inyectarProcesadorPrueba(context),
            ),
          ],
        ),
      ),
    );
  }
}
