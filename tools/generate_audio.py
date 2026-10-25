#!/usr/bin/env python3
"""Synthesises all sound effects and the looping music. Run from the project root: python3 tools/generate_audio.py"""
import math, os, random, struct, wave

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)
SR = 22050
rnd = random.Random(5)


def write(name, samples, vol=0.8):
    peak = max(1e-6, max(abs(s) for s in samples))
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s / peak * vol)) * 32767)) for s in samples))


def sine(f, t): return math.sin(2 * math.pi * f * t)
def square(f, t): return 1.0 if (f * t) % 1.0 < 0.5 else -1.0
def tri(f, t): return 4 * abs((f * t) % 1.0 - 0.5) - 1
def noise(): return rnd.uniform(-1, 1)


def tone_seq(notes, wavef, dur_each, decay=6.0):
    out = []
    for f in notes:
        n = int(SR * dur_each)
        out += [wavef(f, i / SR) * math.exp(-decay * i / n) * min(1, i / 60) for i in range(n)]
    return out


def sweep(f0, f1, dur, wavef=sine, decay=3.0, noise_amt=0.0):
    n = int(SR * dur); out = []; ph = 0.0
    for i in range(n):
        f = f0 + (f1 - f0) * (i / n)
        ph += f / SR
        v = wavef(1.0, ph) * (1 - noise_amt) + noise() * noise_amt
        out.append(v * math.exp(-decay * i / n) * min(1, i / 40))
    return out


write("cast", [a * 0.7 + b * 0.3 for a, b in zip(sweep(380, 1100, 0.18, sine, 4, 0.1), sweep(190, 550, 0.18, tri, 4))])
hit = []
lp = 0.0
for i in range(int(SR * 0.1)):
    lp += (noise() - lp) * 0.35
    hit.append((lp * 0.8 + sine(140 - 600 * i / SR, i / SR) * 0.6) * math.exp(-30 * i / SR * 0.35 * 10 / 10) * math.exp(-i / (SR * 0.03)))
write("hit", hit)
death = sweep(320, 50, 0.32, square, 3.5, 0.35)
write("zombie_death", death, 0.7)
write("coin", tone_seq([988, 1319], square, 0.07, 5), 0.5)
write("upgrade", tone_seq([523, 659, 784, 1047], tri, 0.09, 3), 0.8)
write("deny", sweep(160, 110, 0.14, square, 2.0, 0.1), 0.45)
write("wave", tone_seq([196, 196, 262], square, 0.16, 2.0), 0.55)
over = []
for f in (392, 349, 311, 262, 196):
    over += tone_seq([f], tri, 0.22, 2.0)
over += sweep(196, 90, 0.5, tri, 3.0)
write("game_over", over, 0.8)

# ---- music: 8 bars A-minor loop, bass + arpeggio + soft pad + hats
BPM = 104
beat = 60 / BPM
chords = [(57, [57, 60, 64]), (53, [53, 57, 60]), (48, [48, 52, 55]), (55, [55, 59, 62])] * 2  # root, triad (midi)
mtof = lambda m: 440 * 2 ** ((m - 69) / 12)
total = int(SR * beat * 4 * len(chords))
buf = [0.0] * total
def add(start_t, dur, f, wavef, amp, decay):
    s = int(start_t * SR); n = int(dur * SR)
    for i in range(n):
        if s + i >= total: break
        t = i / SR
        buf[s + i] += wavef(f, t) * amp * math.exp(-decay * t / dur) * min(1, i / 80)
for bar, (root, triad) in enumerate(chords):
    t0 = bar * beat * 4
    for b in range(4):  # bass: root / octave pattern
        add(t0 + b * beat, beat * 0.9, mtof(root - 12 + (12 if b == 2 else 0)), tri, 0.5, 2.5)
    for k in range(8):  # eighth-note arpeggio
        note = triad[[0, 1, 2, 1, 0, 1, 2, 1][k]] + 12 + (12 if k in (3, 7) and bar % 2 else 0)
        add(t0 + k * beat / 2, beat * 0.55, mtof(note), square, 0.12, 4)
    for n in triad:  # pad
        add(t0, beat * 4, mtof(n), sine, 0.07, 0.6)
    for k in range(8):  # hats
        s = int((t0 + k * beat / 2) * SR)
        for i in range(int(SR * 0.03)):
            if s + i < total: buf[s + i] += noise() * 0.05 * (1 - i / (SR * 0.03)) * (1.6 if k % 2 else 1)
    for k in (0, 2):  # kick
        s = int((t0 + k * beat) * SR)
        for i in range(int(SR * 0.12)):
            if s + i < total: buf[s + i] += sine(110 - 700 * i / SR * 0.12, i / SR) * 0.5 * math.exp(-i / (SR * 0.05))
write("music", buf, 0.6)
print("audio done")
