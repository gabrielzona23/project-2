# Bateria 2 - Escalabilidade Progressiva

**Data:** Wed Oct  1 06:18:43 -05 2025  
**Duração:** 330 segundos (5.5 minutos)  
**Estratégia:** Load testing progressivo  
**Execução:** Docker K6 v1.3.0  

## 📊 Configuração do Teste

### Progressão de Carga

- **Estágio 1:** 10 VUs por 60s (warm-up)
- **Estágio 2:** 25 VUs por 60s  
- **Estágio 3:** 50 VUs por 60s
- **Estágio 4:** 100 VUs por 60s
- **Estágio 5:** 200 VUs por 60s (stress test)
- **Cool-down:** 0 VUs por 30s

### Endpoints Testados

- `/` - Página inicial
- `/api/cache` - Teste de cache Redis  
- `/api/static` - Conteúdo estático

### Runtimes Comparados

- **Swoole** (Laravel Octane) - Port 8001
- **FrankenPHP** - Port 8003
- **PHP-FPM + Nginx** - Port 8002

## 📁 Arquivos Gerados

- `k6_results.json` - Dados completos K6
- `k6_summary.json` - Resumo de métricas
- `k6_output.txt` - Log de execução
- `resource_monitoring.log` - Monitoramento de recursos
- `system_state_before.txt` - Estado inicial do sistema
- `system_state_after.txt` - Estado final do sistema

## 🎯 Objetivos de Análise

1. **Curvas de Escalabilidade** - P95 latency vs VUs
2. **Pontos de Saturação** - Onde cada runtime atinge limite
3. **Degradação de Performance** - Como performance diminui com carga
4. **Eficiência de Recursos** - CPU/Memory usage patterns
5. **Comparação de Estabilidade** - Variabilidade sob stress

## 📊 Próximos Passos

1. Análise detalhada dos dados JSON
2. Geração de gráficos comparativos
3. Identificação de breaking points
4. Correlação com uso de recursos
5. Documentação de findings acadêmicos

---

**Status:** ✅ Teste executado com sucesso  
**Dados:** Prontos para análise acadêmica
