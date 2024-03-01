extends FlowContainer

var udp_network
var server_broadcasting_udp_port: int = 6868 # 6868 for 

# Called when the node enters the scene tree for the first time.
func _ready():
	udp_network = PacketPeerUDP.new()

	if udp_network.bind(server_broadcasting_udp_port) != OK:
		print("Error listening on port: ", server_broadcasting_udp_port)
	else:
		print("Listening on port: ", server_broadcasting_udp_port)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if udp_network.get_available_packet_count() > 0:
		
		var array_bytes = udp_network.get_packet()
		var packet_string = array_bytes.get_string_from_ascii()
		var new_server_room_code = packet_string
		for child in get_children():
			child.queue_free()
				
		var object_to_spawn = load("res://Scenes/MainMenu/LocalJoin.tscn") as PackedScene
		var object_instance = object_to_spawn.instantiate()
		object_instance.ip = udp_network.get_packet_ip()
		object_instance.room_code = new_server_room_code 
		add_child(object_instance)
		
		

