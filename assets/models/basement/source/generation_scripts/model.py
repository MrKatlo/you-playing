"""Assemble pieces + rig + animation clips into a single skinned GLB."""
from __future__ import annotations

import math

import numpy as np

import palette
from gltf import GLTF, hex_to_linear, quat_from_matrix, euler_to_quat
from mesh import Builder, face_normals, tri_centers
from shading import bake_ao, vertex_shade, welded_normals
from texture import box_uv


class Clip:
    """A procedurally generated animation clip.

    pose_fn(t) -> {bone_name: (pitch, yaw, roll)} in degrees
    root_fn(t) -> (x, y, z) offset of the root bone (metres)
    """

    def __init__(self, name, duration, pose_fn, root_fn=None, fps=30,
                 loop=False, description=""):
        self.name = name
        self.duration = duration
        self.pose_fn = pose_fn
        self.root_fn = root_fn
        self.fps = fps
        self.loop = loop
        self.description = description


class Model:
    def __init__(self, name, builder: Builder, rig=None):
        self.name = name
        self.builder = builder
        self.rig = rig
        self.clips: list[Clip] = []
        # PNG bytes of a tileable detail map; None leaves the model on flat
        # palette colours like the rest of the pack
        self.detail_texture: bytes | None = None
        if rig is not None:
            rig.finalize()

    def add_clip(self, clip: Clip):
        self.clips.append(clip)
        return clip

    # ----------------------------------------------------------------- data
    def _expand(self):
        """Unpack every piece into corner attributes: 3 vertices per triangle.

        Pieces marked smooth get their normals averaged across the welded
        surface; the rest keep faceted normals. Ambient occlusion is baked
        against the whole model, not one piece, so an ear darkens the skull it
        hangs against and a leg darkens the belly above it.
        """
        pieces = self.builder.pieces
        if not pieces:
            return {"verts": np.zeros((0, 3)), "normals": np.zeros((0, 3)),
                    "colors": np.zeros((0, 4)), "mats": []}

        sizes = [len(p.verts) for p in pieces]
        starts = np.concatenate([[0], np.cumsum(sizes)[:-1]]).astype(int)
        soup_v = np.concatenate([p.verts for p in pieces])
        soup_t = np.concatenate([p.tris + starts[i] for i, p in enumerate(pieces)])
        extent = float(np.max(soup_v.max(axis=0) - soup_v.min(axis=0)))
        ao = bake_ao(soup_v, soup_t, rays=7,
                     distance=max(0.05, extent * 0.055), strength=0.8)
        shade = vertex_shade(soup_v, ao, seed=self.name.__hash__() % 997)
        corner_shade = np.concatenate(
            [shade[starts[i] + p.tris].reshape(-1, 3)
             for i, p in enumerate(pieces)])
        colors = np.concatenate([corner_shade,
                                 np.ones((len(corner_shade), 1))], axis=1)

        verts, normals, uvs, mats, joints, weights = [], [], [], [], [], []
        for piece in pieces:
            v = piece.verts[piece.tris]
            if piece.smooth:
                n = welded_normals(piece.verts, piece.tris).reshape(-1, 3)
            else:
                n = np.repeat(face_normals(piece.verts, piece.tris), 3, axis=0)
            verts.append(v.reshape(-1, 3))
            normals.append(n)
            uvs.append(box_uv(piece.verts, piece.tris, tile=1.0))
            mats.extend(piece.mats)
            if self.rig is not None:
                j, w = self.rig.weights(v.reshape(-1, 3), piece.bones)
                joints.append(j)
                weights.append(w)
        data = {
            "verts": np.concatenate(verts),
            "normals": np.concatenate(normals),
            "uvs": np.concatenate(uvs),
            "colors": colors,
            "mats": mats,
        }
        if self.rig is not None:
            data["joints"] = np.concatenate(joints)
            data["weights"] = np.concatenate(weights)
        return data

    # ---------------------------------------------------------------- write
    def export(self, path):
        g = GLTF()
        data = self._expand()
        verts = data["verts"]
        normals = data["normals"]
        colors = data["colors"]
        uvs = data["uvs"]
        mats = data["mats"]

        tex = None
        if self.detail_texture is not None:
            tex = g.base_color_texture(self.detail_texture, "hide_grain")
        material_index = {}
        for name in dict.fromkeys(mats):
            hexcol, rough, metal, double = palette.material(name)
            options = palette.gltf_options(name) if hasattr(palette, "gltf_options") else {}
            alpha = float(options.get("alpha", 1.0))
            material_index[name] = g.material(
                name, hex_to_linear(hexcol, alpha=alpha), roughness=rough,
                metallic=metal, double_sided=double, alpha=alpha,
                emissive=options.get("emissive"), base_color_texture=tex)

        # one primitive per material
        mat_array = np.array(mats)
        prims = []
        for name in dict.fromkeys(mats):
            sel = np.nonzero(mat_array == name)[0]          # triangle ids
            tri_count = len(sel)
            if tri_count == 0:
                continue
            vids = (sel[:, None] * 3 + np.arange(3)[None, :]).reshape(-1)
            attrs = {
                "POSITION": g.accessor(verts[vids], "VEC3", 34962, minmax=True),
                "NORMAL": g.accessor(normals[vids], "VEC3", 34962),
                "COLOR_0": g.accessor(colors[vids].astype(np.float32),
                                      "VEC4", 34962),
            }
            if tex is not None:
                attrs["TEXCOORD_0"] = g.accessor(uvs[vids].astype(np.float32),
                                                 "VEC2", 34962)
            if self.rig is not None:
                attrs["JOINTS_0"] = g.accessor(data["joints"][vids], "VEC4", 34962)
                attrs["WEIGHTS_0"] = g.accessor(
                    data["weights"][vids].astype(np.float32), "VEC4", 34962)
            idx = np.arange(tri_count * 3, dtype=np.uint32)
            attrs_idx = g.accessor(idx, "SCALAR", 34963)
            prims.append({"attributes": attrs, "indices": attrs_idx,
                          "material": material_index[name]})
        mesh_index = g.mesh(self.name, prims)

        root_node = g.node(self.name)
        g.add_to_scene(root_node)
        children = []

        if self.rig is not None:
            rig = self.rig
            armature = g.node("Armature")
            bone_nodes = {}
            for bone in rig.bones:
                local = bone.pos if bone.parent is None else bone.pos - rig.by_name[bone.parent].pos
                bone_nodes[bone.name] = g.node(bone.name, translation=local)
            for bone in rig.bones:
                if bone.children:
                    g.json["nodes"][bone_nodes[bone.name]]["children"] = [
                        bone_nodes[c.name] for c in bone.children]
            g.json["nodes"][armature]["children"] = [bone_nodes[rig.bones[0].name]]
            children.append(armature)
            ibm = g.accessor(rig.inverse_bind().astype(np.float32), "MAT4")
            skin_index = g.skin([bone_nodes[b.name] for b in rig.bones], ibm,
                                skeleton=bone_nodes[rig.bones[0].name])
            mesh_node = g.node(self.name + "_Mesh", mesh=mesh_index, skin=skin_index)
        else:
            mesh_node = g.node(self.name + "_Mesh", mesh=mesh_index)
        children.append(mesh_node)
        g.json["nodes"][root_node]["children"] = children

        if self.rig is not None and self.clips:
            for clip in self.clips:
                self._bake(g, clip, bone_nodes)

        g.write(path)
        return {
            "triangles": len(mats),
            "vertices": int(len(verts)),
            "materials": len(material_index),
            "bones": len(self.rig.bones) if self.rig else 0,
            "animations": [c.name for c in self.clips],
        }

    def _bake(self, g, clip, bone_nodes):
        rig = self.rig
        n = max(2, int(round(clip.duration * clip.fps)) + 1)
        times = np.linspace(0.0, clip.duration, n)

        poses = [clip.pose_fn(t) for t in times]
        roots = [clip.root_fn(t) if clip.root_fn else (0.0, 0.0, 0.0) for t in times]

        channels = []
        for bone in rig.bones:
            quats = []
            changed = False
            for p in poses:
                rot = p.get(bone.name, (0.0, 0.0, 0.0))
                q = euler_to_quat(*rot)
                if any(abs(v) > 1e-6 for v in rot):
                    changed = True
                quats.append(q)
            if not changed:
                continue
            quats = np.array(quats)
            for i in range(1, len(quats)):
                if float(np.dot(quats[i], quats[i - 1])) < 0.0:
                    quats[i] *= -1.0
            channels.append((bone_nodes[bone.name], "rotation", times, quats))

        root = rig.bones[0]
        offsets = np.array(roots, dtype=np.float64)
        if np.abs(offsets).max() > 1e-6:
            trans = np.array([root.pos + o for o in offsets])
            channels.append((bone_nodes[root.name], "translation", times, trans))

        if channels:
            g.animation(clip.name, channels)
