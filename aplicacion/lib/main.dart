import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/api_config.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquear orientación vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await ApiConfig.load();
  await ApiService().init();

  runApp(const MapaApp());
}

class MapaApp extends StatelessWidget {
  const MapaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MapaApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D5C8C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      // Ruta inicial según si hay token guardado
      home: ApiService().isLoggedIn ? const MapScreen() : const LoginScreen(),
      routes: {
        '/login':    (_) => const LoginScreen(),
        '/map':      (_) => const MapScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
