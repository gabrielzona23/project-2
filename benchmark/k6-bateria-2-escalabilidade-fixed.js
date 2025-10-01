import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics for detailed analysis
export let errorRate = new Rate('errors');
export let responseTimeTrend = new Trend('response_time');

// Test configuration for progressive load testing - Bateria 2
export let options = {
    stages: [
        // Progressive load testing stages
        { duration: '60s', target: 10 },   // Warm up to 10 VUs
        { duration: '60s', target: 25 },   // Scale to 25 VUs  
        { duration: '60s', target: 50 },   // Scale to 50 VUs
        { duration: '60s', target: 100 },  // Scale to 100 VUs
        { duration: '60s', target: 200 },  // Scale to 200 VUs
        { duration: '30s', target: 0 },    // Cool down
    ],
    thresholds: {
        // Success criteria for academic analysis
        'http_req_duration': ['p(95)<500'], // 95% of requests under 500ms
        'errors': ['rate<0.1'], // Less than 10% errors
        'http_req_failed': ['rate<0.05'], // Less than 5% failures
    }
};

// Runtime endpoints configuration
const runtimes = {
    swoole: 'http://localhost:8001',
    frankenphp: 'http://localhost:8003',
    php_fpm: 'http://localhost:8002'
};

// Test endpoints (using working endpoints only)
const endpoints = ['/api/cache', '/api/static'];

export default function () {
    // Randomly select a runtime and endpoint to test
    let runtimeNames = Object.keys(runtimes);
    let runtime = runtimeNames[Math.floor(Math.random() * runtimeNames.length)];
    let endpoint = endpoints[Math.floor(Math.random() * endpoints.length)];

    let url = runtimes[runtime] + endpoint;

    // Execute request with runtime tagging
    let response = http.get(url, {
        tags: {
            runtime: runtime,
            endpoint: endpoint
        }
    });

    // Record custom metrics
    responseTimeTrend.add(response.timings.duration, {
        runtime: runtime,
        endpoint: endpoint
    });

    // Validation checks
    let success = check(response, {
        [`${runtime}:${endpoint} - Status 200`]: (r) => r.status === 200,
        [`${runtime}:${endpoint} - Response time < 1s`]: (r) => r.timings.duration < 1000,
        [`${runtime}:${endpoint} - Has content`]: (r) => r.body && r.body.length > 0,
    }, {
        runtime: runtime,
        endpoint: endpoint
    });

    // Track error rate
    errorRate.add(!success, {
        runtime: runtime,
        endpoint: endpoint
    });

    // Random sleep between 0.5-2 seconds to simulate real user behavior
    sleep(Math.random() * 1.5 + 0.5);
}

// Setup function - called once at start
export function setup() {
    console.log('🚀 Starting Bateria 2 - Progressive Load Testing');
    console.log('📊 Test Strategy: 10→25→50→100→200 VUs over 330 seconds');
    console.log('🎯 Focus: Scalability and performance degradation under load');

    // Verify all endpoints are accessible
    let healthCheck = {};
    for (let [runtime, baseUrl] of Object.entries(runtimes)) {
        try {
            let response = http.get(baseUrl + '/api/static');
            healthCheck[runtime] = response.status === 200;
            console.log(`🔍 ${runtime}: ${response.status === 200 ? '✅ Ready' : '❌ Not Ready'}`);
        } catch (e) {
            healthCheck[runtime] = false;
            console.log(`🔍 ${runtime}: ❌ Error - ${e.message}`);
        }
    }

    return healthCheck;
}

// Teardown function - called once at end  
export function teardown(data) {
    console.log('📋 Bateria 2 Complete - Progressive Load Testing');
    console.log('📊 Data collected for academic analysis:');
    console.log('   - Scalability performance under increasing load');
    console.log('   - Runtime comparison across different VU levels');
    console.log('   - Performance degradation patterns');
    console.log('   - Error rates under stress conditions');
}