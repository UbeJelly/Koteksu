extends GridContainer


func _on_ImgBoard_size_changed() -> void:
	size.x = %ImgBoard.size.x + 20
	var img_width: float = 160.0
	var h_separate: int = get_theme_constant("h_separation")
	var new_columns = floor(size.x / (img_width + h_separate))
	columns = max(2, int(new_columns))
