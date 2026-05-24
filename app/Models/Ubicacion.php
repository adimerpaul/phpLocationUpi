<?php
declare(strict_types=1);

class Ubicacion
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::getInstance();
    }

    public function all(): array
    {
        $stmt = $this->db->query(
            "SELECT u.*, us.nombre AS usuario_nombre, us.usuario AS usuario_user
             FROM ubicaciones u
             JOIN usuarios us ON u.user_id = us.id
             WHERE u.deleted_at IS NULL
             ORDER BY u.created_at DESC"
        );
        return $stmt->fetchAll();
    }

    public function find(int $id): ?array
    {
        $stmt = $this->db->prepare(
            "SELECT u.*, us.nombre AS usuario_nombre, us.usuario AS usuario_user
             FROM ubicaciones u
             JOIN usuarios us ON u.user_id = us.id
             WHERE u.id = :id AND u.deleted_at IS NULL LIMIT 1"
        );
        $stmt->execute(['id' => $id]);
        return $stmt->fetch() ?: null;
    }

    public function byUsuario(int $userId): array
    {
        $stmt = $this->db->prepare(
            "SELECT * FROM ubicaciones WHERE user_id = :user_id AND deleted_at IS NULL ORDER BY created_at DESC"
        );
        $stmt->execute(['user_id' => $userId]);
        return $stmt->fetchAll();
    }

    public function create(array $data): int
    {
        $stmt = $this->db->prepare(
            "INSERT INTO ubicaciones (lat, lng, nombre, descripcion, user_id)
             VALUES (:lat, :lng, :nombre, :descripcion, :user_id)"
        );
        $stmt->execute([
            'lat'         => $data['lat'],
            'lng'         => $data['lng'],
            'nombre'      => $data['nombre'],
            'descripcion' => $data['descripcion'] ?? null,
            'user_id'     => $data['user_id'],
        ]);
        return (int) $this->db->lastInsertId();
    }

    public function update(int $id, array $data): bool
    {
        $stmt = $this->db->prepare(
            "UPDATE ubicaciones
             SET lat = :lat, lng = :lng, nombre = :nombre, descripcion = :descripcion
             WHERE id = :id AND deleted_at IS NULL"
        );
        return $stmt->execute([
            'lat'         => $data['lat'],
            'lng'         => $data['lng'],
            'nombre'      => $data['nombre'],
            'descripcion' => $data['descripcion'] ?? null,
            'id'          => $id,
        ]);
    }

    public function delete(int $id): bool
    {
        $stmt = $this->db->prepare(
            "UPDATE ubicaciones SET deleted_at = NOW() WHERE id = :id AND deleted_at IS NULL"
        );
        return $stmt->execute(['id' => $id]);
    }
}
