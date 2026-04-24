extends LineEdit


@onready var main: Control = $"../../../../.."


func _input(event) -> void:
	if event.is_action_pressed("Enter"):
		main._message_rpc.rpc(main.username, main.message_field.text)
		main.message_field.text = ""

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			if has_selection():
				main.has_selected_text = true

				var start: int = get_selection_from_column()
				var end: int = get_selection_to_column()
				var length: int = 0
				var sub_string: String = ""

				length = start - end
				sub_string = text.substr(start, int(abs(length)))
				main.set_selected_text(sub_string)
