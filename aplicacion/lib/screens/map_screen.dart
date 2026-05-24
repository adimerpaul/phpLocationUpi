import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import '../models/ubicacion.dart';
import '../services/api_service.dart';
import 'settings_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  final _api = ApiService();
  final _picker = ImagePicker();

  List<Ubicacion> _ubicaciones = [];
  bool _isSatellite = false;
  bool _loadingList  = false;

  // Add mode
  Marker? _tempMarker;

  static const Color _blue  = Color(0xFF0D5C8C);
  static const Color _blueD = Color(0xFF07304F);

  // ── Tile layers ─────────────────────────────────────────────

  TileLayer get _streetTile => TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.aplicacion',
      );

  TileLayer get _satTile => TileLayer(
        urlTemplate:
            'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        userAgentPackageName: 'com.example.aplicacion',
      );

  TileLayer get _labelTile => TileLayer(
        urlTemplate:
            'https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
        userAgentPackageName: 'com.example.aplicacion',
      );

  // ── Lifecycle ────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadUbicaciones();
  }

  // ── Data ─────────────────────────────────────────────────────

  Future<void> _loadUbicaciones() async {
    setState(() => _loadingList = true);
    try {
      final list = await _api.getUbicaciones();
      setState(() => _ubicaciones = list);
    } on UnauthorizedException {
      _handleUnauth();
    } catch (e) {
      _snack('Error al cargar ubicaciones: $e');
    } finally {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  void _handleUnauth() {
    _api.logout();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  // ── Map interactions ─────────────────────────────────────────

  void _onMapTap(TapPosition _, LatLng point) {
    setState(() {
      _tempMarker = _buildTempMarker(point);
    });
    _showAddSheet(point);
  }

  Marker _buildPinMarker(Ubicacion u) => Marker(
        point: LatLng(u.lat, u.lng),
        width: 40, height: 48,
        child: GestureDetector(
          onTap: () => _showUbicacionDetail(u),
          child: const Icon(Icons.location_on, color: _blue, size: 40),
        ),
      );

  Marker _buildTempMarker(LatLng p) => Marker(
        point: p,
        width: 40, height: 48,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      );

  List<Marker> get _markers {
    final list = _ubicaciones.map(_buildPinMarker).toList();
    if (_tempMarker != null) list.add(_tempMarker!);
    return list;
  }

  // ── GPS ──────────────────────────────────────────────────────

  Future<void> _locateMe() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _snack('Activa el GPS del dispositivo');
      return;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        _snack('Permiso de ubicación denegado');
        return;
      }
    }
    if (perm == LocationPermission.deniedForever) {
      _snack('Permiso denegado permanentemente. Ve a Configuración.');
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
  }

  // ── Sheets ───────────────────────────────────────────────────

  void _showUbicacionDetail(Ubicacion u) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DetailSheet(
        ubicacion: u,
        mediaBase: ApiConfig.baseUrl,
        onDelete: () async {
          Navigator.pop(context);
          try {
            await _api.deleteUbicacion(u.id);
            _loadUbicaciones();
          } on UnauthorizedException {
            _handleUnauth();
          } catch (e) {
            _snack('Error: $e');
          }
        },
      ),
    );
  }

  void _showAddSheet(LatLng point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddSheet(
        point: point,
        picker: _picker,
        onSave: (nombre, desc, img) async {
          Navigator.pop(context);
          try {
            await _api.createUbicacion(
              nombre: nombre,
              lat: point.latitude,
              lng: point.longitude,
              descripcion: desc,
              imagen: img,
            );
            _loadUbicaciones();
          } on UnauthorizedException {
            _handleUnauth();
          } catch (e) {
            _snack('Error: $e');
          }
        },
        onCancel: () {
          Navigator.pop(context);
          setState(() { _tempMarker = null; });
        },
      ),
    ).whenComplete(() {
      setState(() { _tempMarker = null; });
    });
  }

  // ── Sidebar ───────────────────────────────────────────────────

  Widget _buildDrawer() {
    final user = _api.currentUser;
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_blueD, _blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 10),
                Text(user?.nombre ?? 'Usuario',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                Text('@${user?.usuario ?? ''}',
                    style: const TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ubicaciones (${_ubicaciones.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: _blueD)),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadUbicaciones,
                  tooltip: 'Actualizar',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loadingList
                ? const Center(child: CircularProgressIndicator())
                : _ubicaciones.isEmpty
                    ? const Center(
                        child: Text('Sin ubicaciones.\nToca el mapa para agregar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _ubicaciones.length,
                        itemBuilder: (_, i) => _buildListTile(_ubicaciones[i]),
                      ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))
                  .then((_) => setState(() {}));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(Ubicacion u) {
    final imgUrl = u.url != null ? '${ApiConfig.baseUrl}/${u.url}' : null;
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imgUrl != null
            ? Image.network(imgUrl, width: 46, height: 46, fit: BoxFit.cover,
                errorBuilder: (_, e, s) => _defaultThumb())
            : _defaultThumb(),
      ),
      title: Text(u.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: u.descripcion != null
          ? Text(u.descripcion!, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12))
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
        onPressed: () async {
          Navigator.pop(context);
          try {
            await _api.deleteUbicacion(u.id);
            _loadUbicaciones();
          } catch (_) {}
        },
      ),
      onTap: () {
        Navigator.pop(context);
        _mapController.move(LatLng(u.lat, u.lng), 16);
      },
    );
  }

  Widget _defaultThumb() => Container(
        width: 46, height: 46,
        color: _blue,
        child: const Icon(Icons.location_on, color: Colors.white, size: 22),
      );

  // ── Helpers ──────────────────────────────────────────────────

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _logout() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _blueD,
        foregroundColor: Colors.white,
        title: const Text('MapaApp', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ).then((_) => setState(() {})),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Salir',
            onPressed: _logout,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // ── Mapa ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-12.0464, -77.0428),
              initialZoom: 13,
              onTap: _onMapTap,
            ),
            children: [
              if (_isSatellite) ...[_satTile, _labelTile] else _streetTile,
              MarkerLayer(markers: _markers),
            ],
          ),

          // ── Botón capa ──
          Positioned(
            left: 12,
            bottom: 90,
            child: _layerBtn(),
          ),

          // ── Botón GPS ──
          Positioned(
            right: 12,
            bottom: 90,
            child: FloatingActionButton.small(
              heroTag: 'locate',
              backgroundColor: Colors.white,
              foregroundColor: _blue,
              onPressed: _locateMe,
              tooltip: 'Mi ubicación',
              child: const Icon(Icons.my_location),
            ),
          ),

          // ── FAB agregar ──
          Positioned(
            right: 12,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'add',
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              onPressed: () => _snack('Toca el mapa para colocar la ubicación'),
              tooltip: 'Agregar ubicación',
              child: const Icon(Icons.add_location_alt),
            ),
          ),

          // ── Lista btn ──
          Positioned(
            left: 12,
            bottom: 16,
            child: _listBtn(),
          ),
        ],
      ),
    );
  }

  Widget _layerBtn() => Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _isSatellite = !_isSatellite),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: _isSatellite ? _blueD : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.layers,
                    color: _isSatellite ? Colors.white : _blue, size: 18),
                const SizedBox(width: 6),
                Text(
                  _isSatellite ? 'Mapa' : 'Satélite',
                  style: TextStyle(
                    color: _isSatellite ? Colors.white : _blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _listBtn() => Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(50),
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.format_list_bulleted, color: _blue, size: 18),
                const SizedBox(width: 6),
                Text('Ver lista',
                    style: TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet: Detalle de ubicación existente
// ─────────────────────────────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final Ubicacion ubicacion;
  final String mediaBase;
  final VoidCallback onDelete;

  const _DetailSheet({
    required this.ubicacion,
    required this.mediaBase,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final imgUrl = ubicacion.url != null ? '$mediaBase/${ubicacion.url}' : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (imgUrl != null)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              imgUrl, height: 180, width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => const SizedBox(height: 8),
            ),
          )
        else
          const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(ubicacion.nombre,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
              if (ubicacion.descripcion != null) ...[
                const SizedBox(height: 4),
                Text(ubicacion.descripcion!,
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${ubicacion.lat.toStringAsFixed(5)}, ${ubicacion.lng.toStringAsFixed(5)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet: Agregar nueva ubicación
// ─────────────────────────────────────────────────────────────────────────────

class _AddSheet extends StatefulWidget {
  final LatLng point;
  final ImagePicker picker;
  final Future<void> Function(String nombre, String? desc, File? img) onSave;
  final VoidCallback onCancel;

  const _AddSheet({
    required this.point,
    required this.picker,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _nombre = TextEditingController();
  final _desc   = TextEditingController();
  File? _image;
  bool  _saving = false;

  static const Color _blue  = Color(0xFF0D5C8C);
  static const Color _blueD = Color(0xFF07304F);

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await widget.picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (xFile != null) {
      setState(() => _image = File(xFile.path));
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nueva Ubicación',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _blueD)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onCancel,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Nombre
              const Text('Nombre *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 4),
              TextField(
                controller: _nombre,
                decoration: InputDecoration(
                  hintText: 'Nombre del lugar',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Descripción
              const Text('Descripción', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 4),
              TextField(
                controller: _desc,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Opcional...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Coordenadas
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.point.latitude.toStringAsFixed(6)},  ${widget.point.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Foto
              const Text('Foto del lugar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 6),
              if (_image != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_image!, height: 160, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 6, right: 6,
                      child: GestureDetector(
                        onTap: () => setState(() => _image = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _camBtn(
                        icon: Icons.camera_alt_outlined,
                        label: 'Cámara',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _camBtn(
                        icon: Icons.photo_library_outlined,
                        label: 'Galería',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),

              // Botones acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: widget.onCancel,
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: _saving
                          ? null
                          : () async {
                              if (_nombre.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('El nombre es obligatorio')),
                                );
                                return;
                              }
                              setState(() => _saving = true);
                              await widget.onSave(
                                _nombre.text.trim(),
                                _desc.text.trim().isNotEmpty ? _desc.text.trim() : null,
                                _image,
                              );
                            },
                      child: _saving
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _camBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade100),
          borderRadius: BorderRadius.circular(10),
          color: Colors.blue.shade50,
        ),
        child: Column(
          children: [
            Icon(icon, color: _blue, size: 26),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: _blue, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
