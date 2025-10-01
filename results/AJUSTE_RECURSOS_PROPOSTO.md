# 🔧 Ajustes Recomendados para Equidade de Recursos

## Análise da Configuração Atual

### ✅ **Pontos Positivos Identificados:**

1. **Configurações PHP idênticas** em todos os runtimes (512M memory_limit)
2. **Mesma base Alpine** para consistência de OS
3. **Recursos compartilhados** (PostgreSQL, Redis) únicos
4. **Hardware abundante** (12 cores, 19GB RAM)

### ⚠️ **Recomendação de Ajuste:**

Embora a configuração atual seja adequada, para **máximo rigor acadêmico**, sugiro adicionar limitações explícitas de recursos para garantir **absoluta equidade**.

## Ajuste Proposto no docker-compose.yml

```yaml
services:
  php-fpm:
    # ... configuração existente ...
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 512M

  swoole:
    # ... configuração existente ...
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 512M

  frankenphp:
    # ... configuração existente ...
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 512M
```

### Justificativa dos Limites

- **4 CPUs por container:** Permite paralelização mas evita monopolização
- **4GB RAM limite:** Generoso mas controlado (total 12GB para runtimes)
- **Reservas mínimas:** Garantem recursos básicos sempre disponíveis

## Verificação Pós-Ajuste

Após aplicar os ajustes, verificar com:

```bash
# Verificar limitações aplicadas
docker stats --no-stream

# Confirmar recursos por container
docker inspect <container_name> | grep -A 10 "Resources"
```