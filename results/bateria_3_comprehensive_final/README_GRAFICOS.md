# 📊 GRÁFICOS DA BATERIA 3 - COMPREHENSIVE LOAD TESTING

## 🎯 **VISÃO GERAL**

Este conjunto de 6 gráficos apresenta uma análise visual completa dos resultados da **Bateria 3**, que testou todos os 3 runtimes PHP (Swoole, PHP-FPM, FrankenPHP) com progressão de carga de 10 → 200 VUs durante 5.5 minutos.

---

## 📈 **GRÁFICOS GERADOS**

### 1️⃣ **`1_runtime_comparison.png`** - Comparação Geral de Performance

- **O que mostra:** Performance média geral de cada runtime
- **Métrica:** Taxa de sucesso média (requests < 2s)
- **Insights:**
  - 🥇 **Swoole: 98.2%** - Melhor performance geral
  - 🥈 **PHP-FPM: 96.5%** - Performance sólida e estável  
  - 🥉 **FrankenPHP: 84.1%** - Maior sensibilidade à carga

### 2️⃣ **`2_category_performance.png`** - Performance por Categoria de Operação

- **O que mostra:** Comparação detalhada por tipo de operação
- **Categorias:** Static, Cache, File, Database, CPU, Mixed, Memory, Runtime, Concurrent
- **Insights:**
  - **Static Content:** Melhor performance em todos os runtimes
  - **Concurrent Operations:** Maior desafio, especialmente para FrankenPHP
  - **Swoole:** Consistência superior em todas as categorias
  - **FrankenPHP:** Degradação uniforme (~15-20%) em todas as categorias

### 3️⃣ **`3_degradation_patterns.png`** - Degradação sob Alta Carga

- **O que mostra:** Quanto cada runtime degrada sob 200 VUs concorrentes
- **Linhas de referência:**
  
  - 🟠 5% = Limite Aceitável
  - 🔴 10% = Limite Crítico
- **Insights:**
  - **Swoole:** 2% degradação (excelente)
  - **PHP-FPM:** 5% degradação (aceitável)
  - **FrankenPHP:** 18% degradação (crítica)

### 4️⃣ **`4_throughput_metrics.png`** - Métricas Globais de Performance

- **O que mostra:** 4 métricas chave do teste completo
- **Métricas:**
  - **Throughput:** 57.8 req/s
  - **Tempo Médio:** 563ms
  - **P95:** 2.95s (95% das requests)
  - **Tempo Máximo:** 11.7s
- **Insights:** Performance geral sólida com alguns outliers sob alta carga

### 5️⃣ **`5_summary_dashboard.png`** - Dashboard de Resumo

- **O que mostra:** 4 visões em pizza para análise rápida
- **Componentes:**
  - **Performance por Runtime:** Distribuição equilibrada de requests
  - **Taxa de Sucesso:** 100% sem erros
  - **Distribuição por Categoria:** Cobertura balanceada de operações
  - **Tempos de Resposta:** Maioria < 500ms
- **Insights:** Teste abrangente e bem-sucedido

### 6️⃣ **`6_load_progression.png`** - Progressão de Carga

- **O que mostra:** Evolução da carga e throughput ao longo do tempo
- **Estágios:** 6 estágios progressivos (10→25→50→100→200→0 VUs)
- **Insights:**
  - **Scaling linear** até 100 VUs
  - **Plateau/degradação** a partir de 150 VUs
  - **Recovery suave** no stage final

---

## 🎓 **INSIGHTS ACADÊMICOS PRINCIPAIS**

### 🏆 **Performance Ranking:**

1. **Swoole** - Arquitetura async/event-loop superior
2. **PHP-FPM** - Process-based estável e previsível
3. **FrankenPHP** - Worker-based com limitações de concorrência

### 📊 **Padrões Identificados:**

- **I/O Operations** favorecem Swoole
- **CPU Operations** mostram menor diferencial
- **Concurrent Operations** amplificam diferenças arquiteturais
- **Memory Operations** evidenciam overhead de cada runtime

### ⚡ **Escalabilidade:**

- **Swoole:** Linear até 100 VUs, degradação mínima depois
- **PHP-FPM:** Estável até 150 VUs, plateau controlado
- **FrankenPHP:** Degradação iniciando em 100 VUs

---

## 📋 **DADOS TÉCNICOS**

| Métrica | Valor |
|---------|-------|
| **Total de Iterações** | 20,947 |
| **Duração do Teste** | 5 minutos 30 segundos |
| **Taxa de Erro** | 0.00% |
| **Requests/segundo** | 57.8 |
| **Dados Transferidos** | 9.2 MB recebidos |

---

## 🎯 **RECOMENDAÇÕES POR CENÁRIO**

### 🚀 **Alta Performance (Produção)**

✅ **Swoole** - Melhor throughput e menor latência

### 🏢 **Enterprise/Estabilidade**

✅ **PHP-FPM** - Balanceamento ideal performance/estabilidade

### 🔬 **Desenvolvimento/Prototipagem**

⚠️ **FrankenPHP** - Adequado para baixa/média carga

---

**📅 Gerado em:** 01/10/2025  
**🔬 Fonte:** K6 Comprehensive Load Testing - Bateria 3  
**📊 Amostras:** 20,947 iterações para análise estatística  
**🎓 Finalidade:** TCC - Análise Comparativa de Runtimes PHP
