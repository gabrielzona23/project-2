import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
export let errorRate = new Rate('errors');

export let options = {
    stages: [
        { duration: '1m', target: 10 },   // Stage 1: Warm-up to 10 VUs
        { duration: '1m', target: 25 },   // Stage 2: Scale to 25 VUs  
        { duration: '1m', target: 50 },   // Stage 3: Scale to 50 VUs
        { duration: '1m', target: 100 },  // Stage 4: Scale to 100 VUs
        { duration: '1m', target: 200 },  // Stage 5: Stress test to 200 VUs
        { duration: '30s', target: 0 },   // Stage 6: Cool down
    ],
    thresholds: {
        'errors': ['rate<0.1'],
        'http_req_duration': ['p(95)<1000'],
        'http_req_failed': ['rate<0.05'],
    },
};

// Definir endpoints por categoria
const endpoints = {
    static: [
        '/api/static',
        '/api',
        '/api/health'
    ],
    database: [
        '/api/database',
        '/api/database/read',
        '/api/database/write',
        '/api/database/complex'
    ],
    cache: [
        '/api/cache',
        '/api/cache/read',
        '/api/cache/write'
    ],
    file: [
        '/api/file-read',
        '/api/file-write',
        '/api/file-operations'
    ],
    cpu: [
        '/api/cpu-intensive',
        '/api/json-encode',
        '/api/json-decode'
    ],
    memory: [
        '/api/memory-test'
    ],
    mixed: [
        '/api/mixed-workload',
        '/api/stress-test'
    ],
    concurrent: [
        '/api/concurrent/light',
        '/api/concurrent/medium',
        '/api/concurrent/heavy'
    ],
    runtime: [
        '/api/runtime-info'
    ]
};

const runtimes = [
    { name: 'swoole', port: 8001 },
    { name: 'php_fpm', port: 8002 },
    { name: 'frankenphp', port: 8003 }
];

export function setup() {
    console.log('🚀 Starting Bateria 3 - Comprehensive Load Testing with Resource Monitoring');
    console.log('📊 Test Strategy: Progressive load with ALL endpoints');
    console.log('🎯 Focus: Resource usage patterns across different workload types');
    console.log('📈 Monitoring: CPU, Memory, and Performance per endpoint category');

    // Health check for all runtimes
    for (let runtime of runtimes) {
        let response = http.get(`http://localhost:${runtime.port}/api/health`);
        if (response.status === 200) {
            console.log(`🔍 ${runtime.name}: ✅ Ready`);
        } else {
            console.log(`🔍 ${runtime.name}: ❌ Not ready (${response.status})`);
        }
    }
}

export default function () {
    // Escolher runtime randomico
    const runtime = runtimes[Math.floor(Math.random() * runtimes.length)];

    // Escolher categoria baseada na distribuição de carga
    const categories = Object.keys(endpoints);
    const weights = {
        static: 0.20,     // 20% - operações leves
        database: 0.15,   // 15% - operações de DB
        cache: 0.15,      // 15% - operações de cache
        file: 0.10,       // 10% - operações de arquivo
        cpu: 0.15,        // 15% - operações CPU intensivas
        memory: 0.05,     // 5% - testes de memória
        mixed: 0.10,      // 10% - workload misto
        concurrent: 0.05, // 5% - testes concorrentes
        runtime: 0.05     // 5% - info de runtime
    };

    // Escolher categoria com base nos pesos
    let random = Math.random();
    let cumulative = 0;
    let selectedCategory = 'static';

    for (let category of categories) {
        cumulative += weights[category] || 0;
        if (random <= cumulative) {
            selectedCategory = category;
            break;
        }
    }

    // Escolher endpoint específico da categoria
    const categoryEndpoints = endpoints[selectedCategory];
    const endpoint = categoryEndpoints[Math.floor(Math.random() * categoryEndpoints.length)];

    // Fazer requisição
    const url = `http://localhost:${runtime.port}${endpoint}`;
    const response = http.get(url, {
        tags: {
            runtime: runtime.name,
            category: selectedCategory,
            endpoint: endpoint
        }
    });

    // Verificações específicas por categoria
    const isSuccess = response.status === 200;
    const hasValidResponse = response.body && response.body.length > 0;
    const responseTime = response.timings.duration;

    check(response, {
        [`${runtime.name}:${selectedCategory} - Status 200`]: isSuccess,
        [`${runtime.name}:${selectedCategory} - Response time < 2s`]: responseTime < 2000,
        [`${runtime.name}:${selectedCategory} - Has content`]: hasValidResponse,
    });

    errorRate.add(!isSuccess);

    // Sleep proporcional à complexidade da categoria
    const sleepTimes = {
        static: 0.1,
        database: 0.5,
        cache: 0.2,
        file: 0.3,
        cpu: 0.8,
        memory: 0.6,
        mixed: 1.0,
        concurrent: 1.2,
        runtime: 0.1
    };

    sleep(sleepTimes[selectedCategory] || 0.5);
}

export function teardown() {
    console.log('📋 Bateria 3 Complete - Comprehensive Load Testing');
    console.log('📊 Data collected for academic analysis:');
    console.log('   - Resource usage patterns per endpoint category');
    console.log('   - Runtime performance comparison across workload types');
    console.log('   - Scalability behavior under mixed workloads');
    console.log('   - Performance degradation patterns by operation type');
}