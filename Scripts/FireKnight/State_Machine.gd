class_name State_Machine

var states

func _init():
	states = {
		"idle": Idle_State,
		"move": Move_State,
		"jump": Jump_State,
		"air_attack": Air_Attack_State,
		"attack1": Attack1_State,
		"attack2": Attack2_State,
		"attack3": Attack3_State,
		"sp_attack": SpAttack_State,
		"defend": Defend_State,
		"roll": Roll_State,
		"death":Death_State,
		"hit":Hit_State,
	}

func get_state(state_name):
	if states.has(state_name):
		return states.get(state_name)
