<?php

use App\Http\Controllers\BenchmarkController;
use App\Services\HttpService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Response;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Root API endpoint
Route::get('', function () {
    return response()->json([
        'message' => 'Laravel Benchmark API',
        'timestamp' => now()->toISOString(),
        'server' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown',
        'php_version' => PHP_VERSION,
        'memory_usage' => memory_get_usage(true),
        'peak_memory' => memory_get_peak_usage(true)
    ]);
});

// Health check endpoints
Route::get('health', function () {
    try {
        DB::connection()->getPdo();
        Cache::put('health_check', time(), 60);
        $cached_value = Cache::get('health_check');

        return response()->json([
            'status' => 'OK',
            'database' => 'Connected',
            'cache' => $cached_value ? 'Connected' : 'Failed',
            'timestamp' => now()->toISOString()
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'ERROR',
            'message' => $e->getMessage()
        ], 500);
    }
});

Route::get('health-check', fn(Request $request) => Response::noContent())->name('health-check');

// Simple test endpoints
Route::get('static', fn(Request $request) => Response::json(['status' => true]))->name('static');

Route::get(
    '/http-request',
    fn(Request $request, HttpService $httpService) =>
    Response::json(json_decode($httpService->get('http://whoami/api')))
)->name('http-request');

Route::controller(BenchmarkController::class)->group(function () {

    // Database operations
    Route::get('database', 'database');
    Route::get('database/read', 'databaseRead');
    Route::get('database/write', 'databaseWrite');
    Route::get('database/complex', 'databaseComplex');

    // Cache operations
    Route::get('cache', 'cache');
    Route::get('cache/read', 'cacheRead');
    Route::get('cache/write', 'cacheWrite');

    // File operations
    Route::get('file-read', 'fileRead');
    Route::get('file-write', 'fileWrite');
    Route::get('file-operations', 'fileOperations');

    // External API calls
    Route::get('api-external', 'externalApi');

    // CPU intensive operations
    Route::get('cpu-intensive', 'cpuIntensive');

    // Memory operations
    Route::get('memory-test', 'memoryTest');

    // JSON operations
    Route::get('json-encode', 'jsonEncode');
    Route::get('json-decode', 'jsonDecode');

    // Mixed workload
    Route::get('mixed-workload', 'mixedWorkload');

    // Stress tests
    Route::get('stress-test', 'stressTest');

    // Runtime specific tests
    Route::get('runtime-info', 'runtimeInfo');

    // Concurrent tests (varying difficulty)
    Route::get('concurrent/light', 'concurrentLight');
    Route::get('concurrent/medium', 'concurrentMedium');
    Route::get('concurrent/heavy', 'concurrentHeavy');
});
