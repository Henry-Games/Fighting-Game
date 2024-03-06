extends Node2D

# Store the network_var sync for easy access
var network_node : Node2D

# ID for the connected device 0 for keyboard and first connected controller, 2nd controller id = 1 etc
var device_id := 0
var controller := true


var player_name := "" : set = player_name_changed

signal PlayerNameChangedSignal(new_name)

#region Player Input Variables

var MoveAxis := Vector2(0,0) : set = MoveAxisChanged
var LookAxis := Vector2(0,0) : set = LookAxisChanged
var MousePos := Vector2.ZERO : set = MousePositionChange

signal MoveAxisChangedSignal(move_dir : Vector2)
signal LookAxisChangedSignal(lookDir : Vector2)
signal MousePositionChangeSignal(mouse_pos : Vector2)
signal JumpSignal()
signal AttackSignal()
signal SpecialSignal()
signal RollSignal()
signal DefendSignal()

# Keyboard Bindings
var key_bindings_keyboard = {
	"MOVE LEFT":"A",
	"MOVE RIGHT":"D",
	"MOVE UP":"W",
	"MOVE DOWN":"S",
	"JUMP":"Space",
	"ATTACK":"U",
	"SPECIAL":"I",
	"DEFEND":"K",
	"ROLL":"J",
	"SPAWN PLAYER":"Enter",
}

# Controller Bindings
var joystick_left_deadzone := 0.2
var joystick_right_deadzone := 0.2
var key_bindings_controller = {
	"JUMP":JOY_BUTTON_A,
	"SPAWN PLAYER":JOY_BUTTON_A,
}
#endregion

func _ready():
	network_node = get_node("NetworkVarSync")
	add_to_group("puppet_masters")
	pass

func _process(delta):
	# Only run input detection on puppet if this puppet is owned by the local player
	if !network_node.is_local_player: 
		return
		
	if controller:
		## Left Joystick
		# Horizontal Axis
		var joy_left_x = Input.get_joy_axis(device_id,JOY_AXIS_LEFT_X)
		if joy_left_x < joystick_left_deadzone and joy_left_x > (joystick_left_deadzone * -1):
			joy_left_x = 0
		
		# Vertical Axis
		var joy_left_y = Input.get_joy_axis(device_id,JOY_AXIS_LEFT_Y)
		if joy_left_y < joystick_left_deadzone and joy_left_y > (joystick_left_deadzone * -1):
			joy_left_y = 0
		
		# Only set MoveAxis if it is a different value to avoid spamming the MoveAxisChanged signal
		var new_left_stick = Vector2(joy_left_x,joy_left_y)
		if new_left_stick != MoveAxis:
			MoveAxis = new_left_stick
		
		## Right Joystick
		# Horizontal Axis
		var joy_right_x = Input.get_joy_axis(device_id,JOY_AXIS_RIGHT_X)
		if joy_right_x < joystick_right_deadzone and joy_right_x > (joystick_right_deadzone * -1):
			joy_right_x = 0
		
		# Vertical Axis
		var joy_right_y = Input.get_joy_axis(device_id,JOY_AXIS_RIGHT_Y)
		if joy_right_y < joystick_right_deadzone and joy_right_y > (joystick_right_deadzone * -1):
			joy_right_y = 0
		
		# Only set LookAxis if it is a different value to avoid spamming the LookAxisChanged signal
		var new_right_stick = Vector2(joy_right_x,joy_right_y)
		if new_right_stick != LookAxis:
			LookAxis = new_right_stick
	else:
		# Resets LookAxis to zero here because when you stop moving the mouse it does not trigger an
		# input event so the last mouse velocity gets left causing drift
		if Input.get_last_mouse_velocity().is_zero_approx() and !LookAxis.is_zero_approx():
			LookAxis = Vector2(0,0)
	

func _input(event : InputEvent):
	# Only run input detection on puppet if this puppet is owned by the local player
	if !network_node.is_local_player: 
		return
		
	if controller:
		match event.get_class():
			#if controller button pressed and device id corresponds to this puppets device id then 
			# send that button press to this puppet on all devices
			"InputEventJoypadButton":
				if event.device != device_id:
					return
				if event.pressed:
					Relayconnect.call_rpc_room(ButtonSignalCall,[key_bindings_controller.find_key(event.button_index)])
			
	else:
		match event.get_class():
			"InputEventMouseMotion":
				LookAxis = event.velocity/1000
				MousePos = event.position
				return
			"InputEventKey":
				var key = OS.get_keycode_string(event.keycode)
				if event.echo:
					return
				match key_bindings_keyboard.find_key(key):
					"MOVE LEFT":
						if event.pressed:
							MoveAxis.x -= 1
						else:
							MoveAxis.x += 1
					"MOVE RIGHT":
						if event.pressed:
							MoveAxis.x += 1
						else:
							MoveAxis.x -= 1
					"MOVE UP":
						if event.pressed:
							MoveAxis.y += 1
						else:
							MoveAxis.y -= 1
					"MOVE DOWN":
						if event.pressed:
							MoveAxis.y -= 1
						else:
							MoveAxis.y += 1
					_:
						if event.pressed:
								Relayconnect.call_rpc_room(ButtonSignalCall,[key_bindings_keyboard.find_key(key)])
 

@rpc("any_peer","call_local","reliable")
func ButtonSignalCall(signalName):
	if get_child_count() < 2 && Relayconnect.IS_HOST:
		# Tell gamemanager to spawn the puppet for this puppet master
		GameManager.SPAWN_PUPPET_SIGNAL.emit(self)
		return
		
	match signalName:
		"JUMP":
			JumpSignal.emit()
		"ATTACK":
			AttackSignal.emit()
		"DEFEND":
			DefendSignal.emit()
		"SPECIAL":
			SpecialSignal.emit()
		"ROLL":
			RollSignal.emit()


#region OnMoveAxisChange
#####		
func MoveAxisChanged(new_move_axis : Vector2):
	MoveAxis = new_move_axis
	if MoveAxis.is_zero_approx():
		MoveAxis = Vector2.ZERO
		
	MoveAxisChangedSignal.emit(MoveAxis)
		
#####
#endregion

#region OnLookAxisChange
#####
func LookAxisChanged(new_look_axis):
	LookAxis = new_look_axis
	if LookAxis.is_zero_approx():
		LookAxis = Vector2.ZERO
	LookAxisChangedSignal.emit(LookAxis)

#####
#endregion

#region OnMousePosChange
#####
func MousePositionChange(new_mouse_pos):
	MousePos = new_mouse_pos
	MousePositionChangeSignal.emit(new_mouse_pos)
#####
	
#endregion

func player_name_changed(new_player_name):
	player_name = new_player_name
	PlayerNameChangedSignal.emit(new_player_name)



@rpc("any_peer","call_local","reliable")
func DestroySelf():
	GameManager.objects_to_sync.erase(name)
	queue_free()

