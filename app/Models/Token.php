<?php
declare(strict_types=1);

class Token
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::getInstance();
    }

    public function store(int $usuarioId, string $token): void
    {
        $expiresAt = date('Y-m-d H:i:s', time() + JWT_EXPIRY);

        $stmt = $this->db->prepare(
            "INSERT INTO tokens (usuario_id, token, expires_at) VALUES (:usuario_id, :token, :expires_at)"
        );
        $stmt->execute(['usuario_id' => $usuarioId, 'token' => $token, 'expires_at' => $expiresAt]);
    }

    public function isActive(string $token): bool
    {
        $stmt = $this->db->prepare(
            "SELECT id FROM tokens
             WHERE token = :token
               AND deleted_at IS NULL
               AND expires_at > NOW()
             LIMIT 1"
        );
        $stmt->execute(['token' => $token]);
        return (bool) $stmt->fetch();
    }

    public function revoke(string $token): void
    {
        $stmt = $this->db->prepare(
            "UPDATE tokens SET deleted_at = NOW() WHERE token = :token AND deleted_at IS NULL"
        );
        $stmt->execute(['token' => $token]);
    }

    public function revokeAll(int $usuarioId): void
    {
        $stmt = $this->db->prepare(
            "UPDATE tokens SET deleted_at = NOW() WHERE usuario_id = :usuario_id AND deleted_at IS NULL"
        );
        $stmt->execute(['usuario_id' => $usuarioId]);
    }
}
