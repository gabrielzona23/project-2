# 📊 Bateria 3 - Comprehensive Load Testing Results

**Data:** 01/10/2025  
**Horário:** 06:46:50  
**Duração:** 5.5 minutos  
**Status:** ✅ SUCESSO  

## 🎯 Estratégia Executada

### Progressive Load Testing com TODAS as rotas

**6 Stages:**
- Stage 1: 0→10 VUs (60s) - Warm-up
- Stage 2: 10→25 VUs (60s) - Low load  
- Stage 3: 25→50 VUs (60s) - Medium load
- Stage 4: 50→100 VUs (60s) - High load
- Stage 5: 100→200 VUs (60s) - Stress test
- Stage 6: 200→0 VUs (30s) - Cool-down

### Categorias de Endpoints Testadas

| Categoria | Peso | Endpoints |
|-----------|------|-----------|
| **Static** | 20% | /api, /api/static, /api/health |
| **Database** | 15% | /api/database/*, /api/database/read, write, complex |
| **Cache** | 15% | /api/cache/*, /api/cache/read, write |
| **File** | 10% | /api/file-read, /api/file-write, /api/file-operations |
| **CPU** | 15% | /api/cpu-intensive, /api/json-encode, /api/json-decode |
| **Memory** | 5% | /api/memory-test |
| **Mixed** | 10% | /api/mixed-workload, /api/stress-test |
| **Concurrent** | 5% | /api/concurrent/light, medium, heavy |
| **Runtime** | 5% | /api/runtime-info |

## 📁 Arquivos Gerados

- `k6-results.json` - Dados brutos do K6
- `k6-output.txt` - Log completo da execução
- `*_resources.log` - Logs de recursos por container
- `system_resources.log` - Recursos do sistema
- `RESOURCE_SUMMARY.md` - Resumo de recursos

## 📊 Análise de Recursos


## 🎓 Valor Acadêmico

Esta bateria coletou dados abrangentes sobre:

1. **Performance por tipo de operação** - Como cada runtime se comporta com diferentes workloads
2. **Padrões de uso de recursos** - CPU e memória correlacionados com carga e tipo de operação  
3. **Escalabilidade diferenciada** - Breaking points específicos por categoria de endpoint
4. **Eficiência operacional** - Relação performance/recursos para cada runtime

---

**🔬 Material científico completo para análise comparativa de runtimes PHP modernos!**
