## Template: GameManager — Autoload/Singleton
## Godot 4
## Registrar em: Project Settings > Autoloads > game_manager.gd como "GameManager"

extends Node

# Signals
signal score_changed(new_score: int)
signal game_over
signal level_completed

# Estado global
var score: int = 0
var current_level: int = 1
var is_game_over: bool = false


func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)


func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	game_over.emit()


func complete_level() -> void:
	level_completed.emit()
	current_level += 1


func reset() -> void:
	score = 0
	current_level = 1
	is_game_over = false


func go_to_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)
