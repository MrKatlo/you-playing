class_name HorrorAudio
extends Node

var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var drone_phase := 0.0
var high_phase := 0.0
var pulse_phase := 0.0
var stinger_phase := 0.0
var echo_phase := 0.0
var tension := 0.16
var target_tension := 0.16
var stinger_time := 0.0
var echo_time := 0.0
var noise_seed := 0.0

func _ready() -> void:
	player = AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = 1.0
	player.stream = stream
	player.volume_db = -3.5
	add_child(player)
	player.play()
	playback = player.get_stream_playback()

func set_tension(value: float) -> void:
	target_tension = clampf(value, 0.0, 1.0)

func play_stinger() -> void:
	stinger_time = 0.75

func play_echo_pulse() -> void:
	# A readable low-to-high biological sonar call. It is deliberately distinct
	# from the music bed so the player can react before being located.
	echo_time = 0.42

func _process(delta: float) -> void:
	tension = lerpf(tension, target_tension, delta * 1.6)
	if playback == null:
		playback = player.get_stream_playback()
		return
	var frames := playback.get_frames_available()
	for _i in frames:
		playback.push_frame(Vector2(_next_sample(), _next_sample()))

func _next_sample() -> float:
	const RATE := 22050.0
	drone_phase += TAU * (36.0 + tension * 9.0) / RATE
	high_phase += TAU * (83.0 + tension * 44.0) / RATE
	pulse_phase += TAU * (0.34 + tension * 1.18) / RATE
	stinger_phase += TAU * (95.0 + tension * 145.0) / RATE
	noise_seed += 0.6180339
	var pulse := pow(maxf(0.0, sin(pulse_phase)), 20.0)
	var drone := sin(drone_phase) * 0.12 + sin(drone_phase * 0.501) * 0.075
	var wire := sin(high_phase) * (0.008 + tension * 0.036)
	var heartbeat := sin(drone_phase * 0.53) * pulse * (0.035 + tension * 0.13)
	var hiss := (sin(noise_seed * 91.7) + sin(noise_seed * 173.3)) * (0.004 + tension * 0.015)
	var sting := 0.0
	if stinger_time > 0.0:
		sting = (sin(stinger_phase) + sin(stinger_phase * 1.71)) * minf(0.33, stinger_time * 0.45)
		stinger_time -= 1.0 / RATE
	var echo := 0.0
	if echo_time > 0.0:
		var echo_progress := 1.0 - echo_time / 0.42
		echo_phase += TAU * lerpf(58.0, 174.0, echo_progress) / RATE
		echo = sin(echo_phase) * sin(echo_progress * PI) * 0.24
		echo_time -= 1.0 / RATE
	return clampf(drone + wire + heartbeat + hiss + sting + echo, -0.8, 0.8)
