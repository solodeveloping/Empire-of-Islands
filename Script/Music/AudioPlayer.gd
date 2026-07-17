extends Node
class_name AudioPlayer

@export
var in_game_music_tracks: Array[AudioStream] = []

@export
var invalid_construction: AudioStream

@export
var valid_construction: AudioStream

var current_music_index: int = 0

# TODO : UI sounds

func start_in_game_music():
	current_music_index = randi_range(0, in_game_music_tracks.size() - 1)
	play_current_music()

func _on_music_done_playing():
	# TODO : random
	current_music_index += 1
	if current_music_index >= in_game_music_tracks.size():
		current_music_index = 0
	
	play_current_music()
	
func play_current_music():
	print("play_current_music")
	var player: AudioStreamPlayer = SoundManager.play_music(
		in_game_music_tracks[current_music_index], 0, "Music"
	)
	
	print("bus ", player.bus)
	print("volume ", player.volume_db)
	print("volume ", player.volume_linear)
	print("bus volume ", AudioServer.get_bus_volume_db(0))
	
	player.finished.connect(_on_music_done_playing)

func play_invalid_construction():
	SoundManager.play_sound(
		invalid_construction
	)

func play_valid_construction():
	SoundManager.play_sound(
		valid_construction
	)
