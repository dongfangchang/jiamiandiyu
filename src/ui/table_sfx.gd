extends RefCounted
## v0.39 procedural table SFX. Presentation only — never affects rules.
## Headless tests can assert call counts without requiring audio hardware.

const KIND_CARD_PLAY := "card_play"
const KIND_DAMAGE := "damage"
const KIND_RITUAL := "ritual"
const KIND_ALTAR := "altar"
const KIND_SEAL := "seal"
const KIND_FLIP := "flip"
const KIND_TURN := "turn"
const KIND_PEN := "pen"
const KIND_WIPE := "wipe"

static var muted := false
static var call_log: Array[String] = []
static var _tone_cache: Dictionary = {}


static func reset_for_tests() -> void:
	call_log.clear()
	muted = false


static func set_muted(value: bool) -> void:
	muted = value


static func is_muted() -> bool:
	return muted


static func call_count(kind: String = "") -> int:
	if kind.is_empty():
		return call_log.size()
	var total := 0
	for entry in call_log:
		if entry == kind:
			total += 1
	return total


static func play(host: Node, kind: String) -> void:
	call_log.append(kind)
	if muted or host == null or not is_instance_valid(host):
		return
	var stream := _tone_for(kind)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.name = "TableSfxPlayer"
	player.stream = stream
	player.volume_db = _volume_db_for(kind)
	host.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


static func _volume_db_for(kind: String) -> float:
	match kind:
		KIND_DAMAGE:
			return -6.0
		KIND_CARD_PLAY, KIND_FLIP:
			return -8.0
		KIND_PEN:
			return -5.0
		KIND_WIPE:
			return -7.0
		KIND_RITUAL, KIND_TURN:
			return -10.0
		_:
			return -12.0


static func _tone_for(kind: String) -> AudioStreamWAV:
	if _tone_cache.has(kind):
		return _tone_cache[kind] as AudioStreamWAV
	var freq := 440.0
	var ms := 90.0
	var volume := 0.22
	match kind:
		KIND_CARD_PLAY:
			freq = 118.0
			ms = 120.0
			volume = 0.28
		KIND_DAMAGE:
			freq = 760.0
			ms = 70.0
			volume = 0.24
		KIND_RITUAL:
			freq = 523.25
			ms = 160.0
			volume = 0.2
		KIND_ALTAR:
			freq = 92.0
			ms = 140.0
			volume = 0.26
		KIND_SEAL:
			freq = 640.0
			ms = 55.0
			volume = 0.18
		KIND_FLIP:
			freq = 880.0
			ms = 100.0
			volume = 0.2
		KIND_PEN:
			freq = 165.0
			ms = 320.0
			volume = 0.32
		KIND_WIPE:
			freq = 380.0
			ms = 200.0
			volume = 0.26
		KIND_TURN:
			freq = 330.0
			ms = 110.0
			volume = 0.18
		_:
			freq = 400.0
			ms = 80.0
	var stream := _synthesize(freq, ms, volume)
	_tone_cache[kind] = stream
	return stream


static func _synthesize(freq: float, ms: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var frames := maxi(1, int(sample_rate * ms / 1000.0))
	var data := PackedByteArray()
	data.resize(frames * 2)
	for index in range(frames):
		var t := float(index) / float(sample_rate)
		var env := 1.0 - float(index) / float(frames)
		# Soft attack to avoid clicks.
		if index < 24:
			env *= float(index) / 24.0
		var sample := sin(t * TAU * freq) * env * volume
		# Mild second harmonic for table-wood character.
		sample += sin(t * TAU * freq * 2.0) * env * volume * 0.18
		var encoded := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(index * 2, encoded)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
