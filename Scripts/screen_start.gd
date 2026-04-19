extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Music.play(preload("res://Assets/output.ogg"))

func _on_start_game_button_pressed() -> void:
	get_tree().paused = false
	Ethanol.level = 0.0
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_tutorial_button_pressed() -> void:
	pass # Replace with function body.


func _on_exit_game_button_pressed() -> void:
	get_tree().quit()
