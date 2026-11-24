"""Behaviour-led animation clips for generated Basement Farm creatures."""
from __future__ import annotations

import math

from model import Clip


TAU = math.tau


def _add(pose: dict, bone: str, *, pitch: float = 0.0, yaw: float = 0.0,
         roll: float = 0.0) -> None:
    old = pose.get(bone, (0.0, 0.0, 0.0))
    pose[bone] = (old[0] + pitch, old[1] + yaw, old[2] + roll)


def slime_idle():
    """Slow breathing, internal pulse, and irregular floor contact."""
    def pose_at(time: float) -> dict:
        pose: dict = {}
        breath = math.sin(TAU * time / 2.6)
        drift = math.sin(TAU * time / 4.9 + 0.6)
        _add(pose, "root", roll=0.8 * drift)
        _add(pose, "front", pitch=2.5 * breath, yaw=1.4 * drift)
        _add(pose, "back", pitch=-1.9 * breath, yaw=-0.8 * drift)
        _add(pose, "core", pitch=-4.2 * breath, roll=1.8 * math.sin(TAU * time / 1.3))
        _add(pose, "tail", pitch=-1.5 * breath)
        _add(pose, "skirt_L", roll=2.2 * math.sin(TAU * time / 2.0))
        _add(pose, "skirt_R", roll=-1.8 * math.sin(TAU * time / 2.0 + 0.5))
        return pose
    return pose_at


def slime_crawl():
    """In-place travelling wave; movement remains controlled by CharacterBody3D."""
    def pose_at(time: float) -> dict:
        pose: dict = {}
        wave = math.sin(TAU * time / 0.78)
        crest = math.sin(TAU * time / 0.78 + 1.35)
        _add(pose, "root", pitch=-1.3 * wave, roll=1.3 * math.sin(TAU * time / 1.56))
        _add(pose, "front", pitch=8.0 * wave, yaw=1.6 * crest)
        _add(pose, "back", pitch=-7.0 * crest, yaw=-1.4 * wave)
        _add(pose, "core", pitch=-5.0 * wave, roll=2.7 * crest)
        _add(pose, "tail", pitch=-6.0 * crest)
        _add(pose, "skirt_L", roll=14.0 * max(0.0, wave) - 7.0 * max(0.0, -crest))
        _add(pose, "skirt_R", roll=-14.0 * max(0.0, -wave) + 7.0 * max(0.0, crest))
        return pose
    return pose_at


def slime_lure():
    """A scent-reading probe used while the prey is committed to bait."""
    def pose_at(time: float) -> dict:
        pose: dict = {}
        sniff = math.sin(TAU * time / 1.2)
        _add(pose, "front", pitch=-9.0 + 4.0 * sniff, yaw=8.0 * math.sin(TAU * time / 2.4))
        _add(pose, "core", pitch=7.0 - 3.0 * sniff)
        _add(pose, "back", pitch=3.0 * sniff)
        _add(pose, "skirt_L", roll=6.0 * sniff)
        _add(pose, "skirt_R", roll=-6.0 * sniff)
        return pose
    return pose_at


def slime_crouch():
    """The pounce wind-up: gather the mantle, tuck the skirts, aim the face.

    This is the clip that makes the telegraph readable as a body coiling rather
    than as a model being scaled down. It holds at full coil on the last frame,
    so gameplay can swap to `strike` at the exact moment it leaves the floor.
    """
    def pose_at(time: float) -> dict:
        pose: dict = {}
        u = min(max(time / 0.46, 0.0), 1.0)
        coil = u * u * (3.0 - 2.0 * u)
        # A fast tremor under the held coil: the animal is straining to spring.
        tremble = math.sin(TAU * time * 9.0) * coil
        _add(pose, "root", pitch=6.0 * coil, roll=1.1 * tremble)
        _add(pose, "front", pitch=-14.0 * coil, yaw=2.2 * tremble)
        _add(pose, "core", pitch=10.0 * coil, roll=1.6 * tremble)
        _add(pose, "back", pitch=8.0 * coil, roll=-1.2 * tremble)
        _add(pose, "tail", pitch=-6.0 * coil)
        _add(pose, "skirt_L", roll=-11.0 * coil)
        _add(pose, "skirt_R", roll=11.0 * coil)
        return pose
    return pose_at


def slime_leap():
    """The airborne pounce: mantle stretched along the throw, skirts trailing.

    Duration matches the physics airtime (2 * lift / gravity = 0.48 s), so the
    clip ends as the body meets the floor. The last third tucks the face down so
    the landing reads as a catch rather than a frozen mid-air pose.
    """
    def pose_at(time: float) -> dict:
        pose: dict = {}
        u = min(max(time / 0.48, 0.0), 1.0)
        stretch = u * u * (3.0 - 2.0 * u)
        tuck = max(0.0, (u - 0.66) / 0.34)
        _add(pose, "root", pitch=-7.0 * stretch + 5.0 * tuck)
        _add(pose, "front", pitch=-23.0 * stretch + 17.0 * tuck)
        _add(pose, "core", pitch=13.0 * stretch - 7.0 * tuck)
        _add(pose, "back", pitch=17.0 * stretch - 9.0 * tuck)
        _add(pose, "tail", pitch=21.0 * stretch - 11.0 * tuck)
        _add(pose, "skirt_L", roll=-25.0 * stretch + 9.0 * tuck)
        _add(pose, "skirt_R", roll=25.0 * stretch - 9.0 * tuck)
        return pose
    return pose_at


def slime_strike():
    """A compression and forward throw without root motion."""
    def pose_at(time: float) -> dict:
        pose: dict = {}
        u = min(max(time / 0.44, 0.0), 1.0)
        thrust = math.sin(math.pi * u)
        recoil = max(0.0, (u - 0.62) / 0.38)
        _add(pose, "root", pitch=-5.0 * thrust + 3.0 * recoil)
        _add(pose, "front", pitch=-31.0 * thrust + 12.0 * recoil)
        _add(pose, "core", pitch=14.0 * thrust - 6.0 * recoil)
        _add(pose, "back", pitch=18.0 * thrust - 8.0 * recoil)
        _add(pose, "skirt_L", roll=-17.0 * thrust)
        _add(pose, "skirt_R", roll=17.0 * thrust)
        return pose
    return pose_at


def slime_hurt():
    """A sharp asymmetric recoil so combat impacts read at a glance."""
    def pose_at(time: float) -> dict:
        pose: dict = {}
        u = min(max(time / 0.36, 0.0), 1.0)
        flinch = math.sin(math.pi * u)
        _add(pose, "root", roll=12.0 * flinch)
        _add(pose, "front", pitch=18.0 * flinch, yaw=-8.0 * flinch)
        _add(pose, "core", pitch=-14.0 * flinch, roll=-10.0 * flinch)
        _add(pose, "back", pitch=-10.0 * flinch)
        _add(pose, "skirt_L", roll=-17.0 * flinch)
        _add(pose, "skirt_R", roll=15.0 * flinch)
        return pose
    return pose_at


def slime_death():
    """A readable collapse rather than an instant disappear."""
    def pose_at(time: float) -> dict:
        pose: dict = {}
        u = min(max(time / 1.1, 0.0), 1.0)
        settle = u * u * (3.0 - 2.0 * u)
        _add(pose, "root", roll=17.0 * settle)
        _add(pose, "front", pitch=29.0 * settle, yaw=-9.0 * settle)
        _add(pose, "core", pitch=-24.0 * settle, roll=-14.0 * settle)
        _add(pose, "back", pitch=-18.0 * settle)
        _add(pose, "tail", pitch=19.0 * settle)
        _add(pose, "skirt_L", roll=-30.0 * settle)
        _add(pose, "skirt_R", roll=22.0 * settle)
        return pose
    return pose_at


def build_slime_clips() -> list[Clip]:
    return [
        Clip("idle", 2.6, slime_idle(), loop=True,
             description="Slow pulse and floor contact."),
        Clip("crawl", 0.78, slime_crawl(), loop=True,
             description="In-place muscle wave for CharacterBody movement."),
        Clip("lure", 1.2, slime_lure(), loop=True,
             description="Scent-reading pose while following bait."),
        Clip("strike", 0.44, slime_strike(), loop=False,
             description="Compression and forward attack throw."),
        Clip("crouch", 0.46, slime_crouch(), loop=False,
             description="Pounce wind-up coil, held on the final frame."),
        Clip("leap", 0.48, slime_leap(), loop=False,
             description="Airborne stretch with trailing skirts and landing tuck."),
        Clip("hurt", 0.36, slime_hurt(), loop=False,
             description="Asymmetric hit recoil."),
        Clip("death", 1.1, slime_death(), loop=False,
             description="Gel collapse after lethal damage."),
    ]
