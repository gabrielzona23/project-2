import http from 'k6/http';
import { group, check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Métricas customizadas para TCC
const errorRate = new Rate('custom_error_rate');
const responseTimeByRuntime = new Trend('response_time_by_runtime');
const requestsPerRuntime = new Counter('requests_per_runtime');
const throughputByRuntime = new Trend('throughput_by_runtime');

// Configuração dos runtimes para TCC
const RUNTIMES = {
    swoole: 'http://localhost:8001',
    phpfpm: 'http://localhost:8002',
    frankenphp: 'http://localhost:8003'
};

// Cenários de teste para TCC - Versão Estável
export const options = {
    scenarios: {
        // Teste de carga baixa - 5 usuários por 3 minutos
        light_load: {
            executor: 'constant-vus',
            vus: 5,
            duration: '3m',
            tags: { test_type: 'light_load' },
        },

        // Teste de carga média - 10 usuários por 3 minutos
        medium_load: {
            executor: 'constant-vus',
            vus: 10,
            duration: '3m',
            startTime: '3m30s',
            tags: { test_type: 'medium_load' },
        },

        // Teste de carga alta - 20 usuários por 2 minutos
        heavy_load: {
            executor: 'constant-vus',
            vus: 20,
            duration: '2m',
            startTime: '7m',
            tags: { test_type: 'heavy_load' },
        },

        // Teste de pico - 30 usuários por 1 minuto
        spike_test: {
            executor: 'constant-vus',
            vus: 30,
            duration: '1m',
            startTime: '9m30s',
            tags: { test_type: 'spike_test' },
        }
    },

    // Thresholds ajustados para TCC
    thresholds: {
        'http_req_duration': ['p(95)<800', 'p(99)<1500'],
        'http_req_failed': ['rate<0.10'],
        'custom_error_rate': ['rate<0.05'],
        'http_reqs': ['rate>50'],
    },

    // Configurações globais
    userAgent: 'K6-TCC-Benchmark-Stable/1.0',
    insecureSkipTLSVerify: true,
    noConnectionReuse: false,
    maxRedirects: 5,
};

// Endpoints estáveis para teste do TCC (evitando database endpoints problemáticos)
const ENDPOINTS = [
    // Endpoints básicos (peso alto - alta confiabilidade)
    { path: '/api/', weight: 25, category: 'basic' },
    { path: '/api/health', weight: 20, category: 'basic' },
    { path: '/api/static', weight: 20, category: 'basic' },

    // Operações de CPU e memória (peso médio-alto)
    { path: '/api/cpu-intensive', weight: 10, category: 'cpu' },
    { path: '/api/memory-test', weight: 8, category: 'cpu' },

    // JSON operations (peso médio)
    { path: '/api/json-encode', weight: 8, category: 'json' },
    { path: '/api/json-decode', weight: 8, category: 'json' },

    // Runtime info (peso baixo mas informativo)
    { path: '/api/runtime-info', weight: 1, category: 'info' },
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
            'User-Agent': 'K6-TCC-Benchmark-Stable/1.0',
            'Accept': 'application/json',
            'Connection': 'keep-alive',
            'Runtime': runtime.name,
        },
        timeout: '10s',
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

    // Verificações focadas para TCC
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
        'tempo de resposta < 10s': (r) => r.timings.duration < 10000,
        'tamanho da resposta > 0': (r) => r.body.length > 0,
        'sem erro de conexão': (r) => r.status !== 0,
        'sem timeout': (r) => r.status !== 408,
        'sem erro do servidor': (r) => r.status < 500,
    });

    // Registrar métricas customizadas
    errorRate.add(!checksResult);
    requestsPerRuntime.add(1, { runtime: runtime.name });
    responseTimeByRuntime.add(response.timings.duration, { runtime: runtime.name });
    throughputByRuntime.add(response.body.length, { runtime: runtime.name });

    // Log apenas para erros importantes
    if (response.status !== 200) {
        console.log(`❌ ERRO: ${runtime.name} - ${endpoint.path} - Status: ${response.status} - Tempo: ${duration}ms`);
    } else if (response.timings.duration > 2000) {
        console.log(`⚠️  LENTO: ${runtime.name} - ${endpoint.path} - Tempo: ${Math.round(response.timings.duration)}ms`);
    }

    // Pausa ajustada por tipo de teste
    const scenario = __ENV.K6_SCENARIO_NAME || 'default';
    switch (scenario) {
        case 'light_load':
            sleep(Math.random() * 1.5 + 1); // 1-2.5s
            break;
        case 'medium_load':
            sleep(Math.random() * 1 + 0.5); // 0.5-1.5s
            break;
        case 'heavy_load':
            sleep(Math.random() * 0.8 + 0.2); // 0.2-1s
            break;
        case 'spike_test':
            sleep(Math.random() * 0.4 + 0.1); // 0.1-0.5s
            break;
        default:
            sleep(Math.random() + 0.5); // 0.5-1.5s
    }
}

// Função de setup para TCC
export function setup() {
    console.log('🚀 Iniciando Benchmark TCC - Versão Estável');
    console.log('📊 Runtimes: Swoole, PHP-FPM, FrankenPHP');
    console.log('⏱️  Duração total: ~11 minutos');
    console.log('👥 Usuários: 5-30 (variável por cenário)');
    console.log(`📋 Endpoints: ${ENDPOINTS.length} endpoints estáveis`);
    console.log('🔍 Focando em endpoints confiáveis para comparação');

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
    console.log('🔍 Analise as métricas por runtime');
    console.log('\n📊 Métricas principais para TCC:');
    console.log('   - response_time_by_runtime: Tempo por runtime');
    console.log('   - requests_per_runtime: Distribuição de requests');
    console.log('   - throughput_by_runtime: Throughput por runtime');
    console.log('   - custom_error_rate: Taxa de erro geral');
}

// Função para relatório personalizado do TCC
export function handleSummary(data) {
    const runtime_metrics = {};

    // Extrair métricas por runtime
    if (data.metrics.response_time_by_runtime && data.metrics.response_time_by_runtime.values) {
        for (const [key, value] of Object.entries(data.metrics.response_time_by_runtime.values)) {
            if (key.includes('runtime:')) {
                const runtime = key.split('runtime:')[1];
                if (!runtime_metrics[runtime]) runtime_metrics[runtime] = {};
                runtime_metrics[runtime].response_time = value;
            }
        }
    }

    // Relatório personalizado para TCC
    const report = {
        tcc_summary: {
            test_duration: `${Math.round(data.state.testRunDuration)}s`,
            total_requests: data.metrics.http_reqs?.values?.count || 0,
            avg_response_time: `${Math.round(data.metrics.http_req_duration?.values?.avg || 0)}ms`,
            p95_response_time: `${Math.round(data.metrics.http_req_duration?.values?.['p(95)'] || 0)}ms`,
            p99_response_time: `${Math.round(data.metrics.http_req_duration?.values?.['p(99)'] || 0)}ms`,
            max_response_time: `${Math.round(data.metrics.http_req_duration?.values?.max || 0)}ms`,
            error_rate: `${((data.metrics.http_req_failed?.values?.rate || 0) * 100).toFixed(2)}%`,
            requests_per_second: Math.round(data.metrics.http_reqs?.values?.rate || 0),
            data_received: `${((data.metrics.data_received?.values?.count || 0) / 1024 / 1024).toFixed(2)} MB`,
            data_sent: `${((data.metrics.data_sent?.values?.count || 0) / 1024 / 1024).toFixed(2)} MB`,
            thresholds_passed: Object.values(data.thresholds || {}).filter(t => t.ok).length,
            thresholds_failed: Object.values(data.thresholds || {}).filter(t => !t.ok).length,
        },
        runtime_comparison: runtime_metrics,
        detailed_metrics: data.metrics,
        thresholds: data.thresholds
    };

    const tccReport = generateTCCReport(report);

    return {
        'results/k6-tcc-stable-benchmark-summary.json': JSON.stringify(report, null, 2),
        'results/k6-tcc-stable-benchmark-detailed.json': JSON.stringify(data, null, 2),
        'stdout': tccReport
    };
}

// Função para gerar relatório formatado para TCC
function generateTCCReport(summary) {
    const date = new Date().toLocaleString('pt-BR');

    return `
# 🎓 RELATÓRIO BENCHMARK TCC - COMPARATIVO ESTÁVEL DE RUNTIMES PHP
**Data:** ${date}
**Duração:** ${summary.tcc_summary.test_duration}
**Arquitetura:** Docker + Laravel + Endpoints Estáveis

## 📊 RESULTADOS PRINCIPAIS

### 🏆 Performance Geral
- **Total de Requisições:** ${summary.tcc_summary.total_requests}
- **Taxa de Erro:** ${summary.tcc_summary.error_rate}
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

## 🔬 COMPARAÇÃO ENTRE RUNTIMES

### 📝 METODOLOGIA TCC
1. **Swoole (8001)**: Runtime assíncrono de alta performance
2. **PHP-FPM (8002)**: Runtime tradicional com Nginx
3. **FrankenPHP (8003)**: Runtime moderno baseado em Go

### 🎯 ENDPOINTS TESTADOS
- APIs básicas (/, /health, /static)
- Operações CPU intensivas
- Processamento JSON
- Informações de runtime

### 📈 RESULTADOS POR CENÁRIO
- **Light Load (5 VUs):** Baseline de performance
- **Medium Load (10 VUs):** Carga moderada
- **Heavy Load (20 VUs):** Carga pesada
- **Spike Test (30 VUs):** Teste de pico

### 🚀 CONCLUSÕES TCC
- Teste focado em endpoints estáveis
- Comparação metodológica entre runtimes
- Dados confiáveis para análise acadêmica
- Métricas consistentes para TCC

---
*Relatório gerado automaticamente para TCC*
*Sistema: Laravel + Docker + K6 - Versão Estável*
*Endpoints testados: ${ENDPOINTS.length} endpoints confiáveis*
    `;
}