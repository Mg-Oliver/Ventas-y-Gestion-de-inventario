import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../inventario/data/models/producto_model.dart';
import '../../../inventario/presentation/screens/dashboard_screen.dart';

class CatalogoStoreScreen extends HookWidget {
  const CatalogoStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = useStream(FirebaseAuth.instance.authStateChanges());
    final user = authState.data;

    // Hook state for card hovering in store
    final hoveredCardId = useState<String?>(null);

    return Scaffold(
      backgroundColor: const Color(0xFF050B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1726),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/img/icon_ovnicore.png', width: 32, height: 32),
            const SizedBox(width: 12),
            const Text(
              'OvniCore Store',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          // Role-based admin button
          if (user != null && FirebaseAuth.instance.currentUser != null)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF3AD8FF),
                        ),
                      ),
                    ),
                  );
                }
                if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final role = data?['role'];
                  if (role == 'admin') {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF3AD8FF),
                          side: const BorderSide(color: Color(0xFF3AD8FF), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        icon: const Icon(Icons.admin_panel_settings, size: 18),
                        label: const Text(
                          'Inventario',
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DashboardScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          const SizedBox(width: 8),
          // User session controller for testing
          _buildSessionControl(context, user),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner/Hero Section
          _buildHeroBanner(),
          // Store Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('inventario').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '❌ Error al cargar catálogo: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      '🚀 Próximamente nuevos componentes en la tienda.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                final productos = snapshot.data!.docs.map((doc) {
                  return ProductoModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                }).toList();

                return GridView.builder(
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final prod = productos[index];
                    return _buildProductCard(context, prod, hoveredCardId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1726),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF007AFF).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HARDWARE DE OTRO MUNDO',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF3AD8FF),
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Equipa tu estación de batalla con tecnología OvniCore',
            style: TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Componentes de alto rendimiento seleccionados y auditados.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    ProductoModel prod,
    ValueNotifier<String?> hoveredCardId,
  ) {
    final isHovered = hoveredCardId.value == prod.id;
    final admin = prod.atributosAdministrativos;
    final price = admin['precio_adquisicion'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MouseRegion(
        onEnter: (_) => hoveredCardId.value = prod.id,
        onExit: (_) => hoveredCardId.value = null,
        child: AnimatedScale(
          scale: isHovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            clipBehavior: Clip.none,
            decoration: BoxDecoration(
              color: const Color(0xFF0E1726),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovered ? const Color(0xFF3AD8FF) : const Color(0xFF007AFF).withOpacity(0.4),
                width: isHovered ? 2 : 1,
              ),
              boxShadow: isHovered
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3AD8FF).withOpacity(0.35),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF050B14),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFF007AFF).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/img/${prod.categoria}.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.developer_board,
                            size: 50,
                            color: Color(0xFF3AD8FF),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Product Info
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prod.categoria.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF3AD8FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${admin['marca']} ${admin['modelo']}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Specs highlight
                      Text(
                        prod.especificacionesTecnicas.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .take(2)
                            .join(' | '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF3AD8FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🛒 ¡${admin['marca']} ${admin['modelo']} añadido al carrito!'),
                                  backgroundColor: const Color(0xFF007AFF),
                                ),
                              );
                            },
                            child: const Text(
                              'Comprar',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionControl(BuildContext context, User? user) {
    if (user == null) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.login, color: Color(0xFF3AD8FF)),
        tooltip: 'Iniciar sesión (Pruebas)',
        onSelected: (value) async {
          try {
            // Utilizamos autenticación por correo para evitar el error de Anonymous Auth deshabilitado
            String targetEmail = value == 'admin' ? 'admin@ovnicore.com' : 'cliente@ovnicore.com';
            String targetPassword = value == 'admin' ? 'ovnicore_admin_2024' : 'ovnicore_cliente_2024';
            
            UserCredential userCredential;
            try {
              userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: targetEmail,
                password: targetPassword,
              );
            } on FirebaseAuthException catch (authEx) {
              // Si el usuario no existe o las credenciales no son válidas, lo creamos automáticamente
              if (authEx.code == 'user-not-found' || authEx.code == 'invalid-credential' || authEx.code == 'wrong-password') {
                userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: targetEmail,
                  password: targetPassword,
                );
              } else {
                rethrow;
              }
            }

            final uid = userCredential.user?.uid;
            if (uid == null) throw Exception('No se pudo obtener el UID del usuario.');

            if (value == 'admin') {
              // Assign admin role to this uid in Firestore
              await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(uid)
                  .set({'role': 'admin', 'email': targetEmail});

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🛸 Autenticado como Administrador de Pruebas.'),
                    backgroundColor: Color(0xFF3AD8FF),
                  ),
                );
              }
            } else if (value == 'cliente') {
              // Assign cliente role to this uid in Firestore
              await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(uid)
                  .set({'role': 'cliente', 'email': targetEmail});

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('👤 Autenticado como Cliente de Pruebas.'),
                    backgroundColor: Colors.grey,
                  ),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Error Auth (Asegura activar Email/Password en Firebase): $e'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'admin',
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Color(0xFF3AD8FF)),
                SizedBox(width: 8),
                Text('Admin de Prueba'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'cliente',
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.grey),
                SizedBox(width: 8),
                Text('Cliente de Prueba'),
              ],
            ),
          ),
        ],
      );
    } else {
      return TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
        icon: const Icon(Icons.logout, size: 16),
        label: const Text(
          'Cerrar Sesión',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🚪 Sesión cerrada.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
      );
    }
  }
}
