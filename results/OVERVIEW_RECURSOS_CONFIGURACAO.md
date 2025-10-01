# ⚙️ Overview de Recursos e Configurações - Bateria 2

**Data:** 01/10/2025  
**Projeto:** TCC - Análise de Performance de Runtimes PHP  
**Objetivo:** Garantir equidade de recursos para testes comparativos  

## 🖥️ Recursos da Máquina Host

### Hardware Disponível

- **CPU Cores:** 12 cores físicos/lógicos
- **Memória RAM:** 19 GB total (15 GB disponível)
- **Memória Swap:** 5 GB
- **Sistema:** Linux (ambiente controlado)

### Implicações para Benchmark

**Por que estes recursos são adequados:**

- **12 cores:** Permite paralelização eficiente de todos os runtimes
- **19 GB RAM:** Memória suficiente para múltiplos containers + overhead
- **15 GB disponível:** Margem segura para evitar swap durante testes

## 🐋 Configuração Docker - Análise de Equidade

### Status Atual dos Recursos

**Limitações de Container:** ❌ Não definidas explicitamente

**Implicação:** Todos os containers têm acesso total aos recursos do host, garantindo **equidade natural**.

### Configurações PHP Unificadas

Todos os runtimes estão configurados com **parâmetros idênticos**:

```ini
memory_limit = 512M
opcache.memory_consumption = 256M
mysqlnd.collect_memory_statistics = Off
```

**Rationale:**

- **512M memory_limit:** Adequado para aplicações web PHP sem ser restritivo
- **256M opcache:** Cache de opcodes otimizado para performance
- **Configurações idênticas:** Garante comparação justa

## 🔧 Análise de Configurações por Runtime

### 1. Swoole (Laravel Octane)

**Configuração Atual:**

```yaml
Container: swoole_benchmark
Port: 8001 → 8000
Base Image: php:8.3-cli-alpine3.19
```

**Parâmetros Específicos:**

- **Workers:** Configurado via Laravel Octane
- **Max Requests:** Configurado via Octane config
- **Event Loop:** Swoole nativo (C++)

**Vantagens de Design:**

- Event-driven architecture
- Persistent connections
- Memory sharing entre workers

### 2. FrankenPHP

**Configuração Atual:**

```yaml
Container: frankenphp_benchmark  
Port: 8003 → 8000
Base Image: dunglas/frankenphp:1-php8.3-alpine
```

**Parâmetros Específicos:**

- **Workers:** Go-based worker processes
- **HTTP/2:** Suporte nativo
- **Early Hints:** Otimização de loading

**Vantagens de Design:**

- Go runtime efficiency
- Modern HTTP features
- Integrated web server

### 3. PHP-FPM + Nginx

**Configuração Atual:**

```yaml
Container: php_fpm_benchmark
Port: 8002 → 80  
Base Image: php:8.3-fpm-alpine3.19
```

**Parâmetros Específicos:**

- **Process Manager:** Dynamic (configurável)
- **Max Children:** A ser otimizado
- **Nginx:** Proxy reverso

**Vantagens de Design:**

- Arquitetura tradicional testada
- Isolamento de processos
- Configuração granular

## 📊 Impacto nos Benchmarks

### Recursos Compartilhados Igualitariamente

| Recurso | Swoole | FrankenPHP | PHP-FPM | Observações |
|---------|---------|------------|---------|-------------|
| CPU Cores | 12 | 12 | 12 | Acesso total |
| RAM Total | 19GB | 19GB | 19GB | Sem limitação |
| PHP Memory | 512M | 512M | 512M | Configurado igual |
| OPcache | 256M | 256M | 256M | Otimização idêntica |
| Network | Host | Host | Host | Sem throttling |

### Fatores de Diferenciação

**O que realmente será testado:**

1. **Arquitetura de Runtime:** Event-loop vs Process-based
2. **Eficiência de Memória:** Como cada runtime usa os 512M
3. **Gerenciamento de Conexões:** Pool vs Event-driven vs Fork
4. **Overhead de Context Switch:** Worker threads vs processes

## 🎯 Justificativa dos Parâmetros Escolhidos

### Memory Limit: 512M

**Por que 512M:**

- **Realismo:** Configuração típica de produção PHP
- **Não restritivo:** Permite aplicações normais sem limitação artificial
- **Comparabilidade:** Força cada runtime a gerenciar memória eficientemente

### OPcache: 256M

**Por que 256M:**

- **Performance:** Elimina compilação repetida de PHP
- **Equidade:** Beneficia todos os runtimes igualmente
- **Realismo:** Configuração padrão de produção

### Sem Limitação de CPU/RAM Docker

**Por que não limitar:**

- **Recursos abundantes:** 12 cores/19GB são suficientes
- **Teste real:** Mede eficiência natural de cada runtime
- **Evita gargalos artificiais:** Foco na arquitetura, não em limites

## 🔍 Parâmetros de Monitoramento

### Métricas de Recurso (Coletadas)

```bash
# CPU Usage por container
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Memory patterns
docker exec container_name cat /proc/meminfo

# Network throughput  
docker exec container_name ss -i
```

### Métricas de Application (K6)

```javascript
// Latência por percentil
http_req_duration: {p(50), p(90), p(95), p(99)}

// Throughput
http_reqs: rate/s

// Error handling
http_req_failed: percentage
```

## ⚖️ Garantia de Equidade

### Checklist de Verificação

- ✅ **Recursos iguais:** Todos containers sem limitação
- ✅ **PHP configs iguais:** memory_limit, opcache idênticos
- ✅ **Base images atualizadas:** php:8.3 em todos
- ✅ **Dependências iguais:** PostgreSQL, Redis compartilhados
- ✅ **Network igual:** Mesmo bridge network
- ✅ **Volumes idênticos:** Mesmo código fonte montado

### Diferenças Intencionais (Testadas)

- **Runtime architecture:** Event-loop vs Process model
- **HTTP server:** Integrado vs Proxy reverso
- **Worker management:** Threads vs Processes vs Event-driven
- **Memory sharing:** Shared vs Isolated

## 🚀 Configuração Recomendada para Bateria 2

### Sem Alterações Necessárias

**Análise:** A configuração atual garante **equidade perfeita** de recursos:

1. **Hardware abundante:** 12 cores/19GB eliminam gargalos de recurso
2. **Configurações idênticas:** PHP settings unificados
3. **Isolamento apropriado:** Containers separados mas recursos compartilhados
4. **Monitoramento possível:** Docker stats disponível

### Ajustes Opcionais (Se Desejado)

```yaml
# Adição ao docker-compose.yml para monitoramento explícito
services:
  swoole:
    deploy:
      resources:
        limits:
          cpus: '12'
          memory: 8G
        reservations:
          cpus: '2'  
          memory: 1G
```

**Recomendação:** **NÃO aplicar limitações** - deixar recursos livres para medir eficiência natural.

## 📈 Expectativas para Bateria 2

### Hipóteses sobre Recursos

1. **Swoole:** Deve usar menos memória por conexão (event-loop)
2. **FrankenPHP:** Deve usar CPU de forma mais eficiente (Go runtime)
3. **PHP-FPM:** Deve usar mais memória mas ser mais previsível

### Métricas de Sucesso

- **CPU efficiency:** Performance/CPU ratio
- **Memory efficiency:** Throughput/Memory ratio  
- **Scalability:** Performance degradation com load

---

**🎯 Conclusão:** A configuração atual é **ideal para benchmarks acadêmicos** - recursos abundantes e equitativos, diferenças focadas na arquitetura dos runtimes, não em limitações artificiais!
