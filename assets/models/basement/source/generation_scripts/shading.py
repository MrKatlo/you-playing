"""Shading data the exporter bakes into every mesh.

The pack's geometry is authored as flat shaded lofts, which is the art style,
but two things separate a crude faceted model from a good one and neither is
polygon count:

  * **smooth normals where the surface is organic.** A body, a neck or a limb
    reads as a rounded form when its normals are averaged across the seam, and
    keeps its crisp edges when they are not. `weld_normals` averages within a
    piece, so a piece either shades smooth or stays faceted, and primitives that
    should keep a hard edge are simply not marked smooth.
  * **baked ambient occlusion.** Crevices - the armpit, under the chin, between
    the legs, behind the ear, inside the mouth - are what tell the eye the shape
    is solid. `bake_ao` traces a short hemisphere of rays from every vertex and
    darkens the ones that are crowded.

Both results are written as glTF vertex data (NORMAL and COLOR_0), so they cost
no draw calls and survive any renderer that multiplies vertex colour into the
base colour, which glTF requires.
"""
from __future__ import annotations

import numpy as np

# A fixed cosine-weighted hemisphere, so AO is deterministic between builds.
_GOLDEN = 0.6180339887498949


def _hemisphere(rays: int):
    dirs = []
    for i in range(rays):
        # cosine-weighted: z = sqrt((i + 0.5) / rays)
        z = np.sqrt((i + 0.5) / rays)
        r = np.sqrt(max(0.0, 1.0 - z * z))
        phi = 2.0 * np.pi * i * _GOLDEN
        dirs.append((r * np.cos(phi), r * np.sin(phi), z))
    return np.array(dirs, dtype=np.float64)


def _orthonormal(normal: np.ndarray):
    """A basis with `normal` as +Z, stable for any direction."""
    n = normal / max(np.linalg.norm(normal), 1e-9)
    up = np.array([0.0, 1.0, 0.0])
    if abs(float(n @ up)) > 0.9:
        up = np.array([1.0, 0.0, 0.0])
    t = np.cross(up, n)
    t /= max(np.linalg.norm(t), 1e-9)
    b = np.cross(n, t)
    return t, b, n


def weld(verts: np.ndarray, decimals: int = 4):
    """Group vertices that sit on the same point; returns (unique, inverse)."""
    keys = np.round(verts, decimals)
    # np.unique on rows gives a stable ordering and the inverse mapping
    uniq, inverse = np.unique(keys, axis=0, return_inverse=True)
    return uniq, inverse.reshape(-1)


def welded_normals(verts: np.ndarray, tris: np.ndarray):
    """Per-corner smooth normals: area-weighted average at each welded point."""
    a = verts[tris[:, 0]]
    b = verts[tris[:, 1]]
    c = verts[tris[:, 2]]
    face = np.cross(b - a, c - a)                 # length == 2 * area
    uniq, inv = weld(verts)
    acc = np.zeros_like(uniq, dtype=np.float64)
    for k in range(3):
        np.add.at(acc, inv[tris[:, k]], face)
    length = np.linalg.norm(acc, axis=1, keepdims=True)
    smooth = acc / np.maximum(length, 1e-12)
    # a point whose faces cancel out falls back to its own face normal
    corners = smooth[inv[tris.reshape(-1)]].reshape(-1, 3, 3)
    flat = face / np.maximum(np.linalg.norm(face, axis=1, keepdims=True), 1e-12)
    bad = np.linalg.norm(corners, axis=2) < 0.5
    if bad.any():
        for k in range(3):
            corners[:, k, :][bad[:, k]] = flat[bad[:, k]]
    return corners


def _ray_hits(origin, direction, a, b, c, eps=1e-7):
    """Moller-Trumbore for one origin/direction against many triangles."""
    e1 = b - a
    e2 = c - a
    h = np.cross(direction, e2)
    det = np.einsum("ij,ij->i", e1, h)
    ok = np.abs(det) > eps
    inv = np.zeros_like(det)
    inv[ok] = 1.0 / det[ok]
    s = origin - a
    u = inv * np.einsum("ij,ij->i", s, h)
    q = np.cross(s, e1)
    v = inv * np.einsum("ij,ij->i", np.broadcast_to(direction, q.shape), q)
    t = inv * np.einsum("ij,ij->i", e2, q)
    hit = ok & (u >= 0.0) & (v >= 0.0) & (u + v <= 1.0) & (t > 1e-4)
    if not hit.any():
        return np.full(len(t), np.inf)
    return np.where(hit, t, np.inf)


def smooth_field(verts: np.ndarray, tris: np.ndarray, values: np.ndarray,
                 passes: int = 2, mix: float = 0.5):
    """Diffuse a per-vertex value across the mesh graph.

    Ray-traced occlusion is quantised by the ray count, so at seven rays the
    darkening comes out in blotches. Averaging it with its neighbours a couple
    of times keeps the contact shadows (armpit, under the chin) while removing
    the speckle.
    """
    uniq, inv = weld(verts)
    edges = np.concatenate([tris[:, [0, 1]], tris[:, [1, 2]], tris[:, [2, 0]]])
    e = inv[edges]
    a, b = e[:, 0], e[:, 1]
    acc = np.zeros(len(uniq))
    count = np.zeros(len(uniq))
    for _ in range(passes):
        acc[:] = 0.0
        count[:] = 0.0
        np.add.at(acc, a, values[b])
        np.add.at(acc, b, values[a])
        np.add.at(count, a, 1.0)
        np.add.at(count, b, 1.0)
        avg = np.where(count > 0, acc / np.maximum(count, 1e-9), values)
        values = values * (1.0 - mix) + avg * mix
    return values[inv]


def bake_ao(verts: np.ndarray, tris: np.ndarray, normals: np.ndarray | None = None,
            rays: int = 14, distance: float = 0.35, strength: float = 0.62,
            chunk: int = 96, floor: float = 0.45):
    """Per-vertex occlusion in 0..1 (1 = open sky).

    Rays are traced from just above each vertex, so a vertex in a fold sees its
    neighbours and comes out dark, while one on the back of the animal sees
    nothing and stays white. Cost is rays x vertices x triangles, so vertices
    are processed in chunks to keep the temporary arrays small.
    """
    if len(tris) == 0:
        return np.ones(len(verts), dtype=np.float64)
    uniq, inv = weld(verts)
    if normals is None:
        corners = welded_normals(verts, tris)
        vnorm = np.zeros_like(uniq)
        np.add.at(vnorm, inv[tris.reshape(-1)], corners.reshape(-1, 3))
        vnorm /= np.maximum(np.linalg.norm(vnorm, axis=1, keepdims=True), 1e-9)
    else:
        vnorm = np.zeros_like(uniq)
        np.add.at(vnorm, inv, normals)
        vnorm /= np.maximum(np.linalg.norm(vnorm, axis=1, keepdims=True), 1e-9)
    a = verts[tris[:, 0]]
    b = verts[tris[:, 1]]
    c = verts[tris[:, 2]]
    hemi = _hemisphere(rays)
    out = np.ones(len(uniq), dtype=np.float64)
    for start in range(0, len(uniq), chunk):
        stop = min(start + chunk, len(uniq))
        block = uniq[start:stop]
        nrm = vnorm[start:stop]
        origin = block + nrm * 0.002
        hits = np.zeros(len(block), dtype=np.float64)
        for i in range(len(block)):
            t_axis, b_axis, n_axis = _orthonormal(nrm[i])
            # rotate the fixed hemisphere so it is never aligned with the mesh
            spin = (i * 2.399963229728653) % (2.0 * np.pi)
            ca, sa = np.cos(spin), np.sin(spin)
            dirs = (hemi[:, 0:1] * (t_axis * ca + b_axis * sa)
                    + hemi[:, 1:2] * (-t_axis * sa + b_axis * ca)
                    + hemi[:, 2:3] * n_axis)
            for d in dirs:
                t = _ray_hits(origin[i], d, a, b, c)
                hits[i] += 1.0 if float(np.min(t)) < distance else 0.0
        out[start:stop] = 1.0 - (hits / max(rays, 1)) * strength
    out = smooth_field(verts, tris, out, passes=2, mix=0.55)
    # mapped back onto the original (unwelded) vertices
    return np.clip(out[inv], floor, 1.0)


def vertex_shade(verts: np.ndarray, ao: np.ndarray, seed: int = 0,
                 ao_amount: float = 0.55, gradient: float = 0.14,
                 variation: float = 0.04):
    """Vertex colours (RGB multipliers) for baked shading.

    Three layers, all of them things a flat palette colour cannot express:
    the occlusion term, a soft top-to-bottom gradient (sunlit back, shaded
    belly) and a little low-frequency variation so a big hide is not a single
    unbroken tone.
    """
    y = verts[:, 1]
    span = max(float(y.max() - y.min()), 1e-6)
    up = (y - y.min()) / span
    shade = 1.0 - (1.0 - np.clip(ao, 0.0, 1.0)) * ao_amount
    shade = shade * (1.0 - gradient * 0.5 + gradient * up)
    # cheap value noise from the position, smooth across neighbours
    rng = np.random.default_rng(seed + 17)
    phase = rng.uniform(0.0, 6.283, 3)
    n = (np.sin(verts[:, 0] * 3.1 + phase[0])
         + np.sin(verts[:, 1] * 4.7 + phase[1])
         + np.sin(verts[:, 2] * 3.7 + phase[2])) / 3.0
    shade = shade * (1.0 + variation * n)
    shade = np.clip(shade, 0.35, 1.12)
    return np.stack([shade, shade, shade], axis=1)
