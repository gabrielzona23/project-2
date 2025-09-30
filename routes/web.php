<?php

use Illuminate\Support\Facades\Route;

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

// Root endpoint with API information
Route::get('/', function () {
    return response()->json([
        'message' => 'Laravel Benchmark API',
        'api_endpoints' => '/api/',
        'health_check' => '/api/health',
        'static_test' => '/api/static',
        'timestamp' => now()->toISOString()
    ]);
});
