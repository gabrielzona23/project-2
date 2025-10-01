# 📋 GUIA DE PADRÕES MARKDOWNLINT

Este documento define os padrões que devem ser seguidos em todos os arquivos Markdown do projeto para garantir compatibilidade com markdownlint.

## 🎯 Regras Principais

### 1. Cabeçalhos (MD022)

✅ **CORRETO:**

```markdown
## Título Principal

Conteúdo aqui...

### Subtítulo

Mais conteúdo...
```

❌ **INCORRETO:**

```markdown
## Título Principal
Conteúdo aqui...
### Subtítulo
Mais conteúdo...
```

### 2. Listas (MD032)

✅ **CORRETO:**

```markdown
Texto antes da lista.

- Item 1
- Item 2
- Item 3

Texto depois da lista.
```

❌ **INCORRETO:**

```markdown
Texto antes da lista.
- Item 1
- Item 2
- Item 3
Texto depois da lista.
```

### 3. Blocos de Código (MD031)

✅ **CORRETO:**

```markdown
Texto antes do código.

```bash
comando aqui
```

Texto depois do código.
```

❌ **INCORRETO:**

```markdown
Texto antes do código.
```bash
comando aqui
```
Texto depois do código.
```

### 4. Pontuação em Cabeçalhos (MD026)

✅ **CORRETO:**

```markdown
### Configuração do Sistema
```

❌ **INCORRETO:**

```markdown
### Configuração do Sistema:
```

### 5. Final do Arquivo (MD047)

✅ **CORRETO:**

- Arquivo deve terminar com uma única quebra de linha

❌ **INCORRETO:**

- Arquivo sem quebra de linha no final
- Arquivo com múltiplas quebras de linha no final

## 🔧 Ferramentas de Verificação

### Verificar erros em um arquivo específico

```bash
# Usando VS Code com extensão markdownlint
# Os erros aparecerão automaticamente no editor

# Usando make para verificar erros
make get-errors filePaths=["caminho/arquivo.md"]
```

### Estrutura Recomendada para Documentos

```markdown
# Título Principal

Breve descrição do documento.

## Seção Principal

### Subseção

Conteúdo com listas:

- Item 1
- Item 2
- Item 3

Código de exemplo:

```bash
comando exemplo
```

### Outra Subseção

Mais conteúdo...

## Conclusão

Texto final.

---

**Informações Adicionais:**
- Data: Setembro 2025
- Projeto: TCC
```

## 📊 Checklist para Novos Documentos

Antes de criar/editar um arquivo Markdown, verifique:

- [ ] Cabeçalhos têm linha em branco antes e depois
- [ ] Listas têm linha em branco antes e depois
- [ ] Blocos de código têm linha em branco antes e depois
- [ ] Cabeçalhos não terminam com pontuação (: ; . !)
- [ ] Arquivo termina com uma única quebra de linha
- [ ] Não há espaços em branco no final das linhas
- [ ] Não há cabeçalhos duplicados no mesmo nível

## 🚀 Exemplos Práticos

### Documento de Benchmark

```markdown
# Relatório de Benchmark - [Nome]

**Data:** [Data]
**Duração:** [Tempo]

## Resultados Principais

### Performance Geral

- **Requests:** 1,000
- **Latência:** 50ms
- **Taxa de Sucesso:** 100%

### Análise por Runtime

#### Swoole

Configuração:

```yaml
runtime: swoole
port: 8001
```

Resultados:

- Latência média: 35ms
- Throughput: 500 req/s

#### PHP-FPM

Configuração:

```yaml
runtime: php-fpm
port: 8002
```

Resultados:

- Latência média: 45ms
- Throughput: 400 req/s

## Conclusões

O benchmark demonstrou que...

---

**Projeto:** TCC - Análise de Runtimes PHP
**Status:** Concluído
```

### Documento de Setup

```markdown
# Guia de Instalação - [Componente]

Este documento explica como configurar...

## Pré-requisitos

- Docker instalado
- Make disponível
- Porta 8001-8003 livres

## Instalação

### 1. Clone o Repositório

```bash
git clone <repo>
cd projeto
```

### 2. Execute o Setup

```bash
make setup
```

### 3. Verifique a Instalação

```bash
make health
```

## Troubleshooting

### Erro de Porta

Se aparecer erro de porta ocupada:

```bash
make down
make up
```

### Erro de Permissão

Para corrigir permissões:

```bash
make fix-permissions
```

## Comandos Úteis

- `make status` - Verifica status
- `make logs` - Visualiza logs
- `make clean` - Limpa ambiente

---

**Última Atualização:** [Data]
**Versão:** 1.0
```

---

**📋 Este guia deve ser seguido para todos os novos arquivos Markdown**
**🔧 Use as ferramentas de verificação antes de commitar**
**✅ Mantenha a consistência em todo o projeto**
