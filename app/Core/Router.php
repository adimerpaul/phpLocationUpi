<?php
declare(strict_types=1);

class Router
{
    private array $routes = [];

    public function get(string $pattern, callable $handler, bool $protected = false): void
    {
        $this->add('GET', $pattern, $handler, $protected);
    }

    public function post(string $pattern, callable $handler, bool $protected = false): void
    {
        $this->add('POST', $pattern, $handler, $protected);
    }

    public function put(string $pattern, callable $handler, bool $protected = false): void
    {
        $this->add('PUT', $pattern, $handler, $protected);
    }

    public function delete(string $pattern, callable $handler, bool $protected = false): void
    {
        $this->add('DELETE', $pattern, $handler, $protected);
    }

    private function add(string $method, string $pattern, callable $handler, bool $protected): void
    {
        $this->routes[] = compact('method', 'pattern', 'handler', 'protected');
    }

    public function dispatch(): void
    {
        $method = $_SERVER['REQUEST_METHOD'];
        $uri    = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

        $base = rtrim(dirname($_SERVER['SCRIPT_NAME']), '/');
        if ($base !== '' && strpos($uri, $base) === 0) {
            $uri = substr($uri, strlen($base));
        }
        $uri = '/' . ltrim($uri, '/');

        foreach ($this->routes as $route) {
            if ($route['method'] !== $method) {
                continue;
            }

            $params = $this->matchPattern($route['pattern'], $uri);
            if ($params === null) {
                continue;
            }

            if ($route['protected']) {
                $params['auth'] = AuthMiddleware::verify();
            }

            call_user_func($route['handler'], $params);
            return;
        }

        http_response_code(404);
        echo json_encode(['error' => 'Ruta no encontrada']);
    }

    private function matchPattern(string $pattern, string $uri): ?array
    {
        $regex = preg_replace('/\{(\w+)\}/', '(?P<$1>[^/]+)', $pattern);
        $regex = '#^' . $regex . '$#';

        if (!preg_match($regex, $uri, $matches)) {
            return null;
        }

        return array_filter($matches, 'is_string', ARRAY_FILTER_USE_KEY);
    }
}
