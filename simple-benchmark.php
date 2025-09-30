<?php
// Teste de Benchmark Simples para demonstração
header('Content-Type: application/json');

$test = $_GET['test'] ?? 'cpu';

switch ($test) {
    case 'cpu':
        $start = microtime(true);
        $result = 0;
        for ($i = 0; $i < 100000; $i++) {
            $result += sqrt($i) * sin($i);
        }
        $time = microtime(true) - $start;
        echo json_encode([
            'test' => 'CPU Intensive',
            'operations' => 100000,
            'time_seconds' => round($time, 4),
            'ops_per_second' => round(100000 / $time, 2),
            'result' => round($result, 2)
        ]);
        break;

    case 'memory':
        $start = microtime(true);
        $array = [];
        for ($i = 0; $i < 50000; $i++) {
            $array[] = "String $i with some data " . str_repeat('x', 50);
        }
        $memory = memory_get_peak_usage(true);
        $time = microtime(true) - $start;
        echo json_encode([
            'test' => 'Memory Allocation',
            'items_created' => 50000,
            'time_seconds' => round($time, 4),
            'memory_mb' => round($memory / 1024 / 1024, 2),
            'items_per_second' => round(50000 / $time, 2)
        ]);
        break;

    case 'io':
        $start = microtime(true);
        $filename = '/tmp/benchmark_test.txt';
        $data = str_repeat("Test data for I/O benchmark\n", 1000);

        // Write test
        for ($i = 0; $i < 100; $i++) {
            file_put_contents($filename, $data, LOCK_EX);
        }

        // Read test
        $content = '';
        for ($i = 0; $i < 100; $i++) {
            $content = file_get_contents($filename);
        }

        unlink($filename);
        $time = microtime(true) - $start;

        echo json_encode([
            'test' => 'File I/O',
            'operations' => 200,
            'data_size_kb' => round(strlen($data) / 1024, 2),
            'time_seconds' => round($time, 4),
            'ops_per_second' => round(200 / $time, 2)
        ]);
        break;

    case 'json':
        $start = microtime(true);
        $data = [];
        for ($i = 0; $i < 1000; $i++) {
            $data[] = [
                'id' => $i,
                'name' => "User $i",
                'email' => "user$i@example.com",
                'created_at' => date('Y-m-d H:i:s'),
                'metadata' => [
                    'score' => rand(1, 100),
                    'active' => $i % 2 == 0,
                    'tags' => ['tag1', 'tag2', 'tag3']
                ]
            ];
        }

        $json = json_encode($data);
        $decoded = json_decode($json, true);
        $time = microtime(true) - $start;

        echo json_encode([
            'test' => 'JSON Processing',
            'records_processed' => 1000,
            'json_size_kb' => round(strlen($json) / 1024, 2),
            'time_seconds' => round($time, 4),
            'records_per_second' => round(1000 / $time, 2)
        ]);
        break;

    default:
        echo json_encode([
            'error' => 'Invalid test',
            'available_tests' => ['cpu', 'memory', 'io', 'json'],
            'usage' => 'Add ?test=cpu|memory|io|json to URL'
        ]);
}
