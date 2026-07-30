import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../data/models/producto_model.dart';
import '../../data/services/auth_service.dart';
import 'agregar_producto_screen.dart';
import 'inventario_list_screen.dart';
import 'historial_auditoria_screen.dart';
import 'registro_ventas_screen.dart';
import 'tabla_posiciones_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends HookWidget {
  const DashboardScreen({super.key});

  void _mostrarDialogoPerfil(BuildContext context) async {
    final usuario = AuthService.usuarioActual;
    final String initialDesc = await AuthService.obtenerDescripcion(usuario.nombre) ?? '';
    if (!context.mounted) return;

    final descController = TextEditingController(text: initialDesc);
    final passController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool mostrarPass = false;
    String? errorMsg;
    String? successMsg;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0E1726),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: const Color(0xFF3AD8FF).withValues(alpha: 0.5)),
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF3AD8FF).withValues(alpha: 0.2),
                    child: const Icon(Icons.person, color: Color(0xFF3AD8FF)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perfil: ${usuario.nombre}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Personaliza tu descripción y contraseña de acceso',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 12),
                      
                      // SECCIÓN DESCRIPCIÓN
                      Row(
                        children: const [
                          Icon(Icons.badge_outlined, color: Color(0xFF3AD8FF), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Descripción o Cargo (Opcional)',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Agrega una descripción para mostrar en tu tarjeta (ej: Especialista de Hardware, Administrador, etc.):',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ej: Especialista de Sistemas e Inventario',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                          prefixIcon: const Icon(Icons.description, color: Color(0xFF3AD8FF)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF3AD8FF)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 12),

                      // SECCIÓN CONTRASEÑA
                      Row(
                        children: const [
                          Icon(Icons.shield_outlined, color: Color(0xFF3AD8FF), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Contraseña de Acceso (Opcional)',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FutureBuilder<bool>(
                        future: AuthService.tieneContrasena(usuario.nombre),
                        builder: (context, snapshot) {
                          final tienePass = snapshot.data ?? false;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: tienePass ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: tienePass ? Colors.greenAccent : Colors.orangeAccent,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  tienePass ? Icons.lock : Icons.lock_open,
                                  size: 14,
                                  color: tienePass ? Colors.greenAccent : Colors.orangeAccent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tienePass ? 'Perfil protegido con contraseña' : 'Sin contraseña (acceso directo)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: tienePass ? Colors.greenAccent : Colors.orangeAccent,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      if (errorMsg != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(errorMsg!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ),
                      if (successMsg != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(successMsg!, style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                        ),
                      TextField(
                        controller: passController,
                        obscureText: !mostrarPass,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nueva Contraseña',
                          labelStyle: const TextStyle(color: Color(0xFF3AD8FF)),
                          prefixIcon: const Icon(Icons.key, color: Color(0xFF3AD8FF)),
                          suffixIcon: IconButton(
                            icon: Icon(mostrarPass ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                            onPressed: () => setModalState(() => mostrarPass = !mostrarPass),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF3AD8FF)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: confirmPassController,
                        obscureText: !mostrarPass,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Confirmar Contraseña',
                          labelStyle: const TextStyle(color: Color(0xFF3AD8FF)),
                          prefixIcon: const Icon(Icons.key_outlined, color: Color(0xFF3AD8FF)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF3AD8FF)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                FutureBuilder<bool>(
                  future: AuthService.tieneContrasena(usuario.nombre),
                  builder: (context, snapshot) {
                    final tienePass = snapshot.data ?? false;
                    if (!tienePass) return const SizedBox.shrink();
                    return TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Quitar Contraseña', style: TextStyle(fontSize: 12)),
                      onPressed: () async {
                        await AuthService.eliminarContrasena(usuario.nombre);
                        setModalState(() {
                          passController.clear();
                          confirmPassController.clear();
                          errorMsg = null;
                          successMsg = 'Contraseña eliminada correctamente';
                        });
                      },
                    );
                  },
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3AD8FF),
                    foregroundColor: const Color(0xFF050B14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final p1 = passController.text.trim();
                    final p2 = confirmPassController.text.trim();

                    // Guardar Descripción
                    await AuthService.guardarDescripcion(usuario.nombre, descController.text);

                    // Guardar Contraseña si fue especificada
                    if (p1.isNotEmpty) {
                      if (p1 != p2) {
                        setModalState(() {
                          errorMsg = 'Las contraseñas no coinciden';
                          successMsg = null;
                        });
                        return;
                      }
                      await AuthService.guardarContrasena(usuario.nombre, p1);
                      passController.clear();
                      confirmPassController.clear();
                    }

                    setModalState(() {
                      errorMsg = null;
                      successMsg = '¡Perfil actualizado con éxito!';
                    });
                  },
                  child: const Text('Guardar Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hooks
    final panelActivo = useState(
      0,
    ); // 0 = Componentes Internos, 1 = Periféricos Externos
    final idHovered = useState<String?>(null);

    return Scaffold(
      backgroundColor: const Color(0xFF050B14),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/img/icon_ovnicore.png', width: 30, height: 30),
            const SizedBox(width: 10),
            const Text('OvniCore Dashboard'),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0E1726),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFF0E1726)),
        child: Row(
          children: [
            // PANEL IZQUIERDO (Ancho fijo de 280px)
            _buildLeftPanel(context, panelActivo),
            // PANEL DERECHO (Expanded)
            Expanded(
              child: _buildRightPanel(context, panelActivo.value, idHovered),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF3AD8FF),
        foregroundColor: const Color(0xFF050B14),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AgregarProductoScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Añadir nuevo componente',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context, ValueNotifier<int> panelActivo) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: const Color(0xFF007AFF).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Image.asset('assets/img/icon_ovnicore.png', width: 80, height: 80),
          const SizedBox(height: 16),
          const Text(
            'OvniCore\nCentro de Datos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          // 1. Buscador de Inventario
          _buildTab(
            title: 'Buscador de Inventario',
            icon: Icons.search,
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const InventarioListScreen(categoriaFiltro: null),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // 2. Componentes Internos
          _buildTab(
            title: 'Componentes Internos',
            icon: Icons.developer_board,
            isActive: panelActivo.value == 0,
            onTap: () => panelActivo.value = 0,
          ),
          const SizedBox(height: 8),

          // 3. Componentes Externos
          _buildTab(
            title: 'Componentes Externos',
            icon: Icons.mouse,
            isActive: panelActivo.value == 1,
            onTap: () => panelActivo.value = 1,
          ),
          const SizedBox(height: 8),

          // 4. Registro de Ventas
          _buildTab(
            title: 'Registro de Ventas',
            icon: Icons.monetization_on,
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegistroVentasScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // 5. Tabla de Posiciones
          _buildTab(
            title: 'Tabla de Posiciones',
            icon: Icons.emoji_events,
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TablaPosicionesScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // 6. Historial y Auditoría
          _buildTab(
            title: 'Historial y Auditoría',
            icon: Icons.history,
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistorialAuditoriaScreen(),
                ),
              );
            },
          ),
          const Spacer(),
          // Active User Profile Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF050B14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3AD8FF).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => _mostrarDialogoPerfil(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF3AD8FF).withValues(alpha: 0.2),
                            child: const Icon(
                              Icons.person,
                              size: 18,
                              color: Color(0xFF3AD8FF),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AuthService.usuarioActual.nombre,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                FutureBuilder<String?>(
                                  future: AuthService.obtenerDescripcion(AuthService.usuarioActual.nombre),
                                  builder: (context, snapshot) {
                                    final desc = snapshot.data;
                                    if (desc == null || desc.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      desc,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.settings, color: Color(0xFF3AD8FF), size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3AD8FF),
                            side: BorderSide(color: const Color(0xFF3AD8FF).withValues(alpha: 0.5), width: 0.8),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 28),
                          ),
                          icon: const Icon(Icons.lock_person, size: 12),
                          label: const Text('Mi Perfil', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          onPressed: () => _mostrarDialogoPerfil(context),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.6), width: 0.8),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 28),
                          ),
                          icon: const Icon(Icons.logout, size: 12),
                          label: const Text('Cambiar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // KPIs section at the bottom of the left panel
          _buildKpisSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF3AD8FF).withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? const Color(0xFF3AD8FF) : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF3AD8FF) : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.white : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpisSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('inventario').snapshots(),
      builder: (context, snapshot) {
        int totalActivos = 0;
        int alertasCriticas = 0;

        if (snapshot.hasData && snapshot.data != null) {
          final docs = snapshot.data!.docs;
          totalActivos = docs.length;
          final todosLosProductos = docs.map((doc) {
            return ProductoModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
          alertasCriticas = todosLosProductos
              .where((p) => p.atributosAdministrativos['id_activo'] == '001')
              .length;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              _buildMiniKpi(
                'TOTAL ACTIVOS',
                '$totalActivos',
                Colors.blueAccent,
                Icons.inventory_2,
              ),
              const SizedBox(height: 8),
              _buildMiniKpi(
                'ALERTAS CRÍTICAS',
                '$alertasCriticas',
                Colors.redAccent,
                Icons.gpp_maybe,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniKpi(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF050B14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(
    BuildContext context,
    int panelActivo,
    ValueNotifier<String?> idHovered,
  ) {
    final categorias = panelActivo == 0
        ? _getComponentesInternos()
        : _getPerifericosExternos();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            panelActivo == 0 ? 'Componentes Internos' : 'Periféricos Externos',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              clipBehavior: Clip.none,
              itemCount: categorias.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 2.2,
              ),
              itemBuilder: (context, index) {
                final cat = categorias[index];
                return _buildGridCard(context, cat, idHovered);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context,
    Map<String, dynamic> cat,
    ValueNotifier<String?> idHovered,
  ) {
    final bool isHovered = idHovered.value == cat['id'];

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: MouseRegion(
        onEnter: (_) => idHovered.value = cat['id'],
        onExit: (_) => idHovered.value = null,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    InventarioListScreen(categoriaFiltro: cat['id']),
              ),
            );
          },
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHovered
                      ? const Color(0xFF3AD8FF)
                      : const Color(0xFF007AFF).withOpacity(0.5),
                  width: isHovered ? 2 : 1,
                ),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                          color: const Color(0xFF3AD8FF).withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    clipBehavior: Clip.none,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(11),
                        bottomLeft: Radius.circular(11),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/img/${cat['id']}.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              if (cat['id'] == 'almacenamiento_ssd_hdd') {
                                return Image.asset(
                                  'assets/img/ssd_storage.png',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      cat['icon'],
                                      size: 32,
                                      color: const Color(0xFF3AD8FF),
                                    );
                                  },
                                );
                              }
                              return Icon(
                                cat['icon'],
                                size: 32,
                                color: const Color(0xFF3AD8FF),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        cat['title'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(
                            0xFF3AD8FF,
                          ), // Títulos en Cyber Cyan para resaltar en el fondo oscuro
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: isHovered
                          ? const Color(0xFF3AD8FF)
                          : const Color(0xFF007AFF),
                      size: 16,
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

  List<Map<String, dynamic>> _getComponentesInternos() {
    return [
      {
        'id': 'procesador_cpu',
        'title': 'Procesadores (CPU)',
        'icon': Icons.memory,
      },
      {
        'id': 'tarjeta_madre',
        'title': 'Tarjetas Madre (Motherboard)',
        'icon': Icons.developer_board,
      },
      {'id': 'memoria_ram', 'title': 'Memoria RAM', 'icon': Icons.memory},
      {
        'id': 'almacenamiento_ssd_hdd',
        'title': 'Almacenamiento (SSD / HDD)',
        'icon': Icons.storage,
      },
      {
        'id': 'tarjeta_grafica',
        'title': 'Tarjetas Gráficas (GPU)',
        'icon': Icons.extension,
      },
      {
        'id': 'fuente_poder',
        'title': 'Fuentes de Poder (PSU)',
        'icon': Icons.power,
      },
      {
        'id': 'gabinete_chasis',
        'title': 'Gabinetes / Chasis',
        'icon': Icons.desktop_windows,
      },
      {
        'id': 'disipador_cpu',
        'title': 'Disipadores de CPU',
        'icon': Icons.ac_unit,
      },
      {
        'id': 'ventiladores_chasis',
        'title': 'Ventiladores de Chasis',
        'icon': Icons.air,
      },
    ];
  }

  List<Map<String, dynamic>> _getPerifericosExternos() {
    return [
      {'id': 'monitor', 'title': 'Monitores', 'icon': Icons.monitor},
      {'id': 'teclado', 'title': 'Teclados', 'icon': Icons.keyboard},
      {'id': 'mouse', 'title': 'Mouses', 'icon': Icons.mouse},
      {
        'id': 'auriculares_altavoces',
        'title': 'Auriculares y Audio',
        'icon': Icons.headset,
      },
    ];
  }
}
