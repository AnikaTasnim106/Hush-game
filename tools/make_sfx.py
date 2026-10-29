"""Generates all HUSH sound effects and ambience as WAV files (original, procedural).
Run: python3 tools/make_sfx.py   -> writes audio/*.wav
"""
import numpy as np, wave, os

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)

def save(name, x, gain=0.9):
    x = np.asarray(x, dtype=np.float64)
    peak = np.max(np.abs(x)) or 1.0
    x = x / peak * gain
    # tiny fades to avoid clicks
    n = min(200, len(x) // 4)
    if n > 0:
        x[:n] *= np.linspace(0, 1, n)
        x[-n:] *= np.linspace(1, 0, n)
    data = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(data.tobytes())

def t(d): return np.arange(int(SR * d)) / SR

def env(d, a=0.005, decay=1.0):
    tt = t(d)
    e = np.exp(-tt / max(decay, 1e-4))
    na = int(SR * a)
    if na > 0: e[:na] *= np.linspace(0, 1, na)
    return e

def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.zeros_like(x); s = 0.0
    for i in range(len(x)):
        s = (1 - a) * x[i] + a * s; y[i] = s
    return y

def bell(freq, d=1.6, bright=1.0):
    tt = t(d)
    partials = [(1.0, 1.0, 1.0), (2.0, 0.55, 0.6), (2.76, 0.4*bright, 0.45), (5.4, 0.25*bright, 0.25), (8.93, 0.12*bright, 0.15)]
    x = np.zeros_like(tt)
    for ratio, amp, dec in partials:
        x += amp * np.sin(2*np.pi*freq*ratio*tt + rng.random()*6) * np.exp(-tt/(d*dec*0.5))
    x *= env(d, 0.002, d)
    return x

def pluck(freq, d=0.9, damp=0.996):
    n = int(SR * d); p = int(SR / freq)
    buf = rng.uniform(-1, 1, p); y = np.zeros(n)
    for i in range(n):
        y[i] = buf[i % p]
        buf[i % p] = damp * 0.5 * (buf[i % p] + buf[(i + 1) % p])
    return lowpass(y, 5000)

def noise(d): return rng.uniform(-1, 1, int(SR * d))

def mix(*xs):
    n = max(len(x) for x in xs); y = np.zeros(n)
    for x in xs: y[:len(x)] += x
    return y

PENTA = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5]

# bell strikes (combo goes up the scale)
for i, f in enumerate([659.25, 783.99, 1046.5]):
    x = bell(f, 1.1) + 0.25 * noise(1.1) * env(1.1, 0.0005, 0.01)
    save(f"strike{i}", x, 0.75)

save("whoosh", lowpass(noise(0.22), 1800) * np.sin(np.linspace(0, np.pi, int(SR*0.22))), 0.5)

# note pickup plucks
for i, f in enumerate(PENTA):
    save(f"note{i}", pluck(f, 0.6) * env(0.6, 0.001, 0.25), 0.55)

# page get: arpeggio
x = np.zeros(int(SR * 1.8))
for k, f in enumerate([523.25, 659.25, 783.99, 1046.5, 1318.5]):
    s = int(k * 0.11 * SR); b = bell(f, 1.2, 0.6)
    x[s:s+len(b)] += b[:len(x)-s]
save("page", x, 0.7)

# checkpoint: two soft chimes
x = np.zeros(int(SR * 1.6))
for k, f in enumerate([783.99, 1174.66]):
    s = int(k * 0.16 * SR); b = bell(f, 1.3, 0.5); x[s:s+len(b)] += b[:len(x)-s]
save("checkpoint", x, 0.6)

# shell crack: crack noise + glassy tink
for i in range(3):
    d = 0.5
    cr = noise(d) * env(d, 0.0003, 0.02)
    tink = bell(1800 + i*350, d, 1.4) * 0.5
    save(f"crack{i}", cr + tink, 0.7)

# shatter + colour bloom (rising shimmer)
d = 2.4; tt = t(d)
sh = noise(d) * env(d, 0.0005, 0.08)
shimmer = np.zeros_like(tt)
for f in [523.25, 659.25, 783.99, 987.77, 1318.5, 1567.98]:
    shimmer += np.sin(2*np.pi*f*tt) * np.clip(tt*1.5, 0, 1) * np.exp(-tt/1.2)
save("shatter", sh * 0.6 + shimmer * 0.35, 0.8)

# hush dissolve: downward airy sweep
d = 0.7; tt = t(d)
fsweep = 900 * np.exp(-tt * 3) + 200
ph = 2*np.pi*np.cumsum(fsweep)/SR
x = np.sin(ph) * env(d, 0.01, 0.25) * 0.5 + lowpass(noise(d), 3000) * env(d, 0.01, 0.2) * 0.6
save("dissolve", x, 0.6)

# hush hurt (soft)
save("hush_hit", lowpass(noise(0.18), 2500) * env(0.18, 0.001, 0.05) + 0.4*np.sin(2*np.pi*240*t(0.18))*env(0.18,0.001,0.06), 0.55)

# player hurt: low thud + dissonant pair
d = 0.5; tt = t(d)
x = np.sin(2*np.pi*90*tt) * env(d, 0.001, 0.12) + 0.3*(np.sin(2*np.pi*466*tt)+np.sin(2*np.pi*494*tt))*env(d,0.002,0.15)
save("hurt", x, 0.75)

# jump, land, step
save("jump", lowpass(noise(0.12), 1200) * env(0.12, 0.002, 0.04) + 0.25*np.sin(2*np.pi*np.linspace(300,520,int(SR*0.12))*t(0.12))*env(0.12,0.002,0.05), 0.35)
save("land", lowpass(noise(0.16), 600) * env(0.16, 0.001, 0.04), 0.45)
for i in range(3):
    save(f"step{i}", lowpass(noise(0.06), 900 + i*200) * env(0.06, 0.001, 0.012), 0.22)

# stomp: deep thud + bell ring
d = 0.9; tt = t(d)
x = mix(np.sin(2*np.pi*55*tt*(1+0.5*np.exp(-tt*20))) * env(d, 0.001, 0.2), 0.35*bell(392, d))
save("stomp", x, 0.85)

# bounce (awning)
d = 0.35; tt = t(d)
save("bounce", np.sin(2*np.pi*(180+500*tt)*tt) * env(d, 0.002, 0.12), 0.5)

# boss: huge bell clang, slam, wave
save("boss_clang", mix(bell(98, 3.5, 1.2), 0.5*bell(196, 3.0, 0.8)), 0.9)
d = 1.4; tt = t(d)
save("boss_slam", np.sin(2*np.pi*42*tt*(1+np.exp(-tt*12))) * env(d, 0.001, 0.35) + lowpass(noise(d), 400)*env(d,0.001,0.4)*0.8, 0.95)
save("boss_wave", lowpass(noise(1.0), 700) * np.sin(np.linspace(0, np.pi, int(SR*1.0))), 0.5)
# the bell freed: pure clear ring
save("bell_free", mix(bell(523.25, 4.5, 0.4), 0.6*bell(783.99, 4.0, 0.3)), 0.85)

# ui
save("ui_tick", bell(1568, 0.15, 0.3), 0.3)
save("ui_open", bell(880, 0.5, 0.4) + 0.5*bell(1318.5, 0.5, 0.3), 0.4)
save("talk_blip", np.sin(2*np.pi*660*t(0.04)) * env(0.04, 0.001, 0.015), 0.18)

# ---------------- ambience loops (30 s), seamless via crossfade
def loopify(x, xf=SR*2):
    xf = int(xf)
    head = x[:xf]; tail = x[-xf:]
    fade = np.linspace(0, 1, xf)
    body = x[xf:-xf].copy()
    mixed = tail * (1 - fade) + head * fade
    return np.concatenate([mixed, body])

d = 32.0; tt = t(d)
w = rng.normal(0, 1, len(tt))
brown = np.cumsum(w); brown -= lowpass(brown, 0.5); brown /= np.max(np.abs(brown))
lfo = 0.6 + 0.4 * np.sin(2*np.pi*tt/9.0) * np.sin(2*np.pi*tt/13.0 + 1)
wind = lowpass(brown, 700) * lfo
x = np.zeros(len(tt)); x[:len(wind)] = wind
save("amb_wind", loopify(x), 0.5)

# soft drone (silenced town): low fifths, slow swell, very muted
dr = np.zeros_like(tt)
for f, a in [(110.0, 1.0), (164.81, 0.6), (220.0, 0.35), (329.63, 0.15)]:
    dr += a * np.sin(2*np.pi*f*tt + np.sin(2*np.pi*0.07*tt)*0.8)
dr *= 0.55 + 0.45*np.sin(2*np.pi*tt/16.0)**2
save("amb_drone", loopify(lowpass(dr, 800)), 0.35)

# colour ambience: warm pad with gentle plucked motif (original), for restored areas
pad = np.zeros_like(tt)
for f, a in [(261.63, 0.5), (329.63, 0.4), (392.0, 0.35), (523.25, 0.15)]:
    pad += a * np.sin(2*np.pi*f*tt) * (0.6 + 0.4*np.sin(2*np.pi*tt/8 + f))
pad = lowpass(pad, 1500) * 0.5
motif = [392.0, 523.25, 587.33, 659.25, 587.33, 523.25, 440.0, 523.25]
for k in range(int(d / 0.75)):
    f = motif[k % len(motif)] * (0.5 if (k // 8) % 2 else 1.0)
    s = int(k * 0.75 * SR); p = pluck(f, 1.2, 0.997) * 0.35
    pad[s:s+len(p)] += p[:len(pad)-s]
save("amb_colour", loopify(pad), 0.45)

print("sfx written to", os.path.abspath(OUT))

# Windmill Fields and ending applause; original procedural sounds.
tt=t(2.2)
save('mill_creak',np.sin(2*np.pi*(110*tt+9*np.sin(tt*3)))*np.exp(-tt*1.2),0.3)
tt=t(2.8)
save('wind_whoosh',lowpass(rng.normal(0,1,len(tt)),1400)*np.sin(np.pi*tt/2.8)**2,0.4)
tt=t(3.5)
save('choir_hum',sum(np.sin(2*np.pi*f*tt) for f in [146.83,220,293.66])*np.sin(np.pi*tt/3.5)**2,0.35)
tt=t(0.7)
save('crow_soft',lowpass(rng.normal(0,1,len(tt)),900)*np.sin(np.pi*tt/0.7)**2,0.22)
tt=t(0.24)
clap=lowpass(rng.normal(0,1,len(tt)),9000)*np.exp(-tt*34)
save('clap',clap,0.65)
cheers=np.zeros(int(SR*4.0))
for i in range(42):
 off=int((i*0.075+rng.uniform(0,0.15))*SR)
 if off+len(clap)<len(cheers): cheers[off:off+len(clap)]+=clap*rng.uniform(0.25,0.8)
save('applause',cheers,0.6)
