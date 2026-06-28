## Template: Player Top-Down 2D
## Godot 4 — CharacterBody2D
## Copie para res://scenes/player/player.gd e ajuste conforme necessário

class_name Player
extends CharacterBody2D

# Signals
signal health_changed(new_health: int)
signal died

# Constantes
const SPEED: float = 150.0

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


func _physics_process(_delta: float) -> void:
	var direction := _get_input_direction()
	velocity = direction * SPEED
	move_and_slide()
	_update_animation(direction)


func take_damage(amount: int) -> void:
	health -= amount
	health_changed.emit(health)
	if health <= 0:
		_die()


# Privadas

func _get_input_direction() -> Vector2:
	# Teclado / gamepad
	var kb := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if kb != Vector2.ZERO:
		return kb
	# Touch (definido pelo VirtualJoystick via sinal)
	return _touch_direction


func _update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		animation_player.play("idle")
	else:
		animation_player.play("walk")
		# Virar sprite conforme direção horizontal
		if direction.x != 0:
			sprite.flip_h = direction.x < 0


func _die() -> void:
	died.emit()
	# Substitua pela lógica de morte do seu jogo
	queue_free()


# Conectar ao VirtualJoystick (se existir)
func _on_virtual_joystick_direction_changed(dir: Vector2) -> void:
	_touch_direction = dir
