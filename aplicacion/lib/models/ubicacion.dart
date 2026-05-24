class Ubicacion {
  final int id;
  final double lat;
  final double lng;
  final String nombre;
  final String? descripcion;
  final String? url;
  final int userId;
  final String? usuarioNombre;

  const Ubicacion({
    required this.id,
    required this.lat,
    required this.lng,
    required this.nombre,
    this.descripcion,
    this.url,
    required this.userId,
    this.usuarioNombre,
  });

  factory Ubicacion.fromJson(Map<String, dynamic> j) => Ubicacion(
        id: j['id'] is int ? j['id'] : int.parse(j['id'].toString()),
        lat: double.parse(j['lat'].toString()),
        lng: double.parse(j['lng'].toString()),
        nombre: j['nombre'] ?? '',
        descripcion: j['descripcion'],
        url: j['url'],
        userId: j['user_id'] is int
            ? j['user_id']
            : int.parse(j['user_id'].toString()),
        usuarioNombre: j['usuario_nombre'],
      );
}

class Usuario {
  final int id;
  final String nombre;
  final String usuario;
  final String? cargo;
  final String rol;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.usuario,
    this.cargo,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: j['id'] is int ? j['id'] : int.parse(j['id'].toString()),
        nombre: j['nombre'] ?? '',
        usuario: j['usuario'] ?? '',
        cargo: j['cargo'],
        rol: j['rol'] ?? 'user',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'usuario': usuario,
        'cargo': cargo,
        'rol': rol,
      };
}
