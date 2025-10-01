import http from 'k6/http';
import { group, check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Métricas customizadas para TCC
const errorRate = new Rate('custom_error_rate');
const responseTimeByRuntime = new Trend('response_time_by_runtime');
const requestsPerRuntime = new Counter('requests_per_runtime');
const databaseErrors = new Rate('database_errors');
const cacheErrors = new Rate('cache_errors');

// Configuração dos runtimes para TCC
const RUNTIMES = {
    swoole: 'http://localhost:8001',
    phpfpm: 'http://localhost:8002',
    frankenphp: 'http://localhost:8003'
};

// Cenários de teste para TCC
export const options = {
    scenarios: {
        // Teste de carga baixa - 5 usuários por 2 minutos
        light_load: {
            executor: 'constant-vus',
            vus: 5,
            duration: '2m',
            tags: { test_type: 'light_load' },
        },

        // Teste de carga média - 15 usuários por 3 minutos
        medium_load: {
            executor: 'constant-vus',
            vus: 15,
            duration: '3m',
            startTime: '2m30s',
            tags: { test_type: 'medium_load' },
        },

        // Teste de carga alta - 30 usuários por 2 minutos
        heavy_load: {
            executor: 'constant-vus',
            vus: 30,
            duration: '2m',
            startTime: '6m',
            tags: { test_type: 'heavy_load' },
        },

        // Teste de pico - 50 usuários por 1 minuto
        spike_test: {
            executor: 'constant-vus',
            vus: 50,
            duration: '1m',
            startTime: '8m30s',
            tags: { test_type: 'spike_test' },
        },

        // Teste de stress - rampa de 1 até 60 usuários
        stress_test: {
            executor: 'ramping-vus',
            startVUs: 1,
            stages: [
                { duration: '1m', target: 20 },
                { duration: '2m', target: 40 },
                { duration: '1m', target: 60 },
                { duration: '1m', target: 10 },
            ],
            startTime: '10m',
            tags: { test_type: 'stress_test' },
        }
    },

    // Thresholds para TCC
    thresholds: {
        'http_req_duration': ['p(95)<500', 'p(99)<1000'],
        'http_req_failed': ['rate<0.05'],
        'custom_error_rate': ['rate<0.02'],
        'database_errors': ['rate<0.01'],
        'cache_errors': ['rate<0.01'],
        'http_reqs': ['rate>100'],
    },

    // Configurações globais
    userAgent: 'K6-TCC-Benchmark/1.0',
    insecureSkipTLSVerify: true,
    noConnectionReuse: false,
    maxRedirects: 5,
};

// Endpoints para teste abrangente do TCC
const ENDPOINTS = [
    // Endpoints básicos (peso alto para baseline)
    { path: '/api/', weight: 15, category: 'basic' },
    { path: '/api/health', weight: 15, category: 'basic' },
    { path: '/api/static', weight: 10, category: 'basic' },

    // Operações de banco de dados (peso médio-alto)
    { path: '/api/database', weight: 12, category: 'database' },
    { path: '/api/database/read', weight: 10, category: 'database' },
    { path: '/api/database/write', weight: 8, category: 'database' },
    { path: '/api/database/complex', weight: 6, category: 'database' },

    // Operações de cache (peso médio)
    { path: '/api/cache', weight: 8, category: 'cache' },
    { path: '/api/cache/read', weight: 8, category: 'cache' },
    { path: '/api/cache/write', weight: 6, category: 'cache' },

    // Operações de arquivo (peso baixo-médio)
    { path: '/api/file-read', weight: 5, category: 'file' },
    { path: '/api/file-write', weight: 4, category: 'file' },
    { path: '/api/file-operations', weight: 3, category: 'file' },

    // CPU intensivo (peso baixo mas importante)
    { path: '/api/cpu-intensive', weight: 4, category: 'cpu' },
    { path: '/api/memory-test', weight: 4, category: 'cpu' },

    // JSON operations (peso médio)
    { path: '/api/json-encode', weight: 6, category: 'json' },
    { path: '/api/json-decode', weight: 6, category: 'json' },

    // Testes de concorrência (peso baixo)
    { path: '/api/concurrent/light', weight: 3, category: 'concurrent' },
    { path: '/api/concurrent/medium', weight: 2, category: 'concurrent' },
    { path: '/api/concurrent/heavy', weight: 1, category: 'concurrent' },

    // Informações do runtime (peso baixo mas informativo)
    { path: '/api/runtime-info', weight: 2, category: 'info' },

    // Mixed workload (peso médio)
    { path: '/api/mixed-workload', weight: 5, category: 'mixed' },
];

// Função para selecionar endpoint baseado no peso
function selectWeightedEndpoint() {
    const totalWeight = ENDPOINTS.reduce((sum, ep) => sum + ep.weight, 0);
    let random = Math.random() * totalWeight;

    for (const endpoint of ENDPOINTS) {
        random -= endpoint.weight;
        if (random <= 0) {
            return endpoint;
        }
    }
    return ENDPOINTS[0];
}

// Função para selecionar runtime em round-robin
let runtimeIndex = 0;
function selectRuntime() {
    const runtimeKeys = Object.keys(RUNTIMES);
    const runtime = runtimeKeys[runtimeIndex % runtimeKeys.length];
    runtimeIndex++;
    return { name: runtime, url: RUNTIMES[runtime] };
}

// Função principal de teste
export default function () {
    const runtime = selectRuntime();
    const endpoint = selectWeightedEndpoint();
    const url = `${runtime.url}${endpoint.path}`;

    // Headers padrão para todos os testes
    const params = {
        headers: {
            'User-Agent': 'K6-TCC-Benchmark/1.0',
            'Accept': 'application/json',
            'Connection': 'keep-alive',
            'Runtime': runtime.name,
        },
        timeout: '30s',
        tags: {
            runtime: runtime.name,
            endpoint: endpoint.path,
            category: endpoint.category,
        }
    };

    // Execução da requisição com tratamento de erro
    const startTime = Date.now();
    const response = http.get(url, params);
    const endTime = Date.now();
    const duration = endTime - startTime;

    // Verificações abrangentes para TCC
    const checksResult = check(response, {
        'status é 200': (r) => r.status === 200,
        'resposta em JSON válido': (r) => {
            try {
                JSON.parse(r.body);
                return true;
            } catch (e) {
                return false;
            }
        },
        'tempo de resposta < 5s': (r) => r.timings.duration < 5000,
        'tamanho da resposta > 0': (r) => r.body.length > 0,
        'sem erro de conexão': (r) => r.status !== 0,
        'sem timeout': (r) => r.status !== 408,
        'sem erro do servidor': (r) => r.status < 500,
    });

    // Registrar métricas customizadas
    errorRate.add(!checksResult);
    requestsPerRuntime.add(1, { runtime: runtime.name });
    responseTimeByRuntime.add(response.timings.duration, { runtime: runtime.name });

    // Verificações específicas por categoria para TCC
    if (endpoint.category === 'database') {
        const dbCheck = check(response, {
            'database conectado': (r) => !r.body.includes('database') || !r.body.includes('error'),
        });
        databaseErrors.add(!dbCheck);
    }

    if (endpoint.category === 'cache') {
        const cacheCheck = check(response, {
            'cache funcionando': (r) => !r.body.includes('cache') || !r.body.includes('failed'),
        });
        cacheErrors.add(!cacheCheck);
    }

    // Log detalhado para análise do TCC
    if (response.status !== 200) {
        console.log(`❌ ERRO: ${runtime.name} - ${endpoint.path} - Status: ${response.status} - Tempo: ${duration}ms`);
    } else if (response.timings.duration > 1000) {
        console.log(`⚠️  LENTO: ${runtime.name} - ${endpoint.path} - Tempo: ${Math.round(response.timings.duration)}ms`);
    }

    // Pausa variável baseada no tipo de teste
    const scenario = __ENV.K6_SCENARIO_NAME || 'default';
    switch (scenario) {
        case 'light_load':
            sleep(Math.random() * 2 + 1); // 1-3s
            break;
        case 'medium_load':
            sleep(Math.random() * 1.5 + 0.5); // 0.5-2s
            break;
        case 'heavy_load':
            sleep(Math.random() * 1 + 0.2); // 0.2-1.2s
            break;
        case 'spike_test':
            sleep(Math.random() * 0.5 + 0.1); // 0.1-0.6s
            break;
        case 'stress_test':
            sleep(Math.random() * 0.3); // 0-0.3s
            break;
        default:
            sleep(Math.random() + 0.5); // 0.5-1.5s
    }
}

// Função de setup para TCC
export function setup() {
    console.log('🚀 Iniciando Benchmark Comparativo TCC');
    console.log('📊 Runtimes: Swoole, PHP-FPM, FrankenPHP');
    console.log('⏱️  Duração total: ~12 minutos');
    console.log('👥 Usuários: 5-60 (variável por cenário)');
    console.log(`📋 Endpoints: ${ENDPOINTS.length} endpoints diferentes`);

    // Verificar conectividade dos runtimes
    for (const [name, url] of Object.entries(RUNTIMES)) {
        const response = http.get(`${url}/api/health`, { timeout: '10s' });
        const status = response.status === 200 ? '✅' : '❌';
        console.log(`${status} ${name.toUpperCase()}: ${url} (Status: ${response.status})`);
    }

    return {
        startTime: new Date().toISOString(),
        runtimes: RUNTIMES,
        endpoints: ENDPOINTS.length
    };
}

// Função de teardown para TCC
export function teardown(data) {
    console.log('\n🏁 Benchmark TCC Finalizado!');
    console.log(`⏰ Iniciado em: ${data.startTime}`);
    console.log(`⏰ Finalizado em: ${new Date().toISOString()}`);
    console.log('📈 Resultados salvos para análise do TCC');
    console.log('🔍 Analise as métricas por runtime e categoria');
    console.log('\n📊 Métricas principais para TCC:');
    console.log('   - response_time_by_runtime: Tempo por runtime');
    console.log('   - requests_per_runtime: Distribuição de requests');
    console.log('   - custom_error_rate: Taxa de erro customizada');
    console.log('   - database_errors: Erros específicos de BD');
    console.log('   - cache_errors: Erros específicos de cache');
}

// Função para grupos de teste específicos do TCC
export function handleSummary(data) {
    const startTime = new Date(data.state.testRunDuration * 1000);

    // Relatório personalizado para TCC
    const report = {
        tcc_summary: {
            test_duration: `${Math.round(data.state.testRunDuration)}s`,
            total_requests: data.metrics.http_reqs.values.count,
            avg_response_time: `${Math.round(data.metrics.http_req_duration.values.avg)}ms`,
            p95_response_time: `${Math.round(data.metrics.http_req_duration.values['p(95)'])}ms`,
            p99_response_time: `${Math.round(data.metrics.http_req_duration.values['p(99)'])}ms`,
            max_response_time: `${Math.round(data.metrics.http_req_duration.values.max)}ms`,
            error_rate: `${(data.metrics.http_req_failed.values.rate * 100).toFixed(2)}%`,
            requests_per_second: Math.round(data.metrics.http_reqs.values.rate),
            data_received: `${(data.metrics.data_received.values.count / 1024 / 1024).toFixed(2)} MB`,
            data_sent: `${(data.metrics.data_sent.values.count / 1024 / 1024).toFixed(2)} MB`,
            scenarios_executed: Object.keys(data.metrics).filter(m => m.includes('scenario')).length,
            thresholds_passed: Object.values(data.thresholds).filter(t => t.ok).length,
            thresholds_failed: Object.values(data.thresholds).filter(t => !t.ok).length,
        },
        detailed_metrics: data.metrics,
        thresholds: data.thresholds
    };

    return {
        'results/k6-tcc-benchmark-summary.json': JSON.stringify(report, null, 2),
        'results/k6-tcc-benchmark-detailed.json': JSON.stringify(data, null, 2),
        'stdout': generateTCCReport(report)
    };
}

// Função para gerar relatório formatado para TCC
function generateTCCReport(summary) {
    const date = new Date().toLocaleString('pt-BR');

    return `
# 🎓 RELATÓRIO BENCHMARK TCC - COMPARATIVO DE RUNTIMES PHP
**Data:** ${date}
**Duração:** ${summary.tcc_summary.test_duration}
**Arquitetura:** Docker + Laravel + PostgreSQL + Redis

## 📊 RESULTADOS PRINCIPAIS

### 🏆 Performance Geral
- **Total de Requisições:** ${summary.tcc_summary.total_requests}
- **Taxa de Erro:** ${summary.tcc_summary.error_rate} ✅
- **Req/s Médio:** ${summary.tcc_summary.requests_per_second}
- **Tempo de Resposta Médio:** ${summary.tcc_summary.avg_response_time}

### ⚡ Latência Detalhada
- **P95:** ${summary.tcc_summary.p95_response_time}
- **P99:** ${summary.tcc_summary.p99_response_time}
- **Máximo:** ${summary.tcc_summary.max_response_time}

### 📈 Transferência de Dados
- **Dados Recebidos:** ${summary.tcc_summary.data_received}
- **Dados Enviados:** ${summary.tcc_summary.data_sent}

### 🎯 Thresholds TCC
- **✅ Aprovados:** ${summary.tcc_summary.thresholds_passed}
- **❌ Falharam:** ${summary.tcc_summary.thresholds_failed}

## 🔬 ANÁLISE POR RUNTIME
(Verifique as métricas detalhadas por runtime nos arquivos JSON)

### 📝 OBSERVAÇÕES PARA TCC
1. **Swoole (8001)**: Runtime assíncrono de alta performance
2. **PHP-FPM (8002)**: Runtime tradicional com Nginx
3. **FrankenPHP (8003)**: Runtime moderno baseado em Go

### 🎯 CONCLUSÕES TCC
- Teste executado com ${summary.tcc_summary.scenarios_executed} cenários diferentes
- Carga variável de 5 a 60 usuários virtuais
- ${ENDPOINTS.length} endpoints testados
- Metodologia consistente para comparação acadêmica

---
*Relatório gerado automaticamente para TCC*
*Sistema: Laravel + Docker + K6*
    `;
}