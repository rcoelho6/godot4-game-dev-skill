---
name: godot4-game-dev
description: "Desenvolvimento de jogos 2D com Godot Engine 4 e GDScript. Use para criar projetos Godot 4, implementar mecânicas 2D com câmera cenital (top-down), estruturar cenas e scripts GDScript, exportar para PC/Android/iOS, e aplicar boas práticas de organização de projeto."
---

# Godot 4 Game Dev

## Configuração do Projeto

### Estrutura de diretórios recomendada

```
project.godot
/assets/         → sprites, sons, fontes
/scenes/         → cenas .tscn organizadas por contexto (player/, ui/, enemies/, world/)
/scripts/        → scripts .gd reutilizáveis
/autoloads/      → singletons (GameManager.gd, AudioManager.gd)
/resources/      → recursos .tres/.res (itens, configurações)
```

### project.godot essencial (2D top-down)

- **Renderer:** Forward+ ou Mobile (Mobile para melhor desempenho em Android/iOS)
- **Viewport:** 1280×720, stretch mode `canvas_items`, aspect `keep`
- **Física:** Layer names definidos em Project Settings > Layer Names > 2D Physics

## Câmera Cenital (Top-Down)

```gdscript
# Camera2D seguindo o player com suavização
extends Camera2D

@export var smoothing_speed: float = 5.0

func _process(delta: float) -> void:
    global_position = global_position.lerp(get_parent().global_position, smoothing_speed * delta)
```

Configurações recomendadas no Camera2D:
- `Position Smoothing > Enabled`: true (alternativa ao script acima)
- `Limit`: defina os limites do mapa para evitar câmera fora dos limites

## GDScript — Padrões

### Ordem de membros (obrigatória pelo style guide)

```gdscript
class_name NomeClasse
extends Node2D

# 1. Signals
signal morreu

# 2. Enums e constantes
enum Estado { IDLE, MOVENDO, ATACANDO }
const VELOCIDADE_MAX: float = 200.0

# 3. Variáveis exportadas
@export var vida: int = 100

# 4. Variáveis públicas
var estado_atual: Estado = Estado.IDLE

# 5. Variáveis privadas
var _velocidade: Vector2 = Vector2.ZERO

# 6. Nodes referenciados
@onready var sprite: Sprite2D = $Sprite2D
@onready var animacao: AnimationPlayer = $AnimationPlayer

# 7. Funções built-in
func _ready() -> void:
    pass

func _process(delta: float) -> void:
    pass

# 8. Funções públicas
func receber_dano(quantidade: int) -> void:
    vida -= quantidade
    if vida <= 0:
        morreu.emit()

# 9. Funções privadas
func _mover(delta: float) -> void:
    pass
```

### Regras importantes

- **Sempre usar tipagem estática** (`var x: float`, `func foo() -> void`)
- Usar `%NomeNode` (Scene Unique Names) em vez de `$Pai/Filho/Neto`
- Preferir signals para comunicação entre nós; evitar referências diretas entre cenas
- Autoloads apenas para dados verdadeiramente globais (pontuação, áudio, save)

## Nós Essenciais para Top-Down 2D

| Propósito | Nó recomendado |
|---|---|
| Personagem jogável | `CharacterBody2D` |
| Inimigos / NPCs | `CharacterBody2D` ou `RigidBody2D` |
| Cenário estático | `StaticBody2D` + `CollisionShape2D` |
| Tilemap | `TileMapLayer` (Godot 4.3+) ou `TileMap` |
| Câmera | `Camera2D` (filho do player) |
| Detecção de área | `Area2D` + `CollisionShape2D` |
| HUD / UI | `CanvasLayer` > `Control` |

## Movimento Top-Down (CharacterBody2D)

```gdscript
extends CharacterBody2D

const SPEED: float = 150.0

func _physics_process(delta: float) -> void:
    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    velocity = direction * SPEED
    move_and_slide()
```

Para mobile, substitua `Input.get_vector` por um joystick virtual (ver `references/mobile-input.md`).

## Versionamento com Git

- Adicionar ao `.gitignore`: `.godot/`, builds de exportação
- Commitar sempre: `project.godot`, todos os `.tscn`, `.gd`, `.tres`, `.import`
- Usar branches por feature: `feature/sistema-de-combate`, `feature/mapa-fase-1`
- Ver `references/git-godot.md` para o `.gitignore` completo recomendado

## Exportação Multiplataforma

Consulte `references/export-guide.md` para o passo a passo completo.

**Resumo rápido:**

| Plataforma | Requisito principal | Formato final |
|---|---|---|
| PC (Windows/Linux/macOS) | Export Templates instalados | `.exe` / binário |
| Android | OpenJDK 17 + Android SDK + keystore | `.apk` ou `.aab` |
| iOS | macOS + Xcode + Apple Developer account | Projeto Xcode |

> **Importante:** Use **GDScript** (não C#) para garantir suporte total a Android e iOS sem limitações experimentais.

## Boas Práticas Gerais

- Uma cena por entidade lógica (player, inimigo, item)
- Preferir `Resource` customizados para dados (stats de inimigos, itens) em vez de dicionários soltos
- Usar `PhysicsLayers` para separar colisões (player, inimigos, projéteis, mundo)
- Testar no mobile cedo — resolução e toque mudam o design
- Renderer **Mobile** no Project Settings reduz consumo de bateria em dispositivos móveis
