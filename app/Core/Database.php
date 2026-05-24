<?php
declare(strict_types=1);

class Database
{
    private static ?PDO $instance = null;

    public static function getInstance(): PDO
    {
        if (self::$instance === null) {
            self::connect();
        }
        return self::$instance;
    }

    private static function connect(): void
    {
        try {
            $pdo = new PDO(
                "mysql:host=" . DB_HOST . ";port=" . DB_PORT . ";charset=utf8mb4",
                DB_USER,
                DB_PASS,
                [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]
            );

            $pdo->exec("CREATE DATABASE IF NOT EXISTS `" . DB_NAME . "` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
            $pdo->exec("USE `" . DB_NAME . "`");

            $pdo->exec("CREATE TABLE IF NOT EXISTS usuarios (
                id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                nombre      VARCHAR(100) NOT NULL,
                usuario     VARCHAR(80)  NOT NULL UNIQUE,
                password    VARCHAR(255) NOT NULL,
                cargo       VARCHAR(100) NULL,
                rol         VARCHAR(50)  NOT NULL DEFAULT 'user',
                permisos    JSON         NULL,
                domicilio   VARCHAR(255) NULL,
                created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                deleted_at  DATETIME     NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            $pdo->exec("CREATE TABLE IF NOT EXISTS ubicaciones (
                id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                lat         DECIMAL(10,8) NOT NULL,
                lng         DECIMAL(11,8) NOT NULL,
                nombre      VARCHAR(150) NOT NULL,
                descripcion TEXT         NULL,
                user_id     INT UNSIGNED NOT NULL,
                created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                deleted_at  DATETIME     NULL,
                FOREIGN KEY (user_id) REFERENCES usuarios(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            $pdo->exec("CREATE TABLE IF NOT EXISTS tokens (
                id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                usuario_id  INT UNSIGNED NOT NULL,
                token       TEXT         NOT NULL,
                expires_at  DATETIME     NOT NULL,
                created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                deleted_at  DATETIME     NULL,
                FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            self::$instance = $pdo;
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Error de conexión a la base de datos: ' . $e->getMessage()]);
            exit;
        }
    }
}
