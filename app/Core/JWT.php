<?php
declare(strict_types=1);

class JWT
{
    public static function encode(array $payload): string
    {
        $header    = self::b64u(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
        $body      = self::b64u(json_encode($payload));
        $signature = self::b64u(hash_hmac('sha256', "$header.$body", JWT_SECRET, true));

        return "$header.$body.$signature";
    }

    public static function decode(string $token): array
    {
        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            throw new RuntimeException('Token malformado');
        }

        [$header, $body, $signature] = $parts;

        $expected = self::b64u(hash_hmac('sha256', "$header.$body", JWT_SECRET, true));
        if (!hash_equals($expected, $signature)) {
            throw new RuntimeException('Firma inválida');
        }

        $payload = json_decode(base64_decode(strtr($body, '-_', '+/')), true);

        if (!$payload) {
            throw new RuntimeException('Payload inválido');
        }

        if (isset($payload['exp']) && $payload['exp'] < time()) {
            throw new RuntimeException('Token expirado');
        }

        return $payload;
    }

    private static function b64u(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}
