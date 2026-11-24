"""Skeleton definition, automatic skin weights and pose evaluation.

Bones are authored as world-space joint positions with identity rest
rotations, which means a bone's local axes are world-aligned. Animation
authors can therefore think in plain pitch / yaw / roll terms instead of
per-bone roll conventions, and the resulting skeleton is still a normal
hierarchical deform rig.

Skin weights are computed procedurally: every mesh piece declares which
bones may influence it (a whitelist), and each vertex is weighted by inverse
distance to the closest segment of each allowed bone. Only the four strongest
influences are kept, matching the glTF JOINTS_0/WEIGHTS_0 limit Godot uses.
"""
from __future__ import annotations

import numpy as np

from gltf import euler_to_matrix, euler_to_quat


class Bone:
    __slots__ = ("name", "parent", "pos", "tip", "children", "index")

    def __init__(self, name, parent, pos, tip=None):
        self.name = name
        self.parent = parent
        self.pos = np.array(pos, dtype=np.float64)
        self.tip = None if tip is None else np.array(tip, dtype=np.float64)
        self.children: list[Bone] = []
        self.index = -1


class Rig:
    def __init__(self, name="Armature"):
        self.name = name
        self.bones: list[Bone] = []
        self.by_name: dict[str, Bone] = {}
        self.segments: list[list[tuple[np.ndarray, np.ndarray]]] = []

    def add(self, name, parent=None, pos=(0, 0, 0), tip=None) -> Bone:
        bone = Bone(name, parent, pos, tip)
        self.bones.append(bone)
        self.by_name[name] = bone
        if parent is not None:
            self.by_name[parent].children.append(bone)
        return bone

    def finalize(self):
        for i, bone in enumerate(self.bones):
            bone.index = i
        self.segments = []
        for bone in self.bones:
            if bone.tip is not None:
                # an explicit tip lets a bone own a region that runs across its
                # children (e.g. the head owning the muzzle)
                segs = [(bone.pos, bone.tip)]
            else:
                segs = [(bone.pos, child.pos) for child in bone.children]
            if not segs:
                direction = np.array([0.0, 0.0, -1.0])
                if bone.parent is not None:
                    d = bone.pos - self.by_name[bone.parent].pos
                    if np.linalg.norm(d) > 1e-6:
                        direction = d / np.linalg.norm(d)
                segs = [(bone.pos, bone.pos + direction * 0.06)]
            self.segments.append(segs)
        return self

    # ------------------------------------------------------------- weights
    def deform_bones(self):
        return [b.name for b in self.bones if b.name != "root"]

    def weights(self, verts, allowed=None, k=4, power=2.6, eps=0.006):
        verts = np.asarray(verts, dtype=np.float64)
        names = allowed if allowed else self.deform_bones()
        names = [n for n in names if n in self.by_name]
        if not names:
            names = self.deform_bones()
        dist = np.zeros((len(verts), len(names)), dtype=np.float64)
        for j, name in enumerate(names):
            bone = self.by_name[name]
            segs = self.segments[bone.index]
            best = np.full(len(verts), 1e9)
            for a, b in segs:
                ab = b - a
                ab_len2 = float(np.dot(ab, ab))
                if ab_len2 < 1e-12:
                    d = np.linalg.norm(verts - a, axis=1)
                else:
                    t = np.clip(((verts - a) @ ab) / ab_len2, 0.0, 1.0)
                    proj = a + t[:, None] * ab
                    d = np.linalg.norm(verts - proj, axis=1)
                best = np.minimum(best, d)
            dist[:, j] = best
        w = 1.0 / np.power(dist + eps, power)

        if w.shape[1] > k:
            keep = np.argpartition(-w, k - 1, axis=1)[:, :k]
        else:
            keep = np.tile(np.arange(w.shape[1]), (len(verts), 1))
        joints = np.zeros((len(verts), 4), dtype=np.uint16)
        weights = np.zeros((len(verts), 4), dtype=np.float64)
        for i in range(len(verts)):
            cols = keep[i]
            vals = w[i, cols]
            vals = vals / vals.sum()
            order = np.argsort(-vals)
            cols = cols[order]
            vals = vals[order]
            n = min(4, len(cols))
            joints[i, :n] = [self.by_name[names[c]].index for c in cols[:n]]
            weights[i, :n] = vals[:n]
            weights[i, :n] /= weights[i, :n].sum()
        return joints, weights

    # --------------------------------------------------------------- poses
    def world_matrices(self, pose=None, root_translation=(0, 0, 0)):
        """Evaluate world matrices for the rig. `pose` maps bone -> (pitch, yaw, roll)."""
        pose = pose or {}
        mats = {}
        for bone in self.bones:
            local = np.eye(4)
            local[:3, :3] = euler_to_matrix(*pose.get(bone.name, (0.0, 0.0, 0.0)))
            if bone.parent is None:
                local[:3, 3] = bone.pos + np.array(root_translation, dtype=np.float64)
            else:
                local[:3, 3] = bone.pos - self.by_name[bone.parent].pos
            mats[bone.name] = (mats[bone.parent] @ local) if bone.parent else local
        return mats

    def inverse_bind(self):
        inv = np.zeros((len(self.bones), 16), dtype=np.float64)
        for bone in self.bones:
            m = np.eye(4)
            m[:3, 3] = -bone.pos
            inv[bone.index] = m.T.flatten()  # glTF expects column-major
        return inv

    def local_rotation_quats(self, pose=None):
        pose = pose or {}
        out = {}
        for bone in self.bones:
            rot = pose.get(bone.name, (0.0, 0.0, 0.0))
            if any(abs(v) > 1e-9 for v in rot):
                out[bone.name] = euler_to_quat(*rot)
        return out

    def skin_points(self, verts, joints, weights, pose=None,
                    root_translation=(0, 0, 0)):
        """CPU skinning, used by the preview renderer for QA images."""
        mats = self.world_matrices(pose, root_translation)
        bind = {}
        for bone in self.bones:
            m = np.eye(4)
            m[:3, 3] = -bone.pos
            bind[bone.index] = m
        out = np.zeros_like(verts, dtype=np.float64)
        for i in range(len(verts)):
            p = np.append(verts[i], 1.0)
            acc = np.zeros(3)
            for j in range(4):
                w = weights[i, j]
                if w <= 0:
                    continue
                b = int(joints[i, j])
                m = mats[self.bones[b].name] @ bind[b]
                acc += w * (m @ p)[:3]
            out[i] = acc
        return out
