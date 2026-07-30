import 'package:shared_preferences/shared_preferences.dart';

class UsuarioModel {
  final String nombre;

  bool get esAdmin => true;

  const UsuarioModel({
    required this.nombre,
  });
}

class AuthService {
  static final List<UsuarioModel> usuariosDisponibles = const [
    UsuarioModel(nombre: 'Miguel'),
    UsuarioModel(nombre: 'Kevin'),
    UsuarioModel(nombre: 'Diego'),
    UsuarioModel(nombre: 'Edgardo'),
  ];

  static UsuarioModel _usuarioActual = usuariosDisponibles.first;

  static UsuarioModel get usuarioActual => _usuarioActual;

  static void iniciarSesion(UsuarioModel usuario) {
    _usuarioActual = usuario;
  }

  // Clave en SharedPreferences para la contraseña del usuario
  static String _getKey(String nombre) => 'user_password_${nombre.trim().toLowerCase()}';

  static Future<bool> tieneContrasena(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    final pass = prefs.getString(_getKey(nombre));
    return pass != null && pass.isNotEmpty;
  }

  static Future<bool> verificarContrasena(String nombre, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPass = prefs.getString(_getKey(nombre));
    if (savedPass == null || savedPass.isEmpty) return true;
    return savedPass == password;
  }

  static Future<void> guardarContrasena(String nombre, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getKey(nombre), password);
  }

  static Future<void> eliminarContrasena(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getKey(nombre));
  }

  // Descripción opcional del perfil
  static String _getDescKey(String nombre) => 'user_desc_${nombre.trim().toLowerCase()}';

  static Future<String?> obtenerDescripcion(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    final desc = prefs.getString(_getDescKey(nombre));
    if (desc == null || desc.trim().isEmpty) return null;
    return desc.trim();
  }

  static Future<void> guardarDescripcion(String nombre, String descripcion) async {
    final prefs = await SharedPreferences.getInstance();
    if (descripcion.trim().isEmpty) {
      await prefs.remove(_getDescKey(nombre));
    } else {
      await prefs.setString(_getDescKey(nombre), descripcion.trim());
    }
  }
}


