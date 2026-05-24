import 'package:flutter/material.dart';
import '../config/api_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlCtrl;
  bool _saved = false;

  static const Color _blue  = Color(0xFF0D5C8C);
  static const Color _blueD = Color(0xFF07304F);

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    await ApiConfig.save(url);
    setState(() => _saved = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL guardada. Reinicia la sesión para aplicarla.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _reset() {
    _urlCtrl.text = ApiConfig.defaultUrl;
    setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _blueD,
        foregroundColor: Colors.white,
        title: const Text('Configuración', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección URL
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_outlined, color: _blue, size: 20),
                      const SizedBox(width: 8),
                      const Text('URL del servidor backend',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ingresa la URL base del backend (ngrok u otro). '
                    'No incluyas /api al final.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _urlCtrl,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    onChanged: (_) => setState(() => _saved = false),
                    decoration: InputDecoration(
                      hintText: 'https://xxxx.ngrok-free.app/mapa',
                      prefixIcon: const Icon(Icons.link, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // URL actual
            Text('URL actual: ${ApiConfig.baseUrl}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),

            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('Restaurar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _reset,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: _saved
                        ? const Icon(Icons.check, size: 18)
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(_saved ? '¡Guardado!' : 'Guardar URL'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _saved ? Colors.green : _blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: _save,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Tip ngrok
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Si usas ngrok, la URL cambia cada vez que reinicias el túnel. '
                      'Actualízala aquí cuando cambie.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
