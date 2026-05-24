# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PHP puro con arquitectura MVC. API REST con autenticación JWT, gestión de usuarios y ubicaciones geográficas. Sin frameworks — solo PDO y PHP estándar.

## Environment

- **Server**: XAMPP (Apache + MySQL) en Windows
- **URL**: `http://localhost/mapa/`
- **Base de datos**: `mapa_db` (se crea automáticamente al primer request)
- **Credenciales DB por defecto**: host `127.0.0.1`, user `root`, sin contraseña

Iniciar: abrir XAMPP Control Panel → Start Apache y MySQL.

## Estructura MVC

```
mapa/
├── index.php                         # Entry point y registro de rutas
├── config/config.php                 # Constantes: DB_*, JWT_SECRET, JWT_EXPIRY
├── .htaccess                         # Redirige todo a index.php
├── app/
│   ├── Core/
│   │   ├── Database.php              # Singleton PDO + auto-migración (crea DB y tablas)
│   │   ├── Router.php                # Router con soporte de parámetros {id}
│   │   └── JWT.php                   # HS256 encode/decode manual
│   ├── Middleware/
│   │   └── AuthMiddleware.php        # Valida Bearer token + consulta tabla tokens
│   ├── Models/
│   │   ├── Usuario.php               # CRUD + soft delete
│   │   ├── Ubicacion.php             # CRUD + soft delete + JOIN con usuarios
│   │   └── Token.php                 # store / isActive / revoke / revokeAll
│   └── Controllers/
│       ├── UsuarioController.php     # registro, login, logout, index, show, update, destroy
│       └── UbicacionController.php   # index, misUbicaciones, show, store, update, destroy
```

## Tablas (auto-creadas por Database.php)

```sql
usuarios (id, nombre, usuario UNIQUE, password, cargo, rol, permisos JSON, domicilio,
          created_at, updated_at, deleted_at)

ubicaciones (id, lat DECIMAL(10,8), lng DECIMAL(11,8), nombre, descripcion,
             user_id FK→usuarios, created_at, updated_at, deleted_at)

tokens (id, usuario_id FK→usuarios, token TEXT, expires_at,
        created_at, deleted_at)
```

- Soft delete en las tres tablas: `deleted_at IS NULL` filtra registros activos.
- `permisos` es JSON; serializar con `json_encode` al guardar, `json_decode` al leer.

## Flujo JWT

1. `POST /api/usuarios/login` → genera token con `JWT::encode()`, lo guarda en tabla `tokens`, lo devuelve.
2. Cada ruta protegida pasa por `AuthMiddleware::verify()`:
   - Extrae `Authorization: Bearer <token>`
   - Valida firma HS256 y expiración en `JWT::decode()`
   - Consulta `tokens` para confirmar que no fue revocado (`deleted_at IS NULL`)
   - Inyecta el payload como `$params['auth']` en el controller
3. `POST /api/usuarios/logout` → marca el token como `deleted_at = NOW()` (revocación).

## Rutas disponibles

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/api/usuarios/registro` | No | Crear cuenta |
| POST | `/api/usuarios/login` | No | Login → token |
| POST | `/api/usuarios/logout` | Sí | Revocar token |
| GET | `/api/usuarios` | Sí | Listar usuarios |
| GET | `/api/usuarios/{id}` | Sí | Ver usuario |
| PUT | `/api/usuarios/{id}` | Sí | Actualizar usuario |
| DELETE | `/api/usuarios/{id}` | Sí | Soft delete usuario |
| GET | `/api/ubicaciones` | Sí | Listar todas |
| GET | `/api/ubicaciones/mis` | Sí | Las del usuario autenticado |
| GET | `/api/ubicaciones/{id}` | Sí | Ver una |
| POST | `/api/ubicaciones` | Sí | Crear (user_id del token) |
| PUT | `/api/ubicaciones/{id}` | Sí | Actualizar |
| DELETE | `/api/ubicaciones/{id}` | Sí | Soft delete |

## Testing con curl

```bash
# Registro
curl -X POST http://localhost/mapa/api/usuarios/registro \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Ana Lopez","usuario":"ana","password":"secret123","rol":"admin"}'

# Login → guarda el token
TOKEN=$(curl -s -X POST http://localhost/mapa/api/usuarios/login \
  -H "Content-Type: application/json" \
  -d '{"usuario":"ana","password":"secret123"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

# Crear ubicación
curl -X POST http://localhost/mapa/api/ubicaciones \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"nombre":"Oficina","lat":-12.0464,"lng":-77.0428,"descripcion":"Lima centro"}'

# Logout
curl -X POST http://localhost/mapa/api/usuarios/logout \
  -H "Authorization: Bearer $TOKEN"
```

## Convenciones

- Agregar nuevas rutas en `index.php`; el cuarto parámetro `true` activa el middleware.
- El Router inyecta `$params['auth']` (payload JWT) en rutas protegidas — úsalo para obtener `$params['auth']['sub']` (user id).
- `password_hash` / `password_verify` para contraseñas; nunca texto plano.
- Toda consulta SQL usa `prepare` + `execute`; sin interpolación directa.
- Cambiar `JWT_SECRET` en `config/config.php` antes de producción.
