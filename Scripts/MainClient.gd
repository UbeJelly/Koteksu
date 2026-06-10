class_name MainClient extends Panel

#region Variables
enum Role { HOST, CLIENT }

@export var thumbnail_min_size := Vector2(160.0, 160.0)		## Images' min size on ImgBoard/Grid.
@export var hover_tabbar := false							## If TabBars are 'hoverable' and tween animated
@export_category("Terminal")
@export var print_image_files := true						## Prints the loaded image files.
@export var print_tabbar_names := true						## Prints the TabBar names from TabContainers

var role: int = Role.CLIENT
var username: String = ""
var address: String = ""
var message: String = ""
var id: int = 0

var message_field_focus: bool = false
var color_picker_value: String = ""

var has_selected_text: bool = false
var selected_text: String = "": get = get_selected_text, set = set_selected_text

var main_path: String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)+"/Koteksu"
var img_save: String = main_path+"/ImgList"
var img_path: String = main_path+"/img"
var images: PackedStringArray = []

var supported_formats: PackedStringArray = ["png", "jpg", "jpeg", "webp", "svg", "bmp", "dds", "ktx", "exr", "hdr", "tga"]

var scroll_v_size: int = 28

## INFO: Window Rect2
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
@onready var imggrid: HFlowContainer = %HFlow
@onready var emojiboard: PopupPanel = %EmojiBoard

## INFO: Groups
@onready var bbcoded: Array = get_tree().get_nodes_in_group("BBCoded")
@onready var emojis: Array = get_tree().get_nodes_in_group("Emojis")
@onready var tabs: Array = get_tree().get_nodes_in_group("Tabs")
#endregion

func _ready() -> void:
	address = get_local_ip()
	address_field.text = address
	_init_directory(img_path)

	# Connect signals
	get_window().connect("files_dropped", Callable(self, "_on_files_dropped"))
	multiplayer.connect("connected_to_server", Callable(self, "_on_connected"))
	multiplayer.connect("peer_connected", Callable(self, "_on_peer_connected"))

	_set_emojis()
	_set_tabs()


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
	if not imggrid.get_children() == null:
		for i in imggrid.get_children():
			i.queue_free()

	var directory := DirAccess.open(path)
	if not directory == null:
		images = directory.get_files()
		if FileAccess.open(img_save, FileAccess.READ) == null:
			save_images(images)
		else:
			if not images == load_images(img_save):
				save_images(images)
				images = load_images(img_save)
			else:
				if OS.is_debug_build() and print_image_files == true:
					print("Loading images at %s ..." % img_path)

				for img_file in load_images(img_save):
					if print_image_files == true:
						print("✓ %s" % img_file)

					var image = Image.load_from_file(img_path+"/"+img_file)
					var texture = ImageTexture.create_from_image(image)
					var thumbnail := TextureButton.new()

					# Save images as resource to load by valid resource paths
					var texture_res_path: String = "user://%s.res" % img_file
					ResourceSaver.save(texture, texture_res_path)

					# Bind _on_Thumbnail_pressed & its args to TextureButton.pressed signal
					thumbnail.pressed.connect(_on_Thumbnail_pressed.bind(texture_res_path))

					# For adding effects when hovering/unhovered
					thumbnail.mouse_entered.connect(_on_Thumbnail_hovered.bind(thumbnail))
					thumbnail.mouse_exited.connect(_on_Thumbnail_unhover.bind(thumbnail))

					thumbnail.texture_normal = texture
					thumbnail.name = img_file
					thumbnail.ignore_texture_size = true
					thumbnail.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
					thumbnail.custom_minimum_size = thumbnail_min_size
					thumbnail.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
					imggrid.add_child(thumbnail, true)

				if OS.is_debug_build() and print_image_files == true:
					print("Loading images completed!\n")


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


## Called when files are dropped on the window.
func _on_files_dropped(files_paths: PackedStringArray) -> void:
	for path in files_paths:
		var file: String = path.get_file()
		var directory := DirAccess.open(img_path)

		if not directory == null and file.get_extension().to_lower() in supported_formats:
			DirAccess.copy_absolute(path, img_path+"/"+file)


func _joined(_role: int) -> void:
	client.hide()
	username = username_field.text
	address = address_field.text
	match _role:
		Role.HOST:
			_notify.rpc_id(multiplayer.get_unique_id(), username, address, Role.HOST)
		Role.CLIENT:
			_notify.rpc_id(id, username, address, Role.CLIENT)


func _on_connected() -> void:
	_joined(Role.CLIENT)


func _on_peer_connected(_id: int) -> void:
	id = _id


@rpc("any_peer", "call_local", "unreliable")
func _message_rpc(_username: String = "", _text: String = "") -> void:
	chatbox.text += "[b]%s:[/b] %s\n" % [_username, _text]


## The notification at chatbox when someone hosts or joins.
## [param _username] is the username of the user.
## [param _address] is the IP address of the user.
## [param type] is the type whether they 'hosted' or 'joined'.
@rpc("any_peer", "call_local", "unreliable")
func _notify(_username: String = "", _address: String = "", _role: int = role) -> void:
	var text = "[color=gray][b]%s[/b] %s the chat at %s[/color]\n"
	match _role:
		Role.HOST: chatbox.text += text % [_username, "hosted", _address]
		Role.CLIENT: chatbox.text += text % [_username, "joined", _address]


func _on_Host_pressed() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.set_bind_ip(address)
	peer.create_server(55555, 32)
	multiplayer.set_multiplayer_peer(peer)
	_joined(Role.HOST)


func _on_Join_pressed() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_client(address_field.text, 55555)
	multiplayer.set_multiplayer_peer(peer)
	_joined(Role.CLIENT)


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


func _on_Thumbnail_hovered(button: TextureButton) -> void:
	button.z_index = 1
	var tween: Tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.15, 1.15), 0.05)


func _on_Thumbnail_unhover(button: TextureButton) -> void:
	button.z_index = 0
	var tween: Tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.05)


func _on_Emoji_pressed() -> void:
	window_pos = DisplayServer.window_get_position(get_window().get_window_id())
	window_size = DisplayServer.window_get_size(get_window().get_window_id())
	emojiboard.popup(Rect2i(Vector2(window_pos.x - ((window_size.x / 2.0) + scroll_v_size), window_pos.y), Vector2(window_size.x / 2.0 + scroll_v_size, window_size.y)))


## TODO: Add the rest of the emojis
## TODO: Add their description on tooltips/hints
func _on_Emoji_btn_pressed(emoji: String) -> void:
	message_field.text += emoji


func _on_Emoji_btn_hovered(button: Button) -> void:
	button.z_index = 1
	var tween: Tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.25, 1.25), 0.05)


func _on_Emoji_btn_unhover(button: Button) -> void:
	button.z_index = 0
	var tween: Tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.05)


func _on_TabBar_hovered(tab: TabBar) -> void:
	tab.z_index = 1
	var tween: Tween = create_tween()
	tween.tween_property(tab, "scale", Vector2(1.25, 1.25), 0.05)


func _on_TabBar_unhover(tab: TabBar) -> void:
	tab.z_index = 0
	var tween: Tween = create_tween()
	tween.tween_property(tab, "scale", Vector2(1.0, 1.0), 0.05)


func _set_emojis() -> void:
	for emoji in emojis:
		emoji.pivot_offset = Vector2(20.0, 20.0) # To transform scale from center
		emoji.pressed.connect(_on_Emoji_btn_pressed.bind(emoji.text))
		emoji.mouse_entered.connect(_on_Emoji_btn_hovered.bind(emoji))
		emoji.mouse_exited.connect(_on_Emoji_btn_unhover.bind(emoji))


func _set_tabs() -> void:
	if OS.is_debug_build() and print_tabbar_names == true:
		print("TabContainers and TabBars")

	for tab in tabs:
		var tabbar: TabBar = tab.get_tab_bar()
		tabbar.mouse_default_cursor_shape = CursorShape.CURSOR_POINTING_HAND

		if hover_tabbar == true:
			tabbar.mouse_entered.connect(_on_TabBar_hovered.bind(tabbar))
			tabbar.mouse_exited.connect(_on_TabBar_unhover.bind(tabbar))

		if tabbar.get_parent().name == "Category" or "Emojis" or "People" or "Kaomoji":
			_set_tabbar_tooltip(tab, tabbar)

		if OS.is_debug_build() and print_tabbar_names == true:
			print(tabbar.get_parent().name+": "+tabbar.name)

	if OS.is_debug_build() and print_tabbar_names == true:
		print("")


## Sets the tooltip for TabBars. This method sets the tooltip with a TabContainer name.
## [param tab] is the TabContainer which separates nodes with tabs.
## [param tabbar] is a TabBar node from a TabContainer which contains the tabs to click on.
func _set_tabbar_tooltip(tab: TabContainer, tabbar: TabBar) -> void:
	for t in tab.get_child_count():
		var tabname: String = space_between_PascalCase(tab.get_child(t).name)
		tabbar.set_tab_tooltip(t, tabname)


## Returns a 'PascalCase' string into 'Pascal Case' text.
## [param text] is the string to check PascalCase naming convention with. A an space character is added before a substring if more than 1 uppercase letter is detected. 
func space_between_PascalCase(text: String) -> String:
	for c in text:
		if c.begins_with(c.capitalize()):
			text += " " + c
		else:
			text += c
	return text.trim_prefix(text.left(text.find(" "))).strip_edges()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		for textlabel in bbcoded:
			if not textlabel.name == "Chatbox":
				textlabel.process_mode = Node.PROCESS_MODE_DISABLED
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		for textlabel in bbcoded:
			if not textlabel.name == "Chatbox":
				textlabel.process_mode = Node.PROCESS_MODE_INHERIT
