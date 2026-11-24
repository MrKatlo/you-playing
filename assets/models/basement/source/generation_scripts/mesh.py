"""Procedural low-poly mesh primitives.

Everything in the pack is assembled from a handful of building blocks
(lofted tubes, faceted spheres, boxes, folded blades) which keeps the art
style consistent and the polygon budget predictable.

Geometry is authored in metres, Y up, characters facing -Z (Godot forward).
Faces are emitted with any winding; `Builder.add` measures the signed volume
of closed shells and flips them if necessary, so normals always point outward.
"""
from __future__ import annotations

import math

import numpy as np


# --------------------------------------------------------------------- maths
def rotm(pitch=0.0, yaw=0.0, roll=0.0):
    """3x3 rotation, Rz(roll) @ Rx(pitch) @ Ry(yaw), degrees."""
    p, y, r = np.radians([pitch, yaw, roll])
    cp, sp = np.cos(p), np.sin(p)
    cy, sy = np.cos(y), np.sin(y)
    cr, sr = np.cos(r), np.sin(r)
    rx = np.array([[1, 0, 0], [0, cp, -sp], [0, sp, cp]])
    ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    rz = np.array([[cr, -sr, 0], [sr, cr, 0], [0, 0, 1]])
    return rz @ rx @ ry


def xform(verts, translate=(0, 0, 0), rotate=(0, 0, 0), scale=(1, 1, 1),
          pivot=(0, 0, 0)):
    v = np.array(verts, dtype=np.float64)
    v = (v - np.array(pivot, dtype=np.float64)) * np.array(scale, dtype=np.float64)
    v = v @ rotm(*rotate).T
    return v + np.array(translate, dtype=np.float64) + np.array(pivot, dtype=np.float64)


def normalize(v):
    v = np.asarray(v, dtype=np.float64)
    n = np.linalg.norm(v)
    return v / n if n > 1e-12 else v


# ------------------------------------------------------------------ topology
def triangulate(faces):
    out = []
    for f in faces:
        if len(f) == 3:
            out.append((int(f[0]), int(f[1]), int(f[2])))
        else:  # convex fan
            for i in range(1, len(f) - 1):
                out.append((int(f[0]), int(f[i]), int(f[i + 1])))
    return np.array(out, dtype=np.int32)


def face_normals(verts, tris):
    a = verts[tris[:, 0]]
    b = verts[tris[:, 1]]
    c = verts[tris[:, 2]]
    n = np.cross(b - a, c - a)
    length = np.linalg.norm(n, axis=1, keepdims=True)
    return n / np.maximum(length, 1e-12)


def tri_centers(verts, tris):
    return verts[tris].mean(axis=1)


def signed_volume(verts, tris):
    a = verts[tris[:, 0]]
    b = verts[tris[:, 1]]
    c = verts[tris[:, 2]]
    return float(np.sum(np.einsum("ij,ij->i", a, np.cross(b, c))) / 6.0)


# ------------------------------------------------------------------ pieces
class Piece:
    __slots__ = ("name", "verts", "tris", "mats", "bones", "smooth")

    def __init__(self, name, verts, tris, mats, bones=None, smooth=False):
        self.name = name
        self.verts = verts
        self.tris = tris
        self.mats = mats
        self.bones = bones
        self.smooth = smooth

    def transformed(self, translate=(0, 0, 0), rotate=(0, 0, 0),
                    scale=(1, 1, 1), pivot=(0, 0, 0)):
        return Piece(self.name,
                     xform(self.verts, translate, rotate, scale, pivot),
                     self.tris, self.mats, self.bones, self.smooth)


class Builder:
    """Collects pieces (each with one material or a per-face material list)."""

    def __init__(self):
        self.pieces: list[Piece] = []

    # -- low level ---------------------------------------------------------
    def add(self, verts, faces, mat, bones=None, name="", fix_winding=True,
            smooth=False):
        verts = np.asarray(verts, dtype=np.float64)
        tris = triangulate(faces)
        if len(tris) == 0:
            return
        # drop degenerate triangles
        a, b, c = verts[tris[:, 0]], verts[tris[:, 1]], verts[tris[:, 2]]
        area = np.linalg.norm(np.cross(b - a, c - a), axis=1)
        keep = area > 1e-12
        if not keep.all():
            tris = tris[keep]
            if len(tris) == 0:
                return
        if fix_winding and signed_volume(verts, tris) < 0:
            tris = tris[:, ::-1].copy()
        if callable(mat):
            nrm = face_normals(verts, tris)
            cen = tri_centers(verts, tris)
            mats = [mat(cen[i], nrm[i]) for i in range(len(tris))]
        else:
            mats = [mat] * len(tris)
        self.pieces.append(Piece(name, verts, tris, mats, bones, smooth))
        return self.pieces[-1]

    def extend(self, pieces):
        self.pieces.extend(pieces)

    # -- primitives --------------------------------------------------------
    def add_loft(self, stations, seg=10, mat="rock_grey", bones=None,
                 cap_start=True, cap_end=True, shape=None, name="",
                 smooth=False, strip_mats=None):
        """Loft a closed tube through `stations`.

        stations: list of dicts {"pos": (x,y,z), "rx": float, "ry": float,
                   optional "roll": deg, optional "shape": f(angle)->(fx,fy)}.
        """
        pos = np.array([s["pos"] for s in stations], dtype=np.float64)
        rx = np.array([s.get("rx", 0.1) for s in stations], dtype=np.float64)
        ry = np.array([s.get("ry", 0.1) for s in stations], dtype=np.float64)
        rolls = np.radians([s.get("roll", 0.0) for s in stations])
        n = len(stations)

        tangents = np.zeros_like(pos)
        for i in range(n):
            if i == 0:
                t = pos[1] - pos[0]
            elif i == n - 1:
                t = pos[-1] - pos[-2]
            else:
                t = pos[i + 1] - pos[i - 1]
            tangents[i] = normalize(t)

        verts = []
        carried = None
        for i in range(n):
            t = tangents[i]
            # Carry the ring frame along the path instead of rebuilding it from
            # a fixed world axis. Rebuilding it means the reference vector
            # flips whenever the path passes the near-vertical, and every ring
            # past that point is rotated by up to 90 degrees: a leg lofted this
            # way comes out as a stack of offset blocks with a twist in it.
            if carried is None:
                ref = np.array([0.0, 1.0, 0.0])
                if abs(float(np.dot(t, ref))) > 0.9:
                    ref = np.array([0.0, 0.0, 1.0])
                right = normalize(np.cross(ref, t))
            else:
                right = carried - t * float(np.dot(carried, t))
                length = np.linalg.norm(right)
                if length < 1e-6:
                    right = normalize(np.cross(np.array([1.0, 0.0, 0.0]), t))
                else:
                    right = right / length
            up = normalize(np.cross(t, right))
            carried = right
            rr = rolls[i]
            if rr:
                right, up = (right * np.cos(rr) + up * np.sin(rr),
                             -right * np.sin(rr) + up * np.cos(rr))
            shp = stations[i].get("shape", shape)
            for k in range(seg):
                th = 2.0 * math.pi * k / seg
                fx, fy = shp(th) if shp else (1.0, 1.0)
                verts.append(pos[i] + right * (rx[i] * math.cos(th) * fx)
                             + up * (ry[i] * math.sin(th) * fy))

        faces = []
        for i in range(n - 1):
            for k in range(seg):
                k2 = (k + 1) % seg
                faces.append((i * seg + k, i * seg + k2,
                              (i + 1) * seg + k2, (i + 1) * seg + k))
        if cap_start:
            ci = len(verts)
            verts.append(pos[0].copy())
            for k in range(seg):
                faces.append((ci, (k + 1) % seg, k))
        if cap_end:
            ci = len(verts)
            verts.append(pos[-1].copy())
            base = (n - 1) * seg
            for k in range(seg):
                faces.append((ci, base + k, base + (k + 1) % seg))
        piece = self.add(np.array(verts), faces, mat, bones, name or "loft",
                         smooth=smooth)
        if strip_mats is not None and piece is not None:
            # Colour one band of quads at a time instead of testing each face's
            # centre. A centroid test cuts through the middle of a quad, so a
            # stripe boundary comes out as a saw-tooth; colouring the strip
            # gives the straight edge a stripe should have. `strip_mats` is a
            # list or an f(strip_index) -> material name.
            n_strips = n - 1
            expect = (n_strips * seg * 2
                      + (seg if cap_start else 0) + (seg if cap_end else 0))
            if len(piece.mats) == expect:
                pick = strip_mats if callable(strip_mats) else \
                    lambda i: strip_mats[min(i, n_strips - 1)]
                mats = []
                for i in range(n_strips):
                    mats.extend([pick(i)] * (seg * 2))
                cap = mat if isinstance(mat, str) else "rock_grey"
                mats.extend([cap] * (expect - len(mats)))
                piece.mats = mats
        return piece

    def add_tube(self, p0, p1, r0, r1, seg=8, mat="bark", bones=None,
                 rings=1, shape=None, name="", smooth=False):
        p0 = np.array(p0, dtype=np.float64)
        p1 = np.array(p1, dtype=np.float64)
        stations = []
        for i in range(rings + 1):
            t = i / rings
            r = r0 + (r1 - r0) * t
            stations.append({"pos": p0 + (p1 - p0) * t, "rx": r, "ry": r,
                             "shape": shape})
        return self.add_loft(stations, seg=seg, mat=mat, bones=bones,
                             name=name or "tube", smooth=smooth)

    def add_ico(self, center, radii, subdiv=1, mat="rock_grey", bones=None,
                jitter=0.0, seed=0, rotate=(0, 0, 0), name="", smooth=False):
        verts, faces = icosphere(subdiv)
        rng = np.random.default_rng(seed)
        if jitter:
            scale = 1.0 + rng.uniform(-jitter, jitter, (len(verts), 1))
            verts = verts * scale
        verts = verts * np.array(radii, dtype=np.float64)
        verts = verts @ rotm(*rotate).T + np.array(center, dtype=np.float64)
        return self.add(verts, faces, mat, bones, name or "ico", smooth=smooth)

    def add_sphere(self, center, radii, seg=8, rings=5, mat="rock_grey",
                   bones=None, rotate=(0, 0, 0), name="", smooth=False):
        verts, faces = uvsphere(seg, rings)
        verts = verts * np.array(radii, dtype=np.float64)
        verts = verts @ rotm(*rotate).T + np.array(center, dtype=np.float64)
        return self.add(verts, faces, mat, bones, name or "sphere",
                        smooth=smooth)

    def add_box(self, center, size, mat="bark", bones=None, rotate=(0, 0, 0),
                name=""):
        verts, faces = box_mesh()
        verts = verts * np.array(size, dtype=np.float64)
        verts = verts @ rotm(*rotate).T + np.array(center, dtype=np.float64)
        return self.add(verts, faces, mat, bones, name or "box")

    def add_cone(self, base, radius, height, seg=6, mat="bark", bones=None,
                 tilt=(0, 0, 0), name=""):
        verts, faces = cone_mesh(radius, height, seg)
        verts = verts @ rotm(*tilt).T + np.array(base, dtype=np.float64)
        return self.add(verts, faces, mat, bones, name or "cone")

    def add_disc(self, center, radius, seg=10, mat="sand", rot=(0, 0, 0),
                 name="", rx=None, ry=None):
        verts = [np.array(center, dtype=np.float64)]
        for k in range(seg):
            th = 2 * math.pi * k / seg
            verts.append(np.array(center) + rotm(*rot) @ np.array(
                [(rx or radius) * math.cos(th), 0.0, (ry or radius) * math.sin(th)]))
        faces = [(0, k + 1, (k + 1) % seg + 1) for k in range(seg)]
        return self.add(np.array(verts), faces, mat, None, name or "disc")

    def add_blade(self, path, widths, mat="grass", bones=None, fold=0.35,
                  normal=(0, 1, 0), name=""):
        """Folded ribbon (grass blade / leaf) following a polyline."""
        path = np.array(path, dtype=np.float64)
        n = len(path)
        nrm = normalize(normal)
        verts = []
        for i in range(n):
            if i == 0:
                t = path[1] - path[0]
            elif i == n - 1:
                t = path[-1] - path[-2]
            else:
                t = path[i + 1] - path[i - 1]
            side = normalize(np.cross(nrm, t))
            w = widths[min(i, len(widths) - 1)]
            verts += [path[i] - side * w, path[i] + nrm * (w * fold),
                      path[i] + side * w]
        faces = []
        for i in range(n - 1):
            for k in range(2):
                a = i * 3 + k
                faces.append((a, a + 1, a + 4, a + 3))
        return self.add(np.array(verts), faces, mat, bones, name or "blade")

    def add_quad(self, p0, p1, p2, p3, mat, bones=None, name=""):
        return self.add(np.array([p0, p1, p2, p3], dtype=np.float64),
                        [(0, 1, 2, 3)], mat, bones, name or "quad")


# ------------------------------------------------------------------ meshers
def box_mesh():
    v = np.array([[-1, -1, -1], [1, -1, -1], [1, 1, -1], [-1, 1, -1],
                  [-1, -1, 1], [1, -1, 1], [1, 1, 1], [-1, 1, 1]], dtype=np.float64) * 0.5
    f = [(0, 1, 2, 3), (4, 5, 6, 7), (0, 1, 5, 4), (2, 3, 7, 6),
         (0, 3, 7, 4), (1, 2, 6, 5)]
    return v, f


def cone_mesh(radius, height, seg=6):
    v = [np.array([0, 0, 0])]
    for k in range(seg):
        th = 2 * math.pi * k / seg
        v.append(np.array([radius * math.cos(th), 0, radius * math.sin(th)]))
    apex = len(v)
    v.append(np.array([0, height, 0]))
    faces = []
    for k in range(seg):
        faces.append((0, k + 1, (k + 1) % seg + 1))
        faces.append((apex, k + 1, (k + 1) % seg + 1))
    return np.array(v), faces


def uvsphere(seg=8, rings=5):
    verts = [np.array([0.0, 1.0, 0.0])]
    for r in range(1, rings):
        phi = math.pi * r / rings
        y = math.cos(phi)
        rad = math.sin(phi)
        for k in range(seg):
            th = 2 * math.pi * k / seg
            verts.append(np.array([rad * math.cos(th), y, rad * math.sin(th)]))
    verts.append(np.array([0.0, -1.0, 0.0]))
    faces = []
    for k in range(seg):
        faces.append((0, 1 + k, 1 + (k + 1) % seg))
    for r in range(rings - 2):
        for k in range(seg):
            a = 1 + r * seg + k
            b = 1 + r * seg + (k + 1) % seg
            c = 1 + (r + 1) * seg + (k + 1) % seg
            d = 1 + (r + 1) * seg + k
            faces.append((a, b, c, d))
    last = len(verts) - 1
    base = 1 + (rings - 2) * seg
    for k in range(seg):
        faces.append((last, base + (k + 1) % seg, base + k))
    return np.array(verts, dtype=np.float64), faces


def icosphere(subdiv=1):
    t = (1.0 + math.sqrt(5.0)) / 2.0
    verts = [np.array(v) for v in [
        (-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0),
        (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t),
        (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)]]
    verts = [normalize(v) for v in verts]
    faces = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11),
             (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8),
             (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9),
             (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    for _ in range(subdiv):
        cache = {}
        new_faces = []

        def midpoint(a, b):
            key = (min(a, b), max(a, b))
            if key not in cache:
                verts.append(normalize((verts[a] + verts[b]) / 2.0))
                cache[key] = len(verts) - 1
            return cache[key]

        for a, b, c in faces:
            ab, bc, ca = midpoint(a, b), midpoint(b, c), midpoint(c, a)
            new_faces += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
        faces = new_faces
    return np.array(verts, dtype=np.float64), [tuple(f) for f in faces]
