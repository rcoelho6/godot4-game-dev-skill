---
name: godot4-game-dev
description: "Desenvolvimento de jogos 2D com Godot Engine 4 e GDScript. Use para criar projetos Godot 4, escolher tipo de jogo (top-down, plataforma, etc.), configurar view e assets, implementar física desacoplada por tipo de objeto, montar mapas com TileMap, definir sistema de colisão por layers, e exportar para PC/Android/iOS."
---

# Godot 4 Game Dev

## Passo 1 — Escolha o Tipo de Jogo

Antes de qualquer coisa, defina o tipo. Cada tipo tem configurações específicas de câmera, física e assets.

| Tipo | Câmera | Física | Referência |
|---|---|---|---|
| **Top-Down** | Cenital, segue o player | Sem gravidade, movimento 8 direções | `references/type-topdown.md` |
| **Plataforma** | Lateral, segue o player | Com gravidade, pulo | *(em breve)* |
| **Puzzle** | Fixa ou por sala | Estática ou cinemática | *(em breve)* |

Leia a referência do tipo escolhido antes de continuar.

---

## Passo 2 — Configuração do Projeto

### Estrutura de diretórios

```
project.godot
/assets/
  /sprites/      → personagens, objetos, veículos (PNG, spritesheet)
  /tilesets/     → tiles do mapa (PNG)
  /audio/        → sons e músicas
  /fonts/        → fontes .ttf
/scenes/
  /world/        → mapas e fases (.tscn)
  /player/       → cena do jogador
  /enemies/      → cenas de inimigos
  /vehicles/     → cenas de veículos
  /objects/      → itens, coletáveis, obstáculos
  /ui/           → HUD, menus
/scripts/        → scripts .gd reutilizáveis
/autoloads/      → GameManager.gd, AudioManager.gd
/resources/      → dados .tres/.res (stats, itens)
```

### Project Settings essenciais

- **Renderer:** `Mobile` (melhor para Android/iOS; funciona bem no PC)
- **Viewport:** `1280×720`, Stretch Mode `canvas_items`, Aspect `keep`
- **Gravity:** `Project Settings > Physics > 2D > Default Gravity` — defina `0` para top-down
- **Physics Layers:** configure em `Project Settings > Layer Names > 2D Physics` (ver `references/collision.md`)

---

## Passo 3 — View e Assets

Consulte `references/view-and-assets.md` para especificações completas de resolução, tamanho de sprites, tiles e organização de spritesheets.

**Resumo rápido:**

| Elemento | Tamanho recomendado | Formato |
|---|---|---|
| Tile do mapa | 16×16 ou 32×32 px | PNG |
| Personagem | 32×32 ou 48×48 px | PNG (spritesheet) |
| Veículo | 48×48 ou 64×64 px | PNG (spritesheet) |
| Objeto/item | 16×16 ou 32×32 px | PNG |
| UI / ícones | 32×32 px mínimo | PNG |

---

## Passo 4 — Física por Tipo de Objeto

Cada tipo de objeto usa um nó e um script de movimento **independente**. Nenhum objeto conhece o outro diretamente — comunicação via signals.

Consulte `references/physics.md` para scripts completos de cada tipo.

| Objeto | Nó Godot | Movimento |
|---|---|---|
| Personagem jogável | `CharacterBody2D` | Controlado por input |
| Inimigo / NPC | `CharacterBody2D` | Controlado por IA/Pathfinding |
| Veículo | `CharacterBody2D` | Aceleração, frenagem, esterçamento |
| Objeto estático | `StaticBody2D` | Imóvel |
| Objeto físico solto | `RigidBody2D` | Simulação física automática |
| Zona / gatilho | `Area2D` | Sem movimento, detecta entrada/saída |

---

## Passo 5 — Montagem do Mapa

Consulte `references/map-assembly.md` para o guia completo de TileMap, camadas e integração de objetos.

**Resumo:**
- Mapa base: `TileMapLayer` com tileset configurado
- Objetos colocados como cenas instanciadas sobre o mapa
- Câmera com `Limit` definido pelos limites do mapa

---

## Passo 6 — Sistema de Colisão

Consulte `references/collision.md` para a tabela completa de layers e configuração de cada objeto.

**Layers padrão recomendadas:**

| Layer | Nome | Quem usa |
|---|---|---|
| 1 | `world` | Paredes, chão, obstáculos estáticos |
| 2 | `player` | Corpo do jogador |
| 3 | `enemy` | Corpo dos inimigos |
| 4 | `vehicle` | Corpo dos veículos |
| 5 | `projectile` | Projéteis, balas |
| 6 | `pickup` | Itens coletáveis |
| 7 | `trigger` | Zonas de evento (Area2D) |

---

## GDScript — Padrões

Ordem obrigatória de membros em todo script:

```gdscript
class_name NomeClasse
extends Node2D

# 1. Signals
# 2. Enums / Constantes
# 3. @export
# 4. Variáveis públicas
# 5. Variáveis privadas (_prefixo)
# 6. @onready
# 7. _ready / _process / _physics_process
# 8. Funções públicas
# 9. Funções privadas (_prefixo)
```

Regras:
- **Sempre tipagem estática:** `var x: float`, `func foo() -> void`
- Usar `%NomeNode` (Scene Unique Names) em vez de caminhos longos
- Signals para comunicação entre cenas; nunca referência direta entre cenas distintas
- Autoloads apenas para estado verdadeiramente global

---

## Versionamento

- `.gitignore`: pasta `.godot/` e binários de exportação
- Versionar: `project.godot`, `.tscn`, `.gd`, `.tres`, `.import`, assets
- Ver `references/git-godot.md`

## Exportação

Ver `references/export-guide.md`. Use sempre **GDScript** para suporte total a Android e iOS.

| Plataforma | Requisito | Saída |
|---|---|---|
| PC | Export Templates | `.exe` / binário |
| Android | OpenJDK 17 + Android SDK | `.apk` / `.aab` |
| iOS | macOS + Xcode | Projeto Xcode |
