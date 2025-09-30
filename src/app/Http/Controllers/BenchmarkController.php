<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Http;
use App\Models\User;
use App\Models\Post;
use App\Models\BenchmarkData;

class BenchmarkController extends Controller
{
    /**
     * Health check endpoint
     */
    public function health()
    {
        $runtime = $this->getRuntimeInfo();

        return response()->json([
            'status' => 'healthy',
            'timestamp' => now()->toISOString(),
            'runtime' => $runtime['server'],
            'php_version' => $runtime['php_version'],
            'memory_usage' => $runtime['memory_usage'],
            'uptime' => $runtime['uptime'] ?? null,
        ]);
    }

    /**
     * Basic database read operation
     */
    public function database()
    {
        $startTime = microtime(true);

        $users = User::with('posts')->take(10)->get();
        $postsCount = Post::count();
        $latestPosts = Post::with('user', 'comments')
            ->orderBy('created_at', 'desc')
            ->take(5)
            ->get();

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'execution_time' => round($executionTime * 1000, 2),
            'data' => [
                'users_count' => $users->count(),
                'posts_count' => $postsCount,
                'latest_posts' => $latestPosts->count(),
            ],
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * Database read operations
     */
    public function databaseRead()
    {
        $startTime = microtime(true);

        // Perform multiple read operations
        $users = User::all();
        $posts = Post::with('user', 'comments')->get();
        $benchmarkData = BenchmarkData::where('status', 'active')->take(100)->get();

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'database_read',
            'execution_time' => round($executionTime * 1000, 2),
            'records_read' => $users->count() + $posts->count() + $benchmarkData->count(),
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * Database write operations
     */
    public function databaseWrite()
    {
        $startTime = microtime(true);

        // Create multiple records
        $records = [];
        for ($i = 0; $i < 10; $i++) {
            $records[] = BenchmarkData::create([
                'name' => 'benchmark_test_' . uniqid(),
                'value' => [
                    'score' => rand(1, 100),
                    'duration' => rand(100, 1000),
                    'memory' => rand(10, 100),
                ],
                'metadata' => [
                    'test_type' => 'write_benchmark',
                    'timestamp' => now(),
                ],
                'status' => 'active',
            ]);
        }

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'database_write',
            'execution_time' => round($executionTime * 1000, 2),
            'records_created' => count($records),
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * Complex database operations
     */
    public function databaseComplex()
    {
        $startTime = microtime(true);

        // Complex query with joins and aggregations
        $result = DB::table('posts')
            ->join('users', 'posts.user_id', '=', 'users.id')
            ->leftJoin('comments', 'posts.id', '=', 'comments.post_id')
            ->select(
                'users.name',
                'posts.title',
                DB::raw('COUNT(comments.id) as comments_count'),
                DB::raw('AVG(posts.views_count) as avg_views')
            )
            ->groupBy('users.id', 'users.name', 'posts.id', 'posts.title')
            ->orderBy('comments_count', 'desc')
            ->take(20)
            ->get();

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'database_complex',
            'execution_time' => round($executionTime * 1000, 2),
            'results_count' => $result->count(),
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * Cache operations
     */
    public function cache()
    {
        $startTime = microtime(true);

        $cacheKey = 'benchmark_cache_' . uniqid();
        $data = [
            'timestamp' => now(),
            'random_data' => str_repeat('test', 1000),
            'numbers' => range(1, 1000),
        ];

        // Write to cache
        Cache::put($cacheKey, $data, 300);

        // Read from cache
        $cachedData = Cache::get($cacheKey);

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'cache',
            'execution_time' => round($executionTime * 1000, 2),
            'cache_hit' => $cachedData !== null,
            'data_size' => strlen(serialize($data)),
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * Cache read operations
     */
    public function cacheRead()
    {
        $startTime = microtime(true);

        $hits = 0;
        $misses = 0;

        // Try to read multiple cache keys
        for ($i = 0; $i < 50; $i++) {
            $key = "test_key_$i";
            if (Cache::has($key)) {
                Cache::get($key);
                $hits++;
            } else {
                $misses++;
            }
        }

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'cache_read',
            'execution_time' => round($executionTime * 1000, 2),
            'cache_hits' => $hits,
            'cache_misses' => $misses,
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * Cache write operations
     */
    public function cacheWrite()
    {
        $startTime = microtime(true);

        $written = 0;

        // Write multiple cache entries
        for ($i = 0; $i < 50; $i++) {
            $key = "test_key_$i";
            $data = [
                'id' => $i,
                'data' => str_repeat("cache_data_$i", 100),
                'timestamp' => now(),
            ];

            Cache::put($key, $data, 300);
            $written++;
        }

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'cache_write',
            'execution_time' => round($executionTime * 1000, 2),
            'keys_written' => $written,
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * File read operations
     */
    public function fileRead()
    {
        $startTime = microtime(true);

        $filesRead = 0;
        $totalSize = 0;

        // Create and read temporary files
        for ($i = 0; $i < 10; $i++) {
            $filename = "benchmark_read_$i.txt";
            $content = str_repeat("File content line $i\n", 1000);

            Storage::put($filename, $content);

            if (Storage::exists($filename)) {
                $readContent = Storage::get($filename);
                $totalSize += strlen($readContent);
                $filesRead++;
                Storage::delete($filename);
            }
        }

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'file_read',
            'execution_time' => round($executionTime * 1000, 2),
            'files_read' => $filesRead,
            'total_bytes_read' => $totalSize,
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * File write operations
     */
    public function fileWrite()
    {
        $startTime = microtime(true);

        $filesWritten = 0;
        $totalSize = 0;

        // Write multiple files
        for ($i = 0; $i < 10; $i++) {
            $filename = "benchmark_write_$i.txt";
            $content = str_repeat("File write test content for file $i\n", 500);

            Storage::put($filename, $content);
            $totalSize += strlen($content);
            $filesWritten++;
        }

        // Clean up
        for ($i = 0; $i < 10; $i++) {
            Storage::delete("benchmark_write_$i.txt");
        }

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'file_write',
            'execution_time' => round($executionTime * 1000, 2),
            'files_written' => $filesWritten,
            'total_bytes_written' => $totalSize,
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * File operations (combined read/write)
     */
    public function fileOperations()
    {
        $startTime = microtime(true);

        $operations = 0;

        // Perform mixed file operations
        for ($i = 0; $i < 5; $i++) {
            $filename = "benchmark_ops_$i.txt";
            $content = json_encode([
                'id' => $i,
                'data' => range(1, 100),
                'timestamp' => now(),
            ]);

            // Write
            Storage::put($filename, $content);
            $operations++;

            // Read
            $readContent = Storage::get($filename);
            $operations++;

            // Append
            Storage::append($filename, "\nAppended data: " . time());
            $operations++;

            // Delete
            Storage::delete($filename);
            $operations++;
        }

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'file_operations',
            'execution_time' => round($executionTime * 1000, 2),
            'total_operations' => $operations,
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * External API calls
     */
    public function externalApi()
    {
        $startTime = microtime(true);

        $requests = [];
        $successCount = 0;
        $errorCount = 0;

        // Make multiple external API calls
        for ($i = 0; $i < 3; $i++) {
            try {
                $response = Http::timeout(5)->get('https://jsonplaceholder.typicode.com/posts/' . ($i + 1));

                if ($response->successful()) {
                    $requests[] = [
                        'status' => 'success',
                        'response_size' => strlen($response->body()),
                        'status_code' => $response->status(),
                    ];
                    $successCount++;
                } else {
                    $errorCount++;
                }
            } catch (\Exception $e) {
                $errorCount++;
                $requests[] = [
                    'status' => 'error',
                    'error' => $e->getMessage(),
                ];
            }
        }

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'external_api',
            'execution_time' => round($executionTime * 1000, 2),
            'requests_made' => count($requests),
            'successful_requests' => $successCount,
            'failed_requests' => $errorCount,
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * CPU intensive operations
     */
    public function cpuIntensive()
    {
        $startTime = microtime(true);

        $result = 0;
        $iterations = 100000;

        // CPU intensive calculations
        for ($i = 0; $i < $iterations; $i++) {
            $result += sqrt($i) * sin($i) + cos($i * 2);
        }

        // Additional mathematical operations
        $fibonacci = $this->fibonacci(30);
        $prime = $this->isPrime(982451653);

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'cpu_intensive',
            'execution_time' => round($executionTime * 1000, 2),
            'iterations' => $iterations,
            'result' => round($result, 2),
            'fibonacci_30' => $fibonacci,
            'prime_check' => $prime,
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * Memory operations
     */
    public function memoryTest()
    {
        $startTime = microtime(true);
        $initialMemory = memory_get_usage();

        // Create large arrays in memory
        $largeArray = [];
        for ($i = 0; $i < 50000; $i++) {
            $largeArray[] = str_repeat("memory_test_$i", 10);
        }

        $peakMemory = memory_get_peak_usage();

        // Process the array
        $processed = array_map(function ($item) {
            return strtoupper($item);
        }, $largeArray);

        // Clean up
        unset($largeArray);
        unset($processed);

        $finalMemory = memory_get_usage();
        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'memory_test',
            'execution_time' => round($executionTime * 1000, 2),
            'initial_memory' => $initialMemory,
            'peak_memory' => $peakMemory,
            'final_memory' => $finalMemory,
            'memory_used' => $peakMemory - $initialMemory,
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * JSON encode operations
     */
    public function jsonEncode()
    {
        $startTime = microtime(true);

        $data = [];
        for ($i = 0; $i < 1000; $i++) {
            $data[] = [
                'id' => $i,
                'name' => "Item $i",
                'description' => str_repeat("Description for item $i. ", 10),
                'metadata' => [
                    'created' => now(),
                    'tags' => ['tag1', 'tag2', 'tag3'],
                    'scores' => range(1, 10),
                ],
            ];
        }

        $jsonString = json_encode($data);
        $jsonSize = strlen($jsonString);

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'json_encode',
            'execution_time' => round($executionTime * 1000, 2),
            'items_encoded' => count($data),
            'json_size_bytes' => $jsonSize,
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * JSON decode operations
     */
    public function jsonDecode()
    {
        $startTime = microtime(true);

        // Create JSON data
        $data = [];
        for ($i = 0; $i < 1000; $i++) {
            $data[] = [
                'id' => $i,
                'payload' => str_repeat("data_$i", 20),
                'nested' => ['level1' => ['level2' => "value_$i"]],
            ];
        }

        $jsonString = json_encode($data);

        // Decode multiple times
        $decodedItems = 0;
        for ($i = 0; $i < 10; $i++) {
            $decoded = json_decode($jsonString, true);
            $decodedItems += count($decoded);
        }

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'json_decode',
            'execution_time' => round($executionTime * 1000, 2),
            'total_items_decoded' => $decodedItems,
            'json_size_bytes' => strlen($jsonString),
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * Mixed workload
     */
    public function mixedWorkload()
    {
        $startTime = microtime(true);

        $operations = [
            'database' => 0,
            'cache' => 0,
            'file' => 0,
            'cpu' => 0,
        ];

        // Database operation
        $users = User::take(5)->get();
        $operations['database']++;

        // Cache operation
        Cache::put('mixed_test', ['data' => time()], 60);
        Cache::get('mixed_test');
        $operations['cache']++;

        // File operation
        Storage::put('mixed_test.txt', 'Mixed workload test');
        Storage::get('mixed_test.txt');
        Storage::delete('mixed_test.txt');
        $operations['file']++;

        // CPU operation
        for ($i = 0; $i < 10000; $i++) {
            $result = sqrt($i) + sin($i);
        }
        $operations['cpu']++;

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'mixed_workload',
            'execution_time' => round($executionTime * 1000, 2),
            'operations_performed' => $operations,
            'total_operations' => array_sum($operations),
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * Stress test
     */
    public function stressTest()
    {
        $startTime = microtime(true);

        $metrics = [
            'database_queries' => 0,
            'cache_operations' => 0,
            'calculations' => 0,
            'json_operations' => 0,
        ];

        // Multiple database queries
        for ($i = 0; $i < 5; $i++) {
            User::inRandomOrder()->first();
            $metrics['database_queries']++;
        }

        // Multiple cache operations
        for ($i = 0; $i < 20; $i++) {
            $key = "stress_$i";
            Cache::put($key, ['data' => $i], 60);
            Cache::get($key);
            $metrics['cache_operations']++;
        }

        // Mathematical calculations
        for ($i = 0; $i < 50000; $i++) {
            $result = pow($i, 2) + sqrt($i);
            $metrics['calculations']++;
        }

        // JSON operations
        for ($i = 0; $i < 100; $i++) {
            $data = ['id' => $i, 'data' => range(1, 100)];
            $json = json_encode($data);
            json_decode($json);
            $metrics['json_operations']++;
        }

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'stress_test',
            'execution_time' => round($executionTime * 1000, 2),
            'metrics' => $metrics,
            'total_operations' => array_sum($metrics),
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * Runtime information
     */
    public function runtimeInfo()
    {
        $info = $this->getRuntimeInfo();

        return response()->json([
            'status' => 'success',
            'runtime_info' => $info,
            'timestamp' => now()->toISOString(),
        ]);
    }

    /**
     * Light concurrent operations
     */
    public function concurrentLight()
    {
        $startTime = microtime(true);

        // Simulate light concurrent work
        $results = [];
        for ($i = 0; $i < 10; $i++) {
            $results[] = [
                'task_id' => $i,
                'result' => $i * 2,
                'timestamp' => microtime(true),
            ];
        }

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'concurrent_light',
            'execution_time' => round($executionTime * 1000, 2),
            'tasks_completed' => count($results),
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * Medium concurrent operations
     */
    public function concurrentMedium()
    {
        $startTime = microtime(true);

        // Simulate medium concurrent work
        $results = [];
        for ($i = 0; $i < 50; $i++) {
            // Some calculations
            $value = 0;
            for ($j = 0; $j < 1000; $j++) {
                $value += sqrt($j);
            }

            $results[] = [
                'task_id' => $i,
                'calculated_value' => $value,
                'timestamp' => microtime(true),
            ];
        }

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'concurrent_medium',
            'execution_time' => round($executionTime * 1000, 2),
            'tasks_completed' => count($results),
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * Heavy concurrent operations
     */
    public function concurrentHeavy()
    {
        $startTime = microtime(true);

        // Simulate heavy concurrent work
        $results = [];
        for ($i = 0; $i < 100; $i++) {
            // Heavy calculations
            $value = 0;
            for ($j = 0; $j < 5000; $j++) {
                $value += pow($j, 1.5) + sin($j) * cos($j);
            }

            // Database operation
            if ($i % 10 === 0) {
                User::count();
            }

            // Cache operation
            Cache::put("heavy_$i", ['value' => $value], 60);

            $results[] = [
                'task_id' => $i,
                'calculated_value' => round($value, 2),
                'timestamp' => microtime(true),
            ];
        }

        $executionTime = microtime(true) - $startTime;

        return response()->json([
            'status' => 'success',
            'operation' => 'concurrent_heavy',
            'execution_time' => round($executionTime * 1000, 2),
            'tasks_completed' => count($results),
            'memory_usage' => $this->getMemoryUsage(),
        ]);
    }

    /**
     * Helper method to get runtime information
     */
    private function getRuntimeInfo()
    {
        $server = 'unknown';

        // Detect runtime
        if (extension_loaded('swoole')) {
            $server = 'swoole';
        } elseif (isset($_SERVER['SERVER_SOFTWARE'])) {
            if (strpos($_SERVER['SERVER_SOFTWARE'], 'nginx') !== false) {
                $server = 'php-fpm + nginx';
            } elseif (strpos($_SERVER['SERVER_SOFTWARE'], 'Caddy') !== false) {
                $server = 'frankenphp';
            }
        }

        return [
            'server' => $server,
            'php_version' => PHP_VERSION,
            'memory_usage' => $this->getMemoryUsage(),
            'loaded_extensions' => get_loaded_extensions(),
            'max_execution_time' => ini_get('max_execution_time'),
            'memory_limit' => ini_get('memory_limit'),
            'opcache_enabled' => function_exists('opcache_get_status') ? opcache_get_status() !== false : false,
        ];
    }

    /**
     * Helper method to get memory usage
     */
    private function getMemoryUsage()
    {
        return [
            'current' => memory_get_usage(true),
            'peak' => memory_get_peak_usage(true),
            'current_real' => memory_get_usage(false),
            'peak_real' => memory_get_peak_usage(false),
        ];
    }

    /**
     * Helper method to calculate Fibonacci number
     */
    private function fibonacci($n)
    {
        if ($n <= 1) return $n;

        $a = 0;
        $b = 1;

        for ($i = 2; $i <= $n; $i++) {
            $temp = $a + $b;
            $a = $b;
            $b = $temp;
        }

        return $b;
    }

    /**
     * Helper method to check if number is prime
     */
    private function isPrime($n)
    {
        if ($n <= 1) return false;
        if ($n <= 3) return true;
        if ($n % 2 === 0 || $n % 3 === 0) return false;

        for ($i = 5; $i * $i <= $n; $i += 6) {
            if ($n % $i === 0 || $n % ($i + 2) === 0) {
                return false;
            }
        }

        return true;
    }
}
