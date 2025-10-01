import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics for detailed analysis
export let errorRate = new Rate('errors');
export let responseTimeTrend = new Trend('response_time');

// Test configuration for progressive load testing
export let options = {
    stages: [
        // Progressive load testing - Bateria 2
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
        'http_req_duration{group:::swoole}': ['p(95)<300'],
        'http_req_duration{group:::frankenphp}': ['p(95)<300'],
        'http_req_duration{group:::php_fpm}': ['p(95)<800'],
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

// Test endpoints from Bateria 1 (usando apenas endpoints funcionais)
const endpoints = ['/api/cache', '/api/static'];

export default function () {
    // Test each runtime with all endpoints
    for (let [runtime, baseUrl] of Object.entries(runtimes)) {
        for (let endpoint of endpoints) {
            let url = baseUrl + endpoint;

            // Execute request with runtime tagging
            let response = http.get(url, {
                tags: {
                    runtime: runtime,
                    endpoint: endpoint,
                    group: runtime
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
                [`${runtime}:${endpoint} - Has content`]: (r) => r.body.length > 0,
            }, {
                runtime: runtime,
                endpoint: endpoint
            });

            // Track error rate
            errorRate.add(!success, {
                runtime: runtime,
                endpoint: endpoint
            });

            // Small delay between requests to avoid overwhelming
            sleep(0.1);
        }
    }

    // Random sleep between 1-3 seconds to simulate real user behavior
    sleep(Math.random() * 2 + 1);
}

// Setup function - called once at start
export function setup() {
    console.log('🚀 Starting Bateria 2 - Progressive Load Testing');
    console.log('📊 Test Strategy: 10→25→50→100→200 VUs over 330 seconds');
    console.log('🎯 Focus: P95 latency degradation under increasing load');

    // Verify all endpoints are accessible
    let healthCheck = {};
    for (let [runtime, baseUrl] of Object.entries(runtimes)) {
        let response = http.get(baseUrl + '/api/static');
        healthCheck[runtime] = response.status === 200;
        console.log(`🔍 ${runtime}: ${response.status === 200 ? '✅ Ready' : '❌ Not Ready'}`);
    }

    return healthCheck;
}

// Teardown function - called once at end
export function teardown(data) {
    console.log('📋 Bateria 2 Complete - Progressive Load Testing');
    console.log('📊 Data collected for academic analysis:');
    console.log('   - Scalability curves (P95 latency vs VUs)');
    console.log('   - Runtime comparison under increasing load');
    console.log('   - Saturation point identification');
    console.log('   - Performance degradation patterns');
}