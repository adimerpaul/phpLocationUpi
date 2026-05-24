import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _prefKey = 'api_base_url';
  static const String defaultUrl =
      'https://b958-2800-cd0-af7c-2e00-b5fd-30bf-36a2-b533.ngrok-free.app/mapa';

  static String _baseUrl = defaultUrl;

  static String get baseUrl => _baseUrl;
  static String get apiUrl => '$_baseUrl/api';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_prefKey) ?? defaultUrl;
  }

  static Future<void> save(String url) async {
    // Quitar barra final si la hay
    _baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _baseUrl);
  }
}
