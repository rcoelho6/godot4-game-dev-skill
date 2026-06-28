# Git para Projetos Godot 4

## .gitignore recomendado

```gitignore
# Godot 4 - gerado automaticamente, não versionar
.godot/

# Builds de exportação
*.apk
*.aab
*.ipa
*.exe
*.x86_64
*.dmg
*.pkg
export/

# Arquivos de sistema
.DS_Store
Thumbs.db
desktop.ini

# Editor de código
.vscode/
.idea/
*.swp
```

## O que DEVE ser versionado

- `project.godot` — configurações do projeto
- Todos os `.tscn` — cenas
- Todos os `.gd` — scripts
- Todos os `.tres` / `.res` — recursos
- Todos os `.import` — metadados de importação (necessários para rebuild consistente)
- Assets: sprites, sons, fontes (`/assets/`)

## Workflow de branches recomendado

```
main          → versão estável / releases
develop       → integração contínua
feature/xxx   → novas funcionalidades
fix/xxx       → correções de bugs
```

## Comandos úteis

```bash
# Inicializar repositório
git init
git add .
git commit -m "feat: setup inicial do projeto Godot 4"

# Nova feature
git checkout -b feature/sistema-de-combate
# ... trabalhar ...
git add .
git commit -m "feat: adiciona sistema de combate básico"
git checkout develop
git merge feature/sistema-de-combate

# Tag de versão
git tag -a v0.1.0 -m "Alpha: mecânicas básicas implementadas"
git push origin v0.1.0
```

## Mensagens de commit (padrão)

| Prefixo | Uso |
|---|---|
| `feat:` | Nova funcionalidade |
| `fix:` | Correção de bug |
| `scene:` | Alteração em cena .tscn |
| `asset:` | Adição/modificação de asset |
| `refactor:` | Refatoração sem mudança de comportamento |
| `export:` | Configuração de exportação |
