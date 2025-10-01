# 🎓 TCC: Análise Comparativa de Runtimes PHP

Este projeto implementa um benchmark científico para comparação de performance entre diferentes runtimes PHP, desenvolvido como parte de um Trabalho de Conclusão de Curso (TCC).

## 🔬 Objetivo Acadêmico

Realizar uma análise quantitativa e qualitativa da performance de três arquiteturas distintas de processamento PHP:

- **Swoole** - Runtime assíncrono com event-driven I/O
- **FrankenPHP** - Runtime moderno baseado em Go com PHP embarcado
- **PHP-FPM** - Runtime tradicional com arquitetura process-based

## 🛠️ Stack Tecnológico

### 🐘 Backend & Framework

- **PHP:** 8.3 (Alpine Linux 3.19)
- **Laravel:** Framework moderno com suporte Octane
- **Laravel Octane:** Para Swoole e FrankenPHP performance

### 🗄️ Banco de Dados & Cache

- **PostgreSQL:** 17.2 (Primary database)
- **Redis:** 7.4 (Cache e sessões)

### 🚀 Runtimes PHP

- **Swoole:** Event-driven, non-blocking I/O (Porta 8001)
- **FrankenPHP:** Go-based, compiled binary (Porta 8003)  
- **PHP-FPM + Nginx:** Process-based, traditional (Porta 8002)

### 🐳 Infraestrutura

- **Docker & Docker Compose:** Containerização
- **Alpine Linux:** Base images otimizadas
- **Nginx:** Reverse proxy para PHP-FPM

### 📊 Ferramentas de Benchmark

- **K6:** Load testing JavaScript-based (ferramenta principal)
- **WRK:** HTTP benchmarking tool
- **Docker Stats:** Monitoramento de recursos

### 🔧 Automação

- **Makefile:** Comandos automatizados de build e deploy
- **Scripts K6:** Cenários de teste padronizados
- **Health Checks:** Monitoramento contínuo dos serviços

## 🚀 Configuração e Execução

### 📋 Pré-requisitos

- Docker & Docker Compose instalados
- Make (para comandos automatizados)
- Pelo menos 4GB RAM disponível
- Porta 8001, 8002, 8003, 5432, 6379 livres

### ⚡ Setup Rápido (Recomendado)

1. **Clone o repositório:**

   ```bash
   git clone <repository-url>
   cd project-2
   ```

2. **Setup completo automatizado:**

   ```bash
   make setup
   ```

   Este comando irá:
   - Construir todos os containers Docker
   - Inicializar PostgreSQL e Redis
   - Configurar Laravel em todos os runtimes
   - Popular banco de dados com dados de teste
   - Verificar saúde dos serviços

3. **Verificar status dos serviços:**

   ```bash
   make status
   ```

### 🔧 Comandos Disponíveis

#### Gerenciamento da Aplicação

```bash
make help           # Lista todos os comandos disponíveis
make build          # Constrói apenas os containers Docker
make up             # Inicia todos os serviços
make down           # Para todos os serviços
make clean          # Limpa dados temporários
make logs           # Visualiza logs de todos os containers
```

#### Monitoramento e Saúde

```bash
make health         # Verifica saúde detalhada dos serviços
make status         # Overview completo dos containers e serviços
make test-endpoints # Testa todos os endpoints de API
```

#### Configuração Individual

```bash
make setup-laravel    # Configura apenas Laravel (sem DB)
make setup-database   # Popula banco com init.sql
make fix-permissions  # Corrige permissões de storage
make clear-cache     # Limpa caches do Laravel
```

### 🎯 Verificação da Instalação

Após o setup, verifique se todos os serviços estão respondendo:

```bash
# Status geral
make health

# Teste específico dos endpoints
curl http://localhost:8001/api/health  # Swoole
curl http://localhost:8002/api/health  # PHP-FPM  
curl http://localhost:8003/api/health  # FrankenPHP
```

**Resposta esperada:** JSON com `{"status":"OK","database":"Connected","cache":"Connected"}`

## 📊 Execução de Benchmarks

### 🎯 Benchmark Completo TCC (Recomendado)

Execute o benchmark científico completo usado no TCC:

```bash
make benchmark-complete
```

Este comando executa:

- **4 cenários de carga:** Light (5 VUs), Medium (10 VUs), Heavy (20 VUs), Spike (30 VUs)
- **8 endpoints diferentes:** APIs básicas, CPU intensive, JSON operations
- **Distribuição equitativa:** Round-robin entre os 3 runtimes
- **Métricas detalhadas:** Latência, throughput, percentis

### ⚡ Benchmark Rápido

Para testes rápidos de performance:

```bash
make benchmark-quick
```

### 🔍 Benchmarks Individuais

#### 1. Usando K6 (Ferramenta Principal)

```bash
# Benchmark detalhado por endpoint
make benchmark

# Benchmark completo com todos os cenários
make benchmark-all
```

#### 2. Usando WRK (Testes Específicos)

**Swoole (Porta 8001):**

```bash
# Health check
wrk -t16 -c100 -d30s --latency http://localhost:8001/api/health

# Conteúdo estático  
wrk -t16 -c100 -d30s --latency http://localhost:8001/api/static

# Operações CPU intensivas
wrk -t16 -c100 -d30s --latency http://localhost:8001/api/cpu-intensive
```

**FrankenPHP (Porta 8003):**

```bash
# Health check
wrk -t16 -c100 -d30s --latency http://localhost:8003/api/health

# Conteúdo estático
wrk -t16 -c100 -d30s --latency http://localhost:8003/api/static

# Operações CPU intensivas  
wrk -t16 -c100 -d30s --latency http://localhost:8003/api/cpu-intensive
```

**PHP-FPM (Porta 8002):**

```bash
# Health check
wrk -t16 -c100 -d30s --latency http://localhost:8002/api/health

# Conteúdo estático
wrk -t16 -c100 -d30s --latency http://localhost:8002/api/static

# Operações CPU intensivas
wrk -t16 -c100 -d30s --latency http://localhost:8002/api/cpu-intensive
```

### 📋 Visualização de Resultados

```bash
# Mostrar resultados mais recentes
make results

# Listar todos os resultados
ls -la results/

# Ver relatório final do TCC
cat results/RELATORIO_FINAL_TCC_BENCHMARK.md
```

## 🎓 Endpoints de Teste

### 📍 APIs Básicas (65% do tráfego de teste)

- `GET /api/` - Endpoint root básico
- `GET /api/health` - Health check com validação DB/Cache
- `GET /api/static` - Resposta estática otimizada

### ⚙️ Processamento CPU (18% do tráfego)

- `GET /api/cpu-intensive` - Operações matemáticas pesadas
- `GET /api/memory-test` - Teste de alocação de memória

### 📄 Operações JSON (16% do tráfego)

- `GET /api/json-encode` - Encoding de JSON complexo
- `GET /api/json-decode` - Decoding de JSON estruturado

### ℹ️ Informações do Sistema (1% do tráfego)

- `GET /api/runtime-info` - Informações do runtime PHP

## 📈 Arquitetura dos Runtimes

### ⚡ Swoole (Laravel Octane)

- **Arquitetura:** Event-driven, non-blocking I/O
- **Vantagens:** Alta concorrência, persistent connections
- **Melhor para:** APIs complexas, operações assíncronas
- **Performance típica:** ~35ms tempo médio, 14K+ req/s

### 🦆 FrankenPHP (Laravel Octane)

- **Arquitetura:** Go-based compiled binary
- **Vantagens:** Baixo overhead, consistência superior
- **Melhor para:** Latência crítica, microservices
- **Performance típica:** ~37ms tempo médio, 13K+ req/s

### 🐘 PHP-FPM + Nginx

- **Arquitetura:** Process-based traditional
- **Vantagens:** Máxima estabilidade, compatibilidade
- **Melhor para:** Aplicações tradicionais, conteúdo estático
- **Performance típica:** ~39ms tempo médio, 24K+ req/s (estático)

## 🔧 Desenvolvimento e Debugging

### 📝 Logs e Monitoramento

```bash
# Logs de todos os serviços
make logs

# Logs específicos
docker-compose logs swoole
docker-compose logs php-fpm  
docker-compose logs frankenphp
docker-compose logs postgres
docker-compose logs redis
```

### 🛠️ Comandos de Manutenção

```bash
# Rebuild completo (após mudanças no código)
make rebuild

# Reset completo do ambiente
make clean && make setup

# Verificar problemas de permissão
make fix-permissions
```

### 🐳 Comandos Docker Diretos

```bash
# Acesso ao container
docker-compose exec swoole bash
docker-compose exec php-fpm bash
docker-compose exec frankenphp bash

# Executar comandos Laravel
docker-compose exec swoole php artisan route:list
docker-compose exec php-fpm php artisan config:cache
```

## 📊 Resultados de Performance

### 🏆 Resultados Atuais do TCC

- **Total de Requisições:** 6,652 requests
- **Taxa de Sucesso:** 100% (zero falhas)
- **Throughput Médio:** 11.18 req/s
- **Latência P95:** < 136ms
- **Distribuição Equitativa:** ~33.3% para cada runtime

### 📈 Performance por Runtime

| Runtime | Tempo Médio | Arquitetura | Melhor Uso |
|---------|-------------|-------------|------------|
| **Swoole** | 35ms | Assíncrona | APIs complexas |
| **FrankenPHP** | 37ms | Moderna | Latência baixa |
| **PHP-FPM** | 39ms | Tradicional | Estabilidade |

## 🎯 Metodologia Científica

### 🔬 Controles Experimentais

- **Hardware:** Docker padronizado
- **Software:** Mesmas versões em todos os runtimes
- **Network:** Localhost (sem latência externa)
- **Database:** PostgreSQL 17 compartilhado
- **Cache:** Redis 7 compartilhado

### 📏 Métricas Coletadas

- **Latência:** Min, Média, P95, P99, Max
- **Throughput:** Requests/segundo, Bytes/segundo  
- **Distribuição:** Percentis detalhados
- **Confiabilidade:** Taxa de erro, timeouts
- **Escalabilidade:** Performance sob diferentes cargas

### 🎲 Cenários de Teste

1. **Light Load:** 5 VUs x 3 minutos
2. **Medium Load:** 10 VUs x 3 minutos
3. **Heavy Load:** 20 VUs x 2 minutos
4. **Spike Test:** 30 VUs x 1 minuto

---

## 📚 Documentação Adicional

- **📊 Relatório Completo:** `results/RELATORIO_FINAL_TCC_BENCHMARK.md`
- **🔧 Relatório de Testes:** `RELATORIO_TESTES.md`
- **📋 Status do Projeto:** `STATUS_FINAL.md`
- **🎯 Guia Completo:** `results/GUIA_TCC_COMPLETO.md`

## 🤝 Contribuição

Este projeto foi desenvolvido para fins acadêmicos (TCC). Para contribuições:

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

---

**🎓 Desenvolvido para TCC - Análise Comparativa de Runtimes PHP**  
**📅 Data:** Setembro 2025  
**🔬 Metodologia:** Científica e reproduzível  
**📊 Status:** Benchmark completo executado com sucesso
