## Template: Veículo Top-Down 2D
## Godot 4 — CharacterBody2D
## Copie para res://scenes/vehicles/vehicle.gd

class_name Vehicle
extends CharacterBody2D

# Signals
signal speed_changed(current_speed: float)

# Constantes
const LAYER_VEHICLE: int = 1 << 3   # bit 4
const LAYER_WORLD:   int = 1 << 0
const LAYER_PLAYER:  int = 1 << 1
const LAYER_ENEMY:   int = 1 << 2

# Exportadas — ajuste por tipo de veículo no inspetor
@export var max_speed: float     = 250.0
@export var acceleration: float  = 200.0
@export var friction: float      = 150.0
@export var steer_speed: float   = 2.5    # rad/s

# Privadas
var _speed: float = 0.0


func _ready() -> void:
	collision_layer = LAYER_VEHICLE
	collision_mask  = LAYER_WORLD | LAYER_PLAYER | LAYER_ENEMY | LAYER_VEHICLE


func _physics_process(delta: float) -> void:
	var throttle := Input.get_axis("ui_down", "ui_up")
	var steer    := Input.get_axis("ui_left", "ui_right")

	# Aceleração e frenagem com atrito
	if throttle != 0.0:
		_speed = move_toward(_speed, throttle * max_speed, acceleration * delta)
	else:
		_speed = move_toward(_speed, 0.0, friction * delta)

	# Esterçamento só quando em movimento
	if abs(_speed) > 10.0:
		rotation += steer * steer_speed * delta * sign(_speed)

	velocity = Vector2.UP.rotated(rotation) * _speed
	move_and_slide()

	speed_changed.emit(_speed)
