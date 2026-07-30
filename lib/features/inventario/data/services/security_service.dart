class SecurityService {
  static DateTime? _ultimoEnvio;
  static int _intentosRecientes = 0;
  static DateTime? _inicioVentanaIntentos;

  // Configuración de Límites de Seguridad
  static const int _cooldownSegundos = 3; // Mínimo 3s entre registros
  static const int _maxEnviosPorMinuto = 6; // Máximo 6 registros por minuto

  /// Sanitiza cadenas de texto para evitar ataques de Inyección HTML/JS (XSS) y Scripts
  static String sanitizarTexto(String input) {
    if (input.isEmpty) return input;

    // 1. Eliminar etiquetas de script e HTML malicioso
    String limpio = input
        .replaceAll(RegExp(r'<script[^>]*>([\s\S]*?)<\/script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'vbscript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'onload\s*=', caseSensitive: false), '')
        .replaceAll(RegExp(r'onerror\s*=', caseSensitive: false), '');

    return limpio.trim();
  }

  /// Valida que la URL de imagen sea segura y no contenga código ejecutable
  static bool esUrlImagenSegura(String url) {
    final urlLimpia = url.trim().toLowerCase();
    if (urlLimpia.isEmpty) return true;

    // Permitir imágenes Data URL (base64) o enlaces estándar HTTP/HTTPS
    if (urlLimpia.startsWith('data:image/')) return true;
    if (urlLimpia.startsWith('http://') || urlLimpia.startsWith('https://')) {
      // Bloquear scripts y esquemas peligrosos
      if (urlLimpia.contains('javascript:') ||
          urlLimpia.contains('<script>') ||
          urlLimpia.contains('vbscript:')) {
        return false;
      }
      return true;
    }

    return false;
  }

  /// Verifica si la solicitud sobrepasa el límite de frecuencia (Rate Limiting Anti-Spam)
  static String? validarRateLimit() {
    final ahora = DateTime.now();

    // 1. Verificar Cooldown mínimo entre envíos consecutivos
    if (_ultimoEnvio != null) {
      final diferenciaCooldown = ahora.difference(_ultimoEnvio!).inSeconds;
      if (diferenciaCooldown < _cooldownSegundos) {
        final espera = _cooldownSegundos - diferenciaCooldown;
        return '🛡️ Protección Anti-Bot: Por favor espera $espera segundo(s) antes de realizar otro registro.';
      }
    }

    // 2. Verificar Ventana de Intentos Máximos por Minuto
    if (_inicioVentanaIntentos == null || ahora.difference(_inicioVentanaIntentos!).inMinutes >= 1) {
      _inicioVentanaIntentos = ahora;
      _intentosRecientes = 1;
    } else {
      _intentosRecientes++;
      if (_intentosRecientes > _maxEnviosPorMinuto) {
        return '🛑 Alerta de Seguridad: Demasiadas operaciones detectadas en un corto periodo. Límite alcanzado, intenta de nuevo en 1 minuto.';
      }
    }

    return null; // Validación exitosa
  }

  /// Devuelve true si la frecuencia actual amerita mostrar un desafío de verificación de humanidad (CAPTCHA)
  static bool requiereVerificacionCaptcha() {
    return _intentosRecientes >= 3;
  }

  /// Registra la marca de tiempo de un envío exitoso
  static void registrarEnvioExitoso() {
    _ultimoEnvio = DateTime.now();
  }

  /// Trampa Honeypot: Si un bot llena un campo oculto invisible para humanos, devuelve true
  static bool esAtaqueBotDetectado(String valorHoneypot) {
    return valorHoneypot.trim().isNotEmpty;
  }
}
