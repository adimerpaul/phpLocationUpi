import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/ubicacion.dart';

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'Sesión expirada']);
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _i = ApiService._();
  factory ApiService() => _i;
  ApiService._();

  String? _token;
  Usuario? _currentUser;

  String? get token => _token;
  Usuario? get currentUser => _currentUser;
  bool get isLoggedIn => _token != null;

  // Carga el token guardado en disco
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final raw = prefs.getString('usuario');
    if (raw != null) {
      try {
        _currentUser = Usuario.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  String get _api => ApiConfig.apiUrl;

  // ── Auth ──────────────────────────────────────────────────────

  Future<Usuario> login(String usuario, String password) async {
    final res = await http
        .post(
          Uri.parse('$_api/usuarios/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'usuario': usuario, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(data['error'] ?? 'Error al iniciar sesión');
    }

    _token = data['token'];
    _currentUser = Usuario.fromJson(data['usuario']);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('usuario', jsonEncode(_currentUser!.toJson()));
    return _currentUser!;
  }

  Future<void> registro({
    required String nombre,
    required String usuario,
    required String password,
    String? cargo,
    String? domicilio,
  }) async {
    final body = <String, String>{
      'nombre': nombre,
      'usuario': usuario,
      'password': password,
    };
    if (cargo != null && cargo.isNotEmpty) body['cargo'] = cargo;
    if (domicilio != null && domicilio.isNotEmpty) body['domicilio'] = domicilio;

    final res = await http
        .post(
          Uri.parse('$_api/usuarios/registro'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 201) {
      final msg = data['error'] ??
          (data['errors'] as Map?)?.values.join(' · ') ??
          'Error al registrarse';
      throw ApiException(msg.toString());
    }
  }

  Future<void> logout() async {
    try {
      await http.post(Uri.parse('$_api/usuarios/logout'), headers: _headers);
    } catch (_) {}
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('usuario');
  }

  // ── Ubicaciones ───────────────────────────────────────────────

  Future<List<Ubicacion>> getUbicaciones() async {
    final res = await http
        .get(Uri.parse('$_api/ubicaciones'), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 401) throw const UnauthorizedException();
    final List data = jsonDecode(res.body);
    return data.map((j) => Ubicacion.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Ubicacion> createUbicacion({
    required String nombre,
    required double lat,
    required double lng,
    String? descripcion,
    File? imagen,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_api/ubicaciones'),
    )..headers['Authorization'] = 'Bearer $_token';

    request.fields['nombre'] = nombre;
    request.fields['lat']    = lat.toString();
    request.fields['lng']    = lng.toString();
    if (descripcion != null && descripcion.isNotEmpty) {
      request.fields['descripcion'] = descripcion;
    }
    if (imagen != null) {
      request.files.add(
        await http.MultipartFile.fromPath('imagen', imagen.path),
      );
    }

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final res      = await http.Response.fromStream(streamed);

    if (res.statusCode == 401) throw const UnauthorizedException();
    if (res.statusCode != 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw ApiException(data['error'] ??
          (data['errors'] as Map?)?.values.join(' · ') ??
          'Error al crear ubicación');
    }
    return Ubicacion.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteUbicacion(int id) async {
    final res = await http
        .delete(Uri.parse('$_api/ubicaciones/$id'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 401) throw const UnauthorizedException();
  }
}
