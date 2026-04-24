class_name MainClient extends Panel


onready var client: HBoxContainer = $"Margin/Rows/Client"
onready var host: Button = $"Margin/Rows/Client/Host"
onready var join: Button = $"Margin/Rows/Client/Join"
onready var send: Button = $"Margin/Rows/Chat/User/Send"
onready var username_field: LineEdit = $"Margin/Rows/Client/Username"
onready var address_field: LineEdit = $"Margin/Rows/Client/Address"
onready var message_field: LineEdit = $"Margin/Rows/Chat/User/Message"
onready var chatbox: RichTextLabel = $"Margin/Rows/Chat/Chatbox"

var username: String = ""
var address: String = ""
var message: String = ""

var message_field_focus: bool = false
var color_picker_value: String = ""

var has_selected_text: bool = false
var selected_text: String = "" setget set_selected_text, get_selected_text


func _ready() -> void:
	get_tree().connect("connected_to_server", self, "_on_connected")
	get_tree().connect("network_peer_connected", self, "_on_peer_connected")


func _joined() -> void:
	client.hide()
	username = username_field.text
	address = address_field.text
	rpc_unreliable_id(get_tree().get_network_unique_id(), "_notify", username)


func _on_connected() -> void:
	_joined()


func _on_peer_connected(id: int) -> void:
	rpc_unreliable_id(id, "_notify", username)


remotesync func _message_rpc(_username: String = "", _text: String = "") -> void:
	chatbox.bbcode_text += "\n[b]%s:[/b] %s" % [_username, _text]
	message_field.text = ""


remotesync func _notify(_username: String = "") -> void:
	chatbox.bbcode_text += "\n[color=gray]%s joined the chat[/color]" % _username


func _on_Host_pressed() -> void:
	var peer: NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()
	peer.create_server(1029, 2)
	get_tree().set_network_peer(peer)
	_joined()


func _on_Join_pressed() -> void:
	var peer: NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()
	peer.create_client(address_field.text, 1029)
	get_tree().set_network_peer(peer)
	_joined()


func _on_Send_pressed() -> void:
	if not message_field.text.empty():
		rpc_unreliable("_message_rpc", username, message_field.text)


func _bbcode_formatter(bbcoded_string: String = "") -> String:
	return message_field.text.replace(get_selected_text(), bbcoded_string)


func set_selected_text(text: String = "") -> void:
	selected_text = text


func get_selected_text() -> String:
	return selected_text


func _on_Bold_pressed() -> void:
	if has_selected_text == true:
		message_field.text = _bbcode_formatter("[b]%s[/b]" % get_selected_text())
		has_selected_text = false
		selected_text = ""
	else:
		message_field.text += "[b][/b]"


func _on_Italic_pressed() -> void:
	if has_selected_text == true:
		message_field.text = _bbcode_formatter("[i]%s[/i]" % get_selected_text())
		has_selected_text = false
		selected_text = ""
	else:
		message_field.text += "[i][/i]"


func _on_Code_pressed() -> void:
	if has_selected_text == true:
		message_field.text = _bbcode_formatter("[code]%s[/code]" % get_selected_text())
		has_selected_text = false
		selected_text = ""
	else:
		message_field.text += "[code][/code]"


func _on_Underline_pressed() -> void:
	if has_selected_text == true:
		message_field.text = _bbcode_formatter("[u]%s[/u]" % get_selected_text())
		has_selected_text = false
		selected_text = ""
	else:
		message_field.text += "[u][/u]"


func _on_Strikethrough_pressed() -> void:
	if has_selected_text == true:
		message_field.text = _bbcode_formatter("[s]%s[/s]" % get_selected_text())
		has_selected_text = false
		selected_text = ""
	else:
		message_field.text += "[s][/s]"


func _on_Color_color_changed(color) -> void:
	color_picker_value = color.to_html(true)


func _on_Color_popup_closed() -> void:
	if has_selected_text == true:
		if not get_selected_text().empty():
			message_field.text = _bbcode_formatter("[color=#%s]%s[/color]" % [color_picker_value, get_selected_text()])
			has_selected_text = false
			selected_text = ""
	else:
		message_field.text += "[color=#%s][/color]" % color_picker_value


func _on_Wave_pressed() -> void:
	if has_selected_text == true:
		message_field.text = _bbcode_formatter("[wave amp=50 freq=2]%s[/wave]" % get_selected_text())
		has_selected_text = false
		selected_text = ""
	else:
		message_field.text += "[wave amp=50 freq=2][/wave]"


func _on_Tornado_pressed() -> void:
	if has_selected_text == true:
		message_field.text = _bbcode_formatter("[tornado radius=5 freq=2]%s[/tornado]" % get_selected_text())
		has_selected_text = false
		selected_text = ""
	else:
		message_field.text += "[tornado radius=5 freq=2][/tornado]"


func _on_Shake_pressed() -> void:
	if has_selected_text == true:
		message_field.text = _bbcode_formatter("[shake rate=5 level=10]%s[/shake]" % get_selected_text())
		has_selected_text = false
		selected_text = ""
	else:
		message_field.text += "[shake rate=5 level=10][/shake]"


func _on_Fade_pressed() -> void:
	if has_selected_text == true:
		message_field.text = _bbcode_formatter("[fade start=4 length=10]%s[/fade]" % get_selected_text())
		has_selected_text = false
		selected_text = ""
	else:
		message_field.text += "[fade start=4 length=10][/fade]"


func _on_Rainbow_pressed() -> void:
	if has_selected_text == true:
		message_field.text = _bbcode_formatter("[rainbow freq=1 sat=5 val=10]%s[/rainbow]" % get_selected_text())
		has_selected_text = false
		selected_text = ""
	else:
		message_field.text += "[rainbow freq=1 sat=5 val=10][/rainbow]"
