extends RefCounted
## Placeholder rifle report synthesized in code; shared by the player's rifle and enemy rifles.
static var _stream: AudioStreamWAV

static func stream() -> AudioStreamWAV:
	if _stream != null:
		return _stream
	_stream = AudioStreamWAV.new()
	_stream.format = AudioStreamWAV.FORMAT_16_BITS
	_stream.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(2646 * 2)
	var noise := RandomNumberGenerator.new()
	noise.seed = 7331
	for index in range(2646):
		var t := float(index) / 22050.0
		var sample := (noise.randf_range(-1.0, 1.0) * 0.65 + sin(t * TAU * 95.0) * 0.35) * exp(-t * 55.0)
		bytes.encode_s16(index * 2, int(sample * 24000.0))
	_stream.data = bytes
	return _stream
