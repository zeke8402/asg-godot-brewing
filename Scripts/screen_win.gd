extends CanvasLayer

@onready var _score_label: Label = $ScoreLabel
@onready var _time_label: Label = $TimeLabel
@onready var _cells_label: Label = $CellsLabel

func setup(score: int, elapsed: float, cell_count: int) -> void:
	_score_label.text = "Score: %d" % score
	_time_label.text = "Time: %.2fs" % elapsed
	_cells_label.text = "Yeast cells: %d" % cell_count
	get_tree().paused = true

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_back_to_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/screen_start.tscn")
