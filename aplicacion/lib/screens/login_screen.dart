import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // Login fields
  final _lUser = TextEditingController();
  final _lPass = TextEditingController();

  // Register fields
  final _rNombre   = TextEditingController();
  final _rUsuario  = TextEditingController();
  final _rPass     = TextEditingController();
  final _rCargo    = TextEditingController();
  final _rDomicilio = TextEditingController();

  bool _obscureL = true;
  bool _obscureR = true;
  bool _loading  = false;
  String? _error;

  static const Color _dark  = Color(0xFF07304F);
  static const Color _mid   = Color(0xFF0D5C8C);
  static const Color _light = Color(0xFF1A85C2);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in [_lUser, _lPass, _rNombre, _rUsuario, _rPass, _rCargo, _rDomicilio]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── UI helpers ──────────────────────────────────────────────

  InputDecoration _inputDec(String hint, {IconData? icon}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white60, size: 20) : null,
        filled: true,
        fillColor: Colors.white12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      );

  TextStyle get _label => const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      );

  Widget _field(String label, TextEditingController ctrl, String hint,
      {bool obscure = false,
      VoidCallback? toggleObscure,
      TextInputType keyboard = TextInputType.text,
      IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _label),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboard,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDec(hint, icon: icon).copyWith(
            suffixIcon: toggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: toggleObscure,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ── Actions ─────────────────────────────────────────────────

  Future<void> _doLogin() async {
    if (_lUser.text.trim().isEmpty || _lPass.text.isEmpty) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService().login(_lUser.text.trim(), _lPass.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/map');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Error de conexión. Verifica la URL del servidor.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doRegistro() async {
    if (_rNombre.text.trim().isEmpty ||
        _rUsuario.text.trim().isEmpty ||
        _rPass.text.isEmpty) {
      setState(() => _error = 'Nombre, usuario y contraseña son obligatorios');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService().registro(
        nombre:    _rNombre.text.trim(),
        usuario:   _rUsuario.text.trim(),
        password:  _rPass.text,
        cargo:     _rCargo.text.trim(),
        domicilio: _rDomicilio.text.trim(),
      );
      if (!mounted) return;
      setState(() => _error = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada. Ahora inicia sesión.')),
      );
      _tab.animateTo(0);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Error de conexión. Verifica la URL del servidor.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_dark, _mid, _light],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Acción de settings (URL)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white70),
                  tooltip: 'Configurar servidor',
                  onPressed: () => Navigator.pushNamed(context, '/settings').then((_) => setState(() {})),
                ),
              ),

              // Logo
              const SizedBox(height: 8),
              _buildLogo(),
              const SizedBox(height: 24),

              // Card con tabs
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Tab selector
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          controller: _tab,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          dividerColor: Colors.transparent,
                          labelColor: _mid,
                          unselectedLabelColor: Colors.white54,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          tabs: const [
                            Tab(text: 'Iniciar Sesión'),
                            Tab(text: 'Registrarse'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Error alert
                      if (_error != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                          ),
                          child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ),

                      // Forms
                      SizedBox(
                        height: _tab.index == 0 ? 280 : 420,
                        child: TabBarView(
                          controller: _tab,
                          children: [_buildLoginForm(), _buildRegisterForm()],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/logo.png',
      height: 160,
      fit: BoxFit.contain,
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _field('Usuario', _lUser, 'Tu nombre de usuario', icon: Icons.person_outline),
        _field('Contraseña', _lPass, '••••••••',
            obscure: _obscureL,
            toggleObscure: () => setState(() => _obscureL = !_obscureL),
            icon: Icons.lock_outline),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _mid,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            onPressed: _loading ? null : _doLogin,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Iniciar Sesión'),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        _field('Nombre completo *', _rNombre, 'Tu nombre', icon: Icons.badge_outlined),
        _field('Usuario *', _rUsuario, 'Nombre de usuario', icon: Icons.person_outline),
        _field('Contraseña *', _rPass, 'Mínimo 6 caracteres',
            obscure: _obscureR,
            toggleObscure: () => setState(() => _obscureR = !_obscureR),
            icon: Icons.lock_outline),
        _field('Cargo', _rCargo, 'Tu cargo (opcional)', icon: Icons.work_outline),
        _field('Domicilio', _rDomicilio, 'Dirección (opcional)', icon: Icons.home_outlined),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _mid,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            onPressed: _loading ? null : _doRegistro,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Crear Cuenta'),
          ),
        ),
      ],
    );
  }
}
