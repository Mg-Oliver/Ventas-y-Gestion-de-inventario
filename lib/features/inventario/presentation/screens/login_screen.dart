import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _seleccionarUsuario(UsuarioModel usuario) async {
    final tienePass = await AuthService.tieneContrasena(usuario.nombre);
    if (!mounted) return;

    if (tienePass) {
      _mostrarDialogoContrasena(usuario);
    } else {
      AuthService.iniciarSesion(usuario);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  void _mostrarDialogoContrasena(UsuarioModel usuario) {
    final passController = TextEditingController();
    bool mostrarPass = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: true,
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
                  const Icon(Icons.lock_outline, color: Color(0xFF3AD8FF), size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Acceso Protegido: ${usuario.nombre}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Este perfil requiere contraseña para ingresar.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passController,
                    obscureText: !mostrarPass,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Contraseña de Acceso',
                      labelStyle: const TextStyle(color: Color(0xFF3AD8FF)),
                      prefixIcon: const Icon(Icons.key, color: Color(0xFF3AD8FF)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          mostrarPass ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setModalState(() {
                            mostrarPass = !mostrarPass;
                          });
                        },
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF3AD8FF)),
                      ),
                      errorText: errorText,
                    ),
                    onSubmitted: (_) async {
                      final ok = await AuthService.verificarContrasena(usuario.nombre, passController.text);
                      if (ok) {
                        AuthService.iniciarSesion(usuario);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const DashboardScreen()),
                        );
                      } else {
                        setModalState(() {
                          errorText = 'Contraseña incorrecta';
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3AD8FF),
                    foregroundColor: const Color(0xFF050B14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final ok = await AuthService.verificarContrasena(usuario.nombre, passController.text);
                    if (ok) {
                      AuthService.iniciarSesion(usuario);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const DashboardScreen()),
                      );
                    } else {
                      setModalState(() {
                        errorText = 'Contraseña incorrecta';
                      });
                    }
                  },
                  child: const Text('Ingresar', style: TextStyle(fontWeight: FontWeight.bold)),
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
    return Scaffold(
      backgroundColor: const Color(0xFF050B14),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO Y TÍTULO OVNICORE
                Image.asset('assets/img/icon_ovnicore.png', width: 100, height: 100),
                const SizedBox(height: 20),
                const Text(
                  'OvniCore Inventario',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona tu perfil de usuario para ingresar al Centro de Datos',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF3AD8FF), fontSize: 15),
                ),
                const SizedBox(height: 40),

                // TARJETAS DE USUARIOS (TODOS CON MISMO ROL Y ESTILO)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 2.3,
                  ),
                  itemCount: AuthService.usuariosDisponibles.length,
                  itemBuilder: (context, index) {
                    final usuario = AuthService.usuariosDisponibles[index];

                    return InkWell(
                      onTap: () => _seleccionarUsuario(usuario),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1726),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF3AD8FF).withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3AD8FF).withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xFF3AD8FF).withValues(alpha: 0.15),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF3AD8FF),
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    usuario.nombre,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  FutureBuilder<String?>(
                                    future: AuthService.obtenerDescripcion(usuario.nombre),
                                    builder: (context, snapshot) {
                                      final desc = snapshot.data;
                                      if (desc == null || desc.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          desc,
                                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            FutureBuilder<bool>(
                              future: AuthService.tieneContrasena(usuario.nombre),
                              builder: (context, snapshot) {
                                final tienePass = snapshot.data ?? false;
                                return Icon(
                                  tienePass ? Icons.lock : Icons.arrow_forward_ios,
                                  color: tienePass ? const Color(0xFF3AD8FF) : Colors.grey,
                                  size: tienePass ? 20 : 18,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

