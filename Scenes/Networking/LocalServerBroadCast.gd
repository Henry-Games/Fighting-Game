extends RichTextLabel

const UDP_BROADCAST_FREQUENCY : float = 3 # 3 for me
var udp_network: PacketPeerUDP
var server_broadcasting_udp_port: int = 6868 # 6868 for me
var _broadcast_timer = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	udp_network = PacketPeerUDP.new()
	udp_network.set_broadcast_enabled(true)
	udp_network.connect_to_host("255.255.255.255",server_broadcasting_udp_port)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_broadcast_timer -= delta
	if _broadcast_timer <= 0:
		_broadcast_timer = UDP_BROADCAST_FREQUENCY
		var stg = Relayconnect.ROOM_CODE
		var error = udp_network.put_packet(stg.to_ascii_buffer())

