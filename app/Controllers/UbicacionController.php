<?php
declare(strict_types=1);

class UbicacionController
{
    private Ubicacion $model;

    private const UPLOAD_DIR  = __DIR__ . '/../../upload/ubicaciones/';
    private const UPLOAD_PATH = 'upload/ubicaciones/';
    private const MAX_WIDTH   = 1200;
    private const WEBP_QUALITY = 82;

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
        echo json_encode($this->model->byUsuario($params['auth']['sub']));
    }

    public function store(array $params): void
    {
        $data            = $this->input();
        $data['user_id'] = $params['auth']['sub'];

        if (!empty($_FILES['imagen']) && $_FILES['imagen']['error'] === UPLOAD_ERR_OK) {
            $url = $this->processImage($_FILES['imagen']);
            if ($url === null) {
                http_response_code(422);
                echo json_encode(['error' => 'Formato de imagen no válido. Usa JPEG, PNG o WebP.']);
                return;
            }
            $data['url'] = $url;
        }

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

        $data = $this->input();

        if (!empty($_FILES['imagen']) && $_FILES['imagen']['error'] === UPLOAD_ERR_OK) {
            $url = $this->processImage($_FILES['imagen']);
            if ($url !== null) {
                $data['url'] = $url;
                $this->removeOldImage($ubicacion['url'] ?? null);
            }
        }

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

        $this->removeOldImage($ubicacion['url'] ?? null);
        $this->model->delete((int) $params['id']);
        echo json_encode(['message' => 'Ubicación eliminada']);
    }

    // ── Lectura de datos ───────────────────────────────────────
    // multipart/form-data  → $_POST  (usado cuando hay imagen adjunta)
    // application/json     → php://input
    // Se detecta por Content-Type para soportar ambos clientes.

    private function input(): array
    {
        $ct = $_SERVER['CONTENT_TYPE'] ?? '';
        if (strpos($ct, 'application/json') !== false) {
            return json_decode(file_get_contents('php://input'), true) ?? [];
        }
        // multipart/form-data o application/x-www-form-urlencoded
        return $_POST;
    }

    // ── Procesamiento de imagen ────────────────────────────────

    private function processImage(array $file): ?string
    {
        $mime = mime_content_type($file['tmp_name']);
        $allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
        if (!in_array($mime, $allowed, true)) {
            return null;
        }

        $src = match ($mime) {
            'image/jpeg' => imagecreatefromjpeg($file['tmp_name']),
            'image/png'  => imagecreatefrompng($file['tmp_name']),
            'image/webp' => imagecreatefromwebp($file['tmp_name']),
            'image/gif'  => imagecreatefromgif($file['tmp_name']),
            default      => false,
        };

        if (!$src) return null;

        $src = $this->resize($src);

        if (!is_dir(self::UPLOAD_DIR)) {
            mkdir(self::UPLOAD_DIR, 0755, true);
        }

        $filename = 'ubic_' . bin2hex(random_bytes(8)) . '.webp';
        $fullPath = self::UPLOAD_DIR . $filename;

        if (!imagewebp($src, $fullPath, self::WEBP_QUALITY)) {
            imagedestroy($src);
            return null;
        }

        imagedestroy($src);
        return self::UPLOAD_PATH . $filename;
    }

    private function resize(\GdImage $src): \GdImage
    {
        $w = imagesx($src);
        $h = imagesy($src);
        if ($w <= self::MAX_WIDTH) return $src;

        $newH    = (int) round($h * self::MAX_WIDTH / $w);
        $resized = imagecreatetruecolor(self::MAX_WIDTH, $newH);
        imagealphablending($resized, false);
        imagesavealpha($resized, true);
        imagecopyresampled($resized, $src, 0, 0, 0, 0, self::MAX_WIDTH, $newH, $w, $h);
        imagedestroy($src);
        return $resized;
    }

    private function removeOldImage(?string $url): void
    {
        if (!$url) return;
        $path = __DIR__ . '/../../' . $url;
        if (is_file($path)) unlink($path);
    }

    // ── Validación ─────────────────────────────────────────────

    private function validate(array $data): array
    {
        $errors = [];
        if (empty($data['nombre']))                            $errors['nombre'] = 'El nombre es requerido';
        if (!isset($data['lat']) || !is_numeric($data['lat'])) $errors['lat']    = 'Latitud inválida';
        if (!isset($data['lng']) || !is_numeric($data['lng'])) $errors['lng']    = 'Longitud inválida';
        return $errors;
    }
}
