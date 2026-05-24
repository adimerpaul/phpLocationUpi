<?php
declare(strict_types=1);

class Usuario
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::getInstance();
    }

    public function all(): array
    {
        $stmt = $this->db->query(
            "SELECT id, nombre, usuario, cargo, rol, permisos, domicilio, created_at, updated_at
             FROM usuarios WHERE deleted_at IS NULL ORDER BY created_at DESC"
        );
        return $stmt->fetchAll();
    }

    public function find(int $id): ?array
    {
        $stmt = $this->db->prepare(
            "SELECT id, nombre, usuario, cargo, rol, permisos, domicilio, created_at, updated_at
             FROM usuarios WHERE id = :id AND deleted_at IS NULL LIMIT 1"
        );
        $stmt->execute(['id' => $id]);
        return $stmt->fetch() ?: null;
    }

    public function findByUsuario(string $usuario): ?array
    {
        $stmt = $this->db->prepare(
            "SELECT * FROM usuarios WHERE usuario = :usuario AND deleted_at IS NULL LIMIT 1"
        );
        $stmt->execute(['usuario' => $usuario]);
        return $stmt->fetch() ?: null;
    }

    public function create(array $data): int
    {
        $stmt = $this->db->prepare(
            "INSERT INTO usuarios (nombre, usuario, password, cargo, rol, permisos, domicilio)
             VALUES (:nombre, :usuario, :password, :cargo, :rol, :permisos, :domicilio)"
        );
        $stmt->execute([
            'nombre'   => $data['nombre'],
            'usuario'  => $data['usuario'],
            'password' => password_hash($data['password'], PASSWORD_BCRYPT),
            'cargo'    => $data['cargo'] ?? null,
            'rol'      => $data['rol'] ?? 'user',
            'permisos' => isset($data['permisos']) ? json_encode($data['permisos']) : null,
            'domicilio' => $data['domicilio'] ?? null,
        ]);
        return (int) $this->db->lastInsertId();
    }

    public function update(int $id, array $data): bool
    {
        $fields = ['nombre', 'cargo', 'rol', 'domicilio'];
        $sets   = [];
        $params = ['id' => $id];

        foreach ($fields as $field) {
            if (array_key_exists($field, $data)) {
                $sets[]       = "$field = :$field";
                $params[$field] = $data[$field];
            }
        }

        if (isset($data['permisos'])) {
            $sets[]           = 'permisos = :permisos';
            $params['permisos'] = json_encode($data['permisos']);
        }

        if (isset($data['password'])) {
            $sets[]            = 'password = :password';
            $params['password'] = password_hash($data['password'], PASSWORD_BCRYPT);
        }

        if (empty($sets)) {
            return false;
        }

        $stmt = $this->db->prepare(
            "UPDATE usuarios SET " . implode(', ', $sets) . " WHERE id = :id AND deleted_at IS NULL"
        );
        return $stmt->execute($params);
    }

    public function delete(int $id): bool
    {
        $stmt = $this->db->prepare(
            "UPDATE usuarios SET deleted_at = NOW() WHERE id = :id AND deleted_at IS NULL"
        );
        return $stmt->execute(['id' => $id]);
    }
}
