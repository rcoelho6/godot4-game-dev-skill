# Montagem de Mapa e Integração de Objetos — Godot 4

## Estrutura da Cena do Mapa

```
World (Node2D — Y Sort Enabled = true)
├── TileMapLayer_Ground      ← chão, calçadas (sem colisão)
├── TileMapLayer_Walls       ← paredes, obstáculos (com colisão)
├── TileMapLayer_Overlay     ← detalhes sobre o chão (sem colisão)
├── Objects (Node2D)         ← objetos instanciados
│   ├── Barrel               ← instância de res://scenes/objects/barrel.tscn
│   ├── Crate
│   └── Coin
├── Enemies (Node2D)         ← inimigos instanciados
│   └── Enemy_01
├── Player                   ← instância de res://scenes/player/player.tscn
├── NavigationRegion2D       ← região de navegação para pathfinding
└── CanvasLayer (layer=10)   ← HUD / UI
    └── HUD
```

> **Y Sort Enabled** no nó raiz garante que objetos mais ao sul (maior Y) sejam renderizados na frente dos objetos mais ao norte.

---

## Configurando o TileMap

### 1. Criar o TileSet

1. No FileSystem, clique com botão direito em `/assets/tilesets/` → New Resource → `TileSet`
2. Abra o TileSet e adicione a textura do tileset
3. Defina o tamanho do tile (ex: 32×32)
4. Na aba **Physics**, adicione uma Physics Layer (ex: Layer 1 = `world`)
5. Selecione os tiles que devem ter colisão e pinte a forma de colisão

### 2. Usar no TileMapLayer

1. Adicione um nó `TileMapLayer` na cena
2. Atribua o TileSet criado
3. Pinte o mapa no editor com as ferramentas de tile

### 3. Múltiplas Camadas

Use um `TileMapLayer` por camada visual:
- **Ground:** chão, sem colisão
- **Walls:** paredes e obstáculos, com colisão configurada no TileSet
- **Overlay:** detalhes decorativos acima do chão

---

## Instanciando Objetos no Mapa

Objetos são **cenas independentes** instanciadas como filhos do nó `Objects`.

### No editor (estático)

Arraste a cena do objeto (`.tscn`) para dentro do nó `Objects` na cena do mapa. Posicione com a ferramenta de mover.

### Por código (dinâmico)

```gdscript
# world.gd — script da cena do mapa
extends Node2D

@export var enemy_scene: PackedScene
@onready var enemies_node: Node2D = %Enemies

func spawn_enemy(pos: Vector2) -> void:
    var enemy := enemy_scene.instantiate()
    enemy.global_position = pos
    enemies_node.add_child(enemy)
```

---

## Limites do Mapa e Câmera

Defina os limites do mapa em pixels e passe para a câmera:

```gdscript
# world.gd
@onready var camera: Camera2D = %Camera2D

const MAP_WIDTH:  int = 3200   # largura total do mapa em pixels
const MAP_HEIGHT: int = 2400

func _ready() -> void:
    camera.limit_left   = 0
    camera.limit_top    = 0
    camera.limit_right  = MAP_WIDTH
    camera.limit_bottom = MAP_HEIGHT
```

---

## Integração entre Objetos e o Mapa

| Necessidade | Solução |
|---|---|
| Objeto sabe onde está no mapa | `global_position` do próprio nó |
| Objeto precisa spawnar outro | Emite signal → world.gd instancia |
| Objeto precisa do player | `get_tree().get_nodes_in_group("player")[0]` |
| Objeto some ao ser coletado | Emite signal `collected` → chama `queue_free()` |
| Objeto abre porta/evento | Emite signal → outro nó escuta e reage |

---

## NavigationRegion2D (Pathfinding)

Para inimigos com pathfinding:

1. Adicione `NavigationRegion2D` como filho do mapa
2. Desenhe o polígono de navegação cobrindo as áreas caminháveis
3. Clique em **Bake NavigationPolygon**
4. Cada inimigo deve ter um `NavigationAgent2D` como filho
5. O script do inimigo usa `NavigationAgent2D.target_position` (ver `physics.md`)

---

## Checklist de Montagem

- [ ] TileSet criado com physics layer configurada nos tiles de parede
- [ ] TileMapLayer_Walls com colisão ativa
- [ ] Y Sort habilitado no nó raiz
- [ ] Objetos instanciados como filhos de nós organizadores (`Objects`, `Enemies`)
- [ ] Limites do mapa definidos na câmera
- [ ] NavigationRegion2D baked (se usar pathfinding)
- [ ] Player adicionado ao grupo `"player"`
