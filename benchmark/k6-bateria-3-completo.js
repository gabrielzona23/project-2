import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics
export let errorRate = new Rate('errors');
export let responseTime = new Trend('response_time');
export let requestsPerSecond = new Rate('requests_per_second');
export let databaseRequests = new Counter('database_requests');
export let cacheRequests = new Counter('cache_requests');
export let fileRequests = new Counter('file_requests');
export let cpuRequests = new Counter('cpu_requests');
export let memoryRequests = new Counter('memory_requests');

// Test configuration
export let options = {
    stages: [
        { duration: '60s', target: 10 },   // Warm-up: 0→10 VUs
        { duration: '60s', target: 25 },   // Low load: 10→25 VUs
        { duration: '60s', target: 50 },   // Medium load: 25→50 VUs
        { duration: '60s', target: 100 },  // High load: 50→100 VUs
        { duration: '60s', target: 200 },  // Stress test: 100→200 VUs
        { duration: '30s', target: 0 },    // Cool-down: 200→0 VUs
    ],
    thresholds: {
        'errors': ['rate<0.1'],              // Error rate should be less than 10%
        'http_req_duration': ['p(95)<500'],  // 95% of requests should complete within 500ms
        'http_req_failed': ['rate<0.05'],    // HTTP failure rate should be less than 5%
    },
};

// Runtime endpoints
const runtimes = {
    swoole: 'http://localhost:8001',
    frankenphp: 'http://localhost:8003',
    php_fpm: 'http://localhost:8002'
};

// API endpoints grouped by category
const endpoints = {
    // Basic endpoints
    basic: [
        '/api',
        '/api/health',
        '/api/static'
    ],

    // Database operations
    database: [
        '/api/database',
        '/api/database/read',
        '/api/database/write',
        '/api/database/complex'
    ],

    // Cache operations
    cache: [
        '/api/cache',
        '/api/cache/read',
        '/api/cache/write'
    ],

    // File operations
    file: [
        '/api/file-read',
        '/api/file-write',
        '/api/file-operations'
    ],

    // CPU intensive
    cpu: [
        '/api/cpu-intensive',
        '/api/json-encode',
        '/api/json-decode'
    ],

    // Memory operations
    memory: [
        '/api/memory-test',
        '/api/mixed-workload'
    ],

    // Concurrent operations
    concurrent: [
        '/api/concurrent/light',
        '/api/concurrent/medium',
        '/api/concurrent/heavy'
    ]
};

// Health check function
function healthCheck() {
    console.log('🚀 Starting Bateria 3 - Complete Load Testing');
    console.log('📊 Test Strategy: Progressive load with resource monitoring');
    console.log('🎯 Focus: All endpoints, resource usage patterns, performance degradation');

    let allHealthy = true;

    for (let [name, url] of Object.entries(runtimes)) {
        try {
            let response = http.get(`${url}/api/health`, { timeout: '5s' });
            if (response.status === 200) {
                console.log(`🔍 ${name}: ✅ Ready`);
            } else {
                console.log(`🔍 ${name}: ❌ Not Ready (${response.status})`);
                allHealthy = false;
            }
        } catch (error) {
            console.log(`🔍 ${name}: ❌ Error - ${error}`);
            allHealthy = false;
        }
    }

    if (!allHealthy) {
        console.log('❌ Some services are not ready. Please check containers.');
    }
}

// Get random runtime
function getRandomRuntime() {
    const runtimeNames = Object.keys(runtimes);
    const randomName = runtimeNames[Math.floor(Math.random() * runtimeNames.length)];
    return { name: randomName, url: runtimes[randomName] };
}

// Get random endpoint from category
function getRandomEndpoint(category) {
    const categoryEndpoints = endpoints[category];
    return categoryEndpoints[Math.floor(Math.random() * categoryEndpoints.length)];
}

// Test specific endpoint category
function testCategory(runtime, category, categoryName) {
    const endpoint = getRandomEndpoint(category);
    const url = `${runtime.url}${endpoint}`;

    let response = http.get(url, {
        timeout: '10s',
        tags: {
            runtime: runtime.name,
            category: categoryName,
            endpoint: endpoint
        }
    });

    // Record response time
    responseTime.add(response.timings.duration);

    // Count requests by category
    switch (categoryName) {
        case 'database':
            databaseRequests.add(1);
            break;
        case 'cache':
            cacheRequests.add(1);
            break;
        case 'file':
            fileRequests.add(1);
            break;
        case 'cpu':
            cpuRequests.add(1);
            break;
        case 'memory':
            memoryRequests.add(1);
            break;
    }

    // Validate response
    let isSuccess = check(response, {
        [`${runtime.name}:${endpoint} - Status 200`]: (r) => r.status === 200,
        [`${runtime.name}:${endpoint} - Response time < 1s`]: (r) => r.timings.duration < 1000,
        [`${runtime.name}:${endpoint} - Has content`]: (r) => r.body.length > 0,
    });

    if (!isSuccess) {
        errorRate.add(1);
        console.log(`❌ Failed: ${runtime.name}${endpoint} - Status: ${response.status}`);
    }

    return response;
}

// Main test function
export default function () {
    // Test different categories with different weights
    const runtime = getRandomRuntime();

    // Weight distribution (higher weight = more likely to be tested)
    const categoryWeights = {
        basic: 20,      // 20% - Light operations
        database: 25,   // 25% - Heavy database operations  
        cache: 20,      // 20% - Cache operations
        file: 10,       // 10% - File I/O
        cpu: 15,        // 15% - CPU intensive
        memory: 5,      // 5% - Memory operations
        concurrent: 5   // 5% - Concurrent operations
    };

    // Select category based on weights
    const random = Math.random() * 100;
    let cumulative = 0;
    let selectedCategory = 'basic';

    for (let [category, weight] of Object.entries(categoryWeights)) {
        cumulative += weight;
        if (random < cumulative) {
            selectedCategory = category;
            break;
        }
    }

    // Execute test for selected category
    testCategory(runtime, endpoints[selectedCategory], selectedCategory);

    // Short sleep between requests (0.5-1.5 seconds)
    sleep(Math.random() + 0.5);
}

// Setup function
export function setup() {
    healthCheck();
    return {};
}

// Teardown function  
export function teardown(data) {
    console.log('📋 Bateria 3 Complete - Complete Load Testing');
    console.log('📊 Data collected for academic analysis:');
    console.log('   - Comprehensive endpoint coverage');
    console.log('   - Resource usage patterns by category');
    console.log('   - Runtime comparison across workload types');
    console.log('   - Performance degradation under progressive load');
    console.log('   - Category-specific performance characteristics');
}