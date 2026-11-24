class_name BasementAudio
extends Node

# The basement's own sound, synthesised at load the way the station game does
# it: no sample assets, and every bed can be driven by farm state.
#
#   furnace  continuous low roar + noise; silent when the fire is out, and the
#            cooling metal ticks at random once it drops.
#   trays    continuous insect hiss; density follows live colonies, and the
#            treble opens up (thin, quiet) as health falls and colonies die.
#   chain    shutter crank: links rattling, heavy slide, hydraulic seat.
#   bolt     the bolt driver firing: vented air, thump, metal crack.
#   dry      the striker falling on an empty driver.
#   tick     one contracting clank from the furnace.

const RATE := 22050
const TRAY_BUS := "BasementTrays"

var furnace_stream: AudioStreamWAV
var tray_stream: AudioStreamWAV
var chain_stream: AudioStreamWAV
var bolt_stream: AudioStreamWAV
var dry_stream: AudioStreamWAV
var tick_stream: AudioStreamWAV

var furnace_player: AudioStreamPlayer
var tray_player: AudioStreamPlayer
var chain_player: AudioStreamPlayer
var bolt_player: AudioStreamPlayer
var dry_player: AudioStreamPlayer
var tick_player: AudioStreamPlayer

var furnace_target := 0.0
var tray_target := 0.0
var tray_thin := 0.0
var furnace_level := 0.0
var tray_level := 0.0
var thin_level := 0.0
var muted := false
var tick_wait := 3.0
var tray_highpass: AudioEffectHighPassFilter

func _ready() -> void:
	# Ducking has to keep working while the pause menu holds the tree.
	process_mode = Node.PROCESS_MODE_ALWAYS
	furnace_stream = _build_furnace_loop()
	tray_stream = _build_tray_loop()
	chain_stream = _build_chain()
	bolt_stream = _build_bolt()
	dry_stream = _build_dry()
	tick_stream = _build_tick()
	_ensure_tray_bus()
	furnace_player = _make_player(furnace_stream, -46.0)
	tray_player = _make_player(tray_stream, -48.0)
	tray_player.bus = TRAY_BUS
	chain_player = _make_player(chain_stream, -4.0)
	bolt_player = _make_player(bolt_stream, -3.0)
	dry_player = _make_player(dry_stream, -14.0)
	tick_player = _make_player(tick_stream, -18.0)
	furnace_player.play()
	tray_player.play()

func set_beds(furnace_value: float, tray_value: float, thin_value: float) -> void:
	furnace_target = clampf(furnace_value, 0.0, 1.0)
	tray_target = clampf(tray_value, 0.0, 1.0)
	tray_thin = clampf(thin_value, 0.0, 1.0)

func set_muted(value: bool) -> void:
	muted = value

func play_chain() -> void:
	_trigger(chain_player, -3.5, randf_range(0.97, 1.03))

func play_bolt() -> void:
	_trigger(bolt_player, -2.5, randf_range(0.94, 1.06))

func play_dry() -> void:
	_trigger(dry_player, -13.0, randf_range(0.95, 1.12))

func play_tick(pitch: float) -> void:
	_trigger(tick_player, randf_range(-22.0, -17.0), pitch)

func _process(delta: float) -> void:
	if furnace_player == null or tray_player == null:
		return
	furnace_level = move_toward(furnace_level, furnace_target, delta * 0.8)
	tray_level = move_toward(tray_level, tray_target, delta * 0.5)
	thin_level = move_toward(thin_level, tray_thin, delta * 0.35)
	var duck := -22.0 if (muted or get_tree().paused) else 0.0
	furnace_player.volume_db = lerpf(-46.0, -8.0, furnace_level) + duck
	furnace_player.pitch_scale = 0.94 + furnace_level * 0.10
	tray_player.volume_db = lerpf(-48.0, -16.0, tray_level) + duck
	tray_player.pitch_scale = 0.96 + thin_level * 0.22
	if tray_highpass != null:
		# Dense and muddy while the colonies are fat; hissy and thin as they die.
		tray_highpass.cutoff_hz = lerpf(150.0, 820.0, thin_level)
	# Cold metal contracts and ticks. Only while the fire is out.
	if furnace_level < 0.30:
		tick_wait -= delta
		if tick_wait <= 0.0:
			tick_wait = randf_range(2.6, 7.5)
			play_tick(randf_range(0.78, 1.18))
	else:
		tick_wait = maxf(tick_wait, 1.2)

func _trigger(player: AudioStreamPlayer, volume_db: float, pitch: float) -> void:
	if player == null:
		return
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()

func _make_player(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	return player

func _ensure_tray_bus() -> void:
	var index := AudioServer.get_bus_index(TRAY_BUS)
	if index < 0:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, TRAY_BUS)
		AudioServer.set_bus_send(index, "Master")
	if AudioServer.get_bus_effect_count(index) == 0:
		tray_highpass = AudioEffectHighPassFilter.new()
		tray_highpass.cutoff_hz = 150.0
		AudioServer.add_bus_effect(index, tray_highpass)
	else:
		var effect := AudioServer.get_bus_effect(index, 0)
		if effect is AudioEffectHighPassFilter:
			tray_highpass = effect

# ---------------------------------------------------------------- beds

func _build_furnace_loop() -> AudioStreamWAV:
	# Four seconds of roar. Every partial completes a whole number of cycles in
	# that window, so the bed loops without a seam even before the crossfade.
	var frames := int(RATE * 4.0)
	var fade := int(RATE * 0.30)
	var samples := PackedFloat32Array()
	samples.resize(frames + fade)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91127
	var low := 0.0
	var lower := 0.0
	for index in samples.size():
		var time := float(index) / float(RATE)
		var noise := rng.randf_range(-1.0, 1.0)
		low += (noise - low) * 0.02
		lower += (low - lower) * 0.08
		var breath := 0.74 + 0.26 * sin(TAU * 0.25 * time)
		var roar := sin(TAU * 41.0 * time) * 0.34 + sin(TAU * 61.5 * time) * 0.16 + sin(TAU * 29.0 * time) * 0.22
		var rumble := lower * 1.6 + low * 0.5
		var grit := noise * 0.035 * (0.5 + 0.5 * sin(TAU * 7.0 * time))
		samples[index] = (roar * 0.55 + rumble * 0.75 + grit) * breath
	return _seal(samples, frames, fade, true)

func _build_tray_loop() -> AudioStreamWAV:
	# Three seconds of insect hiss: broadband noise above a moving floor, a
	# swarm tremble at 17 Hz, and two stridulation partials on top.
	var frames := int(RATE * 3.0)
	var fade := int(RATE * 0.25)
	var samples := PackedFloat32Array()
	samples.resize(frames + fade)
	var rng := RandomNumberGenerator.new()
	rng.seed = 51233
	var smooth := 0.0
	var smoother := 0.0
	for index in samples.size():
		var time := float(index) / float(RATE)
		var noise := rng.randf_range(-1.0, 1.0)
		smooth += (noise - smooth) * 0.35
		smoother += (smooth - smoother) * 0.06
		var high := noise - smoother
		var tremble := 0.55 + 0.45 * pow(maxf(0.0, sin(TAU * 17.0 * time)), 2.0)
		var flicker := 0.7 + 0.3 * sin(TAU * 43.0 * time)
		var stridulation := sin(TAU * 3100.0 * time + sin(TAU * 6.0 * time) * 0.6) * 0.05
		var chirp := sin(TAU * 4700.0 * time) * pow(maxf(0.0, sin(TAU * 3.0 * time)), 8.0) * 0.06
		samples[index] = high * 0.42 * tremble * flicker + stridulation + chirp
	return _seal(samples, frames, fade, true)

# ---------------------------------------------------------------- one-shots

func _build_chain() -> AudioStreamWAV:
	# Crank: links over the sprocket, the door climbing its rails, then it seats.
	# Long enough for the seating thud to ring out instead of being cut off.
	var frames := int(RATE * 1.45)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77021
	var click_times: Array = []
	var cursor := 0.02
	while cursor < 0.62:
		click_times.append(cursor)
		cursor += rng.randf_range(0.018, 0.055)
	var low := 0.0
	for index in frames:
		var time := float(index) / float(RATE)
		var value := 0.0
		for click_time in click_times:
			var since_click := time - float(click_time)
			if since_click < 0.0 or since_click > 0.09:
				continue
			var envelope := exp(-since_click * 55.0)
			value += rng.randf_range(-1.0, 1.0) * envelope * 0.35
			value += sin(TAU * 2450.0 * since_click) * envelope * 0.16
		if time > 0.30 and time < 0.86:
			var slide := clampf((time - 0.30) / 0.16, 0.0, 1.0) * clampf((0.86 - time) / 0.14, 0.0, 1.0)
			low += (rng.randf_range(-1.0, 1.0) - low) * 0.10
			value += low * slide * 2.4
		if time >= 0.88:
			var since_seat := time - 0.88
			value += sin(TAU * 52.0 * since_seat) * exp(-since_seat * 9.0) * 0.75
			value += rng.randf_range(-1.0, 1.0) * exp(-since_seat * 40.0) * 0.5
			value += sin(TAU * 690.0 * since_seat) * exp(-since_seat * 22.0) * 0.18
		samples[index] = value
	return _to_wav(samples, false)

func _build_bolt() -> AudioStreamWAV:
	# Compressed air out of the driver, the bolt leaving, and a short room tail.
	var frames := int(RATE * 0.45)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33019
	for index in frames:
		var time := float(index) / float(RATE)
		var vent := rng.randf_range(-1.0, 1.0) * exp(-time * 46.0) * 0.75
		var thump := sin(TAU * 94.0 * time) * exp(-time * 15.0) * 0.52
		var crack := sin(TAU * 1740.0 * time) * exp(-time * 38.0) * 0.26
		var body := sin(TAU * 301.0 * time) * exp(-time * 19.0) * 0.20
		var tail := rng.randf_range(-1.0, 1.0) * exp(-time * 7.0) * 0.12
		samples[index] = vent + thump + crack + body + tail
	return _to_wav(samples, false)

func _build_dry() -> AudioStreamWAV:
	var frames := int(RATE * 0.12)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	var rng := RandomNumberGenerator.new()
	rng.seed = 60413
	for index in frames:
		var time := float(index) / float(RATE)
		var first := exp(-time * 120.0)
		var second := 0.0
		if time > 0.045:
			second = exp(-(time - 0.045) * 130.0) * 0.7
		var strike := rng.randf_range(-1.0, 1.0) * (first + second) * 0.6
		var ring := sin(TAU * 2100.0 * time) * first * 0.3
		samples[index] = strike + ring
	return _to_wav(samples, false)

func _build_tick() -> AudioStreamWAV:
	var frames := int(RATE * 0.30)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	var rng := RandomNumberGenerator.new()
	rng.seed = 18809
	for index in frames:
		var time := float(index) / float(RATE)
		var strike := rng.randf_range(-1.0, 1.0) * exp(-time * 200.0) * 0.9
		var ring := sin(TAU * 1180.0 * time) * exp(-time * 16.0) * 0.30
		var ring_two := sin(TAU * 1930.0 * time) * exp(-time * 22.0) * 0.16
		var clank := sin(TAU * 420.0 * time) * exp(-time * 28.0) * 0.18
		samples[index] = strike + ring + ring_two + clank
	return _to_wav(samples, false)

# ---------------------------------------------------------------- encoding

func _seal(samples: PackedFloat32Array, frames: int, fade: int, loop: bool) -> AudioStreamWAV:
	# Fold the tail generated past `frames` back over the head, so the loop
	# point is continuous instead of a click once per cycle.
	var sealed := PackedFloat32Array()
	sealed.resize(frames)
	for index in frames:
		var value := samples[index]
		if index < fade and frames + index < samples.size():
			var weight := float(index) / float(fade)
			value = value * weight + samples[frames + index] * (1.0 - weight)
		sealed[index] = value
	return _to_wav(sealed, loop)

func _to_wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var peak := 0.0001
	for index in samples.size():
		peak = maxf(peak, absf(samples[index]))
	var gain := 0.9 / peak if peak > 0.9 else 1.0
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	var tail := int(RATE * 0.03)
	for index in samples.size():
		var value := samples[index]
		if not loop and tail > 0:
			# Never let a one-shot end on a non-zero sample and click.
			var remaining := samples.size() - 1 - index
			if remaining < tail:
				value *= float(remaining) / float(tail)
		data.encode_s16(index * 2, int(clampf(value * gain, -1.0, 1.0) * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream
