# 📊 Guia de Parâmetros de Benchmark - Explicação para Iniciantes

**Data:** 01/10/2025  
**Projeto:** TCC - Análise de Performance de Runtimes PHP  
**Público-alvo:** Pessoas sem conhecimento técnico em benchmarks  

## 🎯 O que é um Benchmark

Um benchmark é como um **teste de velocidade e resistência** para sistemas computacionais. Imagine que você quer testar qual carro é mais rápido: você faria vários carros correrem na mesma pista, nas mesmas condições, e mediria o tempo, consumo e performance.

Com sistemas web é a mesma coisa: testamos diferentes "motores" (runtimes) para ver qual responde mais rápido e aguenta mais carga.

## 📏 Parâmetros Principais Explicados

### 1. VUs (Virtual Users) - Usuários Virtuais

**O que é:** Simula quantas pessoas estão usando o sistema ao mesmo tempo.

**Analogia:** É como quantas pessoas estão tentando entrar numa loja simultaneamente.

**Exemplos práticos:**

- **1-10 VUs:** Site pessoal ou blog pequeno
- **50-100 VUs:** E-commerce médio em horário normal
- **500+ VUs:** Black Friday, site de notícias em breaking news
- **1000+ VUs:** Aplicações de grande escala (redes sociais)

**Importância:** Quanto mais VUs o sistema aguenta mantendo boa performance, melhor é sua capacidade de atender muitos usuários.

### 2. Latência (Response Time)

**O que é:** Tempo que o sistema demora para responder a uma requisição.

**Analogia:** É como o tempo entre você fazer um pedido no restaurante e receber a comida.

**Faixas de interpretação:**

- **0-50ms:** ⚡ Excelente - Usuário nem percebe demora
- **50-100ms:** ✅ Muito bom - Navegação fluida
- **100-300ms:** ⚠️ Aceitável - Perceptível mas tolerável
- **300-1000ms:** 🐌 Lento - Usuário fica impaciente
- **1000ms+:** ❌ Muito lento - Usuário pode desistir

**Por que importa:** Latência alta = usuários abandonam o site. Amazon descobriu que 100ms extras custam 1% das vendas.

### 3. Percentis (P90, P95, P99)

**O que são:** Mostram como o sistema se comporta nos **piores casos**.

**Analogia:** Se você medir a altura de 100 pessoas:

- **P50 (mediana):** Altura da pessoa no meio (50% são mais altas, 50% mais baixas)
- **P90:** 90% das pessoas são mais baixas que este valor
- **P95:** 95% das pessoas são mais baixas que este valor  
- **P99:** 99% das pessoas são mais baixas que este valor

**Em benchmarks:**

- **P50:** Experiência típica do usuário
- **P90:** 10% dos usuários têm experiência pior que isso
- **P95:** 5% dos usuários têm experiência pior que isso
- **P99:** 1% dos usuários têm experiência pior que isso

**Exemplo prático:**

```text
Latência P50: 20ms  - A maioria dos usuários espera 20ms
Latência P95: 100ms - 5% dos usuários esperam mais de 100ms
Latência P99: 500ms - 1% dos usuários esperam mais de 500ms
```

**Por que percentis altos importam:** Mesmo que a média seja boa, se P99 for muito alto, alguns usuários terão uma experiência terrível.

### 4. Throughput (Taxa de Transferência)

**O que é:** Quantidade de dados que o sistema consegue processar por segundo.

**Analogia:** É como a largura de um cano - quanto mais largo, mais água passa por segundo.

**Unidades comuns:**

- **KB/s:** Quilobytes por segundo (sites simples)
- **MB/s:** Megabytes por segundo (sites com imagens/vídeos)
- **GB/s:** Gigabytes por segundo (aplicações muito pesadas)

**Interpretação:**

- **Alto throughput:** Sistema consegue enviar muitos dados rapidamente
- **Baixo throughput:** Gargalo na transferência de dados

### 5. Requests/Second (RPS) - Requisições por Segundo

**O que é:** Quantas requisições o sistema consegue processar em 1 segundo.

**Analogia:** Quantos pedidos um garçom consegue anotar por minuto.

**Faixas típicas:**

- **1-100 RPS:** Aplicação pequena/média
- **100-1000 RPS:** Aplicação robusta
- **1000+ RPS:** Aplicação de alta performance
- **10000+ RPS:** Sistemas de grande escala

### 6. Taxa de Erro (Error Rate)

**O que é:** Porcentagem de requisições que falharam.

**Analogia:** De cada 100 pedidos no restaurante, quantos vieram errados.

**Interpretação:**

- **0%:** ✅ Perfeito - Nenhum erro
- **0.1-1%:** ✅ Muito bom - Poucos erros isolados
- **1-5%:** ⚠️ Aceitável - Alguns problemas
- **5%+:** ❌ Problemático - Muitos usuários afetados

## 🔍 Como Interpretar Resultados

### Cenário 1: E-commerce em Black Friday

```text
VUs: 1000
Latência P50: 150ms
Latência P95: 800ms
Latência P99: 2000ms
RPS: 2500
Taxa de Erro: 0.5%
```

**Interpretação:**

- ✅ **Bom:** Aguenta 1000 usuários simultâneos
- ⚠️ **Atenção:** P99 de 2s significa 1% dos usuários esperam muito
- ✅ **Bom:** Poucos erros (0.5%)
- **Recomendação:** Otimizar para reduzir P99

### Cenário 2: API Interna da Empresa

```text
VUs: 50
Latência P50: 10ms
Latência P95: 25ms
Latência P99: 50ms
RPS: 800
Taxa de Erro: 0%
```

**Interpretação:**

- ✅ **Excelente:** Latências muito baixas
- ✅ **Excelente:** Consistência alta (pouca diferença entre P50 e P99)
- ✅ **Perfeito:** Zero erros
- **Recomendação:** Performance ideal para uso interno

### Cenário 3: Sistema com Problemas

```text
VUs: 100
Latência P50: 500ms
Latência P95: 3000ms
Latência P99: 10000ms
RPS: 150
Taxa de Erro: 5%
```

**Interpretação:**

- ❌ **Ruim:** Latências muito altas
- ❌ **Crítico:** P99 de 10s é inaceitável
- ❌ **Problemático:** 5% de erro afeta muitos usuários
- **Recomendação:** Necessita otimização urgente

## 📊 Comparando Diferentes Sistemas

### Runtime A vs Runtime B

| Métrica | Runtime A | Runtime B | Vencedor |
|---------|-----------|-----------|----------|
| Latência P50 | 20ms | 30ms | A ✅ |
| Latência P95 | 100ms | 80ms | B ✅ |
| RPS | 1000 | 800 | A ✅ |
| Taxa de Erro | 0.1% | 0% | B ✅ |

**Análise:**

- **Runtime A:** Melhor performance média, mas menos consistente
- **Runtime B:** Performance um pouco menor, mas mais estável
- **Escolha depende:** Preferir velocidade (A) ou estabilidade (B)?

## 🎯 O que Cada Faixa de Resultado Indica

### Latência (Tempo de Resposta)

| Faixa | Categoria | Experiência do Usuário | Casos de Uso |
|-------|-----------|------------------------|--------------|
| 0-20ms | Instantâneo | Nem percebe demora | APIs internas, cache |
| 20-50ms | Muito rápido | Navegação fluida | Sites otimizados |
| 50-100ms | Rápido | Boa experiência | E-commerce normal |
| 100-300ms | Aceitável | Perceptível mas OK | Sites complexos |
| 300-1000ms | Lento | Usuário fica impaciente | Operações pesadas |
| 1000ms+ | Muito lento | Usuário pode desistir | Problemas sérios |

### Taxa de Requisições (RPS)

| Faixa | Categoria | Capacidade | Exemplos |
|-------|-----------|------------|----------|
| 1-50 | Baixa | Blog pessoal | WordPress simples |
| 50-200 | Média | Site empresarial | Portal corporativo |
| 200-1000 | Alta | E-commerce | Loja virtual média |
| 1000-5000 | Muito alta | Aplicação robusta | Rede social pequena |
| 5000+ | Extrema | Grande escala | Facebook, Google |

### Usuários Simultâneos (VUs)

| Faixa | Categoria | Cenário Real | Preparação Necessária |
|-------|-----------|--------------|----------------------|
| 1-10 | Desenvolvimento | Testes básicos | Ambiente local |
| 10-50 | Pequeno | Site pequeno | Servidor básico |
| 50-200 | Médio | E-commerce | Servidor dedicado |
| 200-1000 | Grande | Portal popular | Load balancer |
| 1000+ | Muito grande | Viral/trending | CDN, múltiplos servidores |

## 🚨 Sinais de Alerta nos Resultados

### ⚠️ Problemas de Performance

- **P99 > 10x P50:** Sistema instável
- **Taxa de erro > 1%:** Problemas sérios
- **RPS baixo com poucos VUs:** Gargalo no código
- **Latência crescendo com VUs:** Sistema não escala

### ✅ Sinais de Boa Performance

- **P99 < 3x P50:** Sistema consistente
- **Taxa de erro = 0%:** Sistema estável
- **RPS alto com muitos VUs:** Boa escalabilidade
- **Latência estável:** Performance previsível

## 🎓 Dicas para Apresentações

### Para Gestores

**Foque em:**

- Taxa de erro (diretamente impacta usuários)
- P95/P99 (experiência dos usuários insatisfeitos)
- Capacidade máxima (quantos usuários suporta)

### Para Desenvolvedores

**Foque em:**

- Latência média vs percentis altos
- Throughput vs utilização de recursos
- Pontos de gargalo específicos

### Para Usuários Finais

**Foque em:**

- "O site vai carregar rápido?"
- "Vai funcionar quando muita gente acessar?"
- "Vai dar erro?"

---

**📚 Glossário Rápido:**

- **VUs:** Usuários simultâneos
- **P50/P90/P95/P99:** Percentis de latência  
- **RPS:** Requisições por segundo
- **Latência:** Tempo de resposta
- **Throughput:** Dados transferidos por segundo
- **Taxa de erro:** Porcentagem de falhas

---

**🎯 Próximos Passos:** Use este guia para entender os resultados dos benchmarks e tomar decisões informadas sobre qual tecnologia escolher!

