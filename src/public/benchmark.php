<?php
// Teste de Benchmark Simples para demonstração
header("Content-Type: application/json");

$test = $_GET["test"] ?? "cpu";

switch($test) {
    case "cpu":
        $start = microtime(true);
        $result = 0;
        for($i = 0; $i < 100000; $i++) {
            $result += sqrt($i) * sin($i);
        }
        $time = microtime(true) - $start;
        echo json_encode([
            "test" => "CPU Intensive",
            "operations" => 100000,
            "time_seconds" => round($time, 4),
            "ops_per_second" => round(100000 / $time, 2),
            "result" => round($result, 2)
        ]);
        break;

    case "memory":
        $start = microtime(true);
        $array = [];
        for($i = 0; $i < 50000; $i++) {
            $array[] = "String $i with some data " . str_repeat("x", 50);
        }
        $memory = memory_get_peak_usage(true);
        $time = microtime(true) - $start;
        echo json_encode([
            "test" => "Memory Allocation",
            "items_created" => 50000,
            "time_seconds" => round($time, 4),
            "memory_mb" => round($memory / 1024 / 1024, 2),
            "items_per_second" => round(50000 / $time, 2)
        ]);
        break;

    default:
        echo json_encode([
            "error" => "Invalid test",
            "available_tests" => ["cpu", "memory"],
            "usage" => "Add ?test=cpu|memory to URL"
        ]);
}
?>
