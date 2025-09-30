<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\BenchmarkController;

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

// Health check endpoint
Route::get('/health', [BenchmarkController::class, 'health']);

// Database operations
Route::get('/database', [BenchmarkController::class, 'database']);
Route::get('/database/read', [BenchmarkController::class, 'databaseRead']);
Route::get('/database/write', [BenchmarkController::class, 'databaseWrite']);
Route::get('/database/complex', [BenchmarkController::class, 'databaseComplex']);

// Cache operations
Route::get('/cache', [BenchmarkController::class, 'cache']);
Route::get('/cache/read', [BenchmarkController::class, 'cacheRead']);
Route::get('/cache/write', [BenchmarkController::class, 'cacheWrite']);

// File operations
Route::get('/file-read', [BenchmarkController::class, 'fileRead']);
Route::get('/file-write', [BenchmarkController::class, 'fileWrite']);
Route::get('/file-operations', [BenchmarkController::class, 'fileOperations']);

// External API calls
Route::get('/api-external', [BenchmarkController::class, 'externalApi']);

// CPU intensive operations
Route::get('/cpu-intensive', [BenchmarkController::class, 'cpuIntensive']);

// Memory operations
Route::get('/memory-test', [BenchmarkController::class, 'memoryTest']);

// JSON operations
Route::get('/json-encode', [BenchmarkController::class, 'jsonEncode']);
Route::get('/json-decode', [BenchmarkController::class, 'jsonDecode']);

// Mixed workload
Route::get('/mixed-workload', [BenchmarkController::class, 'mixedWorkload']);

// Stress tests
Route::get('/stress-test', [BenchmarkController::class, 'stressTest']);

// Runtime specific tests
Route::get('/runtime-info', [BenchmarkController::class, 'runtimeInfo']);

// Concurrent tests (varying difficulty)
Route::get('/concurrent/light', [BenchmarkController::class, 'concurrentLight']);
Route::get('/concurrent/medium', [BenchmarkController::class, 'concurrentMedium']);
Route::get('/concurrent/heavy', [BenchmarkController::class, 'concurrentHeavy']);
