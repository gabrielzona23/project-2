import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
    scenarios: {
        ping_test: {
            executor: 'constant-vus',
            vus: 50,
            duration: '30s',
        },
        cpu_test: {
            executor: 'ramping-vus',
            startVUs: 10,
            stages: [
                { duration: '30s', target: 50 },
                { duration: '60s', target: 50 },
                { duration: '30s', target: 0 },
            ],
        },
    },
    thresholds: {
        http_req_duration: ['p(95)<100'],
        http_req_failed: ['rate<0.1'],
    },
};

const BASE_URLS = {
    swoole: 'http://localhost:8001',
    frankenphp: 'http://localhost:8003',
};

export default function () {
    // Test Swoole
    let response = http.get(`${BASE_URLS.swoole}/api/ping`);
    check(response, {
        'Swoole ping status is 200': (r) => r.status === 200,
        'Swoole response time < 500ms': (r) => r.timings.duration < 500,
    });

    // Test FrankenPHP
    response = http.get(`${BASE_URLS.frankenphp}/api/ping`);
    check(response, {
        'FrankenPHP ping status is 200': (r) => r.status === 200,
        'FrankenPHP response time < 500ms': (r) => r.timings.duration < 500,
    });

    // Test CPU endpoint
    response = http.get(`${BASE_URLS.swoole}/api/cpu/1000`);
    check(response, {
        'CPU test status is 200': (r) => r.status === 200,
        'CPU test has result': (r) => r.json('result') !== undefined,
    });

    sleep(1);
}