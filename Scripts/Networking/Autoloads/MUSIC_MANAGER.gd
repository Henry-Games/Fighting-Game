extends Node

var MusicPlayer : AudioStreamPlayer
# Called when the node enters the scene tree for the first time.
func _ready():
	MusicPlayer = AudioStreamPlayer.new()
	MusicPlayer.set_name("Music")
	add_child(MusicPlayer)



func change_music(music_path):
	var ToPlay = load(music_path);
	if ToPlay == MusicPlayer.stream:
		return
	MusicPlayer.stream = ToPlay
	MusicPlayer.play();
