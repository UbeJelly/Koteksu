class_name MainClient extends Control


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
