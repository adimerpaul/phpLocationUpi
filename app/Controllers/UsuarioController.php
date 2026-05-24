<?php
declare(strict_types=1);

class UsuarioController
{
    private Usuario $model;
    private Token   $tokenModel;

    public function __construct()
    {
        $this->model      = new Usuario();
        $this->tokenModel = new Token();
    }

    public function registro(array $params): void
    {
        $data   = $this->json();
        $errors = [];

        if (empty($data['nombre']))   $errors['nombre']   = 'El nombre es requerido';
        if (empty($data['usuario']))  $errors['usuario']  = 'El usuario es requerido';
        if (empty($data['password']) || strlen((string)$data['password']) < 6) {
            $errors['password'] = 'La contraseña debe tener al menos 6 caracteres';
        }

        if ($errors) {
            http_response_code(422);
            echo json_encode(['errors' => $errors]);
            return;
        }

        if ($this->model->findByUsuario($data['usuario'])) {
            http_response_code(409);
            echo json_encode(['error' => 'El nombre de usuario ya existe']);
            return;
        }

        $id      = $this->model->create($data);
        $usuario = $this->model->find($id);

        http_response_code(201);
        echo json_encode(['message' => 'Usuario registrado correctamente', 'usuario' => $usuario]);
    }

    public function login(array $params): void
    {
        $data = $this->json();

        if (empty($data['usuario']) || empty($data['password'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Usuario y contraseña requeridos']);
            return;
        }

        $usuario = $this->model->findByUsuario($data['usuario']);

        if (!$usuario || !password_verify((string)$data['password'], $usuario['password'])) {
            http_response_code(401);
            echo json_encode(['error' => 'Credenciales incorrectas']);
            return;
        }

        $token = JWT::encode([
            'sub'     => $usuario['id'],
            'usuario' => $usuario['usuario'],
            'rol'     => $usuario['rol'],
            'exp'     => time() + JWT_EXPIRY,
        ]);

        $this->tokenModel->store($usuario['id'], $token);

        echo json_encode([
            'token'   => $token,
            'usuario' => [
                'id'      => $usuario['id'],
                'nombre'  => $usuario['nombre'],
                'usuario' => $usuario['usuario'],
                'rol'     => $usuario['rol'],
                'cargo'   => $usuario['cargo'],
            ],
        ]);
    }

    public function logout(array $params): void
    {
        $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
        preg_match('/^Bearer\s+(.+)$/i', $header, $matches);

        if (isset($matches[1])) {
            $this->tokenModel->revoke($matches[1]);
        }

        echo json_encode(['message' => 'Sesión cerrada correctamente']);
    }

    public function index(array $params): void
    {
        echo json_encode($this->model->all());
    }

    public function show(array $params): void
    {
        $usuario = $this->model->find((int) $params['id']);
        if (!$usuario) {
            http_response_code(404);
            echo json_encode(['error' => 'Usuario no encontrado']);
            return;
        }
        echo json_encode($usuario);
    }

    public function update(array $params): void
    {
        $usuario = $this->model->find((int) $params['id']);
        if (!$usuario) {
            http_response_code(404);
            echo json_encode(['error' => 'Usuario no encontrado']);
            return;
        }

        $data = $this->json();
        $this->model->update((int) $params['id'], $data);
        echo json_encode($this->model->find((int) $params['id']));
    }

    public function destroy(array $params): void
    {
        $usuario = $this->model->find((int) $params['id']);
        if (!$usuario) {
            http_response_code(404);
            echo json_encode(['error' => 'Usuario no encontrado']);
            return;
        }

        $this->model->delete((int) $params['id']);
        $this->tokenModel->revokeAll((int) $params['id']);
        echo json_encode(['message' => 'Usuario eliminado']);
    }

    private function json(): array
    {
        return json_decode(file_get_contents('php://input'), true) ?? [];
    }
}
