/**
 * K6 Comprehensive Runtime Comparison Benchmark
 * Compares Swoole, FrankenPHP, and PHP-FPM performance
 * 
 * TCC - Análise Comparativa de Runtimes PHP
 * Data: 2025-09-30
 */

import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

// Custom metrics for detailed analysis
const httpReqDuration = new Trend('http_req_duration_custom');
const httpReqFailed = new Rate('http_req_failed_custom');
const requestsPerSecond = new Counter('requests_per_second');

// Runtime configurations
const RUNTIMES = {
    swoole: {
        name: 'Swoole',
        baseUrl: 'http://localhost:8001',
        port: 8001
    },
    frankenphp: {
        name: 'FrankenPHP',
        baseUrl: 'http://localhost:8003',
        port: 8003
    },
    phpfpm: {
        name: 'PHP-FPM',
        baseUrl: 'http://localhost:8002',
        port: 8002
    }
};

// Test scenarios configuration
const SCENARIOS = {
    // Light load - Verificação inicial
    light_load: {
        executor: 'constant-vus',
        vus: 10,
        duration: '2m',
        gracefulStop: '10s'
    },

    // Medium load - Carga normal
    medium_load: {
        executor: 'constant-vus',
        vus: 50,
        duration: '3m',
        gracefulStop: '15s'
    },

    // Heavy load - Carga pesada
    heavy_load: {
        executor: 'constant-vus',
        vus: 100,
        duration: '3m',
        gracefulStop: '20s'
    },

    // Spike test - Picos de tráfego
    spike_test: {
        executor: 'ramping-vus',
        startVUs: 0,
        stages: [
            { duration: '30s', target: 20 },
            { duration: '1m', target: 100 },
            { duration: '30s', target: 200 },
            { duration: '1m', target: 100 },
            { duration: '30s', target: 0 }
        ],
        gracefulStop: '30s'
    },

    // Stress test - Teste de limite
    stress_test: {
        executor: 'ramping-vus',
        startVUs: 0,
        stages: [
            { duration: '1m', target: 50 },
            { duration: '2m', target: 150 },
            { duration: '2m', target: 250 },
            { duration: '1m', target: 0 }
        ],
        gracefulStop: '30s'
    }
};

// Test endpoints with different complexity levels
const ENDPOINTS = {
    // Básicos
    health: '/api/health-check',
    static: '/api/static',
    root: '/api/',

    // Database operations
    database: '/api/database',
    database_read: '/api/database/read',
    database_write: '/api/database/write',
    database_complex: '/api/database/complex',

    // Cache operations
    cache: '/api/cache',
    cache_read: '/api/cache/read',
    cache_write: '/api/cache/write',

    // File operations
    file_read: '/api/file-read',
    file_write: '/api/file-write',
    file_operations: '/api/file-operations',

    // CPU intensive
    cpu_intensive: '/api/cpu-intensive',
    memory_test: '/api/memory-test',

    // JSON operations
    json_encode: '/api/json-encode',
    json_decode: '/api/json-decode',

    // Mixed workload
    mixed_workload: '/api/mixed-workload',
    stress_test: '/api/stress-test',

    // Concurrent tests
    concurrent_light: '/api/concurrent/light',
    concurrent_medium: '/api/concurrent/medium',
    concurrent_heavy: '/api/concurrent/heavy',

    // Runtime info
    runtime_info: '/api/runtime-info'
};

// Export configuration
export const options = {
    scenarios: SCENARIOS,

    thresholds: {
        // Performance thresholds
        http_req_duration: ['p(95)<1000', 'p(99)<2000'],
        http_req_failed: ['rate<0.1'],
        http_reqs: ['count>1000'],

        // Custom thresholds per runtime
        'http_req_duration{runtime:swoole}': ['p(95)<800'],
        'http_req_duration{runtime:frankenphp}': ['p(95)<800'],
        'http_req_duration{runtime:phpfpm}': ['p(95)<1200'],

        // Specific endpoint thresholds
        'http_req_duration{endpoint:health}': ['p(95)<100'],
        'http_req_duration{endpoint:static}': ['p(95)<100'],
        'http_req_duration{endpoint:database}': ['p(95)<500'],
        'http_req_duration{endpoint:cpu_intensive}': ['p(95)<2000'],
    },

    // Output results
    summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
};

// Runtime selection logic
function selectRuntime() {
    const runtimeKeys = Object.keys(RUNTIMES);
    const selectedKey = runtimeKeys[Math.floor(Math.random() * runtimeKeys.length)];
    return RUNTIMES[selectedKey];
}

// Endpoint selection with weighted distribution
function selectEndpoint(complexity = 'mixed') {
    const endpointGroups = {
        light: ['health', 'static', 'root'],
        medium: ['database', 'cache', 'json_encode', 'json_decode'],
        heavy: ['cpu_intensive', 'memory_test', 'mixed_workload', 'file_operations'],
        mixed: Object.keys(ENDPOINTS)
    };

    const endpoints = endpointGroups[complexity] || endpointGroups.mixed;
    return endpoints[Math.floor(Math.random() * endpoints.length)];
}

// Main test function
export default function () {
    const runtime = selectRuntime();
    const endpointKey = selectEndpoint();
    const endpoint = ENDPOINTS[endpointKey];
    const url = `${runtime.baseUrl}${endpoint}`;

    // Add runtime and endpoint tags for detailed metrics
    const params = {
        tags: {
            runtime: runtime.name.toLowerCase(),
            endpoint: endpointKey,
            port: runtime.port
        },
        timeout: '30s'
    };

    // Execute request
    const response = http.get(url, params);

    // Custom metrics tracking
    httpReqDuration.add(response.timings.duration, params.tags);
    httpReqFailed.add(response.status !== 200 && response.status !== 204, params.tags);
    requestsPerSecond.add(1, params.tags);

    // Response validation
    const isSuccess = check(response, {
        'status is 200 or 204': (r) => r.status === 200 || r.status === 204,
        'response time < 5s': (r) => r.timings.duration < 5000,
        'response has content': (r) => r.body.length > 0 || r.status === 204,
    }, params.tags);

    // Add small delay to simulate real user behavior
    sleep(Math.random() * 0.1);
}

// Specific test groups for detailed analysis
export function healthCheck() {
    group('Health Check Tests', function () {
        for (const [key, runtime] of Object.entries(RUNTIMES)) {
            group(`${runtime.name} Health Check`, function () {
                const response = http.get(`${runtime.baseUrl}/api/health-check`, {
                    tags: { runtime: key, test_type: 'health' }
                });

                check(response, {
                    'health check passes': (r) => r.status === 204,
                    'response time < 100ms': (r) => r.timings.duration < 100,
                });
            });
        }
    });
}

export function databaseTests() {
    group('Database Performance Tests', function () {
        const dbEndpoints = ['database', 'database_read', 'database_write', 'database_complex'];

        for (const [key, runtime] of Object.entries(RUNTIMES)) {
            group(`${runtime.name} Database Tests`, function () {
                dbEndpoints.forEach(endpoint => {
                    const response = http.get(`${runtime.baseUrl}/api/${endpoint.replace('_', '/')}`, {
                        tags: { runtime: key, test_type: 'database', endpoint: endpoint }
                    });

                    check(response, {
                        'database request succeeds': (r) => r.status === 200,
                        'response time < 1s': (r) => r.timings.duration < 1000,
                    });
                });
            });
        }
    });
}

export function performanceTests() {
    group('Performance Intensive Tests', function () {
        const perfEndpoints = ['cpu-intensive', 'memory-test', 'mixed-workload'];

        for (const [key, runtime] of Object.entries(RUNTIMES)) {
            group(`${runtime.name} Performance Tests`, function () {
                perfEndpoints.forEach(endpoint => {
                    const response = http.get(`${runtime.baseUrl}/api/${endpoint}`, {
                        tags: { runtime: key, test_type: 'performance', endpoint: endpoint }
                    });

                    check(response, {
                        'performance test completes': (r) => r.status === 200,
                        'response time < 3s': (r) => r.timings.duration < 3000,
                    });
                });
            });
        }
    });
}

// Teardown function for final summary
export function teardown(data) {
    console.log('\n=== BENCHMARK COMPARISON COMPLETED ===');
    console.log('Results will be available in the K6 output');
    console.log('Runtimes tested: Swoole, FrankenPHP, PHP-FPM');
    console.log('Total scenarios: ', Object.keys(SCENARIOS).length);
    console.log('Total endpoints tested: ', Object.keys(ENDPOINTS).length);
}