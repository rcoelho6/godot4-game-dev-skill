## Template: Player Top-Down 2D
## Godot 4 — CharacterBody2D
## Copie para res://scenes/player/player.gd
## Adicione ao grupo "player" no inspetor (Node > Groups)

class_name Player
extends CharacterBody2D

# Signals
signal health_changed(new_health: int)
signal died

# Constantes
const SPEED: float = 150.0

# Layers de colisão (devem bater com as configuradas no Project Settings)
const LAYER_PLAYER:  int = 1 << 1   # bit 2
const LAYER_WORLD:   int = 1 << 0   # bit 1
const LAYER_ENEMY:   int = 1 << 2   # bit 3
const LAYER_VEHICLE: int = 1 << 3   # bit 4
const LAYER_TRIGGER: int = 1 << 6   # bit 7

# Exportadas
@export var max_health: int = 100

# Públicas
var health: int = max_health

# Privadas
var _touch_direction: Vector2 = Vector2.ZERO

# Nodes
@onready var sprite: Sprite2D = %Sprite2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var camera: Camera2D = %Camera2D


func _ready() -> void:
	health = max_health
	add_to_group("player")
	collision_layer = LAYER_PLAYER
	collision_mask  = LAYER_WORLD | LAYER_ENEMY | LAYER_VEHICLE | LAYER_TRIGGER


func _physics_process(_delta: float) -> void:
	var direction := _get_input_direction()
	velocity = direction * SPEED
	move_and_slide()
	_update_animation(direction)
	_check_collisions()


func take_damage(amount: int) -> void:
	health -= amount
	health_changed.emit(health)
	if health <= 0:
		_die()


# Privadas

func _get_input_direction() -> Vector2:
	var kb := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if kb != Vector2.ZERO:
		return kb
	return _touch_direction


func _update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		animation_player.play("idle")
	else:
		animation_player.play("walk")
		if direction.x != 0:
			sprite.flip_h = direction.x < 0


func _check_collisions() -> void:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider.is_in_group("enemy"):
			take_damage(10)
		elif collider is RigidBody2D:
			# Empurrar objetos físicos soltos
			collider.apply_central_impulse(-col.get_normal() * 120.0)


func _die() -> void:
	died.emit()
	queue_free()


# Conectar ao VirtualJoystick (se existir)
func _on_virtual_joystick_direction_changed(dir: Vector2) -> void:
	_touch_direction = dir
