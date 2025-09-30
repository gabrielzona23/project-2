<?php

namespace App\Enums;

enum ServerEnum
{
    case Swoole;
    case FrankenPHP;
    case PhpFpm;

    public function getPort(): int
    {
        return match ($this) {
            self::Swoole => 8001,
            self::FrankenPHP => 8003,
            self::PhpFpm => 8002,
        };
    }

    public function getBenchmarkCommand(EndpointEnum $endpointEnum): string
    {
        return 'wrk -t16 -c100 -d' . $endpointEnum->getBenchmarkDuration() . 's --latency http://127.0.0.1:' . $this->getPort() . $endpointEnum->getRoute();
    }

    public function getStatsCommand(): string
    {
        return match ($this) {
            self::Swoole => 'docker stats swoole_benchmark --format=json --no-stream',
            self::FrankenPHP => 'docker stats frankenphp_benchmark --format=json --no-stream',
            self::PhpFpm => 'docker stats php_fpm_benchmark --format=json --no-stream',
        };
    }

    public function getTitle(): string
    {
        return $this->name;
    }
}
