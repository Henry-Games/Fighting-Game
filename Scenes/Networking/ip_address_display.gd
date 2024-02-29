extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	var ip_adress :String

	if OS.has_feature("windows"):
		ip_adress =  IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)
	text = "ADDRESS: " + ip_adress


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
