import 'dart:convert';
import 'package:http/http.dart' as http;

class ComponentesApiService {
  /// Devuelve el sticker oficial correspondiente a la generación del procesador (Intel / AMD)
  static String? obtenerStickerEspecificoGeneracion(String marca, String modelo) {
    final mUpper = marca.toUpperCase();
    final modUpper = modelo.toUpperCase();

    // INTEL
    if (mUpper.contains('INTEL') || modUpper.contains('CORE') || modUpper.contains('INTEL')) {
      if (modUpper.contains('I9') || modUpper.contains('CORE 9')) {
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Intel_Core_i9_badge_%282020%29.svg/600px-Intel_Core_i9_badge_%282020%29.svg.png';
      }
      if (modUpper.contains('I7') || modUpper.contains('CORE 7')) {
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Intel_Core_i7_badge_%282020%29.svg/600px-Intel_Core_i7_badge_%282020%29.svg.png';
      }
      if (modUpper.contains('I5') || modUpper.contains('CORE 5')) {
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Intel_Core_i5_badge_%282020%29.svg/600px-Intel_Core_i5_badge_%282020%29.svg.png';
      }
      if (modUpper.contains('I3') || modUpper.contains('CORE 3')) {
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c9/Intel_Core_i3_badge_%282020%29.svg/600px-Intel_Core_i3_badge_%282020%29.svg.png';
      }
      if (modUpper.contains('ULTRA')) {
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Intel_Core_Ultra_logo.svg/600px-Intel_Core_Ultra_logo.svg.png';
      }
      if (modUpper.contains('PENTIUM')) {
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/Intel_Pentium_Gold_logo.svg/600px-Intel_Pentium_Gold_logo.svg.png';
      }
      if (modUpper.contains('CELERON')) {
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Intel_Celeron_logo.svg/600px-Intel_Celeron_logo.svg.png';
      }
    }

    // AMD
    if (mUpper.contains('AMD') || modUpper.contains('RYZEN') || modUpper.contains('ATHLON') || modUpper.contains('THREADRIPPER')) {
      if (modUpper.contains('THREADRIPPER')) {
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/AMD_Threadripper_logo.svg/600px-AMD_Threadripper_logo.svg.png';
      }
      if (modUpper.contains('RYZEN 9') || modUpper.contains('R9')) {
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/AMD_Ryzen_9_logo.svg/600px-AMD_Ryzen_9_logo.svg.png';
      }
      if (modUpper.contains('RYZEN 7') || modUpper.contains('R7')) {
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7c/AMD_Ryzen_7_logo.svg/600px-AMD_Ryzen_7_logo.svg.png';
      }
      if (modUpper.contains('RYZEN 5') || modUpper.contains('R5')) {
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/AMD_Ryzen_5_logo.svg/600px-AMD_Ryzen_5_logo.svg.png';
      }
      if (modUpper.contains('RYZEN 3') || modUpper.contains('R3')) {
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/AMD_Ryzen_3_logo.svg/600px-AMD_Ryzen_3_logo.svg.png';
      }
      if (modUpper.contains('ATHLON')) {
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/AMD_Athlon_logo.svg/600px-AMD_Athlon_logo.svg.png';
      }
    }

    return null;
  }

  /// Busca una lista de múltiples opciones de imágenes reales y stickers consultando múltiples APIs.
  static Future<List<String>> buscarListaImagenesComponente(String marca, String modelo) async {
    final queryLimpio = '$marca $modelo'.trim();
    if (queryLimpio.isEmpty) return [];

    final List<String> resultados = [];
    final Set<String> urlsUnicas = {};

    // API 1: Resolver Específico de Stickers por Generación de Procesador
    final stickerGeneracion = obtenerStickerEspecificoGeneracion(marca, modelo);
    if (stickerGeneracion != null && !urlsUnicas.contains(stickerGeneracion)) {
      urlsUnicas.add(stickerGeneracion);
      resultados.add(stickerGeneracion);
    }

    final searchTerms = [
      '$queryLimpio generation badge sticker',
      '$queryLimpio sticker logo',
      '$queryLimpio case badge',
      queryLimpio,
      '$queryLimpio processor',
    ];

    for (final term in searchTerms) {
      // API 2: Wikimedia Commons API
      final commonsImgs = await _buscarVariasEnWikimediaCommons(term);
      for (final url in commonsImgs) {
        if (!urlsUnicas.contains(url)) {
          urlsUnicas.add(url);
          resultados.add(url);
        }
      }

      // API 3: Wikipedia API (Inglés)
      if (resultados.length < 5) {
        final wikiImgs = await _buscarVariasEnWikipedia(term, lang: 'en');
        for (final url in wikiImgs) {
          if (!urlsUnicas.contains(url)) {
            urlsUnicas.add(url);
            resultados.add(url);
          }
        }
      }

      // API 4: Wikipedia API (Español)
      if (resultados.length < 6) {
        final wikiEsImgs = await _buscarVariasEnWikipedia(term, lang: 'es');
        for (final url in wikiEsImgs) {
          if (!urlsUnicas.contains(url)) {
            urlsUnicas.add(url);
            resultados.add(url);
          }
        }
      }

      // API 5: Openverse API (Creative Commons Media Engine)
      if (resultados.length < 7) {
        final openverseImgs = await _buscarEnOpenverse(term);
        for (final url in openverseImgs) {
          if (!urlsUnicas.contains(url)) {
            urlsUnicas.add(url);
            resultados.add(url);
          }
        }
      }

      if (resultados.length >= 8) break;
    }

    return resultados;
  }

  /// Busca una única imagen de fallback para compatibilidad
  static Future<String?> buscarImagenComponente(String marca, String modelo) async {
    final lista = await buscarListaImagenesComponente(marca, modelo);
    return lista.isNotEmpty ? lista.first : null;
  }

  /// API 2: Consulta la API de Wikimedia Commons retornando varias imágenes
  static Future<List<String>> _buscarVariasEnWikimediaCommons(String searchTerm) async {
    final List<String> urls = [];
    try {
      final uri = Uri.parse(
        'https://commons.wikimedia.org/w/api.php'
        '?action=query'
        '&origin=*'
        '&generator=search'
        '&gsrsearch=${Uri.encodeComponent(searchTerm)}'
        '&gsrlimit=8'
        '&prop=pageimages'
        '&piprop=thumbnail'
        '&pithumbsize=600'
        '&format=json',
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'OvniCoreInventarioApp/1.0 (contacto@ovnicore.com)'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['query'] != null && data['query']['pages'] != null) {
          final Map<String, dynamic> pages = data['query']['pages'];
          for (final page in pages.values) {
            if (page['thumbnail'] != null && page['thumbnail']['source'] != null) {
              final String imgUrl = page['thumbnail']['source'];
              if (!imgUrl.toLowerCase().endsWith('.svg')) {
                urls.add(imgUrl);
              }
            }
          }
        }
      }
    } catch (_) {}
    return urls;
  }

  /// API 3 & 4: Consulta la API de Wikipedia (English / Spanish)
  static Future<List<String>> _buscarVariasEnWikipedia(String searchTerm, {String lang = 'en'}) async {
    final List<String> urls = [];
    try {
      final uri = Uri.parse(
        'https://$lang.wikipedia.org/w/api.php'
        '?action=query'
        '&origin=*'
        '&generator=search'
        '&gsrsearch=${Uri.encodeComponent(searchTerm)}'
        '&gsrlimit=6'
        '&prop=pageimages'
        '&piprop=thumbnail'
        '&pithumbsize=600'
        '&format=json',
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'OvniCoreInventarioApp/1.0 (contacto@ovnicore.com)'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['query'] != null && data['query']['pages'] != null) {
          final Map<String, dynamic> pages = data['query']['pages'];
          for (final page in pages.values) {
            if (page['thumbnail'] != null && page['thumbnail']['source'] != null) {
              final String imgUrl = page['thumbnail']['source'];
              if (!imgUrl.toLowerCase().endsWith('.svg')) {
                urls.add(imgUrl);
              }
            }
          }
        }
      }
    } catch (_) {}
    return urls;
  }

  /// API 5: Consulta la API de Openverse (Creative Commons Search)
  static Future<List<String>> _buscarEnOpenverse(String searchTerm) async {
    final List<String> urls = [];
    try {
      final uri = Uri.parse(
        'https://api.openverse.engineering/v1/images/'
        '?q=${Uri.encodeComponent(searchTerm)}'
        '&page_size=5',
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'OvniCoreInventarioApp/1.0 (contacto@ovnicore.com)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          final List results = data['results'];
          for (final item in results) {
            if (item['url'] != null && item['url'].toString().startsWith('http')) {
              final String url = item['url'].toString();
              if (!url.toLowerCase().endsWith('.svg')) {
                urls.add(url);
              }
            }
          }
        }
      }
    } catch (_) {}
    return urls;
  }
}
