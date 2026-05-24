<?php
declare(strict_types=1);

class AuthMiddleware
{
    public static function verify(): array
    {
        $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';

        if (!preg_match('/^Bearer\s+(.+)$/i', $header, $matches)) {
            http_response_code(401);
            echo json_encode(['error' => 'Token no proporcionado']);
            exit;
        }

        try {
            $payload = JWT::decode($matches[1]);
        } catch (RuntimeException $e) {
            http_response_code(401);
            echo json_encode(['error' => $e->getMessage()]);
            exit;
        }

        // Verificar que el token no haya sido revocado (logout)
        $tokenModel = new Token();
        if (!$tokenModel->isActive($matches[1])) {
            http_response_code(401);
            echo json_encode(['error' => 'Token revocado o inválido']);
            exit;
        }

        return $payload;
    }
}
