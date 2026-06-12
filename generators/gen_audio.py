#!/usr/bin/env python3
"""
Procedural audio generator for Hunkle Bunkle.
Writes WAV files to assets/sfx/ and assets/music/ that override the
GDScript runtime synthesis in audio.gd (file-first fallback path).

No external dependencies — stdlib wave + struct + math only.
"""
import wave, struct, math, os, random

SAMPLE_RATE = 22050
random.seed(42)   # reproducible noise across runs


# ── WAV output ───────────────────────────────────────────────────────────────

def _save(path: str, samples: list) -> None:
    """Write float samples [-1, 1] as 16-bit mono PCM WAV."""
    data = bytearray()
    for s in samples:
        v = max(-32768, min(32767, int(s * 32767.0)))
        data += struct.pack("<h", v)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(bytes(data))


# ── Mixing ────────────────────────────────────────────────────────────────────

def _mix(*tracks) -> list:
    """Sum tracks, soft-limit to ±0.82."""
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    peak = max(abs(v) for v in out) if out else 1.0
    if peak > 0.82:
        out = [v * 0.82 / peak for v in out]
    return out


# ── Oscillators ───────────────────────────────────────────────────────────────

def _sine(freq: float, dur: float, vol: float = 0.5) -> list:
    n, phase, out = int(SAMPLE_RATE * dur), 0.0, []
    for _ in range(n):
        out.append(math.sin(phase) * vol)
        phase += math.tau * freq / SAMPLE_RATE
    return out

def _square(freq: float, dur: float, vol: float = 0.5) -> list:
    n, phase, out = int(SAMPLE_RATE * dur), 0.0, []
    for _ in range(n):
        out.append((1.0 if math.sin(phase) >= 0 else -1.0) * vol)
        phase += math.tau * freq / SAMPLE_RATE
    return out

def _triangle(freq: float, dur: float, vol: float = 0.5) -> list:
    n, phase, out = int(SAMPLE_RATE * dur), 0.0, []
    for _ in range(n):
        p = (phase / math.tau) % 1.0
        v = 4*p - 1 if p < 0.5 else 3 - 4*p
        out.append(v * vol)
        phase += math.tau * freq / SAMPLE_RATE
    return out

def _sweep(f0: float, f1: float, dur: float, vol: float = 0.5,
           wave: str = "sine") -> list:
    """Frequency sweep with bell envelope."""
    n, phase, out = int(SAMPLE_RATE * dur), 0.0, []
    for i in range(n):
        t = i / n
        freq = f0 + (f1 - f0) * t
        env = math.sin(t * math.pi)
        p = math.sin(phase)
        if wave == "square":
            p = 1.0 if p >= 0 else -1.0
        out.append(p * vol * env)
        phase += math.tau * freq / SAMPLE_RATE
    return out

def _noise(dur: float, vol: float = 0.5) -> list:
    n = int(SAMPLE_RATE * dur)
    return [(random.random() * 2 - 1) * vol for _ in range(n)]

def _noise_decay(dur: float, vol: float = 0.5, curve: float = 1.5) -> list:
    n = int(SAMPLE_RATE * dur)
    return [(random.random() * 2 - 1) * vol * (1 - i/n)**curve for i in range(n)]

def _silence(dur: float) -> list:
    return [0.0] * int(SAMPLE_RATE * dur)


# ── Envelope ──────────────────────────────────────────────────────────────────

def _adsr(s: list, attack: float, decay: float, sustain_level: float,
          sustain: float, release: float) -> list:
    a = int(attack * SAMPLE_RATE)
    d = int(decay * SAMPLE_RATE)
    su = int(sustain * SAMPLE_RATE)
    r = int(release * SAMPLE_RATE)
    out = []
    for i, v in enumerate(s):
        if i < a:
            env = i / a if a > 0 else 1.0
        elif i < a + d:
            env = 1.0 - (1 - sustain_level) * (i - a) / d if d > 0 else sustain_level
        elif i < a + d + su:
            env = sustain_level
        else:
            ri = i - a - d - su
            env = sustain_level * max(0.0, 1 - ri / r) if r > 0 else 0.0
        out.append(v * max(0.0, env))
    return out

def _fade_out(s: list, tail: float = 0.05) -> list:
    n = len(s)
    fade_n = min(int(SAMPLE_RATE * tail), n)
    out = list(s)
    for i in range(fade_n):
        out[n - fade_n + i] *= i / fade_n
    return out


# ── Multi-harmonic tone ───────────────────────────────────────────────────────

def _harmonics(freq: float, dur: float, vol: float, osc,
               ratios=(1.0, 2.0), weights=(1.0, 0.4)) -> list:
    total = sum(weights)
    return _mix(*[osc(freq * r, dur, vol * w / total)
                  for r, w in zip(ratios, weights)])


# ── Arpeggio ──────────────────────────────────────────────────────────────────

NOTE = {
    "C3":130.81,"D3":146.83,"E3":164.81,"F3":174.61,"G3":196.00,
    "A3":220.00,"B3":246.94,"C4":261.63,"D4":293.66,"E4":329.63,
    "F4":349.23,"G4":392.00,"A4":440.00,"Bb4":466.16,"B4":493.88,
    "C5":523.25,"D5":587.33,"E5":659.25,"F5":698.46,"G5":783.99,
    "A5":880.00,"B5":987.77,"C6":1046.50,"D6":1174.66,"R":0.0,
}

def _arpeggio(freqs: list, note_dur: float, vol: float = 0.5,
              osc=None, note_fade: float = 0.88) -> list:
    if osc is None:
        osc = _triangle
    out, v = [], vol
    for freq in freqs:
        n = int(SAMPLE_RATE * note_dur)
        gate = int(n * 0.82)
        phase = 0.0
        for i in range(n):
            if freq < 1.0 or i >= gate:
                out.append(0.0)
            else:
                env = 1.0 - i / gate * 0.88
                if osc == _square:
                    p = 1.0 if math.sin(phase) >= 0 else -1.0
                elif osc == _triangle:
                    ph = (phase / math.tau) % 1.0
                    p = 4*ph - 1 if ph < 0.5 else 3 - 4*ph
                else:
                    p = math.sin(phase)
                out.append(p * v * env)
                phase += math.tau * freq / SAMPLE_RATE
        v *= note_fade
    return out


# ═══════════════════════════════════════════════════════════════════════════════
# SFX definitions
# ═══════════════════════════════════════════════════════════════════════════════

def sfx_attack():
    crack = _adsr(_square(380.0, 0.09, 0.55), 0.002, 0.01, 0.0, 0.0, 0.07)
    return _mix(crack, _noise_decay(0.04, 0.38))

def sfx_hit():
    thud = _adsr(_sine(72.0, 0.12, 0.50), 0.001, 0.005, 0.0, 0.0, 0.11)
    return _mix(thud, _noise_decay(0.06, 0.52, 2.2))

def sfx_dash():
    main  = _sweep(260.0, 880.0, 0.14, 0.48)
    upper = _sweep(520.0, 1760.0, 0.12, 0.16)
    return _mix(main, _silence(0.01) + upper)

def sfx_special():
    return _arpeggio([NOTE["C4"], NOTE["E4"], NOTE["G4"], NOTE["C5"]],
                     0.095, 0.50, _triangle)

def sfx_hurt():
    s = _adsr(_square(175.0, 0.20, 0.38), 0.003, 0.015, 0.40, 0.04, 0.08)
    return _mix(_sweep(220.0, 95.0, 0.18, 0.28), s, _noise_decay(0.06, 0.20))

def sfx_defeat():
    s = _sweep(280.0, 40.0, 0.80, 0.48, "square")
    n = _noise_decay(0.50, 0.25, 1.4)
    return _fade_out(_mix(s, n), 0.08)

def sfx_swap():
    h = _harmonics(680.0, 0.12, 0.46, _sine, (1.0, 2.0), (1.0, 0.3))
    return _adsr(h, 0.002, 0.0, 0.0, 0.0, 0.12)

def sfx_bies():
    main = _sweep(1200.0, 100.0, 0.65, 0.50)
    rise = _sweep(200.0, 700.0, 0.38, 0.18, "square")
    return _mix(main, _silence(0.10) + rise)

def sfx_ui_move():
    return _adsr(_sine(510.0, 0.07, 0.25), 0.001, 0.0, 0.0, 0.0, 0.065)

def sfx_ui_select():
    h = _harmonics(820.0, 0.10, 0.34, _sine, (1.0, 1.5), (1.0, 0.25))
    return _adsr(h, 0.001, 0.0, 0.0, 0.0, 0.10)

def sfx_puzzle_complete():
    return _arpeggio([NOTE["G4"], NOTE["B4"], NOTE["D5"], NOTE["G5"]],
                     0.13, 0.48, _triangle, 1.0)

def sfx_loot_open():
    a = _arpeggio([NOTE["C5"], NOTE["E5"], NOTE["G5"], NOTE["C6"]],
                  0.07, 0.42, _sine, 1.0)
    return _mix(a, _silence(0.025) + _noise_decay(0.04, 0.17))

def sfx_alert():
    # Two-tone sharp alarm — guard spotted player
    a = _sweep(400.0, 900.0, 0.11, 0.44, "square")
    b = _sweep(600.0, 1100.0, 0.09, 0.34, "square")
    return _mix(a, _silence(0.05) + b)

def sfx_dice_roll():
    return _noise_decay(0.12, 0.35, 1.3)

def sfx_spoon_pass():
    return _adsr(_sine(880.0, 0.07, 0.25), 0.001, 0.008, 0.0, 0.0, 0.06)

def sfx_spoon_power():
    return _arpeggio([NOTE["E4"], NOTE["G4"], NOTE["B4"], NOTE["E5"]],
                     0.085, 0.42, _triangle)

def sfx_spoon_eliminate():
    return _sweep(500.0, 120.0, 0.45, 0.48, "square")

def sfx_spoon_victory():
    return _arpeggio(
        [NOTE["C4"], NOTE["E4"], NOTE["G4"], NOTE["C5"], NOTE["E5"], NOTE["G5"]],
        0.085, 0.50, _triangle, 0.95)


# ═══════════════════════════════════════════════════════════════════════════════
# Music synthesis — melody + bass + optional percussion
# ═══════════════════════════════════════════════════════════════════════════════

def _music_loop(melody: list, bass: list, bpm: float,
                mel_osc=None, bass_osc=None, percussion: bool = True) -> list:
    if mel_osc  is None: mel_osc  = _triangle
    if bass_osc is None: bass_osc = _square
    beat = 60.0 / bpm

    def sequence(notes, osc, vol):
        s = []
        for name, beats in notes:
            freq = NOTE.get(name, 0.0)
            n    = int(SAMPLE_RATE * beats * beat)
            gate = int(n * 0.78)
            phase = 0.0
            for i in range(n):
                if freq < 1.0 or i >= gate:
                    s.append(0.0)
                else:
                    env = (1.0 - i / gate) ** 0.7
                    if osc == _square:
                        p = 1.0 if math.sin(phase) >= 0 else -1.0
                    elif osc == _triangle:
                        ph = (phase / math.tau) % 1.0
                        p = 4*ph - 1 if ph < 0.5 else 3 - 4*ph
                    else:
                        p = math.sin(phase)
                    s.append(p * vol * env)
                    phase += math.tau * freq / SAMPLE_RATE
        return s

    mel_s = sequence(melody, mel_osc,  0.44)
    bas_s = sequence(bass,   bass_osc, 0.30)
    tracks = [mel_s, bas_s]

    if percussion:
        total_beats = sum(b for _, b in melody)
        total_n = int(SAMPLE_RATE * total_beats * beat)
        beat_n  = int(SAMPLE_RATE * beat)
        hihat = [0.0] * total_n
        kick  = [0.0] * total_n

        for b in range(total_beats):
            start = b * beat_n
            # On-beat hi-hat
            hn = int(SAMPLE_RATE * 0.022)
            for i in range(min(hn, total_n - start)):
                env = (1.0 - i / hn) ** 1.2
                hihat[start + i] += (random.random() * 2 - 1) * 0.19 * env
            # Off-beat hi-hat (lighter)
            half = start + beat_n // 2
            hn2 = int(SAMPLE_RATE * 0.014)
            for i in range(min(hn2, total_n - half)):
                env = (1.0 - i / hn2) ** 1.2
                hihat[half + i] += (random.random() * 2 - 1) * 0.11 * env
            # Kick on beats 0 and 2 of each bar
            if b % 4 in (0, 2):
                kn = int(SAMPLE_RATE * 0.055)
                for i in range(min(kn, total_n - start)):
                    env = (1.0 - i / kn) ** 1.8
                    f   = 110.0 * (1.0 - i / kn * 0.75)
                    kick[start + i] += math.sin(math.tau * f * i / SAMPLE_RATE) * 0.38 * env

        tracks.extend([hihat, kick])

    return _mix(*tracks)


def music_overworld():
    return _music_loop(
        [("C5",1),("E5",1),("G5",1),("E5",1),
         ("F5",1),("A5",1),("C6",1),("A5",1),
         ("G4",1),("B4",1),("D5",1),("B4",1),
         ("C5",1),("G5",1),("E5",1),("C5",1)],
        [("C3",2),("C3",2),("F3",2),("F3",2),
         ("G3",2),("G3",2),("C3",2),("C3",2)],
        130.0, _triangle, _square, True)

def music_combat():
    return _music_loop(
        [("A4",1),("C5",1),("E5",1),("C5",1),
         ("D5",1),("F5",1),("A5",1),("F5",1),
         ("E4",1),("G4",1),("B4",1),("G4",1),
         ("A4",1),("E5",1),("C5",1),("A4",1)],
        [("A2",2),("A2",2),("D3",2),("D3",2),
         ("E3",2),("E3",2),("A2",2),("A2",2)],
        155.0, _square, _square, True)

def music_boss():
    return _music_loop(
        [("A4",1),("R",1),("E5",1),("R",1),
         ("F5",1),("R",1),("C5",1),("R",1),
         ("G4",1),("R",1),("E5",1),("R",1),
         ("A4",1),("R",1),("A4",2)],
        [("A2",2),("A2",2),("F3",2),("F3",2),
         ("E3",2),("E3",2),("A2",2),("A2",2)],
        165.0, _square, _square, True)

def music_victory():
    return _music_loop(
        [("G4",2),("C5",2),("E5",2),("G5",2),
         ("F5",2),("E5",2),("D5",2),("C5",4),
         ("E5",2),("G5",2),("A5",2),("G5",2),
         ("F5",2),("E5",2),("D5",2),("C5",4)],
        [("C3",4),("C3",4),("F3",4),("F3",4),
         ("G3",4),("G3",4),("C3",4),("C3",4)],
        72.0, _triangle, _square, False)


# ═══════════════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════════════

def generate():
    root    = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sfx_dir = os.path.join(root, "assets", "sfx")
    mus_dir = os.path.join(root, "assets", "music")
    os.makedirs(sfx_dir, exist_ok=True)
    os.makedirs(mus_dir, exist_ok=True)

    SFX = [
        ("attack",          sfx_attack),
        ("hit",             sfx_hit),
        ("dash",            sfx_dash),
        ("special",         sfx_special),
        ("hurt",            sfx_hurt),
        ("defeat",          sfx_defeat),
        ("swap",            sfx_swap),
        ("bies",            sfx_bies),
        ("ui_move",         sfx_ui_move),
        ("ui_select",       sfx_ui_select),
        ("puzzle_complete", sfx_puzzle_complete),
        ("loot_open",       sfx_loot_open),
        ("alert",           sfx_alert),
        ("dice_roll",       sfx_dice_roll),
        ("spoon_pass",      sfx_spoon_pass),
        ("spoon_power",     sfx_spoon_power),
        ("spoon_eliminate", sfx_spoon_eliminate),
        ("spoon_victory",   sfx_spoon_victory),
    ]

    print("SFX:")
    for name, fn in SFX:
        samples = fn()
        _save(os.path.join(sfx_dir, name + ".wav"), samples)
        print(f"  {name}.wav  ({len(samples)/SAMPLE_RATE:.2f}s)")

    MUSIC = [
        ("overworld", music_overworld),
        ("combat",    music_combat),
        ("boss",      music_boss),
        ("victory",   music_victory),
    ]

    print("Music:")
    for name, fn in MUSIC:
        samples = fn()
        _save(os.path.join(mus_dir, name + ".wav"), samples)
        print(f"  {name}.wav  ({len(samples)/SAMPLE_RATE:.2f}s, loopable)")

    print(f"\n{len(SFX)} SFX + {len(MUSIC)} music tracks written.")


if __name__ == "__main__":
    generate()
