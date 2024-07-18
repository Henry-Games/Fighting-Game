extends Node2D

@export var join_button : Button
@export var host_button : Button
@export var message_label : RichTextLabel



func _ready():
	if GameManager.prev_scene == "res://Scenes/main_menu.tscn":
		$AnimationPlayer.play("EnterFromRight")
	elif GameManager.prev_scene == "res://Scenes/MultiplayerLobby/Multiplayer_Lobby.tscn":
		$AnimationPlayer.play("EnterFromLeft")
	else:
		$AnimationPlayer.play("EnterFadeFromBlack")
		
	MUSIC_MANAGER.change_music("res://Assets/Sounds/lobby.mp3");
	host_button.grab_focus()
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
	

	
func _on_host_success():
	GameManager.host_started = true
	$AnimationPlayer.play("ExitToLeft")
	$ExitTimerMultiplayerLobby.start()
	
	
func _on_join_success():
	GameManager.host_started = false
	$AnimationPlayer.play("ExitToLeft")
	$ExitTimerMultiplayerLobby.start()

func _on_exit_timer_multiplayer_lobby_timeout():
	if !Relayconnect.IS_HOST:
		GameManager.want_sync_game_data.rpc_id(0)
	Relayconnect.call_rpc_room(GameManager.change_scene_rpc,["res://Scenes/MultiplayerLobby/Multiplayer_Lobby.tscn",false])
	

func _on_host_fail():
	message_label.text = "[center] Relay Server Status : CONNECTED \n HOST FAILED - Retry, if issue persists contact EMAIL"
	print("HOST FAIL")




func _on_join_fail(error_message):
	message_label.text = "[center] Relay Server Status : CONNECTED \n JOIN FAILED : %s" %error_message
	print("JOIN FAIL")

func _on_relay_server_connect():
	if !Relayconnect.IS_LOCAL_HOST:
		message_label.text = "[center] Relay Server Status : CONNECTED"
		join_button.disabled = false
		host_button.disabled = false

func _on_relay_server_disconnected():
	message_label.text = "[center] Relay Server Status : DISCONNECTED \n Could Not Reach Relay Server - check internet connection and then contact EMAIL"
	join_button.disabled = false
	host_button.disabled = false

func _on_relay_server_fail():
	message_label.text = "[center] Relay Server Status : DISCONNECTED \n Could Not Reach Relay Server - check internet connection and then contact EMAIL "

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



func _on_leave_button_button_down():
	$AnimationPlayer.play("ExitToRight")
	$ExitTimerMainMenu.start()
	
	
func _on_exit_timer_main_menu_timeout():
	GameManager.change_scene_rpc("res://Scenes/main_menu.tscn",true)
