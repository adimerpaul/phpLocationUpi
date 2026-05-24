<?php
declare(strict_types=1);

// ── Configuración ──────────────────────────────────────────────
require_once __DIR__ . '/config/config.php';

// ── Core ───────────────────────────────────────────────────────
require_once __DIR__ . '/app/Core/Database.php';
require_once __DIR__ . '/app/Core/JWT.php';
require_once __DIR__ . '/app/Core/Router.php';

// ── Middleware ─────────────────────────────────────────────────
require_once __DIR__ . '/app/Middleware/AuthMiddleware.php';

// ── Models ─────────────────────────────────────────────────────
require_once __DIR__ . '/app/Models/Token.php';
require_once __DIR__ . '/app/Models/Usuario.php';
require_once __DIR__ . '/app/Models/Ubicacion.php';

// ── Controllers ────────────────────────────────────────────────
require_once __DIR__ . '/app/Controllers/UsuarioController.php';
require_once __DIR__ . '/app/Controllers/UbicacionController.php';

// ── Headers globales ───────────────────────────────────────────
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// ── Router ─────────────────────────────────────────────────────
$router     = new Router();
$usuarios   = new UsuarioController();
$ubicaciones = new UbicacionController();

// Rutas públicas
$router->post('/api/usuarios/registro', [$usuarios, 'registro']);
$router->post('/api/usuarios/login',    [$usuarios, 'login']);

// Rutas protegidas - Usuarios
$router->post('/api/usuarios/logout',       [$usuarios, 'logout'],  true);
$router->get('/api/usuarios',               [$usuarios, 'index'],   true);
$router->get('/api/usuarios/{id}',          [$usuarios, 'show'],    true);
$router->put('/api/usuarios/{id}',          [$usuarios, 'update'],  true);
$router->delete('/api/usuarios/{id}',       [$usuarios, 'destroy'], true);

// Rutas protegidas - Ubicaciones
$router->get('/api/ubicaciones',            [$ubicaciones, 'index'],          true);
$router->get('/api/ubicaciones/mis',        [$ubicaciones, 'misUbicaciones'], true);
$router->get('/api/ubicaciones/{id}',       [$ubicaciones, 'show'],           true);
$router->post('/api/ubicaciones',           [$ubicaciones, 'store'],          true);
$router->put('/api/ubicaciones/{id}',       [$ubicaciones, 'update'],         true);
$router->delete('/api/ubicaciones/{id}',    [$ubicaciones, 'destroy'],        true);

$router->dispatch();
