// ===== drawing the moving things, small effects, sound, the minimap =====
const _m = m4(), _t = m4(), _o = m4();
const bits = [];
let GDT = 0.016, lastTv = -1, ME = null;
const CAM = { fx: 0, fz: -4, zoom: 1.5, t: 0 };

// --- sound: a few synthesised knocks and bells
let AC = null, muted = false; const sfxLast = {};
function sfx(name, vol) {
  if (muted) return; const now = performance.now(); if (now - (sfxLast[name] || 0) < 55) return; sfxLast[name] = now;
  try {
    AC = AC || new (window.AudioContext || window.webkitAudioContext)(); if (AC.state === 'suspended') AC.resume();
    const t = AC.currentTime, v = (vol === undefined ? 1 : vol) * 0.5 * OPT.vol / 70; if (v <= 0) return;
    const tone = (f, dur, type, g, f2, at) => { const o = AC.createOscillator(), a = AC.createGain(), s = t + (at || 0); o.type = type || 'sine'; o.frequency.setValueAtTime(f, s); if (f2) o.frequency.exponentialRampToValueAtTime(f2, s + dur); a.gain.setValueAtTime(g * v, s); a.gain.exponentialRampToValueAtTime(0.001, s + dur); o.connect(a).connect(AC.destination); o.start(s); o.stop(s + dur + 0.02); };
    const noise = (dur, g, fc, at) => { const n = AC.sampleRate * dur | 0, b = AC.createBuffer(1, n, AC.sampleRate), d = b.getChannelData(0); for (let i = 0; i < n; i++) d[i] = (Math.random() * 2 - 1) * (1 - i / n); const src = AC.createBufferSource(), f = AC.createBiquadFilter(), a = AC.createGain(); f.type = 'lowpass'; f.frequency.value = fc; a.gain.value = g * v; src.buffer = b; src.connect(f).connect(a).connect(AC.destination); src.start(t + (at || 0)); };
    if (name === 'chop') { noise(0.07, 0.8, 1800); tone(170, 0.09, 'triangle', 0.5, 90); }
    else if (name === 'swing') noise(0.09, 0.25, 900);
    else if (name === 'hit') { noise(0.06, 0.7, 1200); tone(120, 0.1, 'square', 0.25, 60); }
    else if (name === 'bone') { tone(620, 0.05, 'square', 0.2, 380); tone(420, 0.06, 'square', 0.18, 240, 0.05); }
    else if (name === 'hurt') tone(190, 0.18, 'sawtooth', 0.35, 90);
    else if (name === 'build') { noise(0.05, 0.8, 2200); noise(0.05, 0.8, 2200, 0.13); tone(210, 0.07, 'triangle', 0.4, 150, 0.13); }
    else if (name === 'pop') tone(520, 0.08, 'triangle', 0.3, 780);
    else if (name === 'no') tone(160, 0.12, 'square', 0.15, 120);
    else if (name === 'pick') { noise(0.04, 0.7, 3200); tone(520, 0.05, 'square', 0.12, 300); }
    else if (name === 'pluck') noise(0.05, 0.3, 1400);
    else if (name === 'coin') { tone(1320, 0.07, 'square', 0.12); tone(1760, 0.1, 'square', 0.1, 0, 0.06); }
    else if (name === 'forge') { tone(880, 0.12, 'square', 0.16, 700); noise(0.05, 0.7, 4000); tone(660, 0.14, 'square', 0.14, 520, 0.16); noise(0.05, 0.6, 4000, 0.16); }
    else if (name === 'splash') noise(0.22, 0.5, 900);
    else if (name === 'raise') { tone(110, 0.6, 'sawtooth', 0.22, 220); tone(165, 0.6, 'sine', 0.2, 330); }
    else if (name === 'keep') { tone(70, 0.3, 'sine', 0.9, 40); noise(0.12, 0.5, 400); }
    else if (name === 'bell') for (let i = 0; i < 3; i++) { tone(392, 1.6, 'sine', 0.5, 0, i * 0.9); tone(784, 1.0, 'sine', 0.18, 0, i * 0.9); tone(1180, 0.6, 'sine', 0.08, 0, i * 0.9); }
    else if (name === 'dawn') [392, 494, 587, 784].forEach((f, i) => tone(f, 0.5, 'triangle', 0.35, 0, i * 0.16));
    else if (name === 'gulp') { tone(300, 0.09, 'sine', 0.4, 180); tone(260, 0.09, 'sine', 0.4, 150, 0.16); }
    else if (name === 'clang') { tone(1250, 0.5, 'square', 0.16, 1180); tone(1870, 0.4, 'sine', 0.14); noise(0.05, 0.8, 5000); }
    else if (name === 'ring') for (let i = 0; i < 2; i++) { tone(1568, 0.9, 'sine', 0.35, 0, i * 0.25); tone(2350, 0.6, 'sine', 0.12, 0, i * 0.25); }
    else if (name === 'holy') [523, 659, 784].forEach((f, i) => tone(f, 0.7, 'sine', 0.22, 0, i * 0.07));
    else if (name === 'thump') { tone(90, 0.25, 'sine', 0.9, 45); noise(0.1, 0.6, 500); }
    else if (name === 'splat') { noise(0.2, 0.7, 500); tone(140, 0.12, 'sawtooth', 0.2, 70); }
    else if (name === 'find') { tone(660, 0.1, 'triangle', 0.3); tone(880, 0.16, 'triangle', 0.3, 0, 0.09); }
    else if (name === 'relic') [523, 659, 784, 1047, 1319].forEach((f, i) => tone(f, 0.9, 'sine', 0.26, 0, i * 0.11));
    else if (name === 'cheer') { noise(0.5, 0.35, 1500); tone(330, 0.3, 'sawtooth', 0.14, 520); }
    else if (name === 'lost') [330, 262, 196, 147].forEach((f, i) => tone(f, 0.7, 'sawtooth', 0.22, 0, i * 0.3));
  } catch (e) { }
}
const nearCam = (x, z) => dist2(x, z, CAM.fx, CAM.fz) < 900;

function puff(x, y, z, n, cols, spd) {
  for (let i = 0; i < n && bits.length < 480; i++) { const a = Math.random() * TAU, s = (spd || 3) * (0.4 + Math.random()); bits.push({ x, y: y + Math.random() * 0.6, z, vx: Math.cos(a) * s, vy: 2 + Math.random() * 4, vz: Math.sin(a) * s, life: 0.5 + Math.random() * 0.5, c: cols[i % cols.length], s: 0.6 + Math.random() }); }
}
const C_BONE = [[0.92, 0.9, 0.82], [0.8, 0.78, 0.7]], C_ROT = [[0.5, 0.62, 0.48], [0.36, 0.4, 0.33], [0.7, 0.9, 0.6]], C_WOOD = [[0.6, 0.47, 0.3], [0.5, 0.38, 0.25], [0.78, 0.66, 0.44]], C_LEAF = [[0.36, 0.58, 0.29], [0.45, 0.65, 0.33], [0.6, 0.47, 0.3]];
const C_STONE = [[0.76, 0.74, 0.67], [0.6, 0.58, 0.54]], C_IRON = [[0.45, 0.42, 0.4], [0.75, 0.5, 0.3]], C_FOOD = [[0.82, 0.7, 0.34], [0.5, 0.7, 0.3]], C_SPLASH = [[0.56, 0.8, 0.86], [0.8, 0.92, 0.95]], C_COIN = [[0.95, 0.8, 0.3], [0.8, 0.6, 0.2]], C_GHOST = [[0.6, 1, 0.7], [0.8, 1, 0.85]], C_SPARK = [[1, 0.75, 0.3], [1, 0.9, 0.6]];
function fxGone(kind, e) {                       // something was destroyed or put down
  if (kind === 'u') { puff(e.x, 0.5, e.z, e.k === 3 ? 40 : 12, e.k === 3 ? [[0.15, 0.13, 0.18], [0.8, 0.84, 0.78]] : e.k ? C_BONE : C_ROT, e.k === 3 ? 6 : 3.5); if (nearCam(e.x, e.z)) sfx(e.k ? 'bone' : 'hit', 0.8); }
  else if (kind === 's') { puff(e.x, 0.6, e.z, 16, C_WOOD, 4); if (nearCam(e.x, e.z)) sfx('chop'); }
}
const C_HOLY = [[1, 0.95, 0.6], [1, 1, 0.9]], C_POO = [[0.42, 0.3, 0.16], [0.5, 0.42, 0.2], [0.36, 0.4, 0.18]], C_ALE = [[0.9, 0.7, 0.25], [1, 0.95, 0.8]], C_DUST = [[0.8, 0.76, 0.66], [0.66, 0.62, 0.55]];
const arrows = [], toasts = [];
function ringPuff(x, z, rad, n, cols) { for (let i = 0; i < n && bits.length < 480; i++) { const a = i / n * TAU; bits.push({ x: x + Math.cos(a) * rad * 0.3, y: 0.3, z: z + Math.sin(a) * rad * 0.3, vx: Math.cos(a) * rad * 2.2, vy: 2.5, vz: Math.sin(a) * rad * 2.2, life: 0.45, c: cols[i % cols.length], s: 1 }); } }
function handleEvents(ev) {                      // things that happened this moment, from the rules (or from the host)
  for (const e of ev) {
    const k = e[0];
    if (k === 'msg') { toasts.push({ t: e[1], at: performance.now() }); if (toasts.length > 5) toasts.shift(); }
    else if (k === 'arrow') { arrows.push({ x1: e[1], z1: e[2], x2: e[3], z2: e[4], t: 0 }); if (nearCam(e[1], e[2])) sfx('swing', 0.5); }
    else if (k === 'raise') { puff(e[1], 0.3, e[2], 14, C_GHOST, 3); if (nearCam(e[1], e[2])) sfx('raise', 0.7); }
    else if (k === 'coin') { puff(e[1], 1.4, e[2], 6, C_COIN, 2); if (nearCam(e[1], e[2])) sfx('coin'); }
    else if (k === 'forge') { puff(e[1], 1.2, e[2], 10, C_SPARK, 3.5); if (nearCam(e[1], e[2])) sfx('forge'); }
    else if (k === 'build') { puff(e[1], 0.8, e[2], 8, C_WOOD, 3); if (nearCam(e[1], e[2])) sfx('build'); }
    else if (k === 'eat') { puff(e[1], 1.7, e[2], 4, C_FOOD, 1.5); if (nearCam(e[1], e[2])) sfx('pop', 0.6); }
    else if (k === 'fish') { puff(e[1], 0.3, e[2], 10, C_SPLASH, 3); if (nearCam(e[1], e[2])) sfx('splash'); }
    else if (k === 'bite') { if (ME && ME.id === e[1]) sfx('pop'); puff(JETTY.x, 0.2, JETTY.z + 2.6, 4, C_SPLASH, 1.5); }
    else if (k === 'shot') { arrows.push({ x1: e[1], z1: e[2], x2: e[3], z2: e[4], t: 0, k: e[5] + 1 }); if (nearCam(e[1], e[2])) sfx('swing', 0.5); }
    else if (k === 'abl') {                      // a weapon's trick: show where it landed
      const a = e[1], x = e[2], z = e[3], fx = Math.sin(e[4]), fz = Math.cos(e[4]), near = nearCam(x, z);
      if (a === 'smash') { ringPuff(x + fx * 1.6, z + fz * 1.6, 3.2, 22, C_DUST); if (near) sfx('thump'); }
      else if (a === 'clang') { ringPuff(x, z, 4, 18, C_SPARK); if (near) sfx('clang'); }
      else if (a === 'reap' || a === 'trip') { ringPuff(x, z, 2.6, 16, a === 'trip' ? C_DUST : C_WOOD); if (near) sfx('swing'); }
      else if (a === 'parry') { puff(x + fx * 0.6, 1.3, z + fz * 0.6, 5, C_SPARK, 1.5); if (near) sfx('pop', 0.5); }
      else { puff(x + fx * 1.8, 1, z + fz * 1.8, 8, a === 'bury' ? C_DUST : C_SPARK, 3); if (near) sfx(a === 'wallop' || a === 'bury' || a === 'shatter' ? 'thump' : 'swing'); }
    }
    else if (k === 'parry') { puff(e[1], 1.3, e[2], 10, C_SPARK, 4); if (nearCam(e[1], e[2])) sfx('clang', 0.7); }
    else if (k === 'miss') puff(e[1], 1.6, e[2], 3, C_DUST, 2);
    else if (k === 'splat') { ringPuff(e[1], e[2], 4, 24, e[3] ? C_HOLY : C_POO); puff(e[1], 0.4, e[2], 14, C_POO, 4); if (nearCam(e[1], e[2])) { sfx('splat'); if (e[3]) sfx('holy', 0.7); } }
    else if (k === 'ring') { ringPuff(e[1], e[2], 8, 30, C_HOLY); if (nearCam(e[1], e[2])) sfx('ring'); }
    else if (k === 'holy') { puff(e[1], 1.4, e[2], 12, C_HOLY, 2.5); if (nearCam(e[1], e[2])) sfx('holy'); }
    else if (k === 'burst') { ringPuff(e[1], e[2], 3, 20, C_ALE); puff(e[1], 1, e[2], 14, C_WOOD, 5); if (nearCam(e[1], e[2])) sfx('cheer'); }
    else if (k === 'found') {
      puff(e[3], 0.5, e[4], e[5] ? 20 : 6, e[5] ? C_HOLY : C_DUST, 3);
      if (ME && ME.id === e[1]) { banner(e[5] ? 'A find!' : 'You found', e[2] + (e[6] ? `. It is in your pack: ${kn('pack')} opens it.` : ''), e[5] ? 3800 : 2800); sfx(e[5] ? 'relic' : 'find'); } else if (e[5] && nearCam(e[3], e[4])) sfx('relic', 0.6);
    }
  }
}
function view(e) { return e.v || (e.v = { walk: Math.random() * 6, atk: 0, flash: 0, ac: e.ac | 0, hc: e.hc | 0, cc: e.cc | 0, px: e.x, pz: e.z, mv: 0, fall: 0, rise: 0, pile: 0 }); }
function tickView(e, dt) {
  const v = view(e), sp = Math.hypot(e.x - v.px, e.z - v.pz) / Math.max(dt, 1e-3); v.px = e.x; v.pz = e.z;
  v.mv = lerp(v.mv, Math.min(1, sp / 2.2), Math.min(1, dt * 9)); if (v.mv > 0.06) v.walk += dt * (5 + sp * 1.5);
  v.didAtk = (e.ac | 0) !== v.ac; v.didHit = (e.hc | 0) !== v.hc; v.didChop = (e.cc | 0) !== v.cc;
  if (v.didAtk) { v.ac = e.ac | 0; v.atk = 1; } if (v.didChop) { v.cc = e.cc | 0; v.atk = 1; } if (v.didHit) { v.hc = e.hc | 0; v.flash = 1; }
  v.atk = Math.max(0, v.atk - dt * 4.2); v.flash = Math.max(0, v.flash - dt * 7);
  return v;
}
function workFx(e, kind) {                       // a blow landed on a tree, a rock, the ore, or the turnips
  if (kind === 'tree') {
    let bt = null, bd = 9; for (const t of trees) if (t.alive || t.fall > 0) { const d = dist2(e.x, e.z, t.x, t.z); if (d < bd) { bd = d; bt = t; } }
    const x = bt ? bt.x : e.x + Math.sin(e.r), z = bt ? bt.z : e.z + Math.cos(e.r);
    if (bt) bt.shake = 0.3; puff(x, 1, z, 4, C_WOOD, 2.5); if (nearCam(x, z)) sfx('chop', 0.7);
  } else if (kind === 'fish') return;
  else if (kind === 'search') { const x = e.x + Math.sin(e.r) * 0.8, z = e.z + Math.cos(e.r) * 0.8; puff(x, 0.4, z, 4, C_DUST, 2.2); if (nearCam(x, z)) sfx('pick', 0.45); }
  else { const x = e.x + Math.sin(e.r) * 0.9, z = e.z + Math.cos(e.r) * 0.9; puff(x, 0.6, z, 3, kind === 'stone' ? C_STONE : kind === 'iron' ? C_IRON : C_FOOD, 2); if (nearCam(x, z)) sfx(kind === 'food' ? 'pluck' : 'pick', 0.6); }
}
const WHITE = [1, 1, 1], HOLYT = [1.3, 1.2, 0.75];
// o: { sc, tint, player, work (a gather kind or ''), wpn (item id), gear (item ids worn), holy }
function drawFriend(e, v, o) {
  const down = e.state === 'down' || e.state === 'dead' || e.state === 'body', sc = o.sc;
  v.fall = lerp(v.fall, down ? 1 : 0, Math.min(1, GDT * 9));
  const tc = o.tint, bob = Math.abs(Math.sin(v.walk)) * 0.14 * v.mv, f = 1 + v.flash * 1.2, dim = (e.state === 'dead' || e.state === 'body' ? 0.6 : 1) * f;
  const stoop = o.work === 'food' || o.work === 'search' ? 0.5 + Math.sin(performance.now() / 180 + e.id) * 0.12 : 0, wob = o.wobble ? Math.sin(performance.now() / 170) * 0.22 : 0;
  m4trs(_m, e.x, bob + v.fall * 0.2, e.z, e.r, -1.45 * v.fall + stoop, Math.sin(v.walk) * 0.07 * v.mv + wob, sc, sc, sc);
  PL.body.put(_m, dim, dim, dim); PL.tunic.put(_m, tc[0] * dim, tc[1] * dim, tc[2] * dim);
  if (o.player) PL.banner.put(_m, tc[0], tc[1], tc[2]);
  if (o.gear) for (const id of o.gear) if (id >= 0) { const I = IT[id]; if (down && I.s !== 'h' && I.s !== 'b') continue; const t = I.tint || WHITE; PL[I.pool].put(_m, t[0] * f, t[1] * f, t[2] * f); }
  if (down || stoop) return;
  if (o.work === 'fish') { m4trs(_t, 0.42, 0.7, 0.2, 0, 1.15 + Math.sin(performance.now() / 500) * 0.04, 0, 1, 1, 1); m4mul(_o, _m, _t); PL.spear.put(_o, 0.75, 0.6, 0.45); return; }
  if (o.work) { const sw = v.atk > 0 ? -1.0 + (1 - v.atk) * 2.4 : 0.3; m4trs(_t, 0.42, 0.62, 0.16, 0, sw, 0, 1, 1, 1); m4mul(_o, _m, _t); PL.axe.put(_o); return; }
  const I = IT[o.wpn] || IT[0], t = o.holy ? HOLYT : I.tint || WHITE, s = Math.sin(v.atk * Math.PI);
  if (I.pool === 'bow') m4trs(_t, 0.36, 0.72, 0.42 - s * 0.12, 0, 0.12, 0, 1, 1, 1);
  else if (I.pool === 'xbow') m4trs(_t, 0.3, 0.62, 0.2 - s * 0.14, 0, -s * 0.2, 0, 1, 1, 1);
  else { const swing = I.swing || I.pool === 'sling'; m4trs(_t, 0.42, 0.6, 0.14 + s * (swing ? 0.25 : 0.55), swing ? -s * 0.9 : 0, 0.12 + s * (swing ? 1.7 : 1.4), 0, 1, 1, 1); }   // a swing, or a jab
  m4mul(_o, _m, _t); PL[I.pool].put(_o, t[0], t[1], t[2]);
}
function bar(x, y, z, w, frac, col) {
  const p = L.pitch;
  m4trs(_m, x, y, z, 0, -p, 0, w + 0.12, 0.26, 1); PL.barBg.put(_m, 0.14, 0.1, 0.1);
  const fw = Math.max(0.02, w * clamp(frac, 0, 1)); m4trs(_m, x - (w - fw) / 2, y, z + 0.01, 0, -p, 0, fw, 0.14, 1); PL.barFg.put(_m, col[0], col[1], col[2]);
}
const C_HP = [0.56, 0.78, 0.36], C_HP2 = [0.86, 0.36, 0.26], C_ST = [0.88, 0.72, 0.36], C_BOSS = [0.7, 0.3, 0.75];
const UNDYED = [0.72, 0.62, 0.46], C_CORPSE = [0.6, 0.56, 0.5], IRONED = [0.72, 0.76, 0.86];
const SH = { wall: 3.9, gate: 5.6, barricade: 2.1, spikes: 1.6, bodywall: 1.8, decoy: 2.6 }, SW = { wall: 3, gate: 3, barricade: 1.8, spikes: 1.8, bodywall: 1.8, decoy: 1 };

function drawWorld(dt) {
  GDT = dt;
  for (const k in PL) if (!PL[k].keep) PL[k].n = 0;
  // trees
  if (lastTv !== S.tv) {
    lastTv = S.tv;
    for (const t of trees) {
      if (t.vst === t.st && t.vpar === t.par) continue;
      if (t.st === 1 && t.vst === 0 && S.phase !== 'title') { t.fall = 0.35; puff(t.x, 1.5, t.z, 10, C_LEAF, 3); } else { t.fall = 0; showTree(t); }
      t.vst = t.st; t.vpar = t.par;
    }
  }
  for (const t of trees) {
    if (t.fall > 0) { t.fall -= dt; const g = Math.max(0, t.fall / 0.35); if (t.fall <= 0 || t.st !== 1) { t.fall = 0; showTree(t); } else setTree(t, 0.5 + g * 0.5, (1 - g) * 0.9, true); }
    else if (t.shake > 0) { t.shake -= dt; if (t.st === 0) setTree(t, 1, t.shake > 0 ? Math.sin(t.shake * 60) * 0.06 : 0, false); }
  }
  // the places that move: today's outcrop, mine and jetty, and the rubble of the ruins
  m4trs(_m, QUARRY.x, 0, QUARRY.z, 0, 0, 0, 1, 1, 1); PL.outcrop.put(_m);
  m4trs(_m, MINEC.x, 0, MINEC.z, MINE.dir > 0 ? 0 : Math.PI, 0, 0, 1, 1, 1); PL.mine.put(_m);
  m4trs(_m, JETTY.x, 0, JETTY.z, 0, 0, 0, 1, 1, 1); PL.jetty.put(_m);
  const RL = ruinLayout(S.seed, S.phase === 'title' ? 1 : S.day);
  for (const r of RL.rub) { m4trs(_m, r.x, 0, r.z, r.rot, 0, 0, r.w, r.h, r.d); if (r.c) PL.rub.put(_m, 0.65, 0.62, 0.56); else PL.rub.put(_m, 0.54, 0.52, 0.47); }
  for (const r of RL.pil) { m4trs(_m, r.x, 0, r.z, 0, 0, 0, 1, r.h, 1); PL.pillar.put(_m); }
  m4trs(_m, STATIONS[6].x + 0.9, 0, STATIONS[6].z - 0.5, -2.2, 0, 0, 1.08, 1.08, 1.08); PL.body.put(_m); PL.tunic.put(_m, 0.2, 0.18, 0.22);   // the priest, outside his chapel
  const inGame = App.screen === 'game';
  // the keep hides whatever is just north of it from this camera: let it go see-through when there is something there to see
  let seeThru = false;
  if (inGame && OPT.seeKeep && dist2(CAM.fx, CAM.fz, KEEP.x, KEEP.z) < 400) {
    const hid = e => Math.abs(e.x - KEEP.x) < KEEP.h + 2 && e.z < KEEP.z + KEEP.h && e.z > KEEP.z - KEEP.h - 9;
    seeThru = S.undead.some(u => dist2(u.x, u.z, KEEP.x, KEEP.z) < 90) || S.players.some(p => (p.state === 'ok' || p.state === 'down') && hid(p)) || S.drops.some(hid) || S.peasants.some(q => q.state === 'body' && hid(q));
  }
  const K = GFX.keep; K.alpha = lerp(K.alpha, seeThru ? 0.3 : 1, Math.min(1, dt * 7)); K.mode = K.alpha < 0.985 ? 'fade' : 'lit'; if (K.mode === 'lit') K.alpha = seeThru ? K.alpha : 1;
  if (inGame) {
    // defences
    for (const s of S.structs) {
      const v = s.v || (s.v = { pop: 0, shake: 0, hc: s.hc | 0, built: s.built, open: 0, re: s.re });
      if (v.built !== s.built) { v.built = s.built; if (s.built) { v.pop = 1; if (nearCam(s.x, s.z)) sfx('build'); puff(s.x, 0.4, s.z, 8, C_WOOD, 3); } else fxGone('s', s); }
      if (v.fresh === undefined) { v.fresh = true; if (s.slot == null && performance.now() - App.enterAt > 1500) { v.pop = 1; if (nearCam(s.x, s.z)) sfx('build'); } }
      if (v.re !== s.re) { v.re = s.re; if (s.re) v.pop = 1; }
      if ((s.hc | 0) !== v.hc) { v.hc = s.hc | 0; v.shake = 0.18; }
      v.pop = Math.max(0, v.pop - dt * 3.5); v.shake = Math.max(0, v.shake - dt);
      const pp = 1 + Math.sin(v.pop * Math.PI) * 0.22 - (v.pop > 0.7 ? (v.pop - 0.7) * 1.5 : 0), tilt = v.shake > 0 ? Math.sin(v.shake * 70) * 0.04 : 0;
      if (!s.built) { m4trs(_m, s.x, 0, s.z, s.rot, 0, 0, 1, 1, 1); (s.k === 'gate' ? PL.foundGate : PL.found).put(_m); continue; }
      m4trs(_m, s.x, 0, s.z, s.rot, tilt, 0, pp, pp, pp);
      const tn = s.re && (s.k === 'barricade' || s.k === 'spikes') ? IRONED : null;
      if (s.k === 'gate') {
        PL.gateFrame.put(_m); if (s.re) PL.gateRe.put(_m);
        let near = false, danger = false;
        for (const p of S.players) if (p.state === 'ok' && dist2(p.x, p.z, s.x, s.z) < 16) near = true;
        for (const q of S.peasants) if (q.state !== 'body' && q.state !== 'idle' && dist2(q.x, q.z, s.x, s.z) < 12) near = true;
        for (const u of S.undead) if (dist2(u.x, u.z, s.x, s.z) < 30) danger = true;
        v.open = lerp(v.open, near && !danger ? 1 : 0, Math.min(1, dt * 7));
        const dc = s.re ? 0.78 : 1;
        m4trs(_m, s.x - 2.3, 0, s.z, -1.35 * v.open, tilt, 0, pp, pp, pp); PL.door.put(_m, dc, dc, dc * 1.08);
        m4trs(_m, s.x + 2.3, 0, s.z, Math.PI + 1.35 * v.open, -tilt, 0, pp, pp, pp); PL.door.put(_m, dc, dc, dc * 1.08);
      } else { if (tn) PL[s.k].put(_m, tn[0], tn[1], tn[2]); else PL[s.k].put(_m); if (s.k === 'wall' && s.re) PL.wallRe.put(_m); }
      if (s.hp < s.max) bar(s.x, SH[s.k], s.z, SW[s.k], s.hp / s.max, C_ST);
      if (s.bl && Math.random() < dt * 2) puff(s.x + (Math.random() - 0.5) * 3, 1.2, s.z, 1, C_HOLY, 0.6);
    }
    // rubble worth searching, and things lying on the ground
    RL.spots.forEach((sp, i) => { const n = S.spots[i] | 0; m4trs(_m, sp.x, 0, sp.z, i * 1.7, 0, 0, 1, n > 0 ? 1 : 0.55, 1); if (n > 0) PL.spot.put(_m, 0.9, 0.86, 0.74); else PL.spot.put(_m, 0.5, 0.48, 0.44); });
    for (const d of S.drops) {
      const I = IT[d.it], t = I.tint || WHITE, w = I.s === 'w';
      if (w) m4trs(_m, d.x, 0.12, d.z - 0.5, d.id, Math.PI / 2, 0, 1, 1, 1); else m4trs(_m, d.x + (I.s === 'h' ? 0 : 0.5), I.s === 'h' ? -1.25 : I.s === 't' ? -0.4 : -0.3, d.z, d.id, 0, 0, 1, 1, 1);
      PL[I.pool].put(_m, t[0], t[1], t[2]); if (Math.random() < dt * (I.tier === 'relic' ? 6 : 1.5)) puff(d.x, 0.3, d.z, 1, I.tier === 'relic' ? C_HOLY : C_SPARK, 0.5);
    }
    // players and peasants
    for (const p of S.players) {
      const v = tickView(p, dt), tc = PCOL3[p.col % 8], kind = GK[p.gk] || '';
      if (v.didChop) { if (p.state === 'inn') { if (p === ME) sfx('gulp'); } else workFx(p, kind || 'tree'); } if (v.didAtk && nearCam(p.x, p.z)) sfx('swing', 0.7); if (v.didHit && p.state !== 'dead') { puff(p.x, 1, p.z, 3, [[0.8, 0.2, 0.2]], 2); if (p === ME) sfx('hurt'); }
      const c = cottage(p.slot); m4trs(_m, c.x + 1.25, 0, c.z + c.dir * 1.75, 0, 0, 0, 1.2, 1.2, 1.2); PL.banner.put(_m, tc[0], tc[1], tc[2]);
      if (p.state === 'hide' || p.state === 'inn') continue;
      drawFriend(p, v, { sc: 1.2, tint: tc, player: true, work: kind, wpn: p.wpn, gear: [p.head, p.body, p.off, p.trk], holy: p.bless & 1, wobble: p.hang > 0 });
      if (p.charge > 0 && Math.random() < dt * 30) puff(p.x, 0.3, p.z, 1, C_ALE, 1.5);
      if ((p.bless & 1 || IT[p.wpn].holy) && p.state === 'ok' && Math.random() < dt * 3) puff(p.x + Math.sin(p.r) * 0.6, 1.9, p.z + Math.cos(p.r) * 0.6, 1, C_HOLY, 0.4);
      if (p.parry > 0 && Math.random() < dt * 14) puff(p.x + Math.sin(p.r) * 0.7, 1.2, p.z + Math.cos(p.r) * 0.7, 1, C_SPARK, 0.8);
      for (let i = 0; i < (p.bodies | 0); i++) { m4trs(_m, p.x - Math.sin(p.r) * 0.25, 1.75 + i * 0.36, p.z - Math.cos(p.r) * 0.25, p.r + Math.PI / 2, -1.45, 0, 0.9, 0.9, 0.9); PL.body.put(_m, 0.6, 0.6, 0.6); if (i < (p.bbod | 0)) PL.tunic.put(_m, 1.1, 1.05, 0.75); else PL.tunic.put(_m, C_CORPSE[0], C_CORPSE[1], C_CORPSE[2]); }
      if (p.hp < maxHp(p) && p.state === 'ok' && p !== ME) bar(p.x, 2.5, p.z, 1.1, p.hp / maxHp(p), C_HP);
      if (p.state === 'down') bar(p.x, 1.4, p.z, 1.3, (p.downT || 0) / (rk(p, 9) >= 5 ? 30 : 15), C_HP2);
    }
    for (const q of S.peasants) {
      if (q.state === 'gone' || q.state === 'inn') continue;
      const v = tickView(q, dt), own = S.players.find(p => p.id === q.owner), kind = q.state === 'chop' && own ? GK[own.gk] || own.workK || 'tree' : '';
      if (v.didAtk) { if (q.state === 'chop') workFx(q, kind || 'tree'); else if (nearCam(q.x, q.z)) sfx('swing', 0.35); }
      if (v.own !== q.owner) { if (v.own === 0 && q.owner) { sfx('pop'); puff(q.x, 1.8, q.z, 5, [[1, 0.93, 0.6]], 2); } v.own = q.owner; }
      drawFriend(q, v, { sc: 1, tint: q.state === 'body' ? C_CORPSE : own ? PCOL3[own.col % 8] : UNDYED, work: kind === 'fish' || kind === 'search' ? '' : kind, wpn: q.armed ? 2 : 0 });
      if (q.hp < PEASANT_HP && q.state !== 'body') bar(q.x, 2.1, q.z, 0.9, q.hp / PEASANT_HP, C_HP);
      if (q.nv < 45 && q.state !== 'body' && q.state !== 'hide' && Math.random() < dt * 5) puff(q.x, 2, q.z, 1, C_SPLASH, 0.8);   // sweating
    }
    // the undead
    for (const u of S.undead) {
      const v = tickView(u, dt), f = 1 + v.flash * 1.5;
      const fl = u.fl !== undefined ? u.fl : (u.stun > 0 ? 1 : 0) | (u.pin > 0 ? 2 : 0) | (u.fear > 0 ? 4 : 0) | (u.vuln > 0 ? 8 : 0), dz = fl & 3 ? -0.45 : 0;   // dazed ones lean back
      const cr = f * (fl & 8 ? 1.5 : 1), cg = f * (fl & 4 ? 1.25 : fl & 8 ? 0.75 : 1), cb = f * (fl & 12 ? 0.7 : 1);
      if (v.didHit && nearCam(u.x, u.z)) { sfx(u.k === 1 || u.k === 2 ? 'bone' : 'hit', 0.6); puff(u.x, 1, u.z, 3, u.k === 1 || u.k === 2 ? C_BONE : C_ROT, 2.5); }
      if (fl & 1 && Math.random() < dt * 5) puff(u.x, 2, u.z, 1, C_SPARK, 0.7);
      v.rise = u.state === 'rise' ? Math.min(1, v.rise + dt / 1.2) : 1;
      const y = -1.6 * (1 - v.rise);
      if (u.k === 0) { m4trs(_m, u.x, y, u.z, u.r, 0.08 + dz + Math.sin(v.atk * Math.PI) * 0.5, Math.sin(v.walk * 0.8) * 0.11, 1.1, 1.1, 1.1); PL.shamb.put(_m, cr, cg, cb); }
      else if (u.k === 3) {
        const cast = u.state === 'atk' && v.mv < 0.1 ? Math.sin(performance.now() / 260) * 0.06 : 0;
        m4trs(_m, u.x, y * 1.6 + Math.abs(Math.sin(v.walk * 0.7)) * 0.08 * v.mv, u.z, u.r, dz * 0.5 + Math.sin(v.atk * Math.PI) * 0.3, cast, 1.65, 1.65 + cast, 1.65); PL.steward.put(_m, cr, cg, cb);
        if (v.didAtk) puff(u.x, 2.6, u.z, 8, C_GHOST, 2.5);
      }
      else if (u.state === 'pile') { v.pile += dt; const sh = v.pile > 2.4 ? Math.sin(v.pile * 45) * 0.05 : 0; m4trs(_m, u.x + sh, 0, u.z, u.r, 0, 0, 1.35, 0.2, 1.35); (u.k === 2 ? PL.archer : PL.skel).put(_m, f * 0.85, f * 0.85, f * 0.85); }
      else { v.pile = 0; m4trs(_m, u.x, y + Math.abs(Math.sin(v.walk)) * 0.1 * v.mv, u.z, u.r, dz + Math.sin(v.atk * Math.PI) * (u.k === 2 ? -0.2 : 0.45), Math.sin(v.walk) * 0.08, 1.05, 1.05, 1.05); (u.k === 2 ? PL.archer : PL.skel).put(_m, cr, cg, cb); }
    }
    // arrows in flight
    for (let i = arrows.length - 1; i >= 0; i--) {
      const a = arrows[i]; a.t += dt / 0.4; if (a.t >= 1) { arrows.splice(i, 1); continue; }
      const x = lerp(a.x1, a.x2, a.t), z = lerp(a.z1, a.z2, a.t), y = 1.2 + Math.sin(a.t * Math.PI) * 1.3, len = Math.hypot(a.x2 - a.x1, a.z2 - a.z1) || 1;
      if (a.k === 1) { m4trs(_m, x, y + 0.2, z, a.t * 20, a.t * 14, 0, 0.9, 0.9, 0.9); PL.bits.put(_m, 0.62, 0.6, 0.56); }          // a sling stone
      else if (a.k === 3) { m4trs(_m, x, y + 0.6, z, a.t * 16, a.t * 22, 0, 1.3, 1.3, 1.3); PL.bits.put(_m, 0.4, 0.29, 0.15); }  // what the posse threw
      else if (a.k === 4) { m4trs(_m, x + 0.5, y + 0.6, z, a.t * 9, a.t * 12, 0, 1.2, 1.2, 1.2); PL.bucket.put(_m, 0.6, 0.48, 0.3); }
      else { m4trs(_m, x, y, z, Math.atan2(a.x2 - a.x1, a.z2 - a.z1), Math.atan2(Math.cos(a.t * Math.PI) * 1.3 * Math.PI, len) * -1, 0, 1, 1, 1); PL.arrow.put(_m); }
    }
  } else arrows.length = 0;
  // bits
  for (let i = bits.length - 1; i >= 0; i--) {
    const b = bits[i]; b.life -= dt; if (b.life <= 0) { bits.splice(i, 1); continue; }
    b.vy -= 16 * dt; b.x += b.vx * dt; b.y += b.vy * dt; b.z += b.vz * dt; if (b.y < 0.08) { b.y = 0.08; b.vy *= -0.35; b.vx *= 0.6; b.vz *= 0.6; }
    const s = b.s * Math.min(1, b.life * 4); m4trs(_m, b.x, b.y, b.z, b.life * 9, b.life * 7, 0, s, s, s); PL.bits.put(_m, b.c[0], b.c[1], b.c[2]);
  }
}

// --- minimap
let miniBg = null; const MINI = { x0: -100, x1: 100, z0: -128, z1: 72, w: 150, h: 150 };
const mmx = x => (x - MINI.x0) / (MINI.x1 - MINI.x0) * MINI.w, mmz = z => (z - MINI.z0) / (MINI.z1 - MINI.z0) * MINI.h;
function drawMini(cv) {
  const c = cv.getContext('2d');
  if (!miniBg) {
    miniBg = document.createElement('canvas'); miniBg.width = MINI.w; miniBg.height = MINI.h; const b = miniBg.getContext('2d');
    b.fillStyle = '#e4d3a0'; b.fillRect(0, 0, MINI.w, MINI.h);
    b.fillStyle = '#7fb6c4'; b.fillRect(0, mmz(58), MINI.w, MINI.h);
    b.fillStyle = '#cdb77a'; b.fillRect(mmx(-2.5), mmz(-100), mmx(2.5) - mmx(-2.5), mmz(VN) - mmz(-100)); b.fillRect(mmx(-46), mmz(GATE_Z - 2), mmx(46) - mmx(-46), 3);
    b.fillStyle = '#d9c890'; b.fillRect(mmx(-VW), mmz(VN), mmx(VW) - mmx(-VW), mmz(VS) - mmz(VN));
    b.strokeStyle = '#6b4f33'; b.lineWidth = 1.5; b.beginPath(); b.moveTo(mmx(-21), mmz(VN)); b.lineTo(mmx(-VW), mmz(VN)); b.lineTo(mmx(-VW), mmz(VS)); b.lineTo(mmx(VW), mmz(VS)); b.lineTo(mmx(VW), mmz(VN)); b.lineTo(mmx(21), mmz(VN)); b.stroke();
    b.fillStyle = '#7d7668'; b.fillRect(mmx(-KEEP.h), mmz(-KEEP.h), mmx(KEEP.h) - mmx(-KEEP.h), mmz(KEEP.h) - mmz(-KEEP.h));
    b.fillStyle = 'rgba(70,60,80,.16)'; b.fillRect(0, 0, MINI.w, mmz(BOUNDS.z0 - 1));                       // castle ground
    b.strokeStyle = '#3f6b3a'; b.lineWidth = 2; b.beginPath(); b.moveTo(mmx(BOUNDS.x0 - 1.5), mmz(BOUNDS.z0 - 1)); b.lineTo(mmx(BOUNDS.x0 - 1.5), mmz(58)); b.moveTo(mmx(BOUNDS.x1 + 1.5), mmz(BOUNDS.z0 - 1)); b.lineTo(mmx(BOUNDS.x1 + 1.5), mmz(58)); b.stroke();   // the thorn hedge
    b.strokeStyle = '#5a4a3c'; b.lineWidth = 1; b.setLineDash([2, 2]); b.beginPath(); b.moveTo(mmx(BOUNDS.x0 - 1.5), mmz(BOUNDS.z0 - 1)); b.lineTo(mmx(BOUNDS.x1 + 1.5), mmz(BOUNDS.z0 - 1)); b.stroke(); b.setLineDash([]);   // the stakes
    b.fillStyle = '#4d485b'; b.fillRect(mmx(-10), mmz(-122), mmx(10) - mmx(-10), mmz(-109) - mmz(-122)); b.fillRect(mmx(-3), mmz(-126), mmx(3) - mmx(-3), 5);
  }
  c.drawImage(miniBg, 0, 0);
  for (const t of trees) { if (t.st === 1) continue; c.fillStyle = t.st ? '#a9bf78' : '#7f9f58'; if (t.st) c.fillRect(mmx(t.x) - 0.5, mmz(t.z) - 0.5, 1, 1); else c.fillRect(mmx(t.x) - 1, mmz(t.z) - 1, 2, 2); }
  const mark = (x, z, col, ch) => { c.fillStyle = '#2f2318'; c.fillRect(mmx(x) - 3.5, mmz(z) - 3.5, 7, 7); c.fillStyle = col; c.fillRect(mmx(x) - 2.5, mmz(z) - 2.5, 5, 5); };
  mark(QUARRY.x, QUARRY.z, '#d8d2c2'); mark(MINEC.x, MINEC.z, '#b5653a'); mark(JETTY.x, JETTY.z + 2, '#8fd0e0');
  const RL = ruinLayout(S.seed, S.day), lore = ME && rk(ME, 8) >= 2;
  RL.spots.forEach((sp, i) => { if (lore && S.spots[i] > 0) { c.fillStyle = '#f3d36a'; c.fillRect(mmx(sp.x) - 1.5, mmz(sp.z) - 1.5, 3, 3); } else { c.fillStyle = '#8a8478'; c.fillRect(mmx(sp.x) - 1, mmz(sp.z) - 1, 2, 2); } });
  for (const d of S.drops) { c.fillStyle = IT[d.it].tier === 'relic' ? '#ffe27a' : '#c9b48a'; c.fillRect(mmx(d.x) - 1.5, mmz(d.z) - 1.5, 3, 3); }
  for (const s of S.structs) {
    if (s.slot != null) { c.fillStyle = s.built ? '#6b4f33' : 'rgba(107,79,51,.28)'; c.fillRect(mmx(s.x - 3) + 0.3, mmz(s.z) - 1, mmx(s.x + 3) - mmx(s.x - 3) - 0.6, 2); }
    else { c.fillStyle = '#8a6a45'; c.fillRect(mmx(s.x) - 1, mmz(s.z) - 1, 2.5, 2.5); }
  }
  c.fillStyle = '#3f8f4f'; const blink = (performance.now() / 300 | 0) % 2;
  c.fillStyle = blink ? '#b0271f' : '#7e1c16'; for (const u of S.undead) c.fillRect(mmx(u.x) - 1.5, mmz(u.z) - 1.5, 3, 3);
  for (const q of S.peasants) { if (q.state === 'gone' || q.state === 'inn') continue; if (q.state === 'body') { c.fillStyle = '#5a5148'; c.fillRect(mmx(q.x) - 1, mmz(q.z) - 0.5, 2.5, 1.5); continue; } const own = S.players.find(p => p.id === q.owner); c.fillStyle = own ? PCOL[own.col % 8] : '#8c7a5c'; c.fillRect(mmx(q.x) - 1, mmz(q.z) - 1, 2, 2); }
  for (const p of S.players) { if (p.state === 'hide' || p.state === 'inn') continue; c.fillStyle = '#2f2318'; c.beginPath(); c.arc(mmx(p.x), mmz(p.z), p === ME ? 4.2 : 3.4, 0, TAU); c.fill(); c.fillStyle = PCOL[p.col % 8]; c.beginPath(); c.arc(mmx(p.x), mmz(p.z), p === ME ? 3 : 2.3, 0, TAU); c.fill(); }
}
