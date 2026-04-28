class_name MainClient extends Panel

@onready var window_pos: Vector2i = DisplayServer.window_get_position(get_window().get_window_id())
@onready var window_size: Vector2i = DisplayServer.window_get_size(get_window().get_window_id())

@onready var client: HBoxContainer = %Client
@onready var host: Button = %Host
@onready var join: Button = %Join
@onready var send: Button = %Send
@onready var username_field: LineEdit = %Username
@onready var address_field: LineEdit = %Address
@onready var message_field: LineEdit = %Message
@onready var chatbox: RichTextLabel = %Chatbox
@onready var imgboard: PopupPanel = %ImgBoard
@onready var imggrid: GridContainer = %Grid

var username: String = ""
var address: String = ""
var message: String = ""

var message_field_focus: bool = false
var color_picker_value: String = ""

var has_selected_text: bool = false
var selected_text: String = "": get = get_selected_text, set = set_selected_text

var img_path: String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)+"/Koteksu/img"
var images: Array = []
var imgboard_resizing: bool = false

var scroll_v_size: int = 20


func _init_directory(path: String = "") -> void:
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_absolute(path)


func check_images(path: String = "") -> void:
	DirAccess.open(path)


func _ready() -> void:
	_init_directory(img_path)
	multiplayer.connect("connected_to_server", Callable(self, "_on_connected"))
	multiplayer.connect("peer_connected", Callable(self, "_on_peer_connected"))


func _joined() -> void:
	client.hide()
	username = username_field.text
	address = address_field.text
	_notify.rpc_id(multiplayer.get_unique_id(), username)


func _on_connected() -> void:
	_joined()


func _on_peer_connected(id: int) -> void:
	_notify.rpc_id(id, username)


@rpc("any_peer", "call_local", "unreliable") func _message_rpc(_username: String = "", _text: String = "") -> void:
	chatbox.text += "\n[b]%s:[/b] %s" % [_username, _text]


@rpc("any_peer", "call_local", "unreliable") func _notify(_username: String = "") -> void:
	chatbox.text += "\n[color=gray]%s joined the chat[/color]" % _username


func _on_Host_pressed() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_server(1029, 2)
	multiplayer.set_multiplayer_peer(peer)
	_joined()


func _on_Join_pressed() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_client(address_field.text, 1029)
	multiplayer.set_multiplayer_peer(peer)
	_joined()


func _on_Send_pressed() -> void:
	if not message_field.text.is_empty():
		if "[code]" in message_field.text:
			message_field.text = message_field.text.replace("[code]", "[bgcolor=#c8c8c8][code]")
			message_field.text = message_field.text.replace("[/code]", "[/code][/bgcolor]")
		if "[url]" in message_field.text:
			message_field.text = message_field.text.replace("[url]", "[color=#65b900][url]")
			message_field.text = message_field.text.replace("[/url]", "[/url][/color]")
	_message_rpc.rpc(username, message_field.text)
	message_field.text = ""


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
		if not get_selected_text().is_empty():
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
		message_field.text = _bbcode_formatter("[rainbow freq=1.0 sat=0.8 val=0.8 speed=1.0]%s[/rainbow]" % get_selected_text())
		has_selected_text = false
		selected_text = ""
	else:
		message_field.text += "[rainbow freq=1.0 sat=0.8 val=0.8 speed=1.0][/rainbow]"


func _on_URL_pressed() -> void:
	if has_selected_text == true:
		message_field.text = _bbcode_formatter("[url]%s[/url]" % get_selected_text())
		has_selected_text = false
		selected_text = ""
	else:
		message_field.text += "[url][/url]"


func _on_Chatbox_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)


func _on_Pulse_pressed() -> void:
	if has_selected_text == true:
		message_field.text = _bbcode_formatter("[pulse freq=1.0 color=#ffffff40 ease=-2.0]%s[/pulse]" % get_selected_text())
		has_selected_text = false
		selected_text = ""
	else:
		message_field.text += "[pulse freq=1.0 color=#ffffff40 ease=-2.0][/pulse]"


func _on_Image_pressed() -> void:
	window_pos = DisplayServer.window_get_position(get_window().get_window_id())
	window_size = DisplayServer.window_get_size(get_window().get_window_id())
	imgboard.popup(Rect2i(Vector2(window_pos.x - ((window_size.x / 2.0) + scroll_v_size), window_pos.y), Vector2(window_size.x / 2.0 + scroll_v_size, window_size.y)))
