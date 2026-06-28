## Template: Inimigo Top-Down 2D com Pathfinding
## Godot 4 — CharacterBody2D + NavigationAgent2D
## Copie para res://scenes/enemies/enemy.gd
## Adicione ao grupo "enemy" no inspetor (Node > Groups)
## Requer NavigationRegion2D configurado no mapa

class_name Enemy
extends CharacterBody2D

# Signals
signal died

# Constantes
const LAYER_ENEMY:  int = 1 << 2
const LAYER_WORLD:  int = 1 << 0
const LAYER_PLAYER: int = 1 << 1

# Exportadas
@export var speed: float        = 80.0
@export var max_health: int     = 30
@export var chase_range: float  = 300.0
@export var attack_range: float = 40.0
@export var attack_damage: int  = 10
@export var attack_cooldown: float = 1.0

# Privadas
var _health: int = max_health
var _target: Node2D = null
var _attack_timer: float = 0.0

@onready var nav_agent: NavigationAgent2D = %NavigationAgent2D


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = LAYER_ENEMY
	collision_mask  = LAYER_WORLD | LAYER_PLAYER
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_target = players[0]


func _physics_process(delta: float) -> void:
	_attack_timer = max(0.0, _attack_timer - delta)
	if _target == null:
		return

	var dist := global_position.distance_to(_target.global_position)

	if dist > chase_range:
		velocity = Vector2.ZERO
	elif dist <= attack_range:
		velocity = Vector2.ZERO
		_try_attack()
	else:
		nav_agent.target_position = _target.global_position
		var next := nav_agent.get_next_path_position()
		velocity = (next - global_position).normalized() * speed

	move_and_slide()


func take_damage(amount: int) -> void:
	_health -= amount
	if _health <= 0:
		died.emit()
		queue_free()


func _try_attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = attack_cooldown
	if _target.has_method("take_damage"):
		_target.take_damage(attack_damage)
