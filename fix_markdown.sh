#!/bin/bash

# Script para corrigir problemas comuns do markdownlint em todos os arquivos .md
# MD022: Headings should be surrounded by blank lines
# MD032: Lists should be surrounded by blank lines  
# MD031: Fenced code blocks should be surrounded by blank lines
# MD026: No trailing punctuation in heading
# MD047: Files should end with a single newline character

echo "🔧 Corrigindo problemas de markdownlint em arquivos .md..."

find . -name "*.md" -not -path "./node_modules/*" -not -path "./.git/*" | while read -r file; do
    echo "Processando: $file"
    
    # Backup do arquivo original
    cp "$file" "${file}.bak"
    
    # Processar o arquivo
    python3 << EOF
import re

with open('$file', 'r', encoding='utf-8') as f:
    content = f.read()

# MD047: Garantir que o arquivo termine com uma única nova linha
content = content.rstrip() + '\n'

# MD022: Adicionar linhas em branco ao redor de cabeçalhos
lines = content.split('\n')
new_lines = []
i = 0

while i < len(lines):
    line = lines[i]
    
    # Detectar cabeçalhos (começam com #)
    if line.strip().startswith('#') and line.strip() != '#':
        # Adicionar linha em branco antes (se não for o primeiro)
        if i > 0 and new_lines and new_lines[-1].strip() != '':
            new_lines.append('')
        
        # Adicionar o cabeçalho
        new_lines.append(line)
        
        # Adicionar linha em branco depois (se não for o último)
        if i + 1 < len(lines) and lines[i + 1].strip() != '':
            new_lines.append('')
    
    # MD032: Listas devem ser cercadas por linhas em branco
    elif line.strip().startswith(('-', '*', '+')) or re.match(r'^\s*\d+\.', line.strip()):
        # Adicionar linha em branco antes da lista (se necessário)
        if i > 0 and new_lines and new_lines[-1].strip() != '' and not new_lines[-1].strip().startswith(('-', '*', '+')) and not re.match(r'^\s*\d+\.', new_lines[-1].strip()):
            new_lines.append('')
        
        # Adicionar item da lista
        new_lines.append(line)
        
        # Verificar se próxima linha não é item de lista para adicionar linha em branco
        if (i + 1 < len(lines) and 
            lines[i + 1].strip() != '' and 
            not lines[i + 1].strip().startswith(('-', '*', '+')) and 
            not re.match(r'^\s*\d+\.', lines[i + 1].strip()) and
            not lines[i + 1].strip().startswith('#')):
            # Procurar o final da lista
            j = i + 1
            while (j < len(lines) and 
                   (lines[j].strip().startswith(('-', '*', '+')) or 
                    re.match(r'^\s*\d+\.', lines[j].strip()) or
                    lines[j].strip().startswith('  '))):  # Item de lista com indentação
                j += 1
            
            if j == i + 1:  # Próxima linha não é da lista
                new_lines.append('')
    
    # MD031: Blocos de código cercados devem ter linhas em branco
    elif line.strip().startswith('```'):
        # Adicionar linha em branco antes (se necessário)
        if i > 0 and new_lines and new_lines[-1].strip() != '':
            new_lines.append('')
        
        new_lines.append(line)
        
        # Encontrar o final do bloco de código
        i += 1
        while i < len(lines) and not lines[i].strip().startswith('```'):
            new_lines.append(lines[i])
            i += 1
        
        if i < len(lines):  # Adicionar a linha de fechamento
            new_lines.append(lines[i])
        
        # Adicionar linha em branco depois (se necessário)
        if i + 1 < len(lines) and lines[i + 1].strip() != '':
            new_lines.append('')
    
    else:
        new_lines.append(line)
    
    i += 1

# MD026: Remover pontuação no final dos cabeçalhos
final_lines = []
for line in new_lines:
    if line.strip().startswith('#'):
        # Remover : no final dos cabeçalhos
        line = re.sub(r':+$', '', line.rstrip()) + line[len(line.rstrip()):]
    final_lines.append(line)

# Escrever o arquivo corrigido
with open('$file', 'w', encoding='utf-8') as f:
    f.write('\n'.join(final_lines))

EOF
    
done

echo "✅ Correção concluída! Arquivos de backup criados com extensão .bak"