# 🚀 Bateria 2 - Escalabilidade Progressiva em Execução

**Data:** 01/10/2025  
**Hora de Início:** 06:19  
**Status:** ✅ Em execução - Load testing progressivo  
**Duração Total:** 5.5 minutos (330 segundos)  

## 📊 Configuração da Bateria 2

### Estratégia de Teste

**Progressive Load Testing** - Aumento gradual de carga para análise de escalabilidade:

```text
Stage 1: 0→10 VUs   (60s) - Warm-up
Stage 2: 10→25 VUs  (60s) - Low load  
Stage 3: 25→50 VUs  (60s) - Medium load
Stage 4: 50→100 VUs (60s) - High load
Stage 5: 100→200 VUs (60s) - Stress test
Stage 6: 200→0 VUs  (30s) - Cool-down
```

### Endpoints Testados

- `/api/cache` - Teste de cache Redis (Read/Write)
- `/api/static` - Conteúdo estático (Performance baseline)

### Runtimes Comparados

- **Swoole** (Laravel Octane) - Port 8001
- **FrankenPHP** - Port 8003  
- **PHP-FPM + Nginx** - Port 8002

## 🎯 Objetivos Acadêmicos

### Hipóteses a Validar

1. **H1: Escalabilidade Linear**
   - "FrankenPHP mantém P95 latency mais estável que Swoole sob carga crescente"

2. **H2: Pontos de Saturação**
   - "Cada runtime tem um ponto específico onde performance degrada significativamente"

3. **H3: Eficiência de Recursos**
   - "Swoole usa menos memória por VU devido ao event-loop"

### Métricas de Interesse

#### Performance

- **P95 Latency vs VUs** - Curva de degradação
- **Throughput Saturation** - Ponto de saturação
- **Error Rate Growth** - Quando começam os erros

#### Recursos

- **Memory Usage Pattern** - Como cada runtime escala memória
- **CPU Efficiency** - Performance/CPU ratio
- **Connection Handling** - Overhead de conexões

## 📈 Resultados Esperados

### Por Runtime

#### Swoole (Event-Loop)

**Expectativas:**

- Menor uso de memória por VU
- Melhor performance em baixas cargas
- Possível degradação em cargas muito altas

#### FrankenPHP (Go-based)

**Expectativas:**

- Melhor escalabilidade geral
- P95 latency mais consistente
- Eficiência de CPU superior

#### PHP-FPM (Process-based)

**Expectativas:**

- Maior uso de memória (process per request)
- Performance mais previsível
- Melhor isolamento de erros

## 🔬 Valor Acadêmico

### Contribuições Científicas

1. **Caracterização Quantitativa**
   - Curvas de escalabilidade precisas para cada runtime
   - Identificação de breaking points baseada em dados

2. **Análise Comparativa Rigorosa**
   - Metodologia científica com stages controladas
   - Múltiplas métricas (latency, throughput, resources)

3. **Aplicabilidade Prática**
   - Recomendações baseadas em cenários de carga
   - Guidelines para escolha de runtime

### Diferencial do TCC

- **Primeira análise** sistemática de escalabilidade destes runtimes
- **Metodologia replicável** para futuras pesquisas
- **Dados quantitativos** para decisões arquiteturais

## 📊 Monitoramento em Tempo Real

### Status Atual

- ✅ Todos os runtimes saudáveis
- ✅ Progressive stages executando
- ✅ Monitoramento de recursos ativo
- ✅ Zero erros até o momento

### Próximos Passos

1. **Aguardar conclusão** (5.5 minutos total)
2. **Análise de dados** K6 output
3. **Correlação com recursos** Docker stats
4. **Geração de gráficos** comparativos
5. **Documentação acadêmica** dos findings

---

**🎓 Esta bateria representa o core técnico do TCC - dados de escalabilidade que permitirão conclusões científicas sólidas sobre arquiteturas PHP modernas!**
