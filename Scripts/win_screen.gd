extends CanvasLayer

@onready var _score_label: Label = $VBoxContainer/ScoreLabel
@onready var _time_label: Label = $VBoxContainer/TimeLabel
@onready var _cells_label: Label = $VBoxContainer/CellsLabel

func setup(score: int, elapsed: float, cell_count: int) -> void:
	_score_label.text = "Score: %d" % score
	_time_label.text = "Time: %.2fs" % elapsed
	_cells_label.text = "Yeast cells: %d" % cell_count
	get_tree().paused = true
