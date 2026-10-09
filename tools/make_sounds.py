"""Makes every sound in Defend the Village! from nothing: the effects (the web version's recipes, and new ones),
the ambient loops (day, night, rain, the castle) and the two tunes (day and night). Writes WAV files into
godot/sounds/. Run from the repository's top folder:  python3 tools/make_sounds.py

Everything is made with numpy, so nothing is downloaded and the sounds can be tuned here and made again."""

import os
import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, lfilter

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "godot", "sounds")
rng = np.random.default_rng(1337)


# ------------------------------------------------------------------ building blocks
def buf(seconds):
    return np.zeros(int(SR * seconds) + 1)


def add(b, x, at=0.0):
    i = int(at * SR)
    if i >= len(b):
        return b
    n = min(len(x), len(b) - i)
    b[i:i + n] += x[:n]
    return b


def lowpass(x, fc, order=2):
    fc = min(fc, SR / 2 - 100)
    bb, aa = butter(order, fc / (SR / 2), "low")
    return lfilter(bb, aa, x)


def highpass(x, fc, order=2):
    bb, aa = butter(order, fc / (SR / 2), "high")
    return lfilter(bb, aa, x)


def bandpass(x, lo, hi, order=2):
    bb, aa = butter(order, [lo / (SR / 2), min(hi, SR / 2 - 100) / (SR / 2)], "band")
    return lfilter(bb, aa, x)


def osc(freq, wave):
    """freq: an array of frequencies, one per sample. Returns the waveform."""
    ph = np.cumsum(freq / SR)
    p = ph % 1.0
    if wave == "sine":
        return np.sin(2 * np.pi * ph)
    if wave == "square":
        return np.where(p < 0.5, 1.0, -1.0) * 0.8
    if wave == "triangle":
        return 4 * np.abs(p - 0.5) - 1
    if wave == "sawtooth":
        return (2 * p - 1) * 0.8
    raise ValueError(wave)


def tone(f, dur, wave="sine", g=0.5, f2=None, attack=0.004):
    """The web version's tone(): a note that slides from f to f2 and dies away exponentially."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    freq = f * (f2 / f) ** (t / dur) if f2 else np.full(n, float(f))
    env = g * (0.001 / g) ** (t / dur)
    a = int(attack * SR)
    if a:
        env[:a] *= np.linspace(0, 1, a)
    return osc(freq, wave) * env


def noise(dur, g=0.5, fc=2000, shape="fade"):
    """The web version's noise(): white noise, fading out, through a low-pass filter."""
    n = int(dur * SR)
    x = rng.uniform(-1, 1, n)
    if shape == "fade":
        x *= 1 - np.arange(n) / n
    return lowpass(x, fc) * g


def brown(n):
    x = np.cumsum(rng.uniform(-1, 1, n))
    x -= lowpass(x, 8)                          # keep it from wandering off
    return x / (np.max(np.abs(x)) + 1e-9)


def reverb(x, seconds=0.9, mix=0.25, damp=3000):
    n = int(seconds * SR)
    ir = rng.uniform(-1, 1, n) * np.exp(-np.arange(n) / SR * 6 / seconds)
    ir = lowpass(ir, damp)
    wet = np.convolve(x, ir)
    wet = np.concatenate([wet, np.zeros(max(0, len(x) + n - len(wet)))])[: len(x) + n]
    wet /= np.max(np.abs(wet)) + 1e-9
    dry = np.concatenate([x, np.zeros(n)])
    return dry + wet * mix * np.max(np.abs(x))


def pluck(f, dur, g=0.5, bright=0.5):
    """A plucked string (Karplus-Strong): the lute and the harp."""
    n = int(dur * SR)
    p = max(2, int(SR / f))
    line = rng.uniform(-1, 1, p)
    line = lowpass(line, 1500 + 6000 * bright)
    out = np.zeros(n)
    idx = 0
    decay = 0.996
    for i in range(n):
        v = line[idx]
        nxt = line[(idx + 1) % p]
        line[idx] = decay * 0.5 * (v + nxt)
        out[i] = v
        idx = (idx + 1) % p
    env = np.ones(n)
    tail = int(0.05 * SR)
    env[-tail:] = np.linspace(1, 0, tail)
    return out * env * g


def seamless(x, fade=1.0):
    """Make a loop: the tail is faded into the head, so it can repeat without a click."""
    f = int(fade * SR)
    head = x[:f].copy()
    body = x[f:].copy()
    ramp = np.linspace(0, 1, f)
    body[-f:] = body[-f:] * (1 - ramp) + head * ramp
    return body


def save(name, x, peak=None, stereo=False):
    x = np.asarray(x, dtype=np.float64)
    if peak is not None:
        x = x / (np.max(np.abs(x)) + 1e-9) * peak
    x = np.clip(x, -1, 1)
    os.makedirs(OUT, exist_ok=True)
    wavfile.write(os.path.join(OUT, name + ".wav"), SR, (x * 32767).astype(np.int16))


NOTE = {"C": -9, "C#": -8, "Db": -8, "D": -7, "D#": -6, "Eb": -6, "E": -5, "F": -4, "F#": -3, "Gb": -3,
        "G": -2, "G#": -1, "Ab": -1, "A": 0, "A#": 1, "Bb": 1, "B": 2}


def hz(n):
    name, octave = n[:-1], int(n[-1])
    return 440.0 * 2 ** ((NOTE[name] + (octave - 4) * 12) / 12)


# ------------------------------------------------------------------ the effects (the web version's, one for one)
V = 0.5                                         # the web version's overall level


def sfx():
    S = {}

    def mix(dur, *parts):
        b = buf(dur)
        for x, at in parts:
            add(b, x, at)
        return b * V

    S["chop"] = mix(0.12, (noise(0.07, 0.8, 1800), 0), (tone(170, 0.09, "triangle", 0.5, 90), 0))
    S["pluck"] = mix(0.06, (noise(0.05, 0.3, 1400), 0))
    S["swing"] = mix(0.1, (noise(0.09, 0.25, 900), 0))
    S["hit"] = mix(0.12, (noise(0.06, 0.7, 1200), 0), (tone(120, 0.1, "square", 0.25, 60), 0))
    S["bone"] = mix(0.12, (tone(620, 0.05, "square", 0.2, 380), 0), (tone(420, 0.06, "square", 0.18, 240), 0.05))
    S["hurt"] = mix(0.2, (tone(190, 0.18, "sawtooth", 0.35, 90), 0))
    S["build"] = mix(0.22, (noise(0.05, 0.8, 2200), 0), (noise(0.05, 0.8, 2200), 0.13), (tone(210, 0.07, "triangle", 0.4, 150), 0.13))
    S["pop"] = mix(0.1, (tone(520, 0.08, "triangle", 0.3, 780), 0))
    S["no"] = mix(0.14, (tone(160, 0.12, "square", 0.15, 120), 0))
    S["pick"] = mix(0.08, (noise(0.04, 0.7, 3200), 0), (tone(520, 0.05, "square", 0.12, 300), 0))
    S["coin"] = mix(0.18, (tone(1320, 0.07, "square", 0.12), 0), (tone(1760, 0.1, "square", 0.1), 0.06))
    S["forge"] = mix(0.34, (tone(880, 0.12, "square", 0.16, 700), 0), (noise(0.05, 0.7, 4000), 0), (tone(660, 0.14, "square", 0.14, 520), 0.16), (noise(0.05, 0.6, 4000), 0.16))
    S["splash"] = mix(0.24, (noise(0.22, 0.5, 900), 0))
    S["raise"] = mix(0.62, (tone(110, 0.6, "sawtooth", 0.22, 220), 0), (tone(165, 0.6, "sine", 0.2, 330), 0))
    S["keep"] = mix(0.32, (tone(70, 0.3, "sine", 0.9, 40), 0), (noise(0.12, 0.5, 400), 0))
    bell = buf(3.5)
    for i in range(3):
        add(bell, tone(392, 1.6, "sine", 0.5), i * 0.9)
        add(bell, tone(784, 1.0, "sine", 0.18), i * 0.9)
        add(bell, tone(1180, 0.6, "sine", 0.08), i * 0.9)
    S["bell"] = reverb(bell * V, 1.4, 0.35)
    dawn = buf(1.1)
    for i, f in enumerate([392, 494, 587, 784]):
        add(dawn, tone(f, 0.5, "triangle", 0.35), i * 0.16)
    S["dawn"] = reverb(dawn * V, 0.8, 0.2)
    S["gulp"] = mix(0.27, (tone(300, 0.09, "sine", 0.4, 180), 0), (tone(260, 0.09, "sine", 0.4, 150), 0.16))
    S["clang"] = mix(0.52, (tone(1250, 0.5, "square", 0.16, 1180), 0), (tone(1870, 0.4, "sine", 0.14), 0), (noise(0.05, 0.8, 5000), 0))
    ring = buf(1.2)
    for i in range(2):
        add(ring, tone(1568, 0.9, "sine", 0.35), i * 0.25)
        add(ring, tone(2350, 0.6, "sine", 0.12), i * 0.25)
    S["ring"] = reverb(ring * V, 1.0, 0.3)
    holy = buf(0.9)
    for i, f in enumerate([523, 659, 784]):
        add(holy, tone(f, 0.7, "sine", 0.22), i * 0.07)
    S["holy"] = reverb(holy * V, 1.2, 0.4)
    S["thump"] = mix(0.27, (tone(90, 0.25, "sine", 0.9, 45), 0), (noise(0.1, 0.6, 500), 0))
    S["splat"] = mix(0.22, (noise(0.2, 0.7, 500), 0), (tone(140, 0.12, "sawtooth", 0.2, 70), 0))
    S["find"] = mix(0.28, (tone(660, 0.1, "triangle", 0.3), 0), (tone(880, 0.16, "triangle", 0.3), 0.09))
    relic = buf(1.5)
    for i, f in enumerate([523, 659, 784, 1047, 1319]):
        add(relic, tone(f, 0.9, "sine", 0.26), i * 0.11)
    S["relic"] = reverb(relic * V, 1.2, 0.35)
    S["cheer"] = mix(0.52, (noise(0.5, 0.35, 1500), 0), (tone(330, 0.3, "sawtooth", 0.14, 520), 0))
    lost = buf(2.0)
    for i, f in enumerate([330, 262, 196, 147]):
        add(lost, tone(f, 0.7, "sawtooth", 0.22), i * 0.3)
    S["lost"] = reverb(lowpass(lost, 2500) * V, 1.2, 0.3)

    # --- new ones
    won = buf(2.4)                               # the week is held: a little fanfare
    for i, (f, d) in enumerate([(392, 0.2), (392, 0.2), (523, 0.3), (659, 0.3), (784, 0.9)]):
        add(won, tone(f, d + 0.3, "triangle", 0.35), [0, 0.18, 0.36, 0.62, 0.9][i])
        add(won, tone(f * 2, d + 0.2, "sine", 0.08), [0, 0.18, 0.36, 0.62, 0.9][i])
    S["won"] = reverb(won * V, 1.2, 0.3)
    page = noise(0.25, 0.25, 5000, "flat")      # a page turned: a window opens
    page = bandpass(page, 1500, 7000) * np.sin(np.linspace(0, np.pi, len(page))) ** 2
    S["page"] = page * V * 1.6
    S["knock"] = mix(0.7, *[(tone(140, 0.08, "sine", 0.8, 90), t) for t in (0, 0.22, 0.44)], *[(noise(0.04, 0.45, 900), t) for t in (0, 0.22, 0.44)])
    S["stone"] = mix(0.14, (noise(0.06, 0.8, 3500), 0), (tone(320, 0.08, "square", 0.12, 200), 0))
    S["iron"] = mix(0.3, (tone(1900, 0.25, "sine", 0.18, 1850), 0), (noise(0.04, 0.6, 5000), 0), (tone(950, 0.15, "square", 0.08, 900), 0))
    S["eat"] = mix(0.3, (noise(0.05, 0.4, 2500), 0), (noise(0.05, 0.35, 2500), 0.12), (tone(240, 0.06, "sine", 0.3, 200), 0.2))
    S["rally"] = mix(0.36, (tone(392, 0.12, "triangle", 0.25), 0), (tone(523, 0.2, "triangle", 0.3), 0.12))
    S["steward"] = reverb(mix(1.3, (tone(70, 1.2, "sawtooth", 0.45, 48), 0), (tone(105, 1.2, "sawtooth", 0.25, 70), 0.05), (noise(1.0, 0.3, 300), 0)), 1.0, 0.4)
    for k in range(3):                         # the dead, groaning (each a little different)
        d = 0.9 + 0.2 * k
        f0 = [92, 110, 82][k]
        t = np.arange(int(d * SR)) / SR
        fr = f0 * (1 + 0.25 * np.sin(np.pi * t / d)) * (1 + 0.03 * np.sin(2 * np.pi * 6 * t))
        g = np.sin(np.pi * t / d) ** 1.5
        x = lowpass(osc(fr, "sawtooth") * g + rng.uniform(-1, 1, len(t)) * g * 0.25, 900)
        S["groan%d" % k] = x * 0.35 * V * 2
    rattle = buf(0.35)                          # a skeleton, rattling
    for i in range(7):
        add(rattle, tone(rng.uniform(700, 1400), 0.03, "square", 0.12), i * 0.045 + rng.uniform(0, 0.01))
    S["rattle"] = rattle * V
    for k in range(2):                          # thunder, after the lightning
        d = 3.5 + k
        x = brown(int(d * SR))
        env = np.exp(-np.arange(len(x)) / SR * 1.1) * (1 - np.exp(-np.arange(len(x)) / SR * 12))
        crack = np.zeros(len(x))
        crack[: int(0.4 * SR)] = noise(0.4, 0.5, 2500) if k == 0 else noise(0.4, 0.2, 1500)
        S["thunder%d" % k] = (lowpass(x, 220) * env * 1.2 + crack) * V
    for k in range(2):                          # a crow
        x = buf(0.6)
        for j in range(2 if k == 0 else 3):
            d = 0.16
            t = np.arange(int(d * SR)) / SR
            fr = 700 + 300 * np.sin(np.pi * t / d)
            g = np.sin(np.pi * t / d)
            add(x, bandpass(osc(fr, "sawtooth") * g + rng.uniform(-1, 1, len(t)) * g * 0.4, 500, 2500) * 0.6, j * 0.2)
        S["caw%d" % k] = x * V
    hoot = buf(1.4)                             # an owl
    for t0, f in ((0, 420), (0.45, 400), (0.7, 395)):
        t = np.arange(int(0.32 * SR)) / SR
        g = np.sin(np.pi * t / 0.32) ** 2
        add(hoot, np.sin(2 * np.pi * f * t) * g * 0.3, t0)
    S["owl"] = reverb(hoot * V, 1.0, 0.3)
    S["door"] = mix(0.9, (tone(180, 0.7, "sawtooth", 0.12, 230), 0), (noise(0.6, 0.15, 900), 0), (tone(90, 0.15, "sine", 0.6, 60), 0.7))
    S["jeer"] = mix(0.7, (noise(0.6, 0.3, 1800), 0), (tone(260, 0.25, "sawtooth", 0.12, 200), 0), (tone(240, 0.3, "sawtooth", 0.12, 160), 0.3))
    for k, x in S.items():
        save("sfx_" + k, x)


# ------------------------------------------------------------------ ambient loops
def ambient():
    # the day: a breeze, and birds
    d = 25.0
    n = int(d * SR)
    t = np.arange(n) / SR
    wind = lowpass(brown(n), 500) * (0.55 + 0.45 * np.sin(2 * np.pi * t / 12.5)) * 0.35
    birds = np.zeros(n)
    for _ in range(46):
        at = rng.uniform(0, d - 1)
        kind = rng.integers(0, 3)
        notes = rng.integers(2, 6)
        f0 = rng.uniform(2600, 4600)
        for j in range(notes):
            dur = rng.uniform(0.05, 0.12)
            tt = np.arange(int(dur * SR)) / SR
            sweep = f0 * (1 + (0.25 if kind == 0 else -0.2 if kind == 1 else 0.08 * np.sin(2 * np.pi * 30 * tt)) * tt / dur)
            g = np.sin(np.pi * tt / dur) ** 2 * rng.uniform(0.05, 0.12)
            add(birds, osc(sweep, "sine") * g, at + j * (dur + rng.uniform(0.02, 0.06)))
    save("amb_day", seamless(wind + birds), 0.5)

    # the night: crickets, a low wind, and an owl now and then
    d = 24.0
    n = int(d * SR)
    t = np.arange(n) / SR
    crick = np.zeros(n)
    for f, rate, ph in ((4300, 0.62, 0.0), (3900, 0.81, 0.3), (4700, 0.55, 0.15)):
        gate = ((t * rate + ph) % 1.0 < 0.18) * (np.sin(2 * np.pi * 28 * t) > 0.2)
        crick += np.sin(2 * np.pi * f * t) * lowpass(gate.astype(float), 300) * 0.06
    wind = lowpass(brown(n), 300) * (0.6 + 0.4 * np.sin(2 * np.pi * t / 8)) * 0.5
    save("amb_night", seamless(crick + wind), 0.5)

    # rain
    d = 16.0
    n = int(d * SR)
    rain = bandpass(rng.uniform(-1, 1, n), 700, 7000) * 0.25
    drops = np.zeros(n)
    for _ in range(900):
        at = int(rng.uniform(0, n - 400))
        drops[at:at + 120] += np.exp(-np.arange(120) / 18) * rng.uniform(-0.4, 0.4)
    drops = highpass(drops, 1200)
    save("amb_rain", seamless(rain + drops * 0.6), 0.55)

    # the castle: a low drone that beats against itself, and a wind that moans
    d = 20.0
    n = int(d * SR)
    t = np.arange(n) / SR
    drone = (np.sin(2 * np.pi * 55 * t) + 0.7 * np.sin(2 * np.pi * 55.6 * t) + 0.5 * np.sin(2 * np.pi * 82.3 * t)
             + 0.25 * np.sin(2 * np.pi * 116.5 * t) * (0.5 + 0.5 * np.sin(2 * np.pi * t / 5))) * 0.25
    moan_f = 520 + 160 * np.sin(2 * np.pi * t / 6.6) + 60 * np.sin(2 * np.pi * t / 2.2)
    moan = np.zeros(n)
    w = rng.uniform(-1, 1, n)
    for i in range(0, n, 2048):                 # a band of wind that slides up and down
        seg = w[i:i + 2048]
        f = moan_f[i]
        moan[i:i + 2048] = bandpass(seg, f * 0.85, f * 1.15)[: len(seg)]
    moan = lowpass(moan, 1600) * (0.4 + 0.6 * np.sin(2 * np.pi * t / 10) ** 2) * 1.6
    save("amb_castle", seamless(drone + moan, 2.0), 0.5)


# ------------------------------------------------------------------ the tunes
def music():
    # by day: a lute tune in D Dorian over a drone, with a frame drum. 96 beats a minute, sixteen bars.
    bpm = 96
    beat = 60 / bpm
    p1 = [("D4", 1), ("F4", .5), ("G4", .5), ("A4", 1), ("A4", .5), ("G4", .5),
          ("F4", .5), ("E4", .5), ("D4", 1), ("E4", 1), ("F4", 1),
          ("G4", 1), ("A4", .5), ("B4", .5), ("C5", 1), ("A4", 1),
          ("G4", .5), ("F4", .5), ("E4", 1), ("D4", 2)]
    p2 = [("A4", 1), ("C5", .5), ("D5", .5), ("C5", 1), ("A4", 1),
          ("G4", 1), ("A4", .5), ("G4", .5), ("F4", 1), ("D4", 1),
          ("E4", 1), ("F4", 1), ("G4", 1), ("E4", 1),
          ("D4", 3), (None, 1)]
    p3 = [("F4", .5), ("G4", .5), ("A4", 1), ("D5", 1), ("C5", .5), ("A4", .5),
          ("G4", 1), ("F4", .5), ("G4", .5), ("A4", 2),
          ("C5", 1), ("B4", .5), ("A4", .5), ("G4", 1), ("E4", 1),
          ("F4", 1), ("E4", 1), ("D4", 2)]
    tune = p1 + p2 + p3 + p2
    roots = ["D", "D", "C", "D", "F", "C", "C", "D", "F", "C", "C", "A", "F", "C", "C", "D"]
    bars = len(roots)
    total = bars * 4 * beat
    b = buf(total + 3)
    t_ = 0.0
    for n, d in tune:
        if n:
            add(b, pluck(hz(n), d * beat + 0.9, 0.42, 0.6), t_)
        t_ += d * beat
    for i, r in enumerate(roots):                # the bass: root, fifth, root, fifth on a lower string
        root = hz(r + "3") if r in ("C", "D") else hz(r + "2")
        for k, mult in enumerate([1, 1.5, 2, 1.5]):
            add(b, pluck(root * mult / (2 if mult == 2 else 1), beat * 1.2, 0.22, 0.3), (i * 4 + k) * beat)
    tt = np.arange(len(b)) / SR                  # a bowed drone on D and A, very soft
    drone = lowpass(osc(np.full(len(b), hz("D3")), "sawtooth") + 0.6 * osc(np.full(len(b), hz("A3")), "sawtooth"), 700)
    b += drone * 0.05 * (0.8 + 0.2 * np.sin(2 * np.pi * tt / 7))
    for i in range(bars):                         # the frame drum: on one, and the "and" of three
        for at, g in ((0, 0.5), (2.5, 0.3), (3, 0.25)):
            add(b, tone(85, 0.25, "sine", g, 55), (i * 4 + at) * beat)
            add(b, noise(0.05, g * 0.3, 700), (i * 4 + at) * beat)
    loop_n = int(total * SR)
    tail = b[loop_n:]                             # what rings on past the end goes over the beginning
    body = b[:loop_n].copy()
    body[: len(tail)] += tail
    save("music_day", reverb(body, 1.0, 0.18)[:loop_n], 0.7)

    # by night: slow, low and uneasy. A drone, a heartbeat, a harp picking out minor chords, and now and then a
    # voice-like whistle that is probably the wind.
    bpm = 62
    beat = 60 / bpm
    chords = [["D3", "A3", "D4", "F4"], ["D3", "A3", "D4", "F4"], ["Bb2", "F3", "Bb3", "D4"], ["A2", "E3", "A3", "C#4"],
              ["D3", "A3", "D4", "F4"], ["G2", "D3", "G3", "Bb3"], ["Eb3", "Bb3", "Eb4", "G4"], ["A2", "E3", "A3", "C#4"],
              ["D3", "F3", "A3", "D4"], ["C3", "G3", "C4", "Eb4"], ["Bb2", "F3", "Bb3", "D4"], ["A2", "E3", "A3", "C#4"],
              ["G2", "D3", "G3", "Bb3"], ["Eb3", "Bb3", "Eb4", "G4"], ["D3", "A3", "D4", "F4"], ["A2", "E3", "A3", "C#4"]]
    bars = len(chords)
    total = bars * 4 * beat
    b = buf(total + 4)
    for i, ch in enumerate(chords):
        pattern = [(0, 0), (1, 1), (1.5, 2), (2.5, 3), (3, 2)] if i % 2 == 0 else [(0, 0), (1.5, 2), (2, 3), (3.5, 1)]
        for at, k in pattern:
            add(b, pluck(hz(ch[k]), 2.6, 0.3, 0.35), (i * 4 + at) * beat)
        for at in (0, 0.38):                      # the heartbeat
            add(b, tone(55, 0.35, "sine", 0.9 if at == 0 else 0.6, 38), (i * 4) * beat + at)
    tt = np.arange(len(b)) / SR
    drone = (np.sin(2 * np.pi * hz("D2") * tt) + 0.6 * np.sin(2 * np.pi * hz("A2") * 1.003 * tt)) * 0.12
    drone *= 0.75 + 0.25 * np.sin(2 * np.pi * tt / 3.1)
    b += drone
    for start in (6 * 4 * beat, 13 * 4 * beat):   # the whistle
        d = 5.0
        t = np.arange(int(d * SR)) / SR
        f = hz("A5") * (1 - 0.12 * t / d) * (1 + 0.012 * np.sin(2 * np.pi * 5 * t))
        g = np.sin(np.pi * t / d) ** 2 * 0.07
        add(b, osc(f, "sine") * g, start)
    loop_n = int(total * SR)
    tail = b[loop_n:]
    body = b[:loop_n].copy()
    body[: len(tail)] += tail
    save("music_night", reverb(body, 1.6, 0.3)[:loop_n], 0.7)


if __name__ == "__main__":
    sfx()
    ambient()
    music()
    print("made", len(os.listdir(OUT)), "sounds in", os.path.abspath(OUT))
