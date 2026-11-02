"""Original procedural texture sources, v1, 2026-11-01. Python stdlib only.

Periodic Fourier fields have no directional lighting and repeat without seams.
No external images or image-generation outputs are used. Run from any directory.
"""
import math
from pathlib import Path
import random
import struct
import zlib

SIZE = 128
OUT = Path(__file__).resolve().parents[1] / "textures"


def png(path, pixels):
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
    raw = b"".join(b"\0" + bytes(row) for row in pixels)
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def bake(name, low, high, seed, stretch=1):
    rng = random.Random(seed)
    waves = [(rng.randint(-16, 16), rng.randint(1, 16), rng.random() * math.tau, 1 / (1 + i * .35)) for i in range(28)]
    pixels = []
    for y in range(SIZE):
        row = []
        for x in range(SIZE):
            u, v = x / SIZE, y / SIZE
            n = sum(math.sin(math.tau * (fx * u + max(1, fy // stretch) * v) + phase) * amp for fx, fy, phase, amp in waves) / 8
            if name in ("spruce_bark_v1", "weathered_wood_v1"):
                n += .32 * math.sin(math.tau * (u * 14 + .14 * math.sin(v * math.tau)))
            t = max(0, min(1, .5 + n * .65))
            # Restrained stepped pigments rather than photographic grain.
            t = round(t * 9) / 9
            row.extend(round(a + (b - a) * t) for a, b in zip(low, high))
        pixels.append(row)
    png(OUT / (name + ".png"), pixels)
    import_path = OUT / (name + ".png.import")
    if import_path.exists():
        settings = import_path.read_text(encoding="utf-8")
        settings = settings.replace("mipmaps/generate=false", "mipmaps/generate=true")
        settings = settings.replace("detect_3d/compress_to=1", "detect_3d/compress_to=0")
        import_path.write_text(settings, encoding="utf-8")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    bake("moss_soil_v1", (40, 45, 32), (96, 103, 76), 1946)
    bake("spruce_bark_v1", (48, 42, 34), (111, 101, 77), 1947, 8)
    bake("weathered_wood_v1", (65, 57, 42), (142, 125, 91), 1948, 12)
    bake("granite_v1", (66, 70, 64), (145, 147, 130), 1949)
    print("Baked four original seamless 128x128 RGB textures. Existing import presets retain lossless compression and enable mipmaps; after first-ever import rerun this recipe once.")
