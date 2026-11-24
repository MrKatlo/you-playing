"""Tiny software renderer used only for QA previews / documentation images.

It renders the same in-memory geometry that is written to GLB (optionally
skinned into an animation pose) so the generated art can be inspected
without opening Godot or Blender.
"""
from __future__ import annotations

import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

import palette
from mesh import face_normals

BACKGROUND_TOP = (232, 226, 210)
BACKGROUND_BOTTOM = (196, 188, 168)
LIGHT = np.array([-0.45, 0.72, 0.53])
LIGHT = LIGHT / np.linalg.norm(LIGHT)
FILL = np.array([0.62, 0.25, 0.75])
FILL = FILL / np.linalg.norm(FILL)


def look_at(eye, target, up=(0.0, 1.0, 0.0)):
    eye = np.array(eye, dtype=np.float64)
    target = np.array(target, dtype=np.float64)
    forward = target - eye
    forward /= np.linalg.norm(forward)
    right = np.cross(forward, up)
    right /= np.linalg.norm(right)
    true_up = np.cross(right, forward)
    m = np.eye(4)
    m[0, :3] = right
    m[1, :3] = true_up
    m[2, :3] = -forward
    m[:3, 3] = -m[:3, :3] @ eye
    return m


def scene_triangles(model, pose=None, root_translation=(0, 0, 0)):
    verts_all, normals_all, colors_all, ds_all = [], [], [], []
    use_skinning = model.rig is not None and pose is not None
    for piece in model.builder.pieces:
        if use_skinning:
            j, w = model.rig.weights(piece.verts, piece.bones)
            v = model.rig.skin_points(piece.verts, j, w, pose, root_translation)
        else:
            v = piece.verts
        tris = piece.tris
        n = face_normals(v, tris)
        verts_all.append(v[tris])
        normals_all.append(n)
        colors_all.extend(palette.rgb(m) for m in piece.mats)
        ds_all.extend(palette.material(m)[3] for m in piece.mats)
    if not verts_all:
        return (np.zeros((0, 3, 3)), np.zeros((0, 3)), np.zeros((0, 3)),
                np.zeros((0,), dtype=bool))
    return (np.concatenate(verts_all), np.concatenate(normals_all),
            np.array(colors_all), np.array(ds_all, dtype=bool))


def render(model, path=None, size=(760, 560), yaw=38.0, pitch=16.0,
           zoom=1.0, pose=None, root_translation=(0, 0, 0), center=None,
           ground=True, ss=2):
    tris, normals, colors, double_sided = scene_triangles(
        model, pose, root_translation)
    if len(tris) == 0:
        return None
    lo = tris.reshape(-1, 3).min(axis=0)
    hi = tris.reshape(-1, 3).max(axis=0)
    if center is None:
        center = (lo + hi) * 0.5
        center[1] = lo[1] + (hi[1] - lo[1]) * 0.5
    extent = float(np.max(hi - lo))
    dist = extent * 1.55 / max(zoom, 1e-3)

    cy, sy = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    cp, sp = math.cos(math.radians(pitch)), math.sin(math.radians(pitch))
    eye = np.array(center) + dist * np.array([cy * cp, sp, sy * cp])
    view = look_at(eye, center)

    W, H = size[0] * ss, size[1] * ss
    focal = W * 0.95
    cam = tris @ view[:3, :3].T + view[:3, 3]
    z = np.maximum(-cam[:, :, 2], 1e-4)
    px = W * 0.5 + focal * cam[:, :, 0] / z
    py = H * 0.5 - focal * cam[:, :, 1] / z

    img = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img)
    for y in range(H):
        f = y / max(H - 1, 1)
        col = tuple(int(BACKGROUND_TOP[i] * (1 - f) + BACKGROUND_BOTTOM[i] * f)
                    for i in range(3))
        draw.line([(0, y), (W, y)], fill=col)

    # ground shadow: project triangles onto y=0 plane
    if ground:
        shadow = Image.new("L", (W, H), 0)
        sdraw = ImageDraw.Draw(shadow)
        floor_y = lo[1] - 0.002
        for i in range(len(tris)):
            pts = []
            ok = True
            for v in tris[i]:
                p = np.array([v[0], floor_y, v[2], 1.0])
                c = view @ p
                if -c[2] < 0.05:
                    ok = False
                    break
                pts.append((W * 0.5 + focal * c[0] / -c[2],
                            H * 0.5 - focal * c[1] / -c[2]))
            if ok:
                sdraw.polygon(pts, fill=26)
        shadow = shadow.filter(ImageFilter.GaussianBlur(6 * ss))
        img.paste(Image.new("RGB", (W, H), (120, 108, 90)), (0, 0), shadow)

    # z-buffered flat-shaded rasterisation (correct for interpenetrating parts)
    frame = np.asarray(img, dtype=np.float32).copy()
    zbuf = np.full((H, W), np.inf, dtype=np.float32)
    to_cam = eye[None, :] - tris.mean(axis=1)
    facing = np.einsum("ij,ij->i", normals, to_cam)
    for i in range(len(tris)):
        if facing[i] <= 0 and not double_sided[i]:
            continue
        if z[i].min() < 0.02:
            continue
        n = normals[i]
        lam = max(0.0, float(n @ LIGHT))
        fill = max(0.0, float(n @ FILL))
        shade = 0.34 + 0.78 * lam + 0.16 * fill
        base = colors[i]
        col = np.array([255 * (base[k] ** 2.2 * shade) ** (1 / 2.2)
                        for k in range(3)], dtype=np.float32)
        col = np.clip(col, 0, 255)

        x0, x1, x2 = px[i]
        y0, y1, y2 = py[i]
        minx = max(int(math.floor(min(x0, x1, x2))), 0)
        maxx = min(int(math.ceil(max(x0, x1, x2))) + 1, W)
        miny = max(int(math.floor(min(y0, y1, y2))), 0)
        maxy = min(int(math.ceil(max(y0, y1, y2))) + 1, H)
        if minx >= maxx or miny >= maxy:
            continue
        det = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)
        if abs(det) < 1e-9:
            continue
        xs = np.arange(minx, maxx, dtype=np.float32) + 0.5
        ys = np.arange(miny, maxy, dtype=np.float32) + 0.5
        X, Y = np.meshgrid(xs, ys)
        w0 = ((x1 - X) * (y2 - Y) - (x2 - X) * (y1 - Y)) / det
        w1 = ((x2 - X) * (y0 - Y) - (x0 - X) * (y2 - Y)) / det
        w2 = 1.0 - w0 - w1
        inside = (w0 >= -1e-5) & (w1 >= -1e-5) & (w2 >= -1e-5)
        if not inside.any():
            continue
        inv_z = (w0 / z[i, 0] + w1 / z[i, 1] + w2 / z[i, 2])
        tz = np.where(inv_z > 1e-9, 1.0 / np.maximum(inv_z, 1e-9), np.inf)
        sub = zbuf[miny:maxy, minx:maxx]
        mask = inside & (tz < sub)
        if not mask.any():
            continue
        sub[mask] = tz[mask]
        frame[miny:maxy, minx:maxx][mask] = col

    img = Image.fromarray(np.clip(frame, 0, 255).astype(np.uint8))
    img = img.resize(size, Image.LANCZOS)
    if path:
        img.save(path)
    return img


def contact_sheet(images, cols, path, gap=6, bg=(244, 240, 230)):
    if not images:
        return None
    w, h = images[0].size
    rows = (len(images) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * w + (cols + 1) * gap,
                              rows * h + (rows + 1) * gap), bg)
    for i, im in enumerate(images):
        sheet.paste(im, (gap + (i % cols) * (w + gap),
                         gap + (i // cols) * (h + gap)))
    sheet.save(path)
    return sheet

