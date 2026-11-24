"""Synthesise the creature-combat sound set.

These are original recordings made from scratch (no samples, no downloads), in
the same spirit as `machete_swing.wav`: filtered noise and tuned sine bodies
shaped by short envelopes. They replace the placeholder trick of pitching a
machete swing down to stand in for a body, and a metal clank standing in for a
wound.

Run:  python tools/create_creature_audio.py
Writes assets/audio/flesh_impact.wav, player_hurt.wav, slime_coil.wav and
slime_slam.wav.
"""

import math
import random
import struct
import wave

RATE = 22050
OUT_DIR = "assets/audio"


def noise_frame():
    return random.uniform(-1.0, 1.0)


class LowPass:
    """One-pole low pass; cheap and smooth enough for a 0.5 s impact."""

    def __init__(self, cutoff):
        self.a = math.exp(-2.0 * math.pi * cutoff / RATE)
        self.z = 0.0

    def __call__(self, x):
        self.z = (1.0 - self.a) * x + self.a * self.z
        return self.z


class BandPass:
    """RBJ constant-peak band pass, used for the wet/squelch character."""

    def __init__(self, freq, q):
        w0 = 2.0 * math.pi * freq / RATE
        alpha = math.sin(w0) / (2.0 * q)
        cos_w0 = math.cos(w0)
        b0 = alpha
        b1 = 0.0
        b2 = -alpha
        a0 = 1.0 + alpha
        a1 = -2.0 * cos_w0
        a2 = 1.0 - alpha
        self.b0, self.b1, self.b2 = b0 / a0, b1 / a0, b2 / a0
        self.a1, self.a2 = a1 / a0, a2 / a0
        self.x1 = self.x2 = self.y1 = self.y2 = 0.0
        # Static gain so a band-passed noise burst keeps a usable level.
        self.gain = 2.2

    def __call__(self, x):
        y = (
            self.b0 * x
            + self.b1 * self.x1
            + self.b2 * self.x2
            - self.a1 * self.y1
            - self.a2 * self.y2
        )
        self.x2, self.x1 = self.x1, x
        self.y2, self.y1 = self.y1, y
        return y * self.gain

    def set_freq(self, freq, q):
        w0 = 2.0 * math.pi * freq / RATE
        alpha = math.sin(w0) / (2.0 * q)
        cos_w0 = math.cos(w0)
        a0 = 1.0 + alpha
        self.b0 = alpha / a0
        self.b1 = 0.0
        self.b2 = -alpha / a0
        self.a1 = -2.0 * cos_w0 / a0
        self.a2 = (1.0 - alpha) / a0


def env(t, attack, decay):
    if t < attack:
        return t / attack if attack > 0.0 else 1.0
    return math.exp(-(t - attack) / max(decay, 1e-4))


def soft_clip(x):
    return math.tanh(x * 1.35)


def write_wav(name, samples, peak=0.86):
    top = max(abs(s) for s in samples) or 1.0
    scale = peak / top
    data = b"".join(struct.pack("<h", int(max(-32767, min(32767, s * scale * 32767)))) for s in samples)
    path = "%s/%s" % (OUT_DIR, name)
    with wave.open(path, "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes(data)
    print("wrote %-18s %5.2fs" % (name, len(samples) / RATE))


def flesh_impact():
    """A blade going into a gel body: body thump, wet burst, short squelch."""
    length = int(RATE * 0.42)
    out = []
    thump = LowPass(400.0)
    wet = BandPass(700.0, 1.1)
    squelch = BandPass(320.0, 2.4)
    for i in range(length):
        t = i / RATE
        # Heavy body behind the wound, and it drops in pitch as the mass absorbs it.
        body = math.sin(2.0 * math.pi * (58.0 - 16.0 * min(t, 0.25)) * t) * env(t, 0.004, 0.075) * 0.95
        body = thump(body)
        # The wet part: bright noise at contact, then a narrower squelch.
        burst = wet(noise_frame()) * env(t, 0.002, 0.045) * 0.85
        slicks = squelch(noise_frame())
        slicks *= env(max(t - 0.045, 0.0), 0.012, 0.075) * 0.55
        slicks *= 0.55 + 0.45 * math.sin(2.0 * math.pi * 74.0 * t)
        out.append(soft_clip(body + burst + slicks))
    return out


def player_hurt():
    """A short pained exhale: breath pushed out over a dropping voiced tone."""
    length = int(RATE * 0.60)
    out = []
    breath = BandPass(850.0, 0.8)
    f1 = BandPass(620.0, 5.0)
    f2 = BandPass(1180.0, 7.0)
    phase = 0.0
    for i in range(length):
        t = i / RATE
        # Pitch sags through the exhale, which is what makes it read as pain
        # rather than a musical tone.
        pitch = 146.0 - 46.0 * min(1.0, t / 0.42)
        phase += 2.0 * math.pi * pitch / RATE
        saw = 2.0 * (phase / (2.0 * math.pi) % 1.0) - 1.0
        voiced = f1(saw) * 0.55 + f2(saw) * 0.30
        # Roughness: a little jitter on the vocal folds.
        voiced *= 1.0 + 0.06 * math.sin(2.0 * math.pi * 27.0 * t)
        air = breath(noise_frame()) * 0.75
        mix = (voiced + air) * env(t, 0.035, 0.24)
        out.append(soft_clip(mix * 0.9))
    return out


def slime_coil():
    """The wind-up: a wet, rising creak as the body gathers itself."""
    length = int(RATE * 0.48)
    out = []
    creak = BandPass(320.0, 2.2)
    hiss = BandPass(1500.0, 0.9)
    for i in range(length):
        t = i / RATE
        k = t / (length / RATE)
        creak.set_freq(300.0 + 780.0 * k * k, 2.0)
        creep = creak(noise_frame()) * 0.5
        # A rising pressure tone under the creak, so the cue has a pitch target.
        tone = math.sin(2.0 * math.pi * (150.0 + 260.0 * k) * t) * 0.22
        tone *= 1.0 + 0.10 * math.sin(2.0 * math.pi * 11.0 * t)
        wet_air = hiss(noise_frame()) * 0.16 * k
        out.append(soft_clip((creep + tone + wet_air) * env(t, 0.05, 0.9) * (0.35 + 0.65 * k)))
    return out


def slime_slam():
    """A gel body hitting concrete: flat slap, low slam, gel wobble tail."""
    length = int(RATE * 0.55)
    out = []
    slap = BandPass(950.0, 1.0)
    low = LowPass(220.0)
    for i in range(length):
        t = i / RATE
        hit = slap(noise_frame()) * env(t, 0.002, 0.05) * 0.9
        slam = math.sin(2.0 * math.pi * (62.0 - 18.0 * min(t, 0.3)) * t) * env(t, 0.003, 0.10) * 0.85
        slam = low(slam)
        # The wobble is the gel settling, not a reverb tail.
        wobble = math.sin(2.0 * math.pi * (168.0 - 60.0 * min(t, 0.5)) * t) * env(t, 0.01, 0.13) * 0.26
        wobble *= 0.6 + 0.4 * math.sin(2.0 * math.pi * 9.5 * t)
        out.append(soft_clip(hit + slam + wobble))
    return out


def main():
    write_wav("flesh_impact.wav", flesh_impact())
    write_wav("player_hurt.wav", player_hurt(), peak=0.78)
    write_wav("slime_coil.wav", slime_coil(), peak=0.62)
    write_wav("slime_slam.wav", slime_slam())


if __name__ == "__main__":
    main()
