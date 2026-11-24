"""Rail assets through the existing Builder -> Model/Rig/Clip -> validated GLB pipeline.

Run with Blender's bundled Python: python.exe rail_build.py
Only rail outputs are rebuilt; the existing farm assets are left in place.
"""
import math
import os
import sys
import json
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from mesh import Builder
from model import Model, Clip
from skin import Rig
import palette
import validate
import verify_anim

OUT = os.path.abspath(os.path.join(HERE, '..', '..', 'generated', 'rail'))
palette.MATERIALS.update({
    'hunter_skin': ('#A6AAA2', 0.86, 0.0, False),
    'hunter_fold': ('#626A65', 0.95, 0.0, False),
    'hunter_ear': ('#8A7770', 0.90, 0.0, False),
})


def cart():
    b = Builder()
    b.add_box((0, .38, 0), (1.34, .16, 2.1), 'cave_steel_dark', name='riveted_chassis')
    for x in [-.64, .64]:
        b.add_box((x, .67, .06), (.08, .50, 1.8), 'cave_steel', name='side_panel')
        for z in [-.8, -.3, .3, .8]:
            b.add_sphere((x * 1.06, .82, z), (.022, .022, .022), mat='cave_rust', name='rivet')
    for z in [-.68, .68]:
        b.add_tube((-.81, .26, z), (.81, .26, z), .06, .06, mat='cave_rust', name='axle')
        for x in [-.72, .72]:
            b.add_tube((x-.07, .26, z), (x+.07, .26, z), .25, .25, seg=20, mat='cave_steel_dark', name='flanged_wheel')
    b.add_box((0, .84, .62), (1.02, .13, .36), 'bench_wood', name='seat')
    b.add_box((0, 1.08, .86), (1.05, .42, .10), 'bench_wood_dark', name='seat_back')
    b.add_box((0, .68, -.73), (.94, .47, .45), 'cave_warning', name='motor_cowling')
    for x in [-.29, -.15, 0, .15, .29]:
        b.add_box((x, .72, -.967), (.065, .25, .024), 'cave_steel_dark', name='cooling_louvre')
    b.add_tube((.40, .86, -.4), (.4, 1.22, -.3), .028, .028, mat='cave_steel', name='brake_lever')
    b.add_sphere((.4, 1.22, -.3), (.055, .055, .055), mat='bench_wood_dark', name='brake_grip')
    b.add_tube((0, .95, -.89), (0, .95, -1.08), .16, .16, seg=20, mat='cave_steel', name='headlamp_housing')
    b.add_tube((0, .95, -1.08), (0, .95, -1.095), .125, .125, seg=20, mat='bench_chalk', name='headlamp_lens')
    for i in range(7):
        b.add_box((-.65, .58+i*.037, -.6+(i%3)*.15), (.012, .025, .14), 'cave_rust', rotate=(0, 0, -9), name='oxide_patch')
    return Model('RailMiningCart', b)


def terminal(cabinet=False):
    b = Builder()
    b.add_box((0, .66, .08), (1.05, 1.32, .65), 'cave_steel', name='welded_cabinet')
    b.add_box((0, .08, .08), (1.20, .16, .78), 'cave_rust', name='anchored_plinth')
    b.add_box((0, .96, -.26), (.81, .48, .06), 'bench_metal_dark', name='screen_bezel')
    b.add_box((0, .98, -.30), (.69, .35, .02), 'bench_wood_dark' if cabinet else 'cave_lamp_glow', name='status_face')
    b.add_box((0, .31, -.29), (.79, .19, .09), 'bench_metal_dark', name='dispenser')
    b.add_box((0, .22, -.43), (.84, .035, .30), 'cave_steel', name='dispenser_tray')
    for x in [-.28, -.09, .10, .29]:
        b.add_sphere((x, .63, -.29), (.05, .05, .024), mat='cave_warning', name='mechanical_key')
    for y in [.20, .55, .90, 1.25]:
        for x in [-.46, .46]:
            b.add_sphere((x, y, -.255), (.022, .022, .022), mat='cave_rust', name='face_bolt')
    b.add_tube((.50, .08, .2), (.50, 1.4, .2), .022, .022, mat='cave_steel_dark', name='conduit')
    return Model('RailPartsCabinet' if cabinet else 'RailTradingTerminal', b)


def hunter():
    b, rig = Builder(), Rig('EchoHunterRig')
    rig.add('root', pos=(0, .9, 0))
    rig.add('spine', 'root', (0, 1.0, 0), tip=(0, 1.5, -.1))
    rig.add('head', 'spine', (0, 1.54, -.12))
    b.add_sphere((0, 1.14, .02), (.25, .48, .22), seg=24, rings=16, mat='hunter_skin', bones=['spine'], name='hunched_ribcage', smooth=True)
    b.add_sphere((0, 1.64, -.17), (.18, .29, .22), seg=24, rings=16, mat='hunter_skin', bones=['head'], name='blind_skull', smooth=True)
    b.add_sphere((0, 1.44, -.35), (.065, .13, .025), seg=16, rings=8, mat='hunter_fold', bones=['head'], name='breathing_slit', smooth=True)
    for sign in [-1, 1]:
        b.add_tube((0, 1.69, -.382), (.16*sign, 1.72, -.29), .018, .008, seg=12, mat='hunter_fold', bones=['head'], name='sealed_eye_fold', smooth=True)
        for rib in range(5):
            b.add_tube((.04*sign, 1.05+rib*.072, -.195), (.22*sign, 1.07+rib*.062, -.10), .012, .018, seg=8, mat='hunter_fold', bones=['spine'], name='subcutaneous_rib', smooth=True)
    for side, sign in [('L', -1), ('R', 1)]:
        rig.add('ear_'+side, 'head', (.19*sign, 1.75, -.13))
        rig.add('arm_'+side, 'spine', (.24*sign, 1.39, 0), tip=(.51*sign, .50, -.21))
        rig.add('leg_'+side, 'root', (.17*sign, .85, .04), tip=(.28*sign, .1, -.03))
        b.add_loft([{'pos':(.19*sign,1.69,-.11),'rx':.09,'ry':.065},
                    {'pos':(.32*sign,1.89,-.10),'rx':.22,'ry':.070},
                    {'pos':(.44*sign,2.13,-.09),'rx':.13,'ry':.045},
                    {'pos':(.51*sign,2.36,-.05),'rx':.012,'ry':.012}],
                   seg=20, mat='hunter_skin', bones=['ear_'+side], name='tapered_listening_pinna', smooth=True)
        b.add_sphere((.33*sign, 1.98, -.164), (.13, .26, .018), seg=20, rings=12, rotate=(0,0,-17*sign), mat='hunter_ear', bones=['ear_'+side], name='ear_membrane', smooth=True)
        b.add_loft([{'pos':(.24*sign,1.40,0),'rx':.10,'ry':.10},
                    {'pos':(.43*sign,.95,.12),'rx':.07,'ry':.07},
                    {'pos':(.51*sign,.52,-.21),'rx':.042,'ry':.045}],
                   seg=16, mat='hunter_skin', bones=['arm_'+side], name='bent_forelimb', smooth=True)
        for finger in range(3):
            b.add_tube((.50*sign+finger*.031, .53, -.21), (.54*sign+finger*.035, .25, -.36), .022, .009, seg=8, mat='hunter_fold', bones=['arm_'+side], name='sensing_finger')
        b.add_loft([{'pos':(.17*sign,.89,.04),'rx':.115,'ry':.10},
                    {'pos':(.29*sign,.49,-.18),'rx':.07,'ry':.075},
                    {'pos':(.28*sign,.16,-.03),'rx':.045,'ry':.05}],
                   seg=16, mat='hunter_skin', bones=['leg_'+side], name='folded_hindlimb', smooth=True)
        b.add_sphere((.28*sign, .1, -.12), (.09, .09, .21), mat='hunter_fold', bones=['leg_'+side], name='splayed_foot')
    model = Model('EchoHunter', b, rig)
    model.add_clip(Clip('listen', 2.8, lambda t: {'head': (4*math.sin(t*2), 12*math.sin(t*1.2), 0), 'ear_L': (0, 9*math.sin(t*3), -6), 'ear_R': (0, -7*math.sin(t*2.3), 6), 'spine': (3*math.sin(t*2), 0, 0)}, loop=True))
    model.add_clip(Clip('ambush', .75, lambda t: {'spine': (24*math.sin(t/.75*math.pi), 0, 0), 'arm_L': (-65*math.sin(t/.75*math.pi), 0, -10), 'arm_R': (-65*math.sin(t/.75*math.pi), 0, 10), 'head': (-10, 0, 0)}, loop=False))
    return model


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    records = []
    for name, model in [('mining_cart', cart()), ('trading_terminal', terminal()), ('parts_cabinet', terminal(True)), ('echo_hunter', hunter())]:
        path = os.path.join(OUT, name+'.glb')
        result = model.export(path)
        check = validate.validate(path)
        if not check['ok']: raise RuntimeError(check['issues'])
        if model.rig:
            for clip in model.clips:
                times = np.linspace(0.0, clip.duration, max(2, int(round(clip.duration * clip.fps)) + 1))
                for time_s in [times[0], times[len(times)//2]]:
                    source = verify_anim.source_vertices(model.builder, model.rig, clip.pose_fn(time_s))
                    baked = verify_anim.evaluate_glb(path, clip.name, time_s)
                    error = np.abs(np.concatenate([source.min(0), source.max(0)]) - np.concatenate([baked.min(0), baked.max(0)])).max()
                    if error > .0005: raise RuntimeError('Animation bounds error: '+str(error))
        records.append({'asset': name, 'triangles': result['triangles'], 'valid': check['ok']})
        print(name, result['triangles'], 'triangles / validated')
    with open(os.path.join(OUT, 'manifest.json'), 'w', encoding='utf-8') as output:
        json.dump(records, output, indent=2)
