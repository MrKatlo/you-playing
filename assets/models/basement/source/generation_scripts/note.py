"""Procedural cave order note texture.

The paper is drawn here rather than painted by hand so the torn state, the ink and
the fold creases stay in one place and can be regenerated with the rest of the
asset pack. There is no Pillow in Blender's bundled Python, so the PNG is written
directly from a NumPy buffer: 8-bit RGB, no alpha, zlib-compressed IDAT.

The handwriting is not a font. Each word is a short run of pen strokes on a ruled
baseline with a slight forward slope, which is what makes it read as a note pinned
under a clamp at gameplay distance instead of as printed text.
"""
from __future__ import annotations

import os
import struct
import zlib

import numpy as np

WIDTH = 256
HEIGHT = 160

PAPER = np.array([201.0, 192.0, 164.0])
PAPER_EDGE = np.array([150.0, 138.0, 110.0])
INK = np.array([38.0, 32.0, 27.0])
RULE = np.array([172.0, 162.0, 132.0])
STAIN = np.array([176.0, 158.0, 118.0])


def _chunk(kind: bytes, payload: bytes) -> bytes:
    return (struct.pack(">I", len(payload)) + kind + payload +
            struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF))


def write_png(path: str, image: np.ndarray) -> None:
    """Write an HxWx3 float image as an 8-bit RGB PNG."""
    height, width = image.shape[:2]
    pixels = np.clip(image, 0.0, 255.0).astype(np.uint8)
    raw = bytearray()
    for row in range(height):
        raw.append(0)  # filter: none
        raw.extend(pixels[row].tobytes())
    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    data = (b"\x89PNG\r\n\x1a\n" + _chunk(b"IHDR", header) +
            _chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + _chunk(b"IEND", b""))
    with open(path, "wb") as handle:
        handle.write(data)


def _pen(image: np.ndarray, x: float, y: float, dx: float, dy: float,
         thickness: float = 1.15) -> None:
    """One pen stroke: a short anti-aliased line."""
    length = max(abs(dx), abs(dy))
    steps = max(1, int(length * 1.5))
    reach = int(thickness + 1.2)
    for step in range(steps + 1):
        t = step / steps
        px = x + dx * t
        py = y + dy * t
        for oy in range(-reach, reach + 1):
            for ox in range(-reach, reach + 1):
                ix = int(px) + ox
                iy = int(py) + oy
                if ix < 0 or iy < 0 or ix >= image.shape[1] or iy >= image.shape[0]:
                    continue
                distance = (ox * ox + oy * oy) ** 0.5
                if distance > thickness + 0.9:
                    continue
                weight = max(0.0, 1.0 - distance / (thickness + 0.9))
                image[iy, ix] = image[iy, ix] * (1.0 - weight * 0.85) + INK * (weight * 0.85)


def _word(image: np.ndarray, x: float, baseline: float, letters: int,
          rng: np.random.Generator, scale: float = 1.0) -> float:
    """Draw one handwritten word and return the x to start the next one at."""
    cursor = x
    for index in range(letters):
        height = (5.0 + rng.random() * 6.0) * scale
        width = (3.0 + rng.random() * 3.5) * scale
        if rng.random() < 0.18:
            # Ascender or descender: the reason the note looks written, not ruled.
            height *= 1.5
        _pen(image, cursor, baseline, width * 0.55, -height, 1.05)
        _pen(image, cursor + width * 0.55, baseline - height,
             width * 0.45, height * (0.35 + rng.random() * 0.4), 1.0)
        if rng.random() < 0.35:
            _pen(image, cursor + width * 0.4, baseline - height * 0.45,
                 width * 0.3, -height * 0.15, 0.9)
        cursor += width + 1.4 + rng.random() * 1.2
    return cursor + 3.2


def build_order_note(path: str) -> None:
    """Build the paper texture with ruled lines, ink and a fold crease."""
    rng = np.random.default_rng(2026)
    image = np.tile(PAPER, (HEIGHT, WIDTH, 1))

    # Paper grain: low-frequency blotches plus per-pixel fibre noise, so the note
    # does not read as a flat colour swatch under the clamp's lamp.
    yy, xx = np.mgrid[0:HEIGHT, 0:WIDTH]
    blotch = (np.sin(xx * 0.11) * np.cos(yy * 0.07) * 4.0 +
              np.sin((xx + yy) * 0.23) * 2.2 +
              rng.normal(0.0, 2.6, (HEIGHT, WIDTH)))
    image += blotch[:, :, None]

    # Darker edges and two hydration stains.
    edge = (np.maximum(0.0, 1.0 - np.minimum(np.minimum(xx, WIDTH - 1 - xx),
                                             np.minimum(yy, HEIGHT - 1 - yy)) / 7.0))
    image = image * (1.0 - edge[:, :, None] * 0.35) + PAPER_EDGE * (edge[:, :, None] * 0.35)
    for cx, cy, radius in ((44, 118, 15), (206, 46, 11)):
        ring = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
        mask = np.clip((radius - np.abs(ring - radius * 0.55)) / 2.0, 0.0, 1.0) * 0.28
        image = image * (1.0 - mask[:, :, None]) + STAIN * mask[:, :, None]

    # Ruled lines, skipped where the ink crosses them.
    for row in range(38, HEIGHT - 18, 17):
        band = slice(row, row + 1)
        image[band, 18:WIDTH - 18] = image[band, 18:WIDTH - 18] * 0.72 + RULE * 0.28

    # A dotted price column and the buyer's thumbprint block.
    for row in range(38, HEIGHT - 18, 17):
        for x in range(WIDTH - 62, WIDTH - 32, 4):
            image[row - 3:row - 2, x:x + 1] = INK * 0.55 + image[row - 3:row - 2, x:x + 1] * 0.45

    # Handwritten order: three lines of words, then a signature flourish.
    baselines = (40.0, 57.0, 74.0)
    for row, baseline in enumerate(baselines):
        cursor = 22.0
        words = 4 if row else 3
        for word in range(words):
            letters = int(rng.integers(3, 7)) if row else int(rng.integers(4, 8))
            cursor = _word(image, cursor, baseline, letters, rng,
                           scale=0.85 if row == 2 else 1.0)
            if cursor > WIDTH - 78:
                break
    # Signature: a long low sweep with one loop.
    _pen(image, 26, 106, 58, -3, 1.3)
    _pen(image, 84, 103, 12, -9, 1.2)
    _pen(image, 96, 94, 14, 9, 1.2)
    _pen(image, 110, 103, 40, 2, 1.1)
    _pen(image, 26, 106, 124, 5, 1.0)

    # A fold crease across the middle and a torn lower-right corner.
    for y in range(HEIGHT):
        image[y, WIDTH // 2] *= 0.93
        image[y, WIDTH // 2 + 1] *= 0.97
    for y in range(HEIGHT):
        for x in range(WIDTH - 22, WIDTH):
            if (WIDTH - x) + (HEIGHT - y) < 26:
                image[y, x] = np.array([16.0, 14.0, 12.0])

    os.makedirs(os.path.dirname(path), exist_ok=True)
    write_png(path, image)


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    target = os.path.join(here, "..", "..", "generated", "props", "order_note.png")
    build_order_note(os.path.abspath(target))
    print("Built order note:", os.path.abspath(target))
