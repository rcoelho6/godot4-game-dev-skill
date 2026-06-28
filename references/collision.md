# Sistema de Colisão — Godot 4

## Conceito: Layers e Masks

Todo corpo físico no Godot tem dois conjuntos de bits:

- **Layer (camada):** "Eu sou do tipo X"
- **Mask (máscara):** "Eu colido com objetos do tipo Y"

Um objeto só interage com outro se a **layer** de um estiver na **mask** do outro.

---

## Configuração das Layers

Acesse `Project Settings > Layer Names > 2D Physics` e nomeie as layers:

| Bit | Nome | Quem usa |
|---|---|---|
| 1 | `world` | Paredes, chão, obstáculos estáticos |
| 2 | `player` | Corpo do jogador |
| 3 | `enemy` | Corpo dos inimigos |
| 4 | `vehicle` | Corpo dos veículos |
| 5 | `projectile` | Projéteis, balas |
| 6 | `pickup` | Itens coletáveis (Area2D) |
| 7 | `trigger` | Zonas de evento (Area2D) |

---

## Tabela de Layer × Mask por Objeto

| Objeto | Layer | Mask (colide com) |
|---|---|---|
| Parede / obstáculo | `world` | *(nenhuma — estático)* |
| Personagem jogável | `player` | `world`, `enemy`, `vehicle`, `pickup`, `trigger` |
| Inimigo | `enemy` | `world`, `player`, `vehicle` |
| Veículo | `vehicle` | `world`, `player`, `enemy`, `vehicle` |
| Projétil do player | `projectile` | `world`, `enemy`, `vehicle` |
| Item coletável | `pickup` | *(Area2D — sem mask física)* |
| Zona de evento | `trigger` | *(Area2D — sem mask física)* |

---

## Configurando no Inspetor

Selecione o nó `CharacterBody2D` (ou `StaticBody2D`, `Area2D`) e no inspetor:

- **Collision > Layer:** marque a layer do objeto
- **Collision > Mask:** marque as layers com que ele deve colidir

Para `Area2D`, use as mesmas propriedades mas lembre que ela **não bloqueia** movimento — apenas detecta.

---

## Configurando por Script

```gdscript
# Definir layer e mask via código (útil para objetos criados dinamicamente)
# Cada bit corresponde a uma layer (bit 0 = layer 1, bit 1 = layer 2, etc.)

func _ready() -> void:
    collision_layer = 0b0000_0010   # layer 2 = player
    collision_mask  = 0b0100_1101   # mask: world(1) + enemy(3) + vehicle(4) + trigger(7)
```

Ou use as constantes para legibilidade:

```gdscript
const LAYER_WORLD:      int = 1 << 0   # bit 1
const LAYER_PLAYER:     int = 1 << 1   # bit 2
const LAYER_ENEMY:      int = 1 << 2   # bit 3
const LAYER_VEHICLE:    int = 1 << 3   # bit 4
const LAYER_PROJECTILE: int = 1 << 4   # bit 5
const LAYER_PICKUP:     int = 1 << 5   # bit 6
const LAYER_TRIGGER:    int = 1 << 6   # bit 7

func _ready() -> void:
    collision_layer = LAYER_PLAYER
    collision_mask  = LAYER_WORLD | LAYER_ENEMY | LAYER_VEHICLE | LAYER_TRIGGER
```

---

## Detectando Colisões

### CharacterBody2D (após move_and_slide)

```gdscript
func _physics_process(_delta: float) -> void:
    move_and_slide()
    for i in get_slide_collision_count():
        var col := get_slide_collision(i)
        var collider := col.get_collider()
        if collider.is_in_group("enemy"):
            take_damage(10)
```

### Area2D (via signals)

```gdscript
func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        # player entrou na zona
        pass
```

### RayCast2D (linha de visão, tiro)

```gdscript
@onready var ray: RayCast2D = %RayCast2D

func _physics_process(_delta: float) -> void:
    if ray.is_colliding():
        var hit := ray.get_collider()
        if hit.is_in_group("enemy"):
            hit.take_damage(25)
```

---

## Formas de Colisão por Objeto

| Objeto | Forma recomendada | Motivo |
|---|---|---|
| Personagem | `CapsuleShape2D` ou `CircleShape2D` | Desliza suavemente em cantos |
| Veículo | `RectangleShape2D` | Representa bem a caixa do veículo |
| Projétil | `CircleShape2D` pequeno | Rápido e preciso |
| Parede/tile | Definida no TileSet | Automática pelo editor |
| Item coletável | `CircleShape2D` levemente maior | Área de coleta generosa |

---

## Layers por Tipo de Superfície (jogos com áreas distintas)

A configuração padrão da skill usa `layer 1 = world` como obstáculo genérico. Quando o jogo precisa distinguir **tipos de superfície** (prédio, parque, água, calçada), reorganize as layers para que cada tipo tenha sua própria camada.

**Exemplo para jogo de cidade (GameDeli-style):**

| Bit | Nome | Comportamento no player |
|---|---|---|
| 1 | `sidewalk` | Livre passagem (chão normal) |
| 2 | `player` | Corpo do jogador |
| 3 | `building` | Bloqueia passagem, dano leve ao colidir |
| 4 | `park` | Livre passagem, efeito visual |
| 5 | `water` | Bloqueia passagem, game over |
| 6 | `pickup` | Item coletável (Area2D) |
| 7 | `trigger` | Zona de evento (Area2D) |

O player deve ter sua `collision_mask` ajustada para detectar cada tipo:

```gdscript
const LAYER_PLAYER:   int = 1 << 1
const LAYER_BUILDING: int = 1 << 2
const LAYER_WATER:    int = 1 << 4
const LAYER_PICKUP:   int = 1 << 5
const LAYER_TRIGGER:  int = 1 << 6

func _ready() -> void:
    collision_layer = LAYER_PLAYER
    collision_mask  = LAYER_BUILDING | LAYER_WATER | LAYER_PICKUP | LAYER_TRIGGER
```

> Superfícies por onde o player **passa livremente** (calçada, parque) não precisam estar na mask. Apenas o que **bloqueia** ou **dispara efeito** deve ser detectado.

---

## Dano por Tipo de Colisão com `get_meta`

Quando diferentes tipos de obstáculo causam efeitos distintos (dano leve em prédio, game over em água), use **metadata** nos nós de colisão para tipar o comportamento sem criar classes separadas.

### Configurando metadata no nó (editor ou script)

No inspetor do `StaticBody2D`, vá em **Node > Metadata** e adicione:
- Chave: `collision_type` | Tipo: `String` | Valor: `"building"` (ou `"water"`, `"park"`, etc.)

Ou via script ao gerar colisões proceduralmente:
```gdscript
var body := StaticBody2D.new()
body.set_meta("collision_type", "building")
```

### Lendo metadata no player

```gdscript
func _physics_process(_delta: float) -> void:
    move_and_slide()
    for i in get_slide_collision_count():
        var col      := get_slide_collision(i)
        var collider := col.get_collider()
        if not collider.has_meta("collision_type"):
            continue
        match collider.get_meta("collision_type"):
            "building":
                take_damage(5)       # dano leve
            "water":
                GameManager.trigger_game_over()  # game over
            "wall":
                pass                 # apenas bloqueia, sem efeito
```

> Esta abordagem é preferível a verificar `is_in_group()` para tipos de superfície porque metadata é uma propriedade do nó (não requer registro em grupos) e funciona bem com colisões geradas proceduralmente.

---

## Checklist de Colisão

- [ ] Layers nomeadas em Project Settings
- [ ] Cada objeto com Layer e Mask corretos no inspetor
- [ ] TileSet com physics layer configurada nos tiles de parede
- [ ] Area2D de pickups e triggers com signals conectados
- [ ] Grupos (`"player"`, `"enemy"`) atribuídos nos nós
