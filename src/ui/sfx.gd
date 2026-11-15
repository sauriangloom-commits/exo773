extends Node

## Audio service with labeled placeholder slots.
##
## Missing files never crash: playback requests for absent streams are ignored.
## Generated placeholder WAVs live in res://assets/audio and are documented in
## docs/ASSET_GUIDE.md. Replace them with the same filenames (or add .ogg
## support in load_streams) without touching gameplay code.

const AUDIO_DIR := "res://assets/audio"
const SFX_IDS := ["step", "hit", "miss", "spell", "heal", "bell", "ui", "victory", "defeat", "door", "combat"]
const MUSIC_IDS := ["music_menu", "music_explore"]
const AMBIENCE_IDS := ["ambience_dungeon"]

var streams: Dictionary = {}
var pool: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var current_music := ""
var current_ambience := ""


func _ready() -> void:
	_ensure_buses()
	_load_streams()
	for i in 8:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		pool.append(player)
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	ambience_player = AudioStreamPlayer.new()
	ambience_player.bus = "Ambience"
	add_child(ambience_player)


func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX", "Ambience"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var index := AudioServer.bus_count
			AudioServer.add_bus(index)
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")


func _load_streams() -> void:
	for id in SFX_IDS + MUSIC_IDS + AMBIENCE_IDS:
		var path := AUDIO_DIR.path_join("%s.wav" % id)
		if ResourceLoader.exists(path):
			var stream = load(path)
			if stream != null:
				if stream is AudioStreamWAV:
					stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if (MUSIC_IDS + AMBIENCE_IDS).has(id) else AudioStreamWAV.LOOP_DISABLED
					stream.loop_end = stream.data.size() / 2
				streams[id] = stream


func play(sound_id: String, volume_db := 0.0) -> void:
	if not streams.has(sound_id):
		return
	for player in pool:
		if not player.playing:
			player.stream = streams[sound_id]
			player.volume_db = volume_db
			player.play()
			return
	if not pool.is_empty():
		pool[0].stream = streams[sound_id]
		pool[0].volume_db = volume_db
		pool[0].play()


func play_music(music_id: String) -> void:
	if current_music == music_id and music_player != null and music_player.playing:
		return
	current_music = music_id
	if music_player == null:
		return
	if not streams.has(music_id):
		music_player.stop()
		return
	music_player.stream = streams[music_id]
	music_player.play()


func play_ambience(ambience_id: String) -> void:
	if current_ambience == ambience_id and ambience_player != null and ambience_player.playing:
		return
	current_ambience = ambience_id
	if ambience_player == null:
		return
	if not streams.has(ambience_id):
		ambience_player.stop()
		return
	ambience_player.stream = streams[ambience_id]
	ambience_player.play()


func stop_music() -> void:
	current_music = ""
	if music_player != null:
		music_player.stop()


func set_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var value := clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(index, value <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.001)))


func has_stream(sound_id: String) -> bool:
	return streams.has(sound_id)
