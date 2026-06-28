# Colisões Procedurais para Mapas Estáticos — Godot 4

Quando o mapa é uma imagem estática (não TileMap), as colisões de prédios, água e obstáculos precisam ser geradas via script com base em uma grade lógica definida separadamente.

---

## Conceito

A grade do mapa é definida em um arquivo de dados externo (JSON, CSV ou constante GDScript) que descreve o tipo de cada célula. O script de inicialização do mundo lê essa grade e instancia `StaticBody2D` na posição correta de cada célula que deve ter colisão.

```
Grade lógica (dados)  →  Script gera StaticBody2D  →  Cena do mundo
```

---

## Definindo a Grade

Crie um arquivo `res://resources/map_grid.gd` com a grade como constante:

```gdscript
# map_grid.gd
# Tipos de célula:
#   0 = calçada (livre)
#   1 = prédio  (bloqueia + dano)
#   2 = parque  (livre)
#   3 = água    (bloqueia + game over)

const CELL_SIZE: int = 64   # tamanho de cada célula em pixels (no mapa renderizado)
const COLS: int = 30
const ROWS: int = 20

const GRID: Array = [
    [1, 1, 0, 0, 0, 1, 1, ...],  # linha 0
    [1, 1, 0, 0, 0, 1, 1, ...],  # linha 1
    [0, 0, 0, 0, 0, 0, 0, ...],  # linha 2 (rua)
    # ...
]
```

> O `CELL_SIZE` deve corresponder ao tamanho real de cada célula no mapa renderizado (após aplicar o `scale` do `Sprite2D`).

---

## Gerando Colisões por Script (GDScript)

```gdscript
# world.gd
extends Node2D

const MapGrid = preload("res://resources/map_grid.gd")

# Layers de colisão
const LAYER_BUILDING: int = 1 << 2   # bit 3
const LAYER_WATER:    int = 1 << 4   # bit 5

@onready var buildings_node: Node2D = %Buildings
@onready var water_node: Node2D     = %Water


func _ready() -> void:
    _generate_collisions()


func _generate_collisions() -> void:
    for row in MapGrid.ROWS:
        for col in MapGrid.COLS:
            var cell_type: int = MapGrid.GRID[row][col]
            if cell_type == 0 or cell_type == 2:
                continue   # calçada e parque: sem colisão

            var pos := Vector2(
                col * MapGrid.CELL_SIZE + MapGrid.CELL_SIZE / 2.0,
                row * MapGrid.CELL_SIZE + MapGrid.CELL_SIZE / 2.0
            )

            match cell_type:
                1:   # prédio
                    _spawn_static_body(pos, "building", LAYER_BUILDING, buildings_node)
                3:   # água
                    _spawn_static_body(pos, "water", LAYER_WATER, water_node)


func _spawn_static_body(
    pos: Vector2,
    collision_type: String,
    layer: int,
    parent: Node2D
) -> void:
    var body := StaticBody2D.new()
    body.position = pos
    body.collision_layer = layer
    body.collision_mask  = 0   # estático: não precisa detectar nada
    body.set_meta("collision_type", collision_type)

    var shape := CollisionShape2D.new()
    var rect  := RectangleShape2D.new()
    rect.size = Vector2(MapGrid.CELL_SIZE, MapGrid.CELL_SIZE)
    shape.shape = rect
    body.add_child(shape)

    parent.add_child(body)
```

---

## Estrutura da Cena com Colisões Procedurais

```
World (Node2D — Y Sort Enabled = true)
├── MapSprite (Sprite2D)          ← imagem do mapa
├── Buildings (Node2D)            ← StaticBody2D de prédios (gerados por script)
├── Water (Node2D)                ← StaticBody2D de água (gerados por script)
├── Objects (Node2D)              ← objetos instanciados manualmente
├── Enemies (Node2D)
├── Player
└── CanvasLayer (layer=10)
    └── HUD
```

> Separar `Buildings` e `Water` em nós distintos facilita depuração e permite ocultar grupos no editor para visualizar o mapa.

---

## Calculando `CELL_SIZE` a partir do Mapa Real

Se o mapa é uma imagem de `3840×2160 px` renderizada com `scale = Vector2(0.5, 0.5)`:

- Tamanho renderizado: `1920×1080 px`
- Se a grade tem 30 colunas: `CELL_SIZE = 1920 / 30 = 64 px`

```gdscript
const MAP_RENDERED_WIDTH: int  = 1920
const COLS: int                = 30
const CELL_SIZE: int           = MAP_RENDERED_WIDTH / COLS   # = 64
```

---

## Geração via Script Python (pré-processamento)

Para mapas complexos, é mais prático gerar a grade a partir de uma imagem de máscara (onde cada cor representa um tipo de célula) usando Python:

```python
# generate_grid.py
from PIL import Image

CELL_SIZE = 64
img = Image.open("map_mask.png").convert("RGB")
w, h = img.size
cols = w // CELL_SIZE
rows = h // CELL_SIZE

# Mapeamento de cor → tipo
COLOR_MAP = {
    (200, 200, 200): 0,   # cinza = calçada
    (150, 100, 50):  1,   # marrom = prédio
    (100, 180, 100): 2,   # verde = parque
    (50, 100, 200):  3,   # azul = água
}

grid = []
for row in range(rows):
    line = []
    for col in range(cols):
        px = img.getpixel((col * CELL_SIZE + CELL_SIZE // 2,
                           row * CELL_SIZE + CELL_SIZE // 2))
        line.append(COLOR_MAP.get(px, 0))
    grid.append(line)

# Gerar arquivo GDScript
with open("map_grid.gd", "w") as f:
    f.write(f"const CELL_SIZE: int = {CELL_SIZE}\n")
    f.write(f"const COLS: int = {cols}\n")
    f.write(f"const ROWS: int = {rows}\n")
    f.write("const GRID: Array = [\n")
    for line in grid:
        f.write(f"    {line},\n")
    f.write("]\n")

print(f"Grade gerada: {cols}x{rows} células")
```

Execute com: `python3 generate_grid.py`

---

## Checklist de Colisões Procedurais

- [ ] `CELL_SIZE` calculado corretamente em relação ao mapa renderizado
- [ ] Grade (`GRID`) definida ou gerada a partir de máscara de cores
- [ ] `_generate_collisions()` chamado no `_ready()` do mundo
- [ ] Cada `StaticBody2D` com `collision_type` em metadata
- [ ] Nós organizadores (`Buildings`, `Water`) criados na cena
- [ ] Player com `collision_mask` cobrindo as layers de prédio e água
- [ ] Player lendo `get_meta("collision_type")` para diferenciar efeitos
