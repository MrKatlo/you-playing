"""First-night mechanisms. Uses the Basement Builder -> Model -> validated GLB pipeline.

Run with Blender's bundled python.exe phase_a_build.py. Only these five props
are rebuilt. Geometry is in metres; rigid moving parts have their own origins.
"""
import json
import math
import os
import struct
import zlib

import numpy as np

from mesh import Builder
from model import Model
import validate

OUT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'generated', 'props'))


def ring(b, center, rx, ry, tube=.008, turn=0.0, broken=False, material='bench_metal', name='link'):
    """Smooth forged oval, with a real opening/capped ends on a fractured link."""
    segments, sides = 48, 10
    start, end = (.35, math.tau-.35) if broken else (0, math.tau)
    verts, faces = [], []
    for i in range(segments+1):
        a = start + (end-start)*i/segments
        normal = np.array([math.cos(a)/rx, math.sin(a)/ry, 0.0])
        normal /= np.linalg.norm(normal)
        for j in range(sides):
            v = math.tau*j/sides
            p = np.array([rx*math.cos(a), ry*math.sin(a), 0.0])
            p += tube * (normal*math.cos(v) + np.array([0, 0, math.sin(v)]))
            x, y, z = p
            verts.append((center[0]+x*math.cos(turn)+z*math.sin(turn), center[1]+y,
                          center[2]-x*math.sin(turn)+z*math.cos(turn)))
    for i in range(segments):
        for j in range(sides):
            k = i*sides+j
            faces.append((k, i*sides+(j+1)%sides, (i+1)*sides+(j+1)%sides, k+sides))
    if broken:
        faces.append(tuple(reversed(range(sides))))
        faces.append(tuple(segments*sides+j for j in range(sides)))
    b.add(verts, faces, material, name=name, smooth=True)


def plate(b):
    # Clipped corners, thick edges and separated front/rear faces.
    outline = [(-.15,-.34),(.15,-.34),(.17,-.32),(.17,.32),(.15,.34),(-.15,.34),(-.17,.32),(-.17,-.32)]
    verts = [(x,y,z) for z in [-.0225,.0225] for x,y in outline]
    faces = [tuple(reversed(range(8))), tuple(range(8,16))]
    faces += [(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)]
    b.add(verts, faces, 'bench_metal_dark', name='chamfered_mounting_plate')


def crank_body():
    b = Builder()
    plate(b)
    b.add_box((0,-.2,-.042),(.28,.09,.016),'cave_warning',name='worn_nameplate')
    for x in [-.12,.12]:
        for y in [-.27,.27]:
            b.add_tube((x,y,-.025),(x,y,-.038),.026,.026,seg=24,mat='bench_rust',name='rusted_washer')
            b.add_tube((x,y,-.038),(x,y,-.05),.015,.015,seg=6,mat='bench_metal',name='hex_bolt')
    b.add_tube((0,-.02,-.024),(0,-.02,-.12),.116,.108,seg=40,mat='bench_metal_dark',name='gear_case',smooth=True)
    b.add_tube((0,-.02,-.122),(0,-.02,-.136),.107,.107,seg=40,mat='bench_metal',name='case_lip',smooth=True)
    for i in range(8):
        a = math.tau*i/8
        x,y = .083*math.cos(a), -.02+.083*math.sin(a)
        b.add_tube((x,y,-.137),(x,y,-.146),.008,.008,seg=6,mat='bench_rust',name='case_screw')
    b.add_tube((0,-.02,-.135),(0,-.02,-.221),.023,.023,seg=24,mat='bench_metal',name='greased_axle',smooth=True)
    ring(b,(0,-.02,-.145),.032,.032,.006,material='bench_oil',name='grease_seal')
    for i in range(8):
        b.add_box((-.147+i*.007,.20-i*.031,-.026),(.012,.05,.003),'bench_rust',rotate=(0,0,18),name='uneven_paint_loss')
    return b


def crank_wheel():
    b = Builder()
    ring(b,(0,0,0),.151,.151,.014,material='bench_metal',name='continuous_cast_rim')
    for i in range(3):
        a = math.tau*i/3
        p0 = (.025*math.cos(a),.025*math.sin(a),0)
        p1 = (.085*math.cos(a+.22),.085*math.sin(a+.22),.012)
        p2 = (.15*math.cos(a+.13),.15*math.sin(a+.13),0)
        b.add_tube(p0,p1,.017,.014,seg=12,mat='bench_metal',smooth=True,name='swept_spoke')
        b.add_tube(p1,p2,.014,.011,seg=12,mat='bench_metal',smooth=True,name='swept_spoke_tip')
    b.add_tube((0,0,-.026),(0,0,.026),.038,.038,seg=32,mat='bench_rust',name='hub',smooth=True)
    b.add_tube((0,0,-.026),(0,0,-.035),.019,.019,seg=6,mat='bench_metal',name='hub_nut')
    b.add_tube((.145,0,-.012),(.145,0,-.087),.013,.013,seg=16,mat='bench_metal',name='handle_stem',smooth=True)
    b.add_sphere((.145,0,-.095),(.026,.026,.046),seg=24,rings=14,mat='bench_tool_handle',smooth=True,name='worn_wood_grip')
    for i in range(4):
        ring(b,(.145,0,-.069-i*.014),.025,.025,.0017,material='bench_wood_dark',name='grip_groove')
    return b


def chain(broken=False):
    b = Builder()
    for i in range(-4,5):
        if i == 0:
            ring(b,(.006 if broken else 0,0,0),.028,.049,.007,broken=broken,
                 material='bench_rust' if broken else 'bench_metal',name='repair_link')
        else:
            ring(b,(0,i*.065,0),.026,.047,.007,turn=math.pi/2 if i%2 else 0,
                 material='bench_rust' if i in [-3,2] else 'bench_metal_dark',name='chain_link')
    for y in [-.31,.31]:
        b.add_box((0,y,.03),(.12,.05,.05),'bench_metal_dark',name='wall_chain_guide')
        for x in [-.045,.045]:
            b.add_tube((x,y,0),(x,y,-.008),.008,.008,seg=6,mat='bench_metal',name='guide_bolt')
    return b


def replacement():
    b = Builder()
    ring(b,(0,0,0),.029,.05,.008,material='bench_metal',name='forged_replacement_link')
    b.add_tube((.028,-.019,-.008),(.028,.019,-.008),.012,.012,seg=16,mat='bench_metal_dark',name='locking_sleeve',smooth=True)
    b.add_tube((.028,0,-.018),(.028,0,.013),.009,.009,seg=6,mat='patch_hide',name='chitin_lock_pin')
    return b


def metal_grain():
    # Embedded subtle pitting/scratches; no external textures or Pillow dependency.
    rng = np.random.default_rng(317)
    a = np.clip(rng.normal(234,8,(256,256)),195,255).astype(np.uint8)
    for _ in range(130):
        x,y = rng.integers(0,256,2)
        a[y:min(256,y+int(rng.integers(2,20))),x] = 188
    rgb = np.repeat(a[:,:,None],3,axis=2)
    def chunk(kind,data):
        return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
    rows = b''.join(b'\0'+row.tobytes() for row in rgb)
    return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',256,256,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(rows))+chunk(b'IEND',b'')


if __name__ == '__main__':
    os.makedirs(OUT,exist_ok=True)
    records = []
    for name,builder in [('bulkhead_crank',crank_body()),('bulkhead_crank_wheel',crank_wheel()),
                         ('shutter_chain_broken',chain(True)),('shutter_chain_repaired',chain()),
                         ('replacement_chain_link',replacement())]:
        model = Model(name,builder)
        model.detail_texture = metal_grain()
        path = os.path.join(OUT,name+'.glb')
        result = model.export(path)
        check = validate.validate(path)
        if not check['ok']: raise RuntimeError(check['issues'])
        verts = np.concatenate([p.verts for p in builder.pieces])
        records.append({'id':name,'file':name+'.glb','triangles':result['triangles'],
                        'dimensions_m':(verts.max(0)-verts.min(0)).round(4).tolist(),'validated':True})
        print(name,result['triangles'],'triangles / validated')
    with open(os.path.join(OUT,'phase_a_manifest.json'),'w',encoding='utf-8') as out:
        json.dump(records,out,indent=2)
