"""Synthesise the cricket-net catch cue.

A netted tray needs two sounds that belong together: the gauze sweeping through
the air behind the hoop, and the crickets that were just caught. Both are made
from scratch here (filtered noise and tuned sine bursts, no samples), in the same
spirit as `tools/create_creature_audio.py`, whose filter helpers are reused.

Run:  python tools/create_net_audio.py
Writes assets/audio/net_swish.wav and cricket_chirp.wav.
"""

import math
import random

from create_creature_audio import RATE, BandPass, LowPass, env, soft_clip, write_wav


def net_swish():
    """Gauze on a wooden hoop: air pushed through cloth, not a blade in air."""
    length = int(RATE * 0.40)
    out = []
    cloth = BandPass(620.0, 1.4)
    air = BandPass(2100.0, 0.7)
    low = LowPass(320.0)
    for i in range(length):
        t = i / RATE
        k = t / (length / RATE)
        # The cloth opens up as the net accelerates, then closes as it stops.
        cloth.set_freq(360.0 + 1500.0 * math.sin(math.pi * k) ** 1.4, 1.3)
        weave = cloth(noise_frame()) * 0.75
        # Loose gauze flutters rather than hisses: a fast amplitude ripple.
        weave *= 0.62 + 0.38 * math.sin(2.0 * math.pi * (34.0 - 10.0 * k) * t)
        rush = air(noise_frame()) * 0.20 * math.sin(math.pi * k)
        # A little weight from the handle, so the swing has a bottom end.
        handle = math.sin(2.0 * math.pi * (150.0 - 55.0 * k) * t) * 0.10
        handle = low(handle) * math.sin(math.pi * k) ** 2
        burst = env(t, 0.055, 0.115)
        out.append(soft_clip((weave + rush + handle) * burst * 1.1))
    return out


def cricket_chirp():
    """Three trilled chirps from one insect: 4.2 kHz carrier, 44 Hz wing rate."""
    length = int(RATE * 0.34)
    out = []
    for i in range(length):
        t = i / RATE
        value = 0.0
        # Four chirps, each a little quieter: the insect settling after the net.
        for start, loud in ((0.015, 1.0), (0.085, 0.88), (0.155, 0.78), (0.245, 0.55)):
            local = t - start
            if 0.0 <= local <= 0.055:
                # Wings beat fast enough to break the tone into a trill.
                trill = 0.5 + 0.5 * math.sin(2.0 * math.pi * 44.0 * local)
                tone = math.sin(2.0 * math.pi * (4180.0 + 220.0 * local) * local)
                body = math.sin(2.0 * math.pi * 2090.0 * local) * 0.25
                value += (tone + body) * trill * env(local, 0.004, 0.030) * 0.55 * loud
        # A whisper of floor grit keeps the insect in the room with the player.
        value += random.uniform(-1.0, 1.0) * 0.012
        out.append(soft_clip(value))
    return out


def noise_frame():
    return random.uniform(-1.0, 1.0)


def main():
    write_wav("net_swish.wav", net_swish(), peak=0.55)
    write_wav("cricket_chirp.wav", cricket_chirp(), peak=0.50)


if __name__ == "__main__":
    main()
