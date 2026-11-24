"""Structural validator for the generated GLB files.

Checks the parts of the glTF 2.0 spec that matter for a game asset pack:
buffer/accessor bounds, triangle indices, skin joints and inverse bind
matrices, skin weight normalisation, animation sampler validity and node
hierarchy integrity. Run as a script to print a report:

    python validate.py <pack_root>
"""
from __future__ import annotations

import json
import os
import struct
import sys

import numpy as np

COMPONENT = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2), 5123: ("H", 2),
             5125: ("I", 4), 5126: ("f", 4)}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def load_glb(path):
    with open(path, "rb") as fh:
        data = fh.read()
    magic, version, length = struct.unpack("<III", data[:12])
    assert magic == 0x46546C67, "bad magic"
    assert version == 2, "bad version"
    assert length == len(data), f"length mismatch {length} vs {len(data)}"
    offset = 12
    js, bin_chunk = None, b""
    while offset < len(data):
        clen, ctype = struct.unpack("<II", data[offset:offset + 8])
        chunk = data[offset + 8:offset + 8 + clen]
        if ctype == 0x4E4F534A:
            js = json.loads(chunk.decode("utf-8"))
        elif ctype == 0x004E4942:
            bin_chunk = chunk
        offset += 8 + clen
    assert js is not None, "no JSON chunk"
    return js, bin_chunk, len(data)


def read_accessor(gltf, blob, index):
    acc = gltf["accessors"][index]
    view = gltf["bufferViews"][acc["bufferView"]]
    fmt, size = COMPONENT[acc["componentType"]]
    n = NCOMP[acc["type"]]
    count = acc["count"]
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    raw = blob[start:start + count * n * size]
    arr = np.frombuffer(raw, dtype=np.dtype(fmt)).reshape(count, n)
    return arr


def validate(path):
    issues = []
    info = {"file": path}
    try:
        gltf, blob, size = load_glb(path)
    except Exception as exc:  # noqa: BLE001
        return {"file": path, "issues": [f"parse error: {exc}"], "ok": False}

    info["bytes"] = size
    buffer_len = gltf["buffers"][0]["byteLength"]
    if buffer_len > len(blob):
        issues.append(f"buffer declares {buffer_len} bytes but bin chunk is {len(blob)}")
    for i, view in enumerate(gltf.get("bufferViews", [])):
        end = view.get("byteOffset", 0) + view["byteLength"]
        if end > buffer_len:
            issues.append(f"bufferView {i} overruns buffer ({end} > {buffer_len})")

    for i, acc in enumerate(gltf["accessors"]):
        if "bufferView" not in acc:
            issues.append(f"accessor {i} has no bufferView")
            continue
        view = gltf["bufferViews"][acc["bufferView"]]
        elem = COMPONENT[acc["componentType"]][1] * NCOMP[acc["type"]]
        need = acc.get("byteOffset", 0) + elem * acc["count"]
        if need > view["byteLength"]:
            issues.append(f"accessor {i} overruns its bufferView ({need} > {view['byteLength']})")
        if acc["count"] <= 0:
            issues.append(f"accessor {i} has count 0")

    tris = 0
    verts = 0
    skins = gltf.get("skins", [])
    for mesh in gltf.get("meshes", []):
        for primitive in mesh["primitives"]:
            attrs = primitive["attributes"]
            if "POSITION" not in attrs:
                issues.append(f"mesh '{mesh.get('name')}' primitive has no POSITION")
                continue
            pos_acc = gltf["accessors"][attrs["POSITION"]]
            verts += pos_acc["count"]
            if "min" not in pos_acc or "max" not in pos_acc:
                issues.append(f"mesh '{mesh.get('name')}' POSITION lacks min/max")
            idx = primitive.get("indices")
            if idx is not None:
                idx_data = read_accessor(gltf, blob, idx)
                tris += len(idx_data) // 3
                if len(idx_data) % 3:
                    issues.append(f"mesh '{mesh.get('name')}' index count not a multiple of 3")
                if int(idx_data.max()) >= pos_acc["count"]:
                    issues.append(f"mesh '{mesh.get('name')}' index out of range")
            if "NORMAL" in attrs:
                n_acc = gltf["accessors"][attrs["NORMAL"]]
                if n_acc["count"] != pos_acc["count"]:
                    issues.append(f"mesh '{mesh.get('name')}' NORMAL count mismatch")
            if "JOINTS_0" in attrs or "WEIGHTS_0" in attrs:
                if "JOINTS_0" not in attrs or "WEIGHTS_0" not in attrs:
                    issues.append(f"mesh '{mesh.get('name')}' incomplete skin attributes")
                    continue
                j = read_accessor(gltf, blob, attrs["JOINTS_0"])
                w = read_accessor(gltf, blob, attrs["WEIGHTS_0"]).astype(np.float64)
                if len(j) != pos_acc["count"]:
                    issues.append(f"mesh '{mesh.get('name')}' JOINTS_0 count mismatch")
                sums = w.sum(axis=1)
                if np.abs(sums - 1.0).max() > 1e-3:
                    issues.append(f"mesh '{mesh.get('name')}' weights not normalised "
                                  f"(max error {np.abs(sums - 1.0).max():.4f})")
                if (w < -1e-6).any():
                    issues.append(f"mesh '{mesh.get('name')}' has negative weights")
                if skins:
                    max_joint = int(j.max())
                    if max_joint >= len(skins[0]["joints"]):
                        issues.append(f"mesh '{mesh.get('name')}' joint index out of range")
    info["triangles"] = tris
    info["vertices"] = verts

    for i, skin in enumerate(skins):
        joints = skin["joints"]
        if any(j >= len(gltf["nodes"]) for j in joints):
            issues.append(f"skin {i} references missing joint nodes")
        if "inverseBindMatrices" in skin:
            ibm = read_accessor(gltf, blob, skin["inverseBindMatrices"])
            if len(ibm) != len(joints):
                issues.append(f"skin {i} inverse bind count {len(ibm)} != joints {len(joints)}")
        else:
            issues.append(f"skin {i} has no inverseBindMatrices")
    info["bones"] = len(skins[0]["joints"]) if skins else 0

    nodes = gltf.get("nodes", [])
    for i, node in enumerate(nodes):
        for c in node.get("children", []):
            if c >= len(nodes):
                issues.append(f"node {i} has invalid child {c}")
        if "mesh" in node and node["mesh"] >= len(gltf.get("meshes", [])):
            issues.append(f"node {i} has invalid mesh")
        if "skin" in node and node["skin"] >= len(skins):
            issues.append(f"node {i} has invalid skin")

    anims = []
    for anim in gltf.get("animations", []):
        name = anim.get("name", "?")
        duration = 0.0
        for channel in anim["channels"]:
            target = channel["target"]
            if target["node"] >= len(nodes):
                issues.append(f"anim '{name}' targets missing node")
            sampler = anim["samplers"][channel["sampler"]]
            times = read_accessor(gltf, blob, sampler["input"]).astype(np.float64).ravel()
            values = read_accessor(gltf, blob, sampler["output"])
            if len(times) != len(values):
                issues.append(f"anim '{name}' sampler input/output length mismatch")
            if len(times) < 2:
                issues.append(f"anim '{name}' sampler has fewer than 2 keys")
            if np.any(np.diff(times) < -1e-6):
                issues.append(f"anim '{name}' key times are not monotonic")
            duration = max(duration, float(times.max()))
            if target["path"] == "rotation":
                norms = np.linalg.norm(values, axis=1)
                if np.abs(norms - 1.0).max() > 1e-3:
                    issues.append(f"anim '{name}' has non-unit quaternions")
        anims.append({"name": name, "duration": round(duration, 3),
                      "channels": len(anim["channels"])})
    info["animations"] = sorted(anims, key=lambda a: a["name"])
    info["ok"] = not issues
    info["issues"] = issues
    return info


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "build/otter_lowpoly_asset_pack"
    files = []
    for dirpath, _, filenames in os.walk(root):
        for f in sorted(filenames):
            if f.endswith(".glb"):
                files.append(os.path.join(dirpath, f))
    files.sort()
    bad = 0
    for f in files:
        info = validate(f)
        rel = os.path.relpath(f, root).replace("\\", "/")
        status = "OK " if info.get("ok") else "FAIL"
        detail = (f"{info.get('triangles', 0):5d} tris  "
                  f"{info.get('bones', 0):2d} bones  "
                  f"{len(info.get('animations', [])):2d} anims")
        print(f"{status} {rel:58s} {detail}")
        if not info.get("ok"):
            bad += 1
            for issue in info["issues"][:6]:
                print("       -", issue)
    print(f"\n{len(files)} files, {bad} with issues")
    return 0 if bad == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
