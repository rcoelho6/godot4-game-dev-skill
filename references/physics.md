# Física por Tipo de Objeto — Godot 4

Cada objeto tem seu próprio script de movimento. Nenhum script conhece o outro diretamente. Comunicação sempre via **signals**.

---

## Personagem Jogável

**Nó:** `CharacterBody2D`
**Movimento:** 8 direções, controlado por input

```gdscript
# character_movement.gd
# Anexar ao CharacterBody2D do personagem
extends CharacterBody2D

@export var speed: float = 150.0

func _physics_process(_delta: float) -> void:
    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    velocity = direction * speed
    move_and_slide()
```

Para mobile, `direction` vem do joystick virtual via sinal (ver `mobile-input.md`).

---

## Inimigo / NPC com Pathfinding

**Nó:** `CharacterBody2D`
**Movimento:** perseguição via `NavigationAgent2D`

```gdscript
# enemy_movement.gd
extends CharacterBody2D

@export var speed: float = 80.0
@export var chase_range: float = 300.0

@onready var nav_agent: NavigationAgent2D = %NavigationAgent2D
var _target: Node2D = null

func _ready() -> void:
    # Conectar ao player via grupo, sem referência direta
    await get_tree().process_frame
    var players := get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        _target = players[0]

func _physics_process(_delta: float) -> void:
    if _target == null:
        return
    var dist := global_position.distance_to(_target.global_position)
    if dist > chase_range:
        velocity = Vector2.ZERO
        move_and_slide()
        return
    nav_agent.target_position = _target.global_position
    var next := nav_agent.get_next_path_position()
    var direction := (next - global_position).normalized()
    velocity = direction * speed
    move_and_slide()
```

> Adicione o personagem ao grupo `"player"` no inspetor (Node > Groups).
> Adicione `NavigationAgent2D` como filho do inimigo e configure `NavigationRegion2D` no mapa.

---

## Veículo

**Nó:** `CharacterBody2D`
**Movimento:** aceleração, frenagem e esterçamento baseado em rotação

```gdscript
# vehicle_movement.gd
extends CharacterBody2D

@export var max_speed: float = 250.0
@export var acceleration: float = 200.0
@export var friction: float = 150.0
@export var steer_speed: float = 2.5   # radianos por segundo

var _speed: float = 0.0

func _physics_process(delta: float) -> void:
    var throttle := Input.get_axis("ui_down", "ui_up")   # frear / acelerar
    var steer    := Input.get_axis("ui_left", "ui_right") # virar

    # Aceleração e frenagem
    if throttle != 0.0:
        _speed = move_toward(_speed, throttle * max_speed, acceleration * delta)
    else:
        _speed = move_toward(_speed, 0.0, friction * delta)

    # Esterçamento proporcional à velocidade
    if abs(_speed) > 10.0:
        rotation += steer * steer_speed * delta * sign(_speed)

    velocity = Vector2.UP.rotated(rotation) * _speed
    move_and_slide()
```

---

## Objeto Estático (Parede, Obstáculo)

**Nó:** `StaticBody2D` + `CollisionShape2D`
**Movimento:** nenhum — apenas bloqueia passagem

Não precisa de script de movimento. Configure a collision shape no inspetor.

---

## Objeto Físico Solto (Barril, Caixote)

**Nó:** `RigidBody2D` + `CollisionShape2D`
**Movimento:** simulação automática pelo motor de física

```gdscript
# pushable_object.gd
extends RigidBody2D

# Pode ser empurrado por outros corpos
# Não precisa de lógica de movimento manual
# Ajuste Mass e PhysicsMaterial no inspetor
```

Para empurrar via código:
```gdscript
# No script do personagem, ao colidir:
for i in get_slide_collision_count():
    var col := get_slide_collision(i)
    if col.get_collider() is RigidBody2D:
        col.get_collider().apply_central_impulse(-col.get_normal() * 100.0)
```

---

## Zona / Gatilho (Area2D)

**Nó:** `Area2D` + `CollisionShape2D`
**Uso:** detectar entrada/saída de corpos sem bloquear passagem

```gdscript
# trigger_zone.gd
extends Area2D

signal player_entered
signal player_exited

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        player_entered.emit()

func _on_body_exited(body: Node2D) -> void:
    if body.is_in_group("player"):
        player_exited.emit()
```

---

## Resumo de Desacoplamento

| Princípio | Como aplicar |
|---|---|
| Cada objeto move a si mesmo | Script de movimento no próprio nó |
| Sem referências diretas entre cenas | Usar `get_tree().get_nodes_in_group()` ou signals |
| Input separado do movimento | Função `_get_input_direction()` isolada no script |
| Comunicação por eventos | Signals emitidos, outros nós escutam |
