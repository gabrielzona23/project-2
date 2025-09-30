import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend } from 'k6/metrics';

// Custom metrics per runtime
const swooleDuration = new Trend('swoole_duration');
const phpfpmDuration = new Trend('phpfpm_duration');
const frankenphpDuration = new Trend('frankenphp_duration');

export const options = {
    scenarios: {
        endpoint_comparison: {
            executor: 'per-vu-iterations',
            vus: 5,
            iterations: 10,
            maxDuration: '10m',
        },
    },
};

// All endpoints to test individually
const endpoints = [
    { path: '/api/health-check', name: 'Health Check' },
    { path: '/api/static', name: 'Static Response' },
    { path: '/api/health', name: 'Health Endpoint' },
    { path: '/api/database/read', name: 'Database Read' },
    { path: '/api/database/write', name: 'Database Write' },
    { path: '/api/database', name: 'Database General' },
    { path: '/api/cache/read', name: 'Cache Read' },
    { path: '/api/cache/write', name: 'Cache Write' },
    { path: '/api/cache', name: 'Cache General' },
    { path: '/api/file-read', name: 'File Read' },
    { path: '/api/file-write', name: 'File Write' },
    { path: '/api/json-encode', name: 'JSON Encode' },
    { path: '/api/json-decode', name: 'JSON Decode' },
    { path: '/api/cpu-intensive', name: 'CPU Intensive' },
    { path: '/api/memory-test', name: 'Memory Test' },
    { path: '/api/runtime-info', name: 'Runtime Info' },
    { path: '/api/concurrent/light', name: 'Concurrent Light' },
    { path: '/api/concurrent/medium', name: 'Concurrent Medium' },
];

const runtimes = [
    { name: 'Swoole', baseUrl: 'http://localhost:8001', metric: swooleDuration },
    { name: 'PHP-FPM', baseUrl: 'http://localhost:8002', metric: phpfpmDuration },
    { name: 'FrankenPHP', baseUrl: 'http://localhost:8003', metric: frankenphpDuration },
];

export default function () {
    const results = [];

    // Test each endpoint on each runtime
    for (let endpoint of endpoints) {
        console.log(`🧪 Testing: ${endpoint.name}`);

        for (let runtime of runtimes) {
            const url = `${runtime.baseUrl}${endpoint.path}`;

            // Warm-up request
            http.get(url, { timeout: '10s' });
            sleep(0.1);

            // Actual test request
            const startTime = Date.now();
            const response = http.get(url, {
                timeout: '10s',
                tags: {
                    runtime: runtime.name,
                    endpoint: endpoint.name
                }
            });
            const duration = Date.now() - startTime;

            // Record metrics
            runtime.metric.add(duration);

            // Validate response
            const success = check(response, {
                [`${runtime.name} - ${endpoint.name} status 200`]: (r) => r.status === 200,
                [`${runtime.name} - ${endpoint.name} duration < 5s`]: (r) => r.timings.duration < 5000,
            });

            results.push({
                runtime: runtime.name,
                endpoint: endpoint.name,
                status: response.status,
                duration: duration,
                success: success
            });

            if (!success) {
                console.error(`❌ FAILED: ${runtime.name} ${endpoint.name} - Status: ${response.status}`);
            } else {
                console.log(`✅ OK: ${runtime.name} ${endpoint.name} - ${duration}ms`);
            }

            sleep(0.2); // Brief pause between runtime tests
        }

        sleep(0.5); // Brief pause between endpoints
    }
}

export function handleSummary(data) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');

    // Generate detailed comparison report
    const report = generateComparisonReport(data);

    return {
        [`results/k6-endpoint-comparison-${timestamp}.json`]: JSON.stringify(data, null, 2),
        [`results/k6-endpoint-comparison-${timestamp}.txt`]: report,
        stdout: report,
    };
}

function generateComparisonReport(data) {
    const report = [
        '📊 K6 Complete Endpoint Benchmark Report',
        '==========================================',
        '',
        '🏃‍♂️ Runtime Performance Comparison:',
        '',
    ];

    // Extract metrics for each runtime
    const swooleMean = data.metrics.swoole_duration?.values?.avg || 0;
    const phpfpmMean = data.metrics.phpfpm_duration?.values?.avg || 0;
    const frankenphpMean = data.metrics.frankenphp_duration?.values?.avg || 0;

    const swooleP95 = data.metrics.swoole_duration?.values?.['p(95)'] || 0;
    const phpfpmP95 = data.metrics.phpfpm_duration?.values?.['p(95)'] || 0;
    const frankenphpP95 = data.metrics.frankenphp_duration?.values?.['p(95)'] || 0;

    report.push('📈 Average Response Times:');
    report.push(`  • Swoole:     ${swooleMean.toFixed(2)}ms`);
    report.push(`  • PHP-FPM:    ${phpfpmMean.toFixed(2)}ms`);
    report.push(`  • FrankenPHP: ${frankenphpMean.toFixed(2)}ms`);
    report.push('');

    report.push('🎯 95th Percentile Times:');
    report.push(`  • Swoole:     ${swooleP95.toFixed(2)}ms`);
    report.push(`  • PHP-FPM:    ${phpfpmP95.toFixed(2)}ms`);
    report.push(`  • FrankenPHP: ${frankenphpP95.toFixed(2)}ms`);
    report.push('');

    // Determine winner
    const times = [
        { name: 'Swoole', time: swooleMean },
        { name: 'PHP-FPM', time: phpfpmMean },
        { name: 'FrankenPHP', time: frankenphpMean }
    ].sort((a, b) => a.time - b.time);

    report.push('🏆 Performance Ranking (Average):');
    times.forEach((runtime, index) => {
        const medal = index === 0 ? '🥇' : index === 1 ? '🥈' : '🥉';
        report.push(`  ${medal} ${runtime.name}: ${runtime.time.toFixed(2)}ms`);
    });

    report.push('');
    report.push(`📊 Total Endpoints Tested: ${endpoints.length}`);
    report.push(`⚡ Total Requests: ${data.metrics.http_reqs?.values?.count || 0}`);
    report.push(`❌ Failed Requests: ${(data.metrics.http_req_failed?.values?.rate * 100 || 0).toFixed(2)}%`);
    report.push('');
    report.push(`🕒 Test completed at: ${new Date().toLocaleString()}`);

    return report.join('\\n');
}