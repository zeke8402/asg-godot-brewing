extends CanvasLayer

func setup(elapsed: float) -> void:
	get_tree().paused = true

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/screen_start.tscn")
