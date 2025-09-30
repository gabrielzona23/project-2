<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Http\Request;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

Route::get('/', function () {
    return response()->json([
        'message' => 'Laravel Benchmark API',
        'timestamp' => now()->toISOString(),
        'server' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown',
        'php_version' => PHP_VERSION,
        'memory_usage' => memory_get_usage(true),
        'peak_memory' => memory_get_peak_usage(true)
    ]);
});

Route::get('/health', function () {
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

// API Routes
Route::prefix('api')->group(function () {
    
    // Simple endpoint for basic performance testing
    Route::get('/ping', function () {
        return response()->json(['pong' => microtime(true)]);
    });
    
    // CPU intensive endpoint
    Route::get('/cpu/{iterations?}', function ($iterations = 1000) {
        $start = microtime(true);
        $result = 0;
        
        for ($i = 0; $i < $iterations; $i++) {
            $result += sqrt($i * $iterations);
        }
        
        return response()->json([
            'result' => $result,
            'iterations' => $iterations,
            'execution_time' => microtime(true) - $start,
            'memory_usage' => memory_get_usage(true)
        ]);
    });
    
    // Database query endpoint
    Route::get('/users', function () {
        try {
            $users = DB::table('users')->select('id', 'name', 'email', 'created_at')->get();
            return response()->json([
                'users' => $users,
                'count' => $users->count(),
                'query_time' => DB::getQueryLog()
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    });
    
    // Database with joins
    Route::get('/posts', function () {
        try {
            $posts = DB::table('posts')
                ->join('users', 'posts.user_id', '=', 'users.id')
                ->select('posts.*', 'users.name as author')
                ->get();
                
            return response()->json([
                'posts' => $posts,
                'count' => $posts->count()
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    });
    
    // Cache test endpoint
// //     Route::get('/cache/{key?}', function ($key = 'test') {
// //         $cacheKey = 'benchmark_' . $key;
// //         $data = Cache::remember($cacheKey, 300, function () use ($key) {
// //             // Simulate expensive operation
// //             usleep(100000); // 100ms delay
// //             return [
// //                 'key' => $key,
// //                 'generated_at' => now()->toISOString(),
// //                 'random_data' => array_map(function() {
// //                     return random_int(1, 1000);
// //                 }, range(1, 100))
// //             ];
// //         });
//         
//         return response()->json($data);
//     });
    
    // Memory intensive endpoint
    Route::get('/memory/{size?}', function ($size = 1000) {
        $start = microtime(true);
        $start_memory = memory_get_usage(true);
        
        // Create array with specified size
        $data = [];
        for ($i = 0; $i < $size; $i++) {
            $data[] = [
                'id' => $i,
                'data' => str_repeat('x', 1024), // 1KB per entry
                'timestamp' => microtime(true)
            ];
        }
        
        return response()->json([
            'array_size' => count($data),
            'memory_used' => memory_get_usage(true) - $start_memory,
            'execution_time' => microtime(true) - $start,
            'peak_memory' => memory_get_peak_usage(true)
        ]);
    });
    
    // JSON processing endpoint
    Route::post('/json', function (Request $request) {
        $start = microtime(true);
        $input = $request->json()->all();
        
        // Process JSON data
        $processed = collect($input)->map(function ($item, $key) {
            if (is_array($item)) {
                return array_map('strtoupper', $item);
            }
            return strtoupper((string) $item);
        });
        
        return response()->json([
            'processed_data' => $processed,
            'processing_time' => microtime(true) - $start,
            'input_size' => strlen(json_encode($input)),
            'output_size' => strlen(json_encode($processed))
        ]);
    });
});
