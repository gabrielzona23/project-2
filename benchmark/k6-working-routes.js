import http from 'k6/http';
import { check, group } from 'k6';
import { Rate } from 'k6/metrics';

// Configuração personalizada
export const options = {
    duration: '30s',
    vus: 10,
    thresholds: {
        http_req_duration: ['p(95)<500'],
        http_req_failed: ['rate<0.1'],
    },
};

// Métricas customizadas
const errorRate = new Rate('error_rate');

const runtimes = [
    { name: 'Swoole', baseUrl: 'http://localhost:8001' },
    { name: 'PHP-FPM', baseUrl: 'http://localhost:8002' },
    { name: 'FrankenPHP', baseUrl: 'http://localhost:8003' },
];

// Rotas que funcionam (confirmadas)
const workingRoutes = [
    '/',                    // Root funciona
    '/api/cache',          // Cache funciona
    '/api/static',         // Static funciona
];

export default function () {
    for (const runtime of runtimes) {
        group(`${runtime.name} - Working Routes`, () => {
            for (const route of workingRoutes) {
                const url = `${runtime.baseUrl}${route}`;

                const response = http.get(url, {
                    headers: {
                        'Accept': 'application/json',
                        'User-Agent': 'k6-benchmark'
                    },
                    timeout: '10s'
                });

                const isSuccess = check(response, {
                    'status is 200': (r) => r.status === 200,
                    'has response body': (r) => r.body && r.body.length > 0,
                    'response time < 1000ms': (r) => r.timings.duration < 1000,
                });

                errorRate.add(!isSuccess);

                if (!isSuccess) {
                    console.error(`FAILED: ${runtime.name} ${route} - Status: ${response.status}, Duration: ${Math.round(response.timings.duration)}ms`);
                }
            }
        });
    }
}

export function handleSummary(data) {
    const results = {
        summary: {
            total_requests: data.metrics.http_reqs.values.count,
            avg_duration: data.metrics.http_req_duration.values.avg,
            p95_duration: data.metrics.http_req_duration.values['p(95)'],
            max_duration: data.metrics.http_req_duration.values.max,
            error_rate: data.metrics.error_rate ? data.metrics.error_rate.values.rate : 0,
            requests_per_sec: data.metrics.http_reqs.values.rate,
            data_transferred: data.metrics.data_received.values.count
        },
        timestamp: new Date().toLocaleString(),
        test_type: 'Working Routes Only'
    };

    console.log(`
 📊 K6 Working Routes Benchmark Results
 =====================================
 
 🔥 Load Test Summary:
   • Total Requests: ${results.summary.total_requests}
   • Error Rate: ${(results.summary.error_rate * 100).toFixed(1)}%
   • Average Duration: ${results.summary.avg_duration.toFixed(2)}ms
   • 95th Percentile: ${results.summary.p95_duration.toFixed(2)}ms
   • Max Duration: ${results.summary.max_duration.toFixed(2)}ms
 
 📈 Request Rate:
   • Requests/sec: ${results.summary.requests_per_sec.toFixed(2)}
   • Data Transferred: ${(results.summary.data_transferred / 1024 / 1024).toFixed(2)} MB
 
 ⚡ Tested Routes: ${workingRoutes.length} working routes
 🏁 Test completed at: ${results.timestamp}
  `);

    return {
        'results/k6-working-routes-results.json': JSON.stringify(results, null, 2),
    };
}