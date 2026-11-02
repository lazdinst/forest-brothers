extends RefCounted
## Placeholder rifle sounds synthesized in code; shared by the player's rifle and enemy rifles.
static var _stream: AudioStreamWAV
static var _reload: AudioStreamWAV

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

## Two metallic clicks: magazine out, magazine in.
static func reload_stream() -> AudioStreamWAV:
	if _reload != null:
		return _reload
	var rate := 22050
	var count := int(rate * 0.9)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var noise := RandomNumberGenerator.new()
	noise.seed = 913
	for index in range(count):
		var t := float(index) / rate
		var sample := 0.0
		for click_at in [0.05, 0.62]:
			var local: float = t - click_at
			if local >= 0.0:
				sample += (noise.randf_range(-1.0, 1.0) * 0.5 + sin(local * TAU * 2100.0) * 0.5) * exp(-local * 70.0)
		bytes.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 20000.0))
	_reload = AudioStreamWAV.new()
	_reload.format = AudioStreamWAV.FORMAT_16_BITS
	_reload.mix_rate = rate
	_reload.data = bytes
	return _reload
