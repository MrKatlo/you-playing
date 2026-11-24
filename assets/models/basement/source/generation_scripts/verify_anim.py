"""Source-to-GLB animation verifier for Basement Farm generated creatures.

It evaluates baked GLB skinning at exact exported key times and compares the
resulting bounding box with the same source rig pose. This catches the subtle
failure where a file imports and lists clips, but bone nodes, weights, or baked
rotation channels no longer match the source animation.
"""
from __future__ import annotations

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

import numpy as np

from creature_anims import build_slime_clips
from creatures import build_slime
from gltf import quat_from_matrix
from validate import load_glb, read_accessor


def _slerp(a: np.ndarray, b: np.ndarray, fraction: float) -> np.ndarray:
    dot = float(np.dot(a, b))
    if dot < 0.0:
        b = -b
        dot = -dot
    if dot > 0.9995:
        result = a + (b - a) * fraction
        return result / np.linalg.norm(result)
    theta = math.acos(max(-1.0, min(1.0, dot)))
    sine = math.sin(theta)
    return (math.sin((1.0 - fraction) * theta) / sine) * a + \
        (math.sin(fraction * theta) / sine) * b


def _quat_matrix(quat: np.ndarray) -> np.ndarray:
    x, y, z, w = quat
    return np.array([
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
    ], dtype=np.float64)


def evaluate_glb(path: str, clip_name: str, time_s: float) -> np.ndarray:
    """Evaluate one baked animation from a GLB and return skinned vertices."""
    gltf, blob, _ = load_glb(path)
    nodes = gltf["nodes"]
    parents: dict[int, int] = {}
    for index, node in enumerate(nodes):
        for child in node.get("children", []):
            parents[child] = index

    rest_translation = np.array(
        [node.get("translation", [0.0, 0.0, 0.0]) for node in nodes], dtype=np.float64)
    rest_rotation = np.array(
        [node.get("rotation", [0.0, 0.0, 0.0, 1.0]) for node in nodes], dtype=np.float64)
    translation = rest_translation.copy()
    rotation = rest_rotation.copy()

    animation = next(item for item in gltf["animations"] if item["name"] == clip_name)
    for channel in animation["channels"]:
        target = channel["target"]
        sampler = animation["samplers"][channel["sampler"]]
        times = read_accessor(gltf, blob, sampler["input"]).astype(np.float64).ravel()
        values = read_accessor(gltf, blob, sampler["output"]).astype(np.float64)
        sample_time = min(max(time_s, float(times[0])), float(times[-1]))
        start = max(0, min(int(np.searchsorted(times, sample_time) - 1), len(times) - 2))
        span = max(float(times[start + 1] - times[start]), 1e-9)
        fraction = (sample_time - float(times[start])) / span
        node_index = target["node"]
        if target["path"] == "rotation":
            rotation[node_index] = _slerp(values[start], values[start + 1], fraction)
        elif target["path"] == "translation":
            translation[node_index] = values[start] + (values[start + 1] - values[start]) * fraction

    worlds: dict[int, np.ndarray] = {}

    def world(index: int) -> np.ndarray:
        if index in worlds:
            return worlds[index]
        matrix = np.eye(4, dtype=np.float64)
        matrix[:3, :3] = _quat_matrix(rotation[index])
        matrix[:3, 3] = translation[index]
        parent = parents.get(index)
        worlds[index] = world(parent) @ matrix if parent is not None else matrix
        return worlds[index]

    skin = gltf["skins"][0]
    inverse_bind = read_accessor(gltf, blob, skin["inverseBindMatrices"]).reshape(-1, 4, 4)
    inverse_bind = np.transpose(inverse_bind, (0, 2, 1))
    joints = np.array([world(node) @ inverse_bind[index]
                       for index, node in enumerate(skin["joints"])])
    mesh_node = next(node for node in nodes if "mesh" in node)
    primitives = gltf["meshes"][mesh_node["mesh"]]["primitives"]
    all_vertices: list[np.ndarray] = []
    for primitive in primitives:
        attributes = primitive["attributes"]
        positions = read_accessor(gltf, blob, attributes["POSITION"])
        vertex_joints = read_accessor(gltf, blob, attributes["JOINTS_0"]).astype(int)
        weights = read_accessor(gltf, blob, attributes["WEIGHTS_0"]).astype(np.float64)
        deformed = np.zeros_like(positions, dtype=np.float64)
        homogeneous = np.concatenate([positions, np.ones((len(positions), 1))], axis=1)
        for influence in range(4):
            matrices = joints[vertex_joints[:, influence]]
            deformed += weights[:, influence:influence + 1] * \
                np.einsum("nij,nj->ni", matrices, homogeneous)[:, :3]
        all_vertices.append(deformed)
    return np.concatenate(all_vertices)


def source_vertices(builder, rig, pose: dict) -> np.ndarray:
    """Evaluate exactly the source mesh/skin pose for a comparison sample."""
    return np.concatenate([
        rig.skin_points(piece.verts, *rig.weights(piece.verts, piece.bones), pose)
        for piece in builder.pieces
    ])


def verify(path: str, verbose: bool = True) -> dict:
    """Compare all Basement slime clips at four exact baked key times."""
    builder, rig = build_slime()
    rig.finalize()
    clips = build_slime_clips()
    samples: list[dict] = []
    worst_m = 0.0
    for clip in clips:
        # Clip duration * 30 is always integral for current source clips.
        for frame_fraction in (0.0, 0.25, 0.5, 0.75):
            frame = int(round((clip.duration * 30.0) * frame_fraction))
            time_s = frame / 30.0
            pose = clip.pose_fn(time_s)
            source = source_vertices(builder, rig, pose)
            baked = evaluate_glb(path, clip.name, time_s)
            source_bounds = np.concatenate([source.min(axis=0), source.max(axis=0)])
            baked_bounds = np.concatenate([baked.min(axis=0), baked.max(axis=0)])
            error = float(np.abs(source_bounds - baked_bounds).max())
            worst_m = max(worst_m, error)
            row = {"clip": clip.name, "time_s": round(time_s, 3),
                   "bbox_error_mm": round(error * 1000.0, 4)}
            samples.append(row)
            if verbose:
                print("%s @ %.3fs: %.4f mm" %
                      (clip.name, time_s, error * 1000.0))
    result = {
        "ok": worst_m < 0.0005,
        "worst_key_error_mm": round(worst_m * 1000.0, 5),
        "samples": samples,
    }
    if verbose:
        print("Animation verification: %s (worst %.5f mm)" %
              ("PASS" if result["ok"] else "FAIL", result["worst_key_error_mm"]))
    return result


def main() -> int:
    default = os.path.abspath(os.path.join(
        HERE, "..", "..", "generated", "creatures", "slime", "basement_slime.glb"))
    path = sys.argv[-1] if len(sys.argv) > 1 and sys.argv[-1].lower().endswith(".glb") else default
    return 0 if verify(path)["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
