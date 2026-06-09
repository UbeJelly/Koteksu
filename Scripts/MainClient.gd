class_name MainClient extends Panel

@export var thumbnail_min_size := Vector2(160.0, 160.0)		## Images' min size on ImgBoard/Grid.
@export var print_image_files := true						## Prints the loaded image files.

var username: String = ""
var address: String = ""
var message: String = ""

var message_field_focus: bool = false
var color_picker_value: String = ""

var has_selected_text: bool = false
var selected_text: String = "": get = get_selected_text, set = set_selected_text

var main_path: String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)+"/Koteksu"
var img_save: String = main_path+"/ImgList"
var img_path: String = main_path+"/img"
var images: PackedStringArray = []

var scroll_v_size: int = 20

## INFO: Popup window 'ImgBoard'
@onready var window_pos: Vector2i = DisplayServer.window_get_position(get_window().get_window_id())
@onready var window_size: Vector2i = DisplayServer.window_get_size(get_window().get_window_id())

## INFO: Login nodes
@onready var client: HBoxContainer = %Client
@onready var host: Button = %Host
@onready var join: Button = %Join
@onready var username_field: LineEdit = %Username
@onready var address_field: LineEdit = %Address

## INFO: Chat nodes
@onready var message_field: LineEdit = %Message
@onready var send: Button = %Send
@onready var chatbox: RichTextLabel = %Chatbox

## INFO: Popup windows
@onready var imgboard: PopupPanel = %ImgBoard
@onready var imggrid: GridContainer = %Grid
@onready var emojiboard: PopupPanel = %EmojiBoard

## INFO: Groups
@onready var bbcoded: Array = get_tree().get_nodes_in_group("BBCoded")
@onready var emojis: Array = get_tree().get_nodes_in_group("Emojis")
@onready var tabs: Array = get_tree().get_nodes_in_group("Tabs")


func _ready() -> void:
	address = get_local_ip()
	address_field.text = address
	_init_directory(img_path)

	# Connect signals
	get_window().connect("files_dropped", Callable(self, "_on_files_dropped"))
	multiplayer.connect("connected_to_server", Callable(self, "_on_connected"))
	multiplayer.connect("peer_connected", Callable(self, "_on_peer_connected"))
	for emoji in emojis:
		emoji.pressed.connect(_on_Emoji_btn_pressed.bind(emoji.text))

	for tab in tabs:
		var tabbar: TabBar = tab.get_tab_bar()
		tabbar.mouse_default_cursor_shape = CursorShape.CURSOR_POINTING_HAND

## Returns the local ip address of the machine.
func get_local_ip() -> String:
	var ip: String = ""
	for _address in IP.get_local_addresses():
		if "." in _address and not _address.begins_with("127.") and not _address.begins_with("169.254."):
			if _address.begins_with("192.168.") or _address.begins_with("10.") or (_address.begins_with("172.") and int(_address.split(".")[1]) >= 16 and int(_address.split(".")[1]) <= 31):
				ip = _address
				break
	return ip


## Initializes the directory for images.
## [param path] is the directory path to save and load images from.
func _init_directory(path: String = "") -> void:
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_absolute(path)


## Checks for a directory and the images it contains.
## [param path] is the directory path to check and load images from.
func check_images(path: String = "") -> void:
	var directory := DirAccess.open(path)
	if not directory == null:
		# First list all images from directory into an array.
		# Then compare the save file and images' contents.
		# If they're different then overwrite the save file
		# before loading the images.
		images = directory.get_files()
		
		if FileAccess.open(img_save, FileAccess.READ) == null:
			save_images(images)
		else:
			if images == load_images(img_save):
				pass
			else:
				if not imggrid.get_children() == null:
					for i in imggrid.get_children():
						i.queue_free()
				save_images(images)
				images = load_images(img_save)

		for img_file in load_images(img_save):
			if print_image_files == true:
				print(img_file)

			var image = Image.load_from_file(img_path+"/"+img_file)
			var texture = ImageTexture.create_from_image(image)
			var thumbnail := TextureButton.new()

			thumbnail.texture_normal = texture
			thumbnail.name = img_file
			thumbnail.ignore_texture_size = true
			thumbnail.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
			thumbnail.custom_minimum_size = thumbnail_min_size
			thumbnail.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			imggrid.add_child(thumbnail, true)


## Saves an array of images into a file.
## [param image_array] is an array of image paths.
func save_images(image_array: PackedStringArray) -> void:
	var file := FileAccess.open(img_save, FileAccess.WRITE)
	file.store_var(image_array, true)
	file.close()


## Loads a save file of images array.
## [param save_file] is the path of the file to load the image array from.
func load_images(save_file: String) -> PackedStringArray:
	var file := FileAccess.open(save_file, FileAccess.READ)
	var loaded_array = file.get_var(true)
	return loaded_array


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
	chatbox.text += "[b]%s:[/b] %s\n" % [_username, _text]


@rpc("any_peer", "call_local", "unreliable") func _notify(_username: String = "") -> void:
	chatbox.text += "[color=gray]%s joined the chat[/color]\n" % _username


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
	check_images(img_path)
	window_pos = DisplayServer.window_get_position(get_window().get_window_id())
	window_size = DisplayServer.window_get_size(get_window().get_window_id())
	imgboard.popup(Rect2i(Vector2(window_pos.x - ((window_size.x / 2.0) + scroll_v_size), window_pos.y), Vector2(window_size.x / 2.0 + scroll_v_size, window_size.y)))


func _on_Thumbnail_pressed(texture_path: String) -> void:
	var data: Dictionary = { "path": texture_path, "width": str(thumbnail_min_size.x) }
	_message_rpc.rpc(username, "[img={width}]{path}[/img]\n".format(data))


func _on_Emoji_pressed() -> void:
	window_pos = DisplayServer.window_get_position(get_window().get_window_id())
	window_size = DisplayServer.window_get_size(get_window().get_window_id())
	emojiboard.popup(Rect2i(Vector2(window_pos.x - ((window_size.x / 2.0) + scroll_v_size), window_pos.y), Vector2(window_size.x / 2.0 + scroll_v_size, window_size.y)))


## TODO: Add the rest of the emojis
## TODO: Add their description on tooltips/hints
func _on_Emoji_btn_pressed(emoji: String) -> void:
	message_field.text += emoji


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		for textlabel in bbcoded:
			if not textlabel.name == "Chatbox":
				textlabel.process_mode = Node.PROCESS_MODE_DISABLED
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		for textlabel in bbcoded:
			if not textlabel.name == "Chatbox":
				textlabel.process_mode = Node.PROCESS_MODE_INHERIT
