<?php
declare(strict_types=1);

class UbicacionController
{
    private Ubicacion $model;

    public function __construct()
    {
        $this->model = new Ubicacion();
    }

    public function index(array $params): void
    {
        echo json_encode($this->model->all());
    }

    public function show(array $params): void
    {
        $ubicacion = $this->model->find((int) $params['id']);
        if (!$ubicacion) {
            http_response_code(404);
            echo json_encode(['error' => 'Ubicación no encontrada']);
            return;
        }
        echo json_encode($ubicacion);
    }

    public function misUbicaciones(array $params): void
    {
        $userId = $params['auth']['sub'];
        echo json_encode($this->model->byUsuario($userId));
    }

    public function store(array $params): void
    {
        $data            = $this->json();
        $data['user_id'] = $params['auth']['sub'];

        $errors = $this->validate($data);
        if ($errors) {
            http_response_code(422);
            echo json_encode(['errors' => $errors]);
            return;
        }

        $id = $this->model->create($data);
        http_response_code(201);
        echo json_encode($this->model->find($id));
    }

    public function update(array $params): void
    {
        $ubicacion = $this->model->find((int) $params['id']);
        if (!$ubicacion) {
            http_response_code(404);
            echo json_encode(['error' => 'Ubicación no encontrada']);
            return;
        }

        $data   = $this->json();
        $errors = $this->validate($data);
        if ($errors) {
            http_response_code(422);
            echo json_encode(['errors' => $errors]);
            return;
        }

        $this->model->update((int) $params['id'], $data);
        echo json_encode($this->model->find((int) $params['id']));
    }

    public function destroy(array $params): void
    {
        $ubicacion = $this->model->find((int) $params['id']);
        if (!$ubicacion) {
            http_response_code(404);
            echo json_encode(['error' => 'Ubicación no encontrada']);
            return;
        }

        $this->model->delete((int) $params['id']);
        echo json_encode(['message' => 'Ubicación eliminada']);
    }

    private function validate(array $data): array
    {
        $errors = [];
        if (empty($data['nombre']))                                      $errors['nombre']  = 'El nombre es requerido';
        if (!isset($data['lat']) || !is_numeric($data['lat']))           $errors['lat']     = 'Latitud inválida';
        if (!isset($data['lng']) || !is_numeric($data['lng']))           $errors['lng']     = 'Longitud inválida';
        return $errors;
    }

    private function json(): array
    {
        return json_decode(file_get_contents('php://input'), true) ?? [];
    }
}
