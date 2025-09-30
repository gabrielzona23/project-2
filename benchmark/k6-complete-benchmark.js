import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('error_rate');
const requestDuration = new Trend('request_duration', true);
const requestCounter = new Counter('total_requests');

// Test configuration
export const options = {
    stages: [
        { duration: '1m', target: 20 },   // Warm up
        { duration: '3m', target: 50 },   // Load test
        { duration: '1m', target: 100 },  // Peak test
        { duration: '2m', target: 0 },    // Cool down
    ],
    thresholds: {
        http_req_failed: ['rate<0.1'],    // Error rate should be less than 10%
        http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
        error_rate: ['rate<0.1'],
        error_rate: ['rate<0.1'],
    },
};

// Define all API endpoints to test
const endpoints = [
    '/api/health-check',
    '/api/static',
    '/api/health',
    '/api/database/read',
    '/api/database/write',
    '/api/database',
    '/api/cache/read',
    '/api/cache/write',
    '/api/cache',
    '/api/file-read',
    '/api/file-write',
    '/api/json-encode',
    '/api/json-decode',
    '/api/cpu-intensive',
    '/api/memory-test',
    '/api/runtime-info',
    '/api/concurrent/light',
    '/api/concurrent/medium',
    // Skip heavy endpoints for normal load testing
    // '/api/database/complex',
    // '/api/file-operations', 
    // '/api/api-external',
    // '/api/mixed-workload',
    // '/api/stress-test',
    // '/api/concurrent/heavy',
];

// Runtime configurations
const runtimes = [
    { name: 'Swoole', baseUrl: 'http://localhost:8001' },
    { name: 'PHP-FPM', baseUrl: 'http://localhost:8002' },
    { name: 'FrankenPHP', baseUrl: 'http://localhost:8003' },
];

export default function () {
    // Round-robin through runtimes
    const runtime = runtimes[__VU % runtimes.length];

    // Random endpoint selection for varied load
    const endpoint = endpoints[Math.floor(Math.random() * endpoints.length)];
    const url = `${runtime.baseUrl}${endpoint}`;

    const params = {
        timeout: '30s',
        tags: {
            runtime: runtime.name,
            endpoint: endpoint
        },
    };

    // Make request
    const startTime = Date.now();
    const response = http.get(url, params);
    const duration = Date.now() - startTime;

    // Record metrics
    requestCounter.add(1);
    requestDuration.add(duration);

    // Check response
    const success = check(response, {
        'status is 200': (r) => r.status === 200,
        'response time < 5000ms': (r) => r.timings.duration < 5000,
        'has response body': (r) => r.body.length > 0,
    });

    errorRate.add(!success);

    // Log failed requests
    if (!success) {
        console.error(`FAILED: ${runtime.name} ${endpoint} - Status: ${response.status}, Duration: ${duration}ms`);
    }

    // Small delay to prevent overwhelming
    sleep(0.1);
}

export function handleSummary(data) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');

    return {
        [`results/k6-complete-benchmark-${timestamp}.json`]: JSON.stringify(data, null, 2),
        [`results/k6-complete-benchmark-${timestamp}.txt`]: textSummary(data, { indent: ' ', enableColors: false }),
        stdout: textSummary(data, { indent: ' ', enableColors: true }),
    };
}

function textSummary(data, options = {}) {
    const { indent = '', enableColors = true } = options;

    const summary = [
        `${indent}📊 K6 Complete Benchmark Results`,
        `${indent}=====================================`,
        `${indent}`,
        `${indent}🔥 Load Test Summary:`,
        `${indent}  • Total Requests: ${data.metrics.total_requests.values.count}`,
        `${indent}  • Failed Requests: ${data.metrics.http_req_failed.values.rate * 100}%`,
        `${indent}  • Average Duration: ${data.metrics.http_req_duration.values.avg.toFixed(2)}ms`,
        `${indent}  • 95th Percentile: ${data.metrics.http_req_duration.values['p(95)'].toFixed(2)}ms`,
        `${indent}  • Max Duration: ${data.metrics.http_req_duration.values.max.toFixed(2)}ms`,
        `${indent}`,
        `${indent}📈 Request Rate:`,
        `${indent}  • Requests/sec: ${data.metrics.http_reqs.values.rate.toFixed(2)}`,
        `${indent}  • Data Transferred: ${(data.metrics.data_received.values.count / 1024 / 1024).toFixed(2)} MB`,
        `${indent}`,
        `${indent}⚡ Performance Breakdown by Runtime:`,
    ];

    // Add runtime-specific metrics if available
    if (data.metrics.http_req_duration && data.metrics.http_req_duration.values) {
        const runtimeNames = ['Swoole', 'PHP-FPM', 'FrankenPHP'];
        runtimeNames.forEach(runtime => {
            summary.push(`${indent}  • ${runtime}: See detailed JSON report`);
        });
    }

    summary.push(
        `${indent}`,
        `${indent}🎯 Endpoints Tested: ${endpoints.length} different routes`,
        `${indent}🏁 Test completed at: ${new Date().toLocaleString()}`,
        `${indent}`
    );

    return summary.join('\n');
}