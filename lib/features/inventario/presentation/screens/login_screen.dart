import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

                // TARJETAS DE USUARIO (MIGUEL, KEVIN, DIEGO, EDGARDO)
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
                    final esAdmin = usuario.esAdmin;

                    return InkWell(
                      onTap: () {
                        AuthService.iniciarSesion(usuario);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const DashboardScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1726),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: esAdmin
                                ? const Color(0xFF3AD8FF)
                                : const Color(0xFF007AFF).withValues(alpha: 0.4),
                            width: esAdmin ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (esAdmin ? const Color(0xFF3AD8FF) : const Color(0xFF007AFF))
                                  .withValues(alpha: 0.15),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: (esAdmin ? const Color(0xFF3AD8FF) : const Color(0xFF007AFF))
                                  .withValues(alpha: 0.2),
                              child: Icon(
                                esAdmin ? Icons.admin_panel_settings : Icons.engineering,
                                color: esAdmin ? const Color(0xFF3AD8FF) : const Color(0xFF007AFF),
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        usuario.nombre,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (esAdmin ? Colors.purpleAccent : const Color(0xFF007AFF))
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: (esAdmin ? Colors.purpleAccent : const Color(0xFF007AFF))
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Text(
                                          usuario.rol.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: esAdmin ? Colors.purpleAccent : const Color(0xFF3AD8FF),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    usuario.cargo,
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Color(0xFF3AD8FF), size: 18),
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
