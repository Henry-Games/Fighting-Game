extends Node2D

@export var join_button : Button
@export var host_button : Button
@export var message_label : RichTextLabel



func _ready():
	Relayconnect.connect_to_relay_server("13.210.71.64")
	Relayconnect.JoinSuccessSignal.connect(_on_join_success)
	Relayconnect.JoinFailSignal.connect(_on_join_fail)
	Relayconnect.HostSuccessSignal.connect(_on_host_success)
	Relayconnect.HostFailSignal.connect(_on_host_fail)
	Relayconnect.RelayServerFailedSignal.connect(_on_relay_server_fail)
	Relayconnect.RelayServerConnectedSignal.connect(_on_relay_server_connect)
	Relayconnect.RelayServerDisconnectedSignal.connect(_on_relay_server_disconnected)
	if Relayconnect.connected:
		_on_relay_server_connect()
	
	# Place the relay server IP
	


	
func _on_host_success():
	GameManager.host_started = true
	Relayconnect.call_rpc_room(GameManager.change_scene_rpc,["res://Scenes/MultiplayerLobby/Multiplayer_Lobby.tscn",true])

func _on_host_fail():
	message_label.text = "HOST FAILED"
	print("HOST FAIL")

func _on_join_success():
	GameManager.host_started = true
	print("JOIN SUCCESS")

func _on_join_fail(error_message):
	message_label.text = "JOIN FAILED : %s" %error_message
	print("JOIN FAIL")

func _on_relay_server_connect():
	if !Relayconnect.IS_LOCAL_HOST:
		message_label.text = ""
		join_button.disabled = false
		host_button.disabled = false

func _on_relay_server_disconnected():
	message_label.text = ""
	join_button.disabled = false
	host_button.disabled = false

func _on_relay_server_fail():
	message_label.text = "CONNECTION TO RELAY SERVER FAILED"

func _on_host_button_down():
	Relayconnect.host()

func _on_join_button_down():
	Relayconnect.join()

func _on_line_edit_text_changed(new_text):
	Relayconnect.typed_room_code = new_text

func _on_local_host_button_down():
	Relayconnect.local_host()


func _on_local_room_code_text_changed(new_text):
	Relayconnect.typed_room_code = new_text
	pass # Replace with function body.


func _on_local_ip_text_changed(new_text):
	Relayconnect.typed_local_address = new_text

