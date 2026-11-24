"""Minimal but complete glTF 2.0 / GLB writer.

Deliberately dependency-light (numpy only) so the whole asset pack can be
regenerated from source with a single command.

Features used by the pack:
  * indexed triangle meshes split into one primitive per material
  * flat (faceted) normals produced by the mesh builder
  * 4-influence linear blend skinning (JOINTS_0 / WEIGHTS_0 + inverse bind mats)
  * node hierarchies for bone chains
  * baked TRS animation channels (LINEAR interpolation -> slerp for rotations)
"""
from __future__ import annotations

import json
import struct

import numpy as np

COMPONENT_TYPE = {
    "float32": 5126, "uint16": 5123, "uint32": 5125,
    "uint8": 5121, "int16": 5122,
}
COMPONENT_SIZE = {5126: 4, 5123: 2, 5125: 4, 5121: 1, 5122: 2}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}

ARRAY_BUFFER = 34962
ELEMENT_ARRAY_BUFFER = 34963


def srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def hex_to_linear(h: str, alpha: float = 1.0):
    h = h.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    return [srgb_to_linear(r), srgb_to_linear(g), srgb_to_linear(b), alpha]


def mat4_identity():
    return np.eye(4, dtype=np.float64)


def quat_from_matrix(m: np.ndarray):
    """Convert a 3x3 rotation matrix to a (x, y, z, w) quaternion."""
    t = m[0, 0] + m[1, 1] + m[2, 2]
    if t > 0.0:
        s = np.sqrt(t + 1.0) * 2.0
        w = 0.25 * s
        x = (m[2, 1] - m[1, 2]) / s
        y = (m[0, 2] - m[2, 0]) / s
        z = (m[1, 0] - m[0, 1]) / s
    elif m[0, 0] > m[1, 1] and m[0, 0] > m[2, 2]:
        s = np.sqrt(1.0 + m[0, 0] - m[1, 1] - m[2, 2]) * 2.0
        w = (m[2, 1] - m[1, 2]) / s
        x = 0.25 * s
        y = (m[0, 1] + m[1, 0]) / s
        z = (m[0, 2] + m[2, 0]) / s
    elif m[1, 1] > m[2, 2]:
        s = np.sqrt(1.0 + m[1, 1] - m[0, 0] - m[2, 2]) * 2.0
        w = (m[0, 2] - m[2, 0]) / s
        x = (m[0, 1] + m[1, 0]) / s
        y = 0.25 * s
        z = (m[1, 2] + m[2, 1]) / s
    else:
        s = np.sqrt(1.0 + m[2, 2] - m[0, 0] - m[1, 1]) * 2.0
        w = (m[1, 0] - m[0, 1]) / s
        x = (m[0, 2] + m[2, 0]) / s
        y = (m[1, 2] + m[2, 1]) / s
        z = 0.25 * s
    q = np.array([x, y, z, w], dtype=np.float64)
    return q / np.linalg.norm(q)


def euler_to_matrix(pitch: float, yaw: float, roll: float) -> np.ndarray:
    """R = Rz(roll) @ Rx(pitch) @ Ry(yaw), angles in degrees, applied to column vectors."""
    p, y, r = np.radians([pitch, yaw, roll])
    cp, sp = np.cos(p), np.sin(p)
    cy, sy = np.cos(y), np.sin(y)
    cr, sr = np.cos(r), np.sin(r)
    rx = np.array([[1, 0, 0], [0, cp, -sp], [0, sp, cp]], dtype=np.float64)
    ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]], dtype=np.float64)
    rz = np.array([[cr, -sr, 0], [sr, cr, 0], [0, 0, 1]], dtype=np.float64)
    return rz @ rx @ ry


def euler_to_quat(pitch: float, yaw: float, roll: float):
    return quat_from_matrix(euler_to_matrix(pitch, yaw, roll))


class GLTF:
    def __init__(self, generator="Otter Low-Poly Asset Pack generator"):
        self.json = {
            "asset": {"version": "2.0", "generator": generator},
            "scene": 0,
            "scenes": [{"nodes": []}],
            "nodes": [],
            "meshes": [],
            "materials": [],
            "accessors": [],
            "bufferViews": [],
            "skins": [],
            "animations": [],
            "images": [],
            "samplers": [],
            "textures": [],
        }
        self.bin = bytearray()
        self._time_accessors = {}
        self._texture_cache = {}

    # ------------------------------------------------------------- buffer
    def _view(self, array: np.ndarray, target=None) -> int:
        array = np.ascontiguousarray(array)
        while len(self.bin) % 4:
            self.bin.append(0)
        offset = len(self.bin)
        self.bin += array.tobytes()
        view = {
            "buffer": 0, "byteOffset": offset,
            "byteLength": array.nbytes,
        }
        if target is not None:
            view["target"] = target
        self.json["bufferViews"].append(view)
        return len(self.json["bufferViews"]) - 1

    def accessor(self, array: np.ndarray, atype: str, target=None,
                 minmax=False) -> int:
        array = np.ascontiguousarray(array)
        if array.dtype == np.float64:
            array = array.astype(np.float32)
        ctype = COMPONENT_TYPE[str(array.dtype)]
        view = self._view(array, target)
        acc = {
            "bufferView": view,
            "componentType": ctype,
            "count": int(array.size // NCOMP[atype]),
            "type": atype,
        }
        if minmax:
            flat = array.reshape(-1, NCOMP[atype]).astype(np.float64)
            acc["min"] = [float(v) for v in flat.min(axis=0)]
            acc["max"] = [float(v) for v in flat.max(axis=0)]
        self.json["accessors"].append(acc)
        return len(self.json["accessors"]) - 1

    def _time_accessor(self, times: np.ndarray) -> int:
        key = tuple(np.round(times, 6))
        if key not in self._time_accessors:
            self._time_accessors[key] = self.accessor(
                times.astype(np.float32), "SCALAR", minmax=True)
        return self._time_accessors[key]

    # ------------------------------------------------------------ textures
    def image_png(self, data: bytes, name: str = "detail") -> int:
        """Embed a PNG in the binary chunk and register it as an image."""
        array = np.frombuffer(data, dtype=np.uint8).copy()
        view = self._view(array)
        self.json["images"].append({
            "name": name, "bufferView": view, "mimeType": "image/png",
        })
        return len(self.json["images"]) - 1

    def sampler(self, wrap: int = 10497) -> int:
        """Repeat-wrap, trilinear sampler (10497 = REPEAT)."""
        self.json["samplers"].append({
            "magFilter": 9729, "minFilter": 9987,
            "wrapS": wrap, "wrapT": wrap,
        })
        return len(self.json["samplers"]) - 1

    def texture(self, image: int, sampler: int) -> int:
        self.json["textures"].append({"sampler": sampler, "source": image})
        return len(self.json["textures"]) - 1

    def base_color_texture(self, png: bytes, name: str = "detail") -> int:
        """One shared image + sampler, reused by every material."""
        if name in self._texture_cache:
            return self._texture_cache[name]
        image = self.image_png(png, name)
        sampler = self.sampler()
        index = self.texture(image, sampler)
        self._texture_cache[name] = index
        return index

    # ----------------------------------------------------------- materials
    def material(self, name: str, base_color, roughness=0.85, metallic=0.0,
                 double_sided=False, alpha=1.0, emissive=None,
                 base_color_texture: int | None = None) -> int:
        for i, mat in enumerate(self.json["materials"]):
            if mat["name"] == name:
                return i
        pbr = {
            "baseColorFactor": list(base_color),
            "metallicFactor": metallic,
            "roughnessFactor": roughness,
        }
        if base_color_texture is not None:
            pbr["baseColorTexture"] = {
                "index": int(base_color_texture), "texCoord": 0,
            }
        mat = {"name": name, "pbrMetallicRoughness": pbr}
        if alpha < 1.0:
            mat["alphaMode"] = "BLEND"
        if double_sided:
            mat["doubleSided"] = True
        if emissive is not None:
            mat["emissiveFactor"] = list(emissive)
        self.json["materials"].append(mat)
        return len(self.json["materials"]) - 1

    # ---------------------------------------------------------------- node
    def node(self, name, *, mesh=None, skin=None, children=None,
             translation=None, rotation=None, scale=None) -> int:
        n = {"name": name}
        if mesh is not None:
            n["mesh"] = mesh
        if skin is not None:
            n["skin"] = skin
        if children:
            n["children"] = list(children)
        if translation is not None:
            n["translation"] = [float(v) for v in translation]
        if rotation is not None:
            n["rotation"] = [float(v) for v in rotation]
        if scale is not None:
            n["scale"] = [float(v) for v in scale]
        self.json["nodes"].append(n)
        return len(self.json["nodes"]) - 1

    def add_to_scene(self, node_index: int):
        self.json["scenes"][0]["nodes"].append(node_index)

    # ---------------------------------------------------------------- mesh
    def mesh(self, name, primitives) -> int:
        """primitives: list of dicts with 'attributes', optional 'indices', 'material'."""
        prims = []
        for p in primitives:
            prim = {"attributes": dict(p["attributes"])}
            if p.get("indices") is not None:
                prim["indices"] = p["indices"]
            if p.get("material") is not None:
                prim["material"] = p["material"]
            prim["mode"] = 4  # TRIANGLES
            prims.append(prim)
        self.json["meshes"].append({"name": name, "primitives": prims})
        return len(self.json["meshes"]) - 1

    # --------------------------------------------------------------- skins
    def skin(self, joints, inverse_bind_matrices, skeleton=None) -> int:
        skin = {
            "joints": list(joints),
            "inverseBindMatrices": inverse_bind_matrices,
        }
        if skeleton is not None:
            skin["skeleton"] = skeleton
        self.json["skins"].append(skin)
        return len(self.json["skins"]) - 1

    # ---------------------------------------------------------- animations
    def animation(self, name, channels) -> int:
        """channels: list of (node_index, path, times, values) where values are
        (n, 4) quaternions for 'rotation' or (n, 3) vectors for translation/scale."""
        samplers, chans = [], []
        for node_index, path, times, values in channels:
            values = np.ascontiguousarray(values, dtype=np.float32)
            if path == "rotation":
                atype = "VEC4"
            else:
                atype = "VEC3"
            sampler = {
                "input": self._time_accessor(np.asarray(times, dtype=np.float32)),
                "output": self.accessor(values, atype),
                "interpolation": "LINEAR",
            }
            samplers.append(sampler)
            chans.append({
                "sampler": len(samplers) - 1,
                "target": {"node": node_index, "path": path},
            })
        self.json["animations"].append({
            "name": name, "samplers": samplers, "channels": chans,
        })
        return len(self.json["animations"]) - 1

    # --------------------------------------------------------------- output
    def write(self, path):
        while len(self.bin) % 4:
            self.bin.append(0)
        self.json["buffers"] = [{"byteLength": len(self.bin)}]
        js = json.dumps(self.json, separators=(",", ":")).encode("utf-8")
        js += b" " * ((4 - len(js) % 4) % 4)
        out = bytearray()
        out += struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(self.bin))
        out += struct.pack("<II", len(js), 0x4E4F534A) + js
        out += struct.pack("<II", len(self.bin), 0x004E4942) + self.bin
        with open(path, "wb") as fh:
            fh.write(out)
        return len(out)
