extends RefCounted
## Placeholder impact sounds synthesized in code, so no third-party audio license is involved.
## Each zone gets a distinct character: a sharp ring for the head, a dull thud for the torso, a lighter slap for limbs.
const RATE := 22050
# zone: [tone Hz, overtone Hz, noise share, decay per second, length in seconds]
const PROFILES := {
	&"head": [1750.0, 3300.0, 0.35, 16.0, 0.32],
	&"torso": [68.0, 140.0, 0.55, 26.0, 0.2],
	&"arms": [150.0, 310.0, 0.6, 40.0, 0.12],
	&"legs": [120.0, 250.0, 0.6, 36.0, 0.14],
}
static var _cache := {}

static func stream(zone: StringName) -> AudioStreamWAV:
	if not PROFILES.has(zone):
		zone = &"torso"
	if _cache.has(zone):
		return _cache[zone]
	var profile: Array = PROFILES[zone]
	var count := int(RATE * profile[4])
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var noise := RandomNumberGenerator.new()
	noise.seed = 4242
	for index in range(count):
		var t := float(index) / RATE
		var tone: float = sin(t * TAU * profile[0]) * 0.7 + sin(t * TAU * profile[1]) * 0.3
		var sample: float = (noise.randf_range(-1.0, 1.0) * profile[2] + tone * (1.0 - profile[2])) * exp(-t * profile[3])
		bytes.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 24000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = bytes
	_cache[zone] = wav
	return wav
