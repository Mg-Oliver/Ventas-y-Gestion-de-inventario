class UsuarioModel {
  final String nombre;
  final String rol; // 'Admin' | 'Técnico'
  final String cargo;
  final bool esAdmin;

  const UsuarioModel({
    required this.nombre,
    required this.rol,
    required this.cargo,
    this.esAdmin = false,
  });
}

class AuthService {
  static final List<UsuarioModel> usuariosDisponibles = const [
    UsuarioModel(
      nombre: 'Miguel',
      rol: 'Admin',
      cargo: 'Administrador Principal de OvniCore',
      esAdmin: true,
    ),
    UsuarioModel(
      nombre: 'Kevin',
      rol: 'Técnico',
      cargo: 'Técnico Especialista de Sistemas',
      esAdmin: false,
    ),
    UsuarioModel(
      nombre: 'Diego',
      rol: 'Técnico',
      cargo: 'Técnico de Hardware e Inventario',
      esAdmin: false,
    ),
    UsuarioModel(
      nombre: 'Edgardo',
      rol: 'Técnico',
      cargo: 'Técnico de Infraestructura y Redes',
      esAdmin: false,
    ),
  ];

  static UsuarioModel _usuarioActual = usuariosDisponibles.first; // Miguel (Admin) por defecto

  static UsuarioModel get usuarioActual => _usuarioActual;

  static void iniciarSesion(UsuarioModel usuario) {
    _usuarioActual = usuario;
  }
}
