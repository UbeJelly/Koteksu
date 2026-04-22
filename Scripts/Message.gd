extends LineEdit


onready var main: Control = $"../../../../.."


func _input(event) -> void:
	if event.is_action_pressed("Enter"):
		main.rpc_unreliable("_message_rpc", main.username, main.message_field.text)
