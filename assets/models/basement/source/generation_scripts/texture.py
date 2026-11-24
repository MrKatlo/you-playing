"""Procedural surface detail for the pack.

The pack's colours are flat palette values, which is the right base for a
stylised animal but leaves a hide looking like painted plastic up close. This
module bakes a small tileable grain map - hide pores, fine wrinkles and a
little directional streak - and the exporter multiplies it into the base colour
through a box-projected UV, so every species gains surface detail without a
hand-authored texture per animal and without a texture atlas to maintain.

The map is deliberately low contrast: it should read as material, not pattern.
"""
from __future__ import annotations

import io
import math

import numpy as np


def _pillow():
    """Load Pillow only for optional texture baking.

    Blender's bundled Python is used for the asset build because it supplies an
    approved NumPy runtime on this machine.  It does not bundle Pillow, while
    the GLB mesh exporter only needs box_uv below.  Delaying the import keeps
    geometric builds usable and lets a separate Pillow-enabled interpreter add
    baked detail textures later.
    """
    from PIL import Image, ImageFilter
    return Image, ImageFilter


def _value_noise(size: int, cells: int, rng) -> np.ndarray:
    Image, _ = _pillow()
    grid = rng.random((cells + 1, cells + 1))
    # wrap the edges so the tile repeats without a seam
    grid[-1, :] = grid[0, :]
    grid[:, -1] = grid[:, 0]
    img = Image.fromarray((grid * 255).astype(np.uint8), mode="L")
    up = img.resize((size, size), Image.BICUBIC)
    return np.asarray(up, dtype=np.float64) / 255.0


def _streaks(size: int, rng) -> np.ndarray:
    """Fine near-vertical scratches, the way hair or hide folds read."""
    out = np.zeros((size, size), dtype=np.float64)
    for _ in range(size // 3):
        x = rng.integers(0, size)
        y = rng.integers(0, size)
        length = int(rng.integers(size // 12, size // 3))
        strength = float(rng.uniform(0.25, 1.0))
        for k in range(length):
            yy = (y + k) % size
            xx = (x + int(0.12 * k)) % size
            out[yy, xx] += strength
    out /= max(out.max(), 1e-6)
    Image, ImageFilter = _pillow()
    blur = Image.fromarray((out * 255).astype(np.uint8), mode="L").filter(
        ImageFilter.GaussianBlur(1.2))
    return np.asarray(blur, dtype=np.float64) / 255.0


def grain_map(size: int = 256, seed: int = 7,
              contrast: float = 0.085) -> np.ndarray:
    """A tileable grayscale multiplier in 1-contrast .. 1.0."""
    rng = np.random.default_rng(seed)
    coarse = _value_noise(size, 6, rng)
    fine = _value_noise(size, 24, rng)
    streak = _streaks(size, rng)
    n = coarse * 0.45 + fine * 0.35 + streak * 0.20
    n = (n - n.min()) / max(n.max() - n.min(), 1e-6)
    # centred on 1.0, so the palette colour survives untouched on average
    return 1.0 - contrast * (1.0 - n)


def grain_png(size: int = 256, seed: int = 7, contrast: float = 0.085) -> bytes:
    """The grain map as PNG bytes, ready to embed in a GLB."""
    Image, _ = _pillow()
    shade = grain_map(size, seed, contrast)
    rgb = np.stack([shade, shade, shade], axis=-1)
    img = Image.fromarray(np.clip(rgb * 255.0, 0, 255).astype(np.uint8),
                          mode="RGB")
    buf = io.BytesIO()
    img.save(buf, format="PNG", optimize=True)
    return buf.getvalue()


def box_uv(verts: np.ndarray, tris: np.ndarray, tile: float = 1.0):
    """World-space box projection, one UV per triangle corner.

    A UV per metre keeps the grain the same physical size on a 1 m hyena and a
    3 m elephant. Box projection has seams where the dominant axis flips, which
    is invisible for a low-contrast isotropic grain.
    """
    a = verts[tris[:, 0]]
    b = verts[tris[:, 1]]
    c = verts[tris[:, 2]]
    n = np.cross(b - a, c - a)
    axis = np.argmax(np.abs(n), axis=1)
    corners = verts[tris.reshape(-1)]
    out = np.zeros((len(tris), 3, 2), dtype=np.float64)
    for i in range(len(tris)):
        ax = axis[i]
        if ax == 0:      # facing x: project y, z
            uv = corners[i * 3:(i + 1) * 3][:, [2, 1]]
        elif ax == 1:    # facing y: project x, z
            uv = corners[i * 3:(i + 1) * 3][:, [0, 2]]
        else:            # facing z: project x, y
            uv = corners[i * 3:(i + 1) * 3][:, [0, 1]]
        out[i] = uv / max(tile, 1e-6)
    return out.reshape(-1, 2)
