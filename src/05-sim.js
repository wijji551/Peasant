// ===== the rules. The host runs these; everyone else is sent the result. =====
const S = {
  phase: 'title', day: 1, timeLeft: 0, nf: 0, keepHp: KEEP_HP, keepHc: 0,
  players: [], peasants: [], undead: [], structs: [], ev: [], store: { wood: 0, stone: 0, iron: 0, food: 0 },
  items: [], drops: [], spots: [0, 0, 0, 0, 0, 0, 0, 0], sites: [0, 0, 0], seed: 1, ale: 0, innHp: INN_HP, innIn: 0, relics: [],
  nid: 100, sv: 1, tv: 1, tpc: 1, pm: POSSE_MAX, night: null, wave: 0, waves: 3, left: 0, boss: null, graves: [], fallen: [],
  dawn: { seq: 0, day: 1, lines: [] }, stats: { kills: 0, wood: 0, built: 0, lost: 0 }
};
const srand = Math.random, rnd2 = (a, b) => a + (b - a) * srand(), pick = a => a[srand() * a.length | 0];
const say = t => S.ev.push(['msg', t]);
const live = () => S.phase === 'day' || S.phase === 'dusk' || S.phase === 'night';

// --- small rules shared by host and clients (clients use them for prompts and notices)
const rk = (p, b) => p.books[b] | 0;
const cap = p => { const r = rk(p, 0); return r >= 7 ? 50 : r >= 5 ? 40 : r >= 2 ? 30 : CARRY; };
const posseMax = p => { const r = rk(p, 6); return Math.max(1, S.pm + (r >= 6 ? 3 : r >= 4 ? 2 : r >= 2 ? 1 : 0) - (p.coward ? 1 : 0)); };
const popCap = () => POP_PER_PLAYER * S.players.length + (S.players.length === 1 ? 2 : 0);
const maxHp = p => PLAYER_HP + (rk(p, 4) >= 6 ? 20 : 0);
const mealHp = p => { const r = rk(p, 1); return r >= 7 ? 65 : r >= 5 ? 50 : r >= 2 ? 35 : 20; };
const slumFood = p => (rk(p, 1) >= 6 ? 3 : SLUM_FOOD) * (p.coward ? 2 : 1);
const has = (p, c) => { for (const k in c) if ((p[k] || 0) < c[k]) return false; return true; };
const pay = (p, c) => { for (const k in c) p[k] -= c[k]; if (p.bbod > p.bodies) p.bbod = p.bodies; };
const scale = (c, f, only) => { const o = {}; for (const r in c) o[r] = !only || r === only ? Math.max(1, Math.ceil(c[r] * f)) : c[r]; return o; };
function costOf(p, k) { const c = COST[k], r = rk(p, 2); return c.bodies || r < 1 ? c : scale(c, 0.8 - 0.03 * (r - 1)); }
function forgeCost(p, c) { const r = rk(p, 3); return r < 1 ? c : scale(c, 0.67 - 0.04 * (r - 1), 'iron'); }
function reinfCost(p, k) { return rk(p, 3) >= 7 ? scale(REINF[k].cost, 0.5) : REINF[k].cost; }
function gatherTime(p, kind) { const g = GATHER[kind], r = rk(p, g.book); return g.time * (r < 1 ? 1 : (g.book ? 0.7 : 0.78) - 0.04 * (r - 1)); }
const fishWait = p => rnd2(2.2, 4.8) * (rk(p, 1) < 1 ? 1 : 0.7 - 0.04 * (rk(p, 1) - 1));
const searchTime = p => SEARCH_TIME * (1 - 0.1 * rk(p, 8));
const needXp = (b, r) => Math.round(BOOKS[b].base * XPM[r - 1]);          // what rank r needs to become rank r + 1
function bookSlots(p) { const owned = p.books.filter(r => r > 0).length, allow = 1 + (p.books.some(r => r >= 2) ? 1 : 0) + (p.books.filter(r => r >= 3).length >= 2 ? 1 : 0); return Math.max(0, allow - owned); }
const gearCut = p => { let m = 1, any = false; for (const k of ['head', 'body', 'off']) if (p[k] >= 0) { m *= 1 - IT[p[k]].cut; any = true; } return any && rk(p, 3) >= 5 ? m * 0.95 : m; };
const canUse = (p, id) => { const n = IT[id].need; return !n || rk(p, n[0]) >= n[1]; };
const abWait = p => { const I = IT[p.wpn], A = AB[I.ab], r = rk(p, 4); return A ? A.cd * (r >= 5 ? 0.67 : r >= 3 ? 0.8 : 1) * (I.rng && rk(p, 5) >= 7 ? 0.5 : 1) : 0; };
const chargeLen = p => { const r = rk(p, 7); return r >= 6 ? 32 : r >= 2 ? 26 : 20; };
const insideVillage = (x, z) => Math.abs(x) < VW && z > VN && z < VS;
function repairCost(p, s) { const base = (COST[s.k].wood || 2) / 2, n = Math.max(1, Math.ceil(base * (1 - s.hp / s.max))); return { wood: rk(p, 2) >= 2 ? Math.ceil(n / 2) : n }; }
function addXp(p, b, n) {
  if (!p.books[b] || p.books[b] >= 7) return;
  p.xp[b] += p.coward ? n * 0.5 : n;
  while (p.books[b] < 7 && p.xp[b] >= needXp(b, p.books[b])) { p.books[b]++; say(`${p.dn} has reached rank ${p.books[b]} of ${BOOKS[b].name}.`); }
}

function mkPlayer(info, slot) {
  const c = cottage(slot);
  return {
    id: info.id, name: info.name, dn: info.name, col: info.col, slot, x: c.sx, z: c.sz, r: c.dir > 0 ? 0 : Math.PI, tx: c.sx, tz: c.sz, tr: 0,
    hp: PLAYER_HP, wood: 0, stone: 0, iron: 0, food: 0, coin: 0, bodies: 0, bbod: 0, wpn: 0, head: -1, body: -1, off: -1, trk: -1, inv: [], bless: 0, holy: 0, holyT: 0, study: false, gab: false,
    books: new Array(10).fill(0), xp: new Array(10).fill(0), coward: false, deaths: 0,
    cg: 0, charge: 0, hang: 0, drinkT: 0, abCd: 0, useCd: 0, tbCd: 0, ord: 0, parry: 0, guard: 0, combo: 0, upOnce: false,
    state: 'ok', ready: false, posse: 0, ac: 0, hc: 0, cc: 0, gk: 0, prog: 0, tp: S.tpc++, bite: 0, fishT: 3,
    atkCd: 0, eatCd: 0, hurtT: 99, eHold: false, itT: 0, itKey: null, workT: 0, workK: 'tree', downT: 0, lastIn: performance.now()
  };
}
// where a cottage's people stand in the morning: in a row outside the door, clear of the keep
function homeSpot(slot, j, n) { const c = cottage(slot); return { x: c.sx + (j - (n - 1) / 2) * 1.05, z: c.sz + c.dir * (0.15 + (j % 2) * 0.85), r: c.dir > 0 ? 0 : Math.PI }; }
const mkPeasant = (ni, x, z, hx, hz, owner) => ({ id: S.nid++, ni, x, z, r: 0, hx, hz, hp: PEASANT_HP, owner: owner || 0, state: owner ? 'follow' : 'idle', armed: 0, nv: 100, saved: false, cd: 0, ac: 0, hc: 0, ct: 0, tree: null, px: x, pz: z });
function addVillagers(slot, n) { for (let j = 0; j < n; j++) { const h = homeSpot(slot, j, n), q = mkPeasant((slot * 5 + j) % PNAMES.length, h.x, h.z, h.x, h.z, 0); q.r = h.r; S.peasants.push(q); } }
function clearWorld() {
  S.peasants = []; S.undead = []; S.structs = []; S.night = null; S.wave = 0; S.left = 0; S.boss = null; S.graves = []; S.fallen = []; S.ev = [];
  S.keepHp = KEEP_HP; S.keepHc = 0; S.nf = 0; S.store = { wood: 0, stone: 0, iron: 0, food: 0 }; S.stats = { kills: 0, wood: 0, built: 0, lost: 0 };
  S.items = []; S.drops = []; S.relics = []; S.ale = 0; S.innHp = INN_HP; S.innIn = 0;
  for (const t of trees) { t.wood = TREE_WOOD; t.gd = 0; setTreeState(t, 0, 0); }
  S.tv++; S.sv++;
}
function newGame() {
  clearWorld(); S.day = 1; S.seed = 1 + (srand() * 1e6 | 0);
  SLOTX.forEach((x, i) => { const k = i === 3 ? 'gate' : 'wall'; S.structs.push({ id: S.nid++, k, x, z: VN, rot: 0, built: false, hp: 0, max: SHP[k], slot: i, hc: 0, re: false, bl: false, age: 0, hw: SDIM[k].hw, hd: SDIM[k].hd }); });
  S.pm = S.players.length === 1 ? POSSE_SOLO : POSSE_MAX;
  S.players.forEach(p => { Object.assign(p, mkPlayer(p, p.slot)); addVillagers(p.slot, S.pm); });
  rollDay(true);
  startDay(['The dead have begun walking down from Ashhollow Castle at night. Robert Bailiff has bolted his door and wishes you all the best.', 'Start at the library: there is a book in it for each of you.', siteLine()]);
}
function rollDay(first) {                        // a new morning: the stone, the iron and the fish have moved, and the ruins hide new things
  S.sites = first ? [0, 0, 0] : S.sites.map((c, k) => { let n; do n = srand() * SITES[k].length | 0; while (n === c); return n; });
  setSites(S.sites); S.spots = S.spots.map(() => SEARCHES); S.ale = 0; S.innHp = INN_HP;
  for (const e of S.drops) { pushOut(e, 0.7, QUARRY); pushOut(e, 0.7, MINEC); }
  for (const q of S.peasants) if (q.state === 'body') { pushOut(q, 0.9, QUARRY); pushOut(q, 0.9, MINEC); }
  for (const s of S.structs.slice()) if (s.slot == null && (inBox(s.x, s.z, 1.2, QUARRY) || inBox(s.x, s.z, 1.2, MINEC))) destroyStruct(s);
}
const siteLine = () => `Today the stone is ${SITES[0][S.sites[0]].n}, the iron ${SITES[1][S.sites[1]].n}, and the fish are biting ${SITES[2][S.sites[2]].n}.` + (S.day > 1 ? ' The outer ruins have fallen down differently.' : '');
function startDay(lines) {
  S.phase = 'day'; S.timeLeft = DAY_LEN; S.undead = []; S.boss = null; S.night = null; S.left = 0; S.wave = 0; S.rage = 1;
  for (const p of S.players) p.ready = false;
  S.dawn = { seq: S.dawn.seq + 1, day: S.day, lines };
  saveGame();
}

// --- saving: the host's browser keeps the morning of the current day
const P_SAVE = ['name', 'dn', 'col', 'slot', 'hp', 'wood', 'stone', 'iron', 'food', 'coin', 'bodies', 'wpn', 'head', 'body', 'off', 'trk', 'holy', 'holyT', 'gab', 'coward', 'deaths'];
function saveData() {
  return {
    v: 3, day: S.day, pm: S.pm, seed: S.seed, keepHp: S.keepHp, store: S.store, items: S.items, relics: S.relics, sites: S.sites, stats: S.stats, lines: S.dawn.lines,
    drops: S.drops.map(d => ({ it: d.it, x: d.x, z: d.z })), trees: trees.filter(t => t.st || t.par).map(t => [t.i, t.st, t.par, t.gd]),
    structs: S.structs.map(s => ({ k: s.k, x: s.x, z: s.z, rot: s.rot, built: s.built, hp: s.hp, max: s.max, slot: s.slot, re: s.re, bl: s.bl, nr: s.nr, age: s.age })),
    players: S.players.map(p => { const o = { inv: p.inv.slice(), books: p.books.slice(), xp: p.xp.slice() }; for (const k of P_SAVE) o[k] = p[k]; return o; }),
    peasants: S.peasants.map(q => ({ ni: q.ni, x: q.x, z: q.z, hx: q.hx, hz: q.hz, hp: q.hp, armed: q.armed, body: q.state === 'body', os: (S.players.find(p => p.id === q.owner) || { slot: -1 }).slot }))
  };
}
function saveGame() { if (typeof Net !== 'undefined' && Net.role === 'client') return; try { localStorage.setItem('dtv-save', JSON.stringify(saveData())); } catch (e) { } }
function readSave() { try { const d = JSON.parse(localStorage.getItem('dtv-save') || 'null'); return d && d.v === 3 && d.players && d.players.length ? d : null; } catch (e) { return null; } }
function loadGame(d, infos) {                    // infos: the people playing now. Each takes over a saved peasant, by name where possible.
  clearWorld(); S.day = d.day; S.pm = d.pm; S.seed = d.seed || 1; S.keepHp = d.keepHp; S.store = Object.assign({ wood: 0, stone: 0, iron: 0, food: 0 }, d.store); S.stats = Object.assign(S.stats, d.stats);
  S.items = (d.items || []).slice(); S.relics = (d.relics || []).slice(); S.drops = (d.drops || []).map(e => ({ id: S.nid++, it: e.it, x: e.x, z: e.z }));
  for (const a of d.trees || []) { const t = trees[a[0]]; if (t) { setTreeState(t, a[1], a[2]); t.gd = a[3]; } }
  S.tv++;
  S.structs = d.structs.map(s => Object.assign({ id: S.nid++, hc: 0, tick: 0, hw: SDIM[s.k].hw, hd: SDIM[s.k].hd }, s));
  const left = d.players.slice(), used = new Set();
  S.players = infos.map(info => {
    let k = left.findIndex(sp => sp.name === info.name); if (k < 0) k = left.length ? 0 : -1;
    const sp = k >= 0 ? left.splice(k, 1)[0] : null;
    let slot = sp ? sp.slot : 0; while (!sp && (used.has(slot) || d.players.some(o => o.slot === slot))) slot++;
    used.add(slot);
    const p = mkPlayer(info, slot % 8); p.remote = info.remote;
    if (sp) { for (const f of P_SAVE) if (f !== 'name' && f !== 'col' && f !== 'slot' && sp[f] !== undefined) p[f] = sp[f]; p.inv = sp.inv.slice(); p.books = sp.books.slice(); p.xp = sp.xp.slice(); p.dn = relName(info.name, sp.deaths); }
    else addVillagers(p.slot, 3);
    return p;
  });
  for (const q of d.peasants) {
    const own = S.players.find(p => p.slot === q.os), e = mkPeasant(q.ni, own || q.body ? q.x : q.hx, own || q.body ? q.z : q.hz, q.hx, q.hz, own ? own.id : 0);
    e.hp = q.hp; e.armed = q.armed; if (q.body) { e.state = 'body'; e.owner = 0; } S.peasants.push(e);
  }
  const sites = d.sites || [0, 0, 0]; rollDay(true); S.sites = sites; setSites(sites);
  S.phase = 'day'; S.timeLeft = DAY_LEN; S.dawn = { seq: S.dawn.seq + 1, day: S.day, lines: d.lines || [] };
}

// --- collisions
function pushOut(e, r, c, axis) {                // axis 0 or 1 forces the push along x or z (after a move along that axis)
  const dx = e.x - c.x, dz = e.z - c.z; let lx = dx, lz = dz, cs = 1, sn = 0;
  if (c.rot) { cs = Math.cos(c.rot); sn = Math.sin(c.rot); lx = dx * cs - dz * sn; lz = dx * sn + dz * cs; axis = undefined; }
  const px = c.hw + r - Math.abs(lx), pz = c.hd + r - Math.abs(lz);
  if (px <= 1e-9 || pz <= 1e-9) return false;
  if (axis === 0 || (axis === undefined && px < pz)) lx += px * (lx < 0 ? -1 : 1); else lz += pz * (lz < 0 ? -1 : 1);
  if (c.rot) { e.x = c.x + lx * cs + lz * sn; e.z = c.z - lx * sn + lz * cs; } else { e.x = c.x + lx; e.z = c.z + lz; }
  return true;
}
function inBox(x, z, r, c) {
  const dx = x - c.x, dz = z - c.z; let lx = dx, lz = dz;
  if (c.rot) { const cs = Math.cos(c.rot), sn = Math.sin(c.rot); lx = dx * cs - dz * sn; lz = dx * sn + dz * cs; }
  return Math.abs(lx) < c.hw + r && Math.abs(lz) < c.hd + r;
}
function boxPoint(x, z, c) { return [clamp(x, c.x - c.hw, c.x + c.hw), clamp(z, c.z - c.hd, c.z + c.hd)]; }   // nearest point of an unrotated box
function collideFriend(e, r, axis) {             // villagers: buildings, built walls, trees, the edge of the map
  for (const c of colliders) pushOut(e, r, c, axis);
  for (const s of S.structs) if (s.built && s.k === 'wall') pushOut(e, r, s, axis);
  for (const t of trees) if (t.alive) { const dx = e.x - t.x, dz = e.z - t.z, rr = r + 0.42 * t.s, d = dx * dx + dz * dz; if (d < rr * rr && d > 1e-6) { const l = Math.sqrt(d); e.x = t.x + dx / l * rr; e.z = t.z + dz / l * rr; } }
  e.x = clamp(e.x, BOUNDS.x0, BOUNDS.x1); e.z = clamp(e.z, BOUNDS.z0, BOUNDS.z1);
}
// a standing palisade or gate stops blows both ways: nobody can be hit through it (arrows, stones and buckets go over)
function wallBetween(ax, az, bx, bz) {
  if ((az - VN) * (bz - VN) >= 0) return false;
  const x = ax + (bx - ax) * (VN - az) / (bz - az);
  for (const s of S.structs) if (s.slot != null && s.built && Math.abs(x - s.x) <= 3) return true;
  return false;
}
function blockingStruct(x, z, r) { for (const s of S.structs) if (s.built && s.k !== 'spikes' && inBox(x, z, r, s)) return s; return null; }

// --- what holding E would do for this player right now (shared by host and clients, so prompts match)
function findInteract(p) {
  if (!p) return null;
  if (p.state === 'hide') return { type: 'unhide', key: 'unhide', ok: true, dur: 0.6, x: p.x, z: p.z, rad: 1, label: 'Hold E to come out of your cottage' };
  if (p.state !== 'ok') return null;
  const rvT = rk(p, 9) >= 2 ? 1.5 : 3;
  for (const o of S.players) if (o !== p && o.state === 'down' && dist2(p.x, p.z, o.x, o.z) < 7) return { type: 'revive', target: o, key: 'r' + o.id, ok: true, dur: rvT, x: o.x, z: o.z, rad: 1, label: 'Hold E to revive ' + o.dn };
  if (S.phase !== 'day') { const c = cottage(p.slot), hx = c.sx, hz = c.z + c.dir * 2.3; if (dist2(p.x, p.z, hx, hz) < 2.6) return { type: 'hide', key: 'hide', ok: true, dur: 1.2, x: hx, z: hz, rad: 1, label: 'Hold E to hide in your cottage. The village will call you a coward.' }; }
  let best = null, bd = 3.6;
  for (const d of S.drops) { const dd = dist2(p.x, p.z, d.x, d.z); if (dd < bd) { bd = dd; best = d; } }
  if (best) { const full = p.inv.length >= PACK_MAX && !wearsNow(p, best.it); return { type: 'pick', target: best, key: 'd' + best.id, ok: !full, dur: 0.4, x: best.x, z: best.z, rad: 0.7, label: full ? 'Your pack is full (I opens it)' : `Hold E to pick up ${itA(best.it)}` }; }
  best = null; bd = 8;
  for (const q of S.peasants) if (q.state === 'idle') { const d = dist2(p.x, p.z, q.x, q.z); if (d < bd) { bd = d; best = q; } }
  if (best) { const full = p.posse >= posseMax(p); return { type: 'rally', target: best, key: 'q' + best.id, ok: !full, dur: 0.35, x: best.x, z: best.z, rad: 0.8, label: full ? (p.coward ? 'Your posse is full. Nobody else will follow a coward today.' : 'Your posse is full') : 'Hold E to rally ' + PNAMES[best.ni] }; }
  best = null; bd = 6.5;
  for (const q of S.peasants) if (q.state === 'body') { const d = dist2(p.x, p.z, q.x, q.z); if (d < bd) { bd = d; best = q; } }
  if (best) { const full = p.bodies >= MAX_BODIES; return { type: 'body', target: best, key: 'b' + best.id, ok: !full, dur: 0.7, x: best.x, z: best.z, rad: 0.9, label: full ? 'You can carry no more bodies' : `Hold E to pick up what is left of ${PNAMES[best.ni]}` }; }
  for (const s of S.structs) if (!s.built && s.slot != null) {
    const dx = clamp(p.x, s.x - 3, s.x + 3) - p.x, dz = s.z - p.z;
    if (dx * dx + dz * dz < 9) { const c = costOf(p, s.k), ok = has(p, c); return { type: 'found', target: s, key: 's' + s.id, ok, dur: 1.1, x: s.x, z: s.z, rad: 3.2, wide: true, label: ok ? `Hold E to build a ${SNAME[s.k]} (${costText(c)})` : `A ${SNAME[s.k]} needs ${costText(c)}` }; }
  }
  best = null; bd = 1e9;
  for (const s of S.structs) if (s.built && inBox(p.x, p.z, 1.7, s)) { const d = dist2(p.x, p.z, s.x, s.z); if (d < bd) { bd = d; best = s; } }
  if (best) {
    const s = best, rf = REINF[s.k], o = { target: s, x: s.x, z: s.z, rad: SDIM[s.k].hw + 0.2, wide: true, rot: s.rot };
    if (s.hp < s.max - 0.5) { const c = repairCost(p, s), ok = has(p, c); return Object.assign(o, { type: 'repair', key: 'p' + s.id, ok, dur: rk(p, 2) >= 2 ? 0.6 : 1.2, label: ok ? `Hold E to repair the ${SNAME[s.k]} (${costText(c)})` : `Repairing the ${SNAME[s.k]} needs ${costText(c)}` }); }
    if (rf && !s.re && Object.keys(rf.cost).some(k => p[k] > 0)) {
      const c = reinfCost(p, s.k), smith = !rf.smith || rk(p, 3) >= rf.smith, ok = smith && has(p, c);
      return Object.assign(o, { type: 'reinf', key: 'f' + s.id, ok, dur: 1.4, label: !smith ? 'Iron tips need rank 2 of Hammer and Tongs' : ok ? `Hold E to ${rf.name} (${costText(c)})` : `To ${rf.name} needs ${costText(c)}` });
    }
    if (p.bbod > 0 && !s.bl && s.k !== 'decoy' && s.k !== 'spikes') return Object.assign(o, { type: 'blessre', key: 'h' + s.id, ok: true, dur: 1.4, label: `Hold E to build a blessed body into the ${SNAME[s.k]}. It is what they would have wanted.` });
  }
  const kb = { x: KEEP.x, z: KEEP.z, hw: KEEP.h, hd: KEEP.h };
  if (S.keepHp < KEEP_HP && inBox(p.x, p.z, 1.6, kb)) { const c = { wood: 1, stone: 1 }, ok = has(p, c), pt = boxPoint(p.x, p.z, kb); return { type: 'keep', key: 'keep', ok, dur: 0.9, x: pt[0], z: pt[1], rad: 1.2, label: ok ? 'Hold E to mend the keep (1 wood and 1 stone a time)' : 'Mending the keep needs wood and stone' }; }
  const spots = ruinLayout(S.seed, S.day).spots;
  for (let i = 0; i < spots.length; i++) { const sp = spots[i]; if (dist2(p.x, p.z, sp.x, sp.z) < 4.6) { const n = S.spots[i] | 0; return { type: 'search', i, key: 'x' + i, ok: n > 0, dur: searchTime(p), x: sp.x, z: sp.z, rad: 1.1, label: n > 0 ? `Hold E to search the rubble` + (sp.ruin ? '. It is noisy work.' : '') : 'Nothing more under here until tomorrow' }; } }
  for (const st of STATIONS) if (dist2(p.x, p.z, st.x, st.z) < st.r * st.r) return { type: 'station', st, key: 'st' + st.id, ok: true, dur: 0.12, x: st.x, z: st.z, rad: 1.3, label: `Hold E to ${st.verb}` };
  if (rk(p, 9) >= 1) {
    best = null; bd = 5; let isP = false;
    for (const o of S.players) if (o !== p && o.state === 'ok' && o.hp < maxHp(o) - 5) { const d = dist2(p.x, p.z, o.x, o.z); if (d < bd) { bd = d; best = o; isP = true; } }
    for (const q of S.peasants) if ((q.state === 'follow' || q.state === 'fight' || q.state === 'chop') && q.hp < PEASANT_HP - 5) { const d = dist2(p.x, p.z, q.x, q.z); if (d < bd) { bd = d; best = q; isP = false; } }
    if (best) return { type: 'bandage', target: best, isP, key: 'n' + best.id, ok: true, dur: 1.6, x: best.x, z: best.z, rad: 0.8, label: 'Hold E to bandage ' + (isP ? best.dn : PNAMES[best.ni]) };
  }
  let kind = null, gx = p.x, gz = p.z, tgt = null, rad = 1.1; bd = 7.5;
  for (const t of trees) if (t.alive) { const d = dist2(p.x, p.z, t.x, t.z); if (d < bd) { bd = d; tgt = t; } }
  if (tgt) { kind = 'tree'; gx = tgt.x; gz = tgt.z; rad = 1.2 * tgt.s; }
  else if (inBox(p.x, p.z, 1.9, QUARRY)) { kind = 'stone'; const pt = boxPoint(p.x, p.z, QUARRY); gx = pt[0]; gz = pt[1]; }
  else if (dist2(p.x, p.z, MINE.x, MINE.z) < 8) { kind = 'iron'; gx = MINE.x + MINE.dir * 0.6; gz = MINE.z; }
  else if (p.x > FARM.x0 && p.x < FARM.x1 && p.z > FARM.z0 && p.z < FARM.z1) kind = 'food';
  else if (dist2(p.x, p.z, JETTY.x, JETTY.z) < 11) { kind = 'fish'; gx = JETTY.x; gz = JETTY.z + 1.4; }
  if (kind) {
    const g = GATHER[kind], full = p[g.res] >= cap(p);
    return { type: 'gather', kind, target: tgt, key: 'g' + kind + (tgt ? tgt.i : ''), ok: !full, dur: gatherTime(p, kind), x: gx, z: gz, rad, label: full ? `You can carry no more ${g.res}` : kind === 'fish' && p.bite > 0 ? 'A bite! Press Space' : `Hold E to ${g.verb}` };
  }
  return null;
}
function validPlace(k, x, z, rot) {
  if (x < BOUNDS.x0 + 2 || x > BOUNDS.x1 - 2 || z < BOUNDS.z0 + 2 || z > BOUNDS.z1 - 2) return false;
  if (Math.abs(z - VN) < 1.7 && Math.abs(x) < 21.5) return false;              // keep the foundations clear
  if ((k === 'bodywall' || k === 'decoy') && insideVillage(x, z)) return false; // the fallen go outside the wall
  const c = { x, z, hw: SDIM[k].hw, hd: SDIM[k].hd, rot };
  for (const o of colliders) if (inBox(o.x, o.z, Math.max(o.hw, o.hd) * 0.2, c) || inBox(x, z, 0.9, o)) return false;
  for (const s of S.structs) if (s.slot == null && dist2(x, z, s.x, s.z) < 2.3 * 2.3) return false;
  for (const t of trees) if (t.alive && inBox(t.x, t.z, 0.3, c)) return false;
  return true;
}
function aimAssist(p) {                          // turn to the nearest undead in reach
  const I = IT[p.wpn]; let best = null, bd = I.rng ? I.rng * I.rng : (I.reach + 1.5) ** 2;
  for (const u of S.undead) { if (u.state === 'rise') continue; const d = dist2(p.x, p.z, u.x, u.z); if (d < bd) { bd = d; best = u; } }
  if (best) p.r = Math.atan2(best.x - p.x, best.z - p.z);
}

// --- things held and worn
function dropItem(id, x, z) { S.drops.push({ id: S.nid++, it: id, x: clamp(x + rnd2(-0.9, 0.9), BOUNDS.x0, BOUNDS.x1), z: clamp(z + rnd2(-0.9, 0.9), BOUNDS.z0, BOUNDS.z1) }); }
function stow(p, id) { if (p.inv.length < PACK_MAX) p.inv.push(id); else dropItem(id, p.x, p.z); }
function wear(p, id) { const k = SLOTK[IT[id].s], old = p[k]; p[k] = id; if (k === 'wpn') { p.bless &= ~1; p.abCd = Math.max(p.abCd, 1.5); } if (k === 'trk') p.bless &= ~2; if (old > 0) stow(p, old); }
const wearsNow = (p, id) => { const k = SLOTK[IT[id].s]; return canUse(p, id) && (k === 'wpn' ? p.wpn === 0 : p[k] < 0); };   // would go straight on, not into the pack
function gain(p, id) { if (wearsNow(p, id)) wear(p, id); else stow(p, id); }

// --- actions
function gatherOne(kind, t, p) {
  const g = GATHER[kind]; if (p[g.res] >= cap(p)) return false;
  if (kind === 'tree') { if (!t || !t.alive) return false; t.wood--; S.stats.wood++; if (t.wood <= 0) { setTreeState(t, 1, t.par); S.tv++; } }
  p[g.res] = Math.min(cap(p), p[g.res] + (g.book === 0 && rk(p, 0) >= 6 && srand() < 0.2 ? 2 : 1)); addXp(p, g.book, 1); return true;
}
function tryPlace(p, k, x, z, rot) {
  if (!BUILDS.includes(k) || p.state !== 'ok' || !live()) return false;
  const c = costOf(p, k), r = rk(p, 2);
  if (!has(p, c) || dist2(p.x, p.z, x, z) > 144 || !validPlace(k, x, z, rot)) return false;   // generous on distance, to allow for a laggy connection
  pay(p, c); S.stats.built++; addXp(p, 2, 1);
  const max = Math.round(SHP[k] * (k === 'spikes' ? (r >= 5 ? 2 : 1) : k === 'decoy' ? 1 : r >= 6 ? 1.5 : r >= 3 ? 1.25 : 1));
  S.structs.push({ id: S.nid++, k, x, z, rot, built: true, hp: max, max, slot: null, hc: 0, re: false, bl: false, nr: k === 'barricade' && r >= 4, age: 0, hw: SDIM[k].hw, hd: SDIM[k].hd, tick: 0 });
  S.sv++; return true;
}
function destroyStruct(s) {
  if (s.slot != null) { s.built = false; s.hp = 0; s.re = false; s.bl = false; s.max = SHP[s.k]; } else { const i = S.structs.indexOf(s); if (i >= 0) S.structs.splice(i, 1); }
  S.sv++;
}
function killUndead(u) {
  if (u.dead) return;
  u.dead = true; S.stats.kills++; if (S.night) S.night.kills++;
  if (u.k < 3) { S.graves.push({ x: u.x, z: u.z, k: u.k }); if (S.graves.length > 40) S.graves.shift(); }
  else { S.boss = null; say('The Steward has been dismissed.'); }
}
// s: where the blow came from and whose it was: { x, z, p (a player), q (a peasant), blunt, holy (a multiplier), kb (extra knock-back), ranged }
function hitU(u, d, s) {
  s = s || {}; u.hc++;
  if (u.dead) return;
  if (u.state === 'pile') { if (s.p) killUndead(u); return; }
  const bony = u.k === 1 || u.k === 2;
  if (s.holy) d *= s.holy; if (u.vuln > 0) d *= 1.5; if (bony && s.blunt) d *= 2;
  u.hp -= d; u.cd = Math.min(UN[u.k].cd, u.cd + 0.25);                    // a hit delays its next swing a little; it does not stop it
  if (s.x !== undefined && u.k !== 3) { const dx = u.x - s.x, dz = u.z - s.z, l = Math.hypot(dx, dz) || 1, k = (u.k ? 0.7 : 0.25) * (s.blunt ? 1.6 : 1) + (s.kb || 0); u.x += dx / l * k; u.z += dz / l * k; }
  if (s.p) addXp(s.p, s.ranged ? 5 : 4, 1);
  else if (s.q) { const own = S.players.find(p => p.id === s.q.owner); if (own) addXp(own, 6, 0.5); }
  if (u.hp <= 0) {
    if (bony && !u.revived && !s.blunt && !s.holy) { u.state = 'pile'; u.t = 3.6; u.revived = true; u.hp = 0; u.stun = u.pin = u.fear = 0; }
    else killUndead(u);
  }
}
function nerveHit(q, n) {                        // a fright. At no nerve left, a peasant runs for the keep until dawn.
  const own = S.players.find(p => p.id === q.owner);
  if (!own || (q.state !== 'follow' && q.state !== 'fight' && q.state !== 'chop')) return;
  if (own.head === 20 || rk(own, 6) >= 7 || own.charge > 0) return;
  q.nv -= n * (1 - 0.1 * rk(own, 6));
  if (q.nv <= 0) { q.nv = 0; q.state = 'hide'; q.tree = null; say(`${PNAMES[q.ni]} has lost their nerve and run for the keep.`); }
}
function hurtFriend(e, d, isPlayer, u, ranged) {
  if (isPlayer) {
    if (e.state !== 'ok') return;
    if (!ranged && u && e.parry > 0) { e.parry = 0; u.stun = Math.max(u.stun, 2); hitU(u, dmgOf(e, IT[e.wpn], 1), srcOf(e, IT[e.wpn])); S.ev.push(['parry', r1(e.x), r1(e.z)]); return; }
    if (rk(e, 4) >= 2 && srand() < 0.125) { S.ev.push(['miss', r1(e.x), r1(e.z)]); return; }
    d *= gearCut(e) * (e.charge > 0 ? 0.5 : 1);
    if (u && !ranged && e.body === 23) hitU(u, 6, { holy: 1.5 });
  } else d *= e.armed ? 0.8 : 1;
  e.hp -= d; e.hc++; e.hurtT = 0;
  if (!isPlayer) nerveHit(e, 3);
  if (e.hp > 0) return;
  e.hp = 0;
  if (isPlayer) {
    if (rk(e, 9) >= 7 && !e.upOnce) { e.upOnce = true; e.hp = 35; say(`${e.dn} went down, thought better of it, and got up again.`); return; }
    e.state = 'down'; e.downT = rk(e, 9) >= 5 ? 30 : 15; e.gk = 0; e.prog = 0; e.study = false;
    for (const q of S.peasants) if (q.owner === e.id) nerveHit(q, 30);
  } else {
    const own = S.players.find(p => p.id === e.owner);
    if (own && rk(own, 9) >= 3 && !e.saved) { e.saved = true; e.hp = 18; return; }
    e.state = 'body'; e.owner = 0; e.tree = null; S.fallen.push(PNAMES[e.ni]); S.stats.lost++; say(`${PNAMES[e.ni]} has fallen.`);
    for (const q of S.peasants) if (q !== e && dist2(q.x, q.z, e.x, e.z) < 144) nerveHit(q, 22);
  }
}
// --- fighting
function dmgOf(p, I, mul) {
  let d = I.dmg * (mul || 1) * (1 + (I.rng ? 0.08 * rk(p, 5) : 0.06 * rk(p, 4)));
  if (I.tier === 'forged' && rk(p, 3) >= 4) d *= 1.1;
  if (p.charge > 0) d *= rk(p, 7) >= 7 ? 2 : 1.6;
  return d;
}
const srcOf = (p, I, kb) => ({ x: p.x, z: p.z, p, blunt: I.blunt, holy: I.holy || (p.bless & 1) ? (rk(p, 8) >= 5 ? 1.9 : 1.5) : 0, kb: (I.kb || 0) + (kb || 0), ranged: !!I.rng });
function targets(p, reach, arc, over) {          // the undead a blow from p would reach, nearest first. over: it goes over the wall
  const fx = Math.sin(p.r), fz = Math.cos(p.r), out = [];
  for (const u of S.undead) {
    if (u.state === 'rise' || u.dead) continue;
    const dx = u.x - p.x, dz = u.z - p.z, d = Math.hypot(dx, dz);
    if (d > reach + UN[u.k].r) continue;
    if (d > 0.8 && (dx * fx + dz * fz) / d < arc) continue;
    if (!over && wallBetween(p.x, p.z, u.x, u.z)) continue;
    u._d = d; out.push(u);
  }
  return out.sort((a, b) => a._d - b._d);
}
function shoot(p, I, mul, o) {                   // one shot at the nearest enemy ahead. Returns what it hit.
  const t = targets(p, I.rng, 0.3, true).filter(u => u.state !== 'pile')[0], fx = Math.sin(p.r), fz = Math.cos(p.r);
  const tx = t ? t.x : p.x + fx * I.rng * 0.7, tz = t ? t.z : p.z + fz * I.rng * 0.7;
  S.ev.push(['shot', r1(p.x), r1(p.z), r1(tx), r1(tz), I.shot]);
  if (!t || (!o && rk(p, 5) < 2 && srand() > 0.85)) return null;                 // an aimed stone does not miss
  const src = srcOf(p, I); src.x = undefined;                               // a shot does not shove anyone
  hitU(t, dmgOf(p, I, mul), src); if (o && o.stun) t.stun = Math.max(t.stun, t.k === 3 ? o.stun * 0.4 : o.stun);
  if (rk(p, 5) >= 6) { const t2 = S.undead.find(u => u !== t && !u.dead && u.state !== 'rise' && u.state !== 'pile' && dist2(u.x, u.z, t.x, t.z) < 9); if (t2) hitU(t2, dmgOf(p, I, mul * 0.6), src); }
  return t;
}
function doAttack(p) {
  if (p.state !== 'ok' || p.atkCd > 0) return;
  const I = IT[p.wpn]; p.atkCd = I.cd * (I.rng && rk(p, 5) >= 4 ? 0.8 : 1); p.ac++;
  let mul = 1; if (rk(p, 4) >= 7 && ++p.combo % 5 === 0) mul = 2;
  if (I.rng) { shoot(p, I, mul); return; }
  const src = srcOf(p, I);
  for (const u of targets(p, I.reach, rk(p, 4) >= 4 ? I.arc - 0.35 : I.arc)) hitU(u, dmgOf(p, I, mul), src);
}
const stunU = (u, t) => { u.stun = Math.max(u.stun, u.k === 3 ? t * 0.4 : t); };
function doAbility(p) {                          // the weapon's own trick, on Shift
  if (p.state !== 'ok' || p.abCd > 0 || !live()) return;
  const I = IT[p.wpn], k = I.ab; if (!AB[k]) return;
  p.abCd = abWait(p); p.ac++; p.atkCd = Math.max(p.atkCd, 0.35);
  const src = srcOf(p, I), D = m => dmgOf(p, I, m), fx = Math.sin(p.r), fz = Math.cos(p.r);
  if (k === 'pin') { const l = I.line ? targets(p, I.reach + 2.2, 0.9) : targets(p, I.reach + 0.4, I.arc).slice(0, 1); for (const u of l) { hitU(u, D(1.5), src); u.pin = u.k === 3 ? 1.5 : 3.5; } }
  else if (k === 'parry') p.parry = 1.8;
  else if (k === 'brace') { for (const u of targets(p, I.reach + 1.6, 0.93)) { hitU(u, D(2), src); stunU(u, 1.2); } }
  else if (k === 'shatter') { for (const u of targets(p, I.reach + 0.2, I.arc)) { hitU(u, D(1.5), src); u.vuln = 8; } }
  else if (k === 'hook') { const l = targets(p, 5.2, 0.3), u = l[l.length - 1]; if (u) { if (u.k !== 3) { u.x = p.x + fx * 1.4; u.z = p.z + fz * 1.4; } src.x = undefined; hitU(u, D(1), src); stunU(u, 1.6); } }
  else if (k === 'smash') { const c = { x: p.x + fx * 1.6, z: p.z + fz * 1.6, r: 0 }, s2 = Object.assign({}, src, { x: c.x, z: c.z, kb: 1.4 }); for (const u of targets(c, 3.2, -1)) if (!wallBetween(p.x, p.z, u.x, u.z)) { hitU(u, D(1.5), s2); stunU(u, 1.5); } }
  else if (k === 'wallop') { const u = targets(p, I.reach + 0.3, I.arc)[0]; if (u) { hitU(u, D(2.2), Object.assign({}, src, { kb: 2.4 })); stunU(u, 2.5); } }
  else if (k === 'bury') {
    const piles = S.undead.filter(u => u.state === 'pile' && dist2(u.x, u.z, p.x, p.z) < (I.reach + 0.8) ** 2);
    if (piles.length) piles.forEach(killUndead);
    else { const u = targets(p, I.reach + 0.3, I.arc)[0]; if (u) { if (u.k !== 3 && u.hp <= UN[u.k].hp * (I.holy ? 0.6 : 0.4)) { u.hc++; u.revived = true; killUndead(u); } else hitU(u, D(2), Object.assign({}, src, { kb: 1.5 })); } }
  }
  else if (k === 'trip') { for (const u of targets(p, I.reach + 0.5, -0.1)) { hitU(u, D(0.5), src); stunU(u, 2.2); } }
  else if (k === 'reap') { for (const u of targets(p, I.reach + 0.3, -1)) hitU(u, D(1.6), src); }
  else if (k === 'backstab') { const u = targets(p, I.reach + 0.3, I.arc)[0]; if (u) hitU(u, D(u.tg !== p.id || u.stun > 0 || u.pin > 0 || u.fear > 0 ? 3 : 1.5), src); }
  else if (k === 'clang') { p.guard = 6; for (const u of S.undead) { const d = dist2(u.x, u.z, p.x, p.z); if (d < 100 && u.k !== 3) { u.taunt = p.id; u.tauntT = 6; if (d < 9) stunU(u, 0.8); } } }
  else if (k === 'aimed') shoot(p, I, 3, { stun: 1.5 });
  else if (k === 'volley') { const l = targets(p, I.rng, 0, true).filter(u => u.state !== 'pile').slice(0, 3), s2 = Object.assign({}, src, { x: undefined }); for (const u of l) { S.ev.push(['shot', r1(p.x), r1(p.z), r1(u.x), r1(u.z), 1]); hitU(u, D(1), s2); } if (!l.length) S.ev.push(['shot', r1(p.x), r1(p.z), r1(p.x + fx * 10), r1(p.z + fz * 10), 1]); }
  else if (k === 'pierce') { const s2 = Object.assign({}, src, { x: undefined }); for (const u of targets(p, I.rng, 0.985, true)) hitU(u, D(1.5), s2); S.ev.push(['shot', r1(p.x), r1(p.z), r1(p.x + fx * I.rng), r1(p.z + fz * I.rng), 1]); }
  S.ev.push(['abl', k, r1(p.x), r1(p.z), r2(p.r)]);
}
function scare(u, x, z, t) { if (u.k === 3 || u.state === 'rise' || u.state === 'pile') return; u.fear = t; u.fx = x; u.fz = z; }
function doToilet(p) {                           // emergency toilet break: the posse makes its own ammunition
  if (p.state !== 'ok' || p.tbCd > 0 || !live()) return;
  const posse = S.peasants.filter(q => q.owner === p.id && (q.state === 'follow' || q.state === 'fight' || q.state === 'chop') && dist2(q.x, q.z, p.x, p.z) < 200);
  if (!posse.length) return;
  p.tbCd = TOILET_CD * (rk(p, 5) >= 5 ? 0.67 : 1);
  const near = S.undead.filter(u => u.k !== 3 && u.state !== 'rise' && u.state !== 'pile' && dist2(u.x, u.z, p.x, p.z) < 121);
  posse.forEach((q, i) => { const u = near.length ? near[i % near.length] : null; q.ac++; S.ev.push(['shot', r1(q.x), r1(q.z), r1(u ? u.x : q.x + Math.sin(p.r) * 7), r1(u ? u.z : q.z + Math.cos(p.r) * 7), 2]); });
  for (const u of near) { scare(u, p.x, p.z, 5); hitU(u, 2, {}); }
  say(`${p.dn}’s posse has taken an emergency toilet break. The dead did not care for it.`);
}
function doUse(p) {                              // G: whatever you carry
  if (p.state !== 'ok' || !live()) return;
  if (p.trk === 28) {                            // the slop bucket, lobbed once
    const t = targets(p, 9, 0, true)[0], x = t ? t.x : p.x + Math.sin(p.r) * 5, z = t ? t.z : p.z + Math.cos(p.r) * 5, holy = p.bless & 2;
    S.ev.push(['shot', r1(p.x), r1(p.z), r1(x), r1(z), 3]); S.ev.push(['splat', r1(x), r1(z), holy ? 1 : 0]);
    for (const u of S.undead) if (dist2(u.x, u.z, x, z) < 16) { scare(u, x, z, 6); if (holy) hitU(u, 30, { p, holy: rk(p, 8) >= 5 ? 1.9 : 1.5 }); }
    p.trk = -1; p.bless &= ~2;
  } else if (p.trk === 26 && p.useCd <= 0) {     // the Chapel Handbell
    p.useCd = 40; S.ev.push(['ring', r1(p.x), r1(p.z)]);
    for (const u of S.undead) if (u.state !== 'rise' && dist2(u.x, u.z, p.x, p.z) < 64) stunU(u, 3.5);
  }
}
function doOrder(p) {                            // Q: follow, hold here, charge
  if (p.state !== 'ok' || rk(p, 6) < 3) return;
  p.ord = (p.ord + 1) % 3;
  if (p.ord === 1) for (const q of S.peasants) if (q.owner === p.id) { q.px = q.x; q.pz = q.z; }
}
function doEat(p) {
  if (p.state !== 'ok' || p.food < 1 || p.eatCd > 0) return;
  const heal = mealHp(p), mine = S.peasants.filter(q => q.owner === p.id && q.state !== 'body'), posse = rk(p, 1) >= 4 ? mine.filter(q => q.hp < PEASANT_HP) : [];
  if (p.hp >= maxHp(p) && !posse.length) return;
  p.food--; p.eatCd = 0.6; p.hp = Math.min(maxHp(p), p.hp + heal); for (const q of posse) q.hp = Math.min(PEASANT_HP, q.hp + heal);
  if (rk(p, 1) >= 7) for (const q of mine) q.nv = 100;
  S.ev.push(['eat', r1(p.x), r1(p.z)]);
}
function doFish(p) {
  if (p.state !== 'ok' || p.gk !== 5) return;
  if (p.bite > 0) { const n = Math.min(FISH_FOOD + (rk(p, 1) >= 3 ? 1 : 0), cap(p) - p.food); p.food += n; addXp(p, 1, n); p.cc++; S.ev.push(['fish', r1(JETTY.x), r1(JETTY.z + 2.6)]); }
  p.bite = 0; p.fishT = fishWait(p);            // pulling early scares the fish off
}
const JUNK = ['a dead rat', 'somebody else’s left shoe', 'one button', 'a rude carving of Robert Bailiff', 'a jar of what used to be jam', 'nothing but spiders', 'a note reading “IOU one relic”'];
function doSearch(p, i) {                        // one rummage through a heap of rubble
  const sp = ruinLayout(S.seed, S.day).spots[i]; if (!sp || S.spots[i] <= 0) return;
  S.spots[i]--; addXp(p, 8, 1);
  const night = S.phase !== 'day', lore = rk(p, 8), dbl = lore >= 4 ? 2 : 1, left = RELICS.filter(id => !S.relics.includes(id));
  const inv0 = p.inv.length, pr = (night ? 0.06 : 0.012) * (lore >= 6 ? 2.5 : lore >= 3 ? 1.5 : 1) * (1 + 0.1 * (S.day - 1));   // relics glow in moonlight: far better odds at night
  let found, big = 0;
  if (left.length && srand() < pr) { const id = pick(left); S.relics.push(id); gain(p, id); found = IT[id].n; big = 1; say(`${p.dn} has found ${IT[id].n} in ${RUINS[sp.ruin].name}!`); }
  else {
    const r = srand();
    if (r < 0.34) { const res = RES[srand() * 3 | 0], n = Math.max(0, Math.min((3 + (srand() * 4 | 0)) * dbl, cap(p) - p[res])); p[res] += n; found = n ? `${n} ${res}` : `${res}, and no room to carry it`; }
    else if (r < 0.48) { const n = (8 + (srand() * 13 | 0)) * dbl; p.coin += n; found = `an old purse: ${coins(n)}`; }
    else if (r < 0.60) { const id = pick(FOUND_W); gain(p, id); found = itA(id); }
    else if (r < 0.69) { const id = pick(FOUND_A); gain(p, id); found = itA(id); }
    else if (r < 0.75) { gain(p, 28); found = 'a full slop bucket'; }
    else if (r < 0.81 && p.books.some(b => b > 0 && b < 7)) { const l = []; p.books.forEach((b, j) => { if (b > 0 && b < 7) l.push(j); }); const b = pick(l), r = p.books[b]; addXp(p, b, Math.ceil((needXp(b, r) - (r > 1 ? needXp(b, r - 1) : 0)) * 0.25));   /* a quarter of the way to the next rank */ found = `a loose page of ${BOOKS[b].name}`; }
    else if (r < 0.835 && !p.gab) { p.gab = true; big = 1; found = 'a pamphlet: The Gift of the Gab'; say(`${p.dn} has found The Gift of the Gab. The market will regret it.`); }
    else if (r < 0.90) { p.food = Math.min(cap(p), p.food + 1); found = 'a very old turnip. Still food.'; }
    else found = pick(JUNK);
  }
  S.ev.push(['found', p.id, found, r1(sp.x), r1(sp.z), big, p.inv.length > inv0 ? 1 : 0]);
  const pl = sp.ruin ? (night ? 0.6 : 0.3) : (night ? 0.25 : 0);              // the ruins are not empty, and searching is noisy
  if (lore < 7 && srand() < pl) {
    const n = 1 + (S.day >= 4 ? 1 : 0) + (night && srand() < 0.5 ? 1 : 0);
    for (let j = 0; j < n; j++) { const a = srand() * TAU, u = spawnUndead(S.day >= 3 && srand() < 0.35 ? 1 : 0, clamp(sp.x + Math.cos(a) * 3.6, BOUNDS.x0, BOUNDS.x1), clamp(sp.z + Math.sin(a) * 3.6, BOUNDS.z0, BOUNDS.z1)); u.taunt = p.id; u.tauntT = 30; }
    say(`Something in ${RUINS[sp.ruin].name} heard ${p.dn} rummaging.`);
  }
}
function leaveInn(p, charging) {
  if (p.state !== 'inn') return;
  p.state = 'ok'; p.x = p.tx = INN.dx; p.z = p.tz = INN.dz + rnd2(-0.8, 0.8); p.r = p.tr = Math.PI / 2; p.tp = S.tpc++; p.drinkT = 0;
  for (const q of S.peasants) if (q.owner === p.id && q.state === 'inn') { q.state = 'follow'; q.x = p.x + rnd2(0.4, 2); q.z = p.z + rnd2(-2, 2); if (charging) q.nv = 100; }
  if (charging) { p.cg = 0; p.charge = chargeLen(p); S.ev.push(['burst', r1(p.x), r1(p.z)]); say(`${p.dn} bursts out of the Thorny Rose, full of Dutch courage.`); }
}
function doAct(p, a, arg) {                       // things done from a notice. The host checks everything again.
  if (!live()) return;
  if (p.state === 'inn') {
    if (a === 'drink' && S.ale > 0 && p.drinkT <= 0 && p.cg < 100) { S.ale--; p.drinkT = DRINK_TIME; }
    else if (a === 'innout') leaveInn(p, false);
    return;
  }
  if (p.state !== 'ok') return;
  const at = id => { const st = STATIONS.find(s => s.id === id); return dist2(p.x, p.z, st.x, st.z) < (st.r + 2.5) ** 2; };
  const spark = k => S.ev.push([k, r1(p.x), r1(p.z)]);
  if (a === 'sell' && at('market') && RES.includes(arg)) { const n = Math.min(5, p[arg]); p[arg] -= n; p.coin += p.gab ? Math.floor(n * 1.5) : n; if (n) spark('coin'); }
  else if (a === 'buy' && at('market') && RES.includes(arg)) { const n = Math.min(5, cap(p) - p[arg], p.coin / 2 | 0); if (n > 0) { p[arg] += n; p.coin -= n * 2; spark('coin'); } }
  else if (a === 'put' && at('store') && RES.includes(arg)) { S.store[arg] += p[arg]; p[arg] = 0; }
  else if (a === 'take' && at('store') && RES.includes(arg)) { const n = Math.min(5, S.store[arg], cap(p) - p[arg]); if (n > 0) { S.store[arg] -= n; p[arg] += n; } }
  else if (a === 'puti' && at('store') && IT[p.inv[arg]] && S.items.length < 60) S.items.push(p.inv.splice(arg, 1)[0]);
  else if (a === 'pute' && at('store') && SLOTS.includes(arg) && p[arg] > 0 && S.items.length < 60) { S.items.push(p[arg]); p[arg] = arg === 'wpn' ? 0 : -1; if (arg === 'wpn') p.bless &= ~1; if (arg === 'trk') p.bless &= ~2; }
  else if (a === 'takei' && at('store') && IT[S.items[arg]] && (p.inv.length < PACK_MAX || wearsNow(p, S.items[arg]))) gain(p, S.items.splice(arg, 1)[0]);
  else if (a === 'eq' && IT[p.inv[arg]] && canUse(p, p.inv[arg])) { const id = p.inv.splice(arg, 1)[0]; wear(p, id); }
  else if (a === 'uneq' && SLOTS.includes(arg) && p[arg] > 0 && p.inv.length < PACK_MAX) { p.inv.push(p[arg]); p[arg] = arg === 'wpn' ? 0 : -1; if (arg === 'wpn') p.bless &= ~1; if (arg === 'trk') p.bless &= ~2; }
  else if (a === 'dropi' && IT[p.inv[arg]]) dropItem(p.inv.splice(arg, 1)[0], p.x, p.z);
  else if (a === 'forge' && at('smithy') && IT[arg] && IT[arg].cost) {
    const I = IT[arg], c = forgeCost(p, I.cost);
    if ((!I.heavy || rk(p, 3) >= 2) && has(p, c)) { pay(p, c); if (canUse(p, arg)) wear(p, arg); else stow(p, arg); addXp(p, 3, 1); spark('forge'); if (I.s === 'w') say(`${p.dn} has forged ${itA(arg)}.`); }
  }
  else if (a === 'armp' && at('smithy')) {
    const c = forgeCost(p, PEASANT_ARM); let n = 0;
    for (const q of S.peasants) if (q.owner === p.id && !q.armed && q.state !== 'body' && has(p, c)) { pay(p, c); q.armed = 1; addXp(p, 3, 1); n++; if (rk(p, 3) < 3) break; }
    if (n) spark('forge');
  }
  else if (a === 'book' && at('library') && BOOKS[arg] && !p.books[arg] && bookSlots(p) > 0) { p.books[arg] = 1; say(`${p.dn} has taken up ${BOOKS[arg].name}.`); if (arg === 5) { stow(p, 12); S.ev.push(['found', p.id, 'a sling, tucked inside the cover', r1(p.x), r1(p.z), 0, 1]); } }
  else if (a === 'recruit' && at('slum')) {
    const c = { food: slumFood(p) }, pop = S.peasants.filter(q => q.state !== 'body').length;
    if (has(p, c) && p.posse < posseMax(p) && pop < popCap()) {
      pay(p, c); const usedN = new Set(S.peasants.map(q => q.ni)); let ni = srand() * PNAMES.length | 0; for (let i = 0; i < PNAMES.length && usedN.has(ni); i++) ni = (ni + 1) % PNAMES.length;
      const h = homeSpot(p.slot, srand() * 5 | 0, 5);
      S.peasants.push(mkPeasant(ni, p.x - 1.2, p.z + 1.2, h.x, h.z, p.id)); addXp(p, 6, 4);
      say(`${PNAMES[ni]} has left the slum to follow ${p.dn}.`);
    }
  }
  else if (a === 'ale' && at('inn')) { const n = Math.min(5, p.food); if (n > 0) { p.food -= n; S.ale += n; spark('eat'); } }
  else if (a === 'innin' && at('inn') && S.phase !== 'day' && S.innHp > 0) {
    p.state = 'inn'; p.x = p.tx = INN.x; p.z = p.tz = INN.z; p.tp = S.tpc++; p.gk = 0; p.prog = 0; p.study = false;
    for (const q of S.peasants) if (q.owner === p.id && (q.state === 'follow' || q.state === 'fight' || q.state === 'chop')) { q.state = 'inn'; q.tree = null; }
    say(`${p.dn} has gone into the Thorny Rose and barred the door.`);
  }
  else if (a === 'study' && at('priest') && p.holy < 2) p.study = !p.study;
  else if (a === 'bless') {
    const free = arg === 'b' ? p.holy >= 2 : p.holy >= 1, okW = arg === 'w' && !(p.bless & 1) && !IT[p.wpn].holy, okK = arg === 'k' && p.trk === 28 && !(p.bless & 2), okB = arg === 'b' && p.bbod < p.bodies;
    if ((okW || okK || okB) && (free || (at('priest') && p.coin >= BLESS_FEE))) {
      if (!free) p.coin -= BLESS_FEE;
      if (okW) p.bless |= 1; else if (okK) p.bless |= 2; else p.bbod++;
      spark('holy');
    }
  }
}

// --- one step of the world
function simStep(dt) {
  if (S.phase === 'day') {
    S.nf = Math.max(0, S.nf - dt / 6); S.timeLeft -= dt;
    if (S.timeLeft <= 0 || (S.players.length && S.players.every(p => p.ready))) duskFalls();
  } else if (S.phase === 'dusk') {
    S.timeLeft -= dt; S.nf = clamp(1 - S.timeLeft / DUSK_LEN, 0, 1);
    if (S.timeLeft <= 0) startNight();
  } else if (S.phase === 'night') nightStep(dt);
  else if (S.phase === 'won') S.nf = Math.max(0, S.nf - dt / 6);
  if (!live()) return;
  S.innIn = 0; for (const p of S.players) { if (p.state === 'inn') S.innIn++; playerStep(p, dt); }
  for (const q of S.peasants) peasantStep(q, dt);
  undeadStep(dt); spikesStep(dt);
  if (S.undead.some(u => u.dead)) S.undead = S.undead.filter(u => { if (u.dead) fxGone('u', u); return !u.dead; });
}
function duskFalls() {
  S.phase = 'dusk'; S.timeLeft = DUSK_LEN;
  for (const q of S.peasants) if (q.state === 'idle') q.state = 'hide';
  for (const p of S.players) { p.ready = false; p.coward = false; }
  let rot = 0, gone = 0;                         // every evening the damp takes half of what is left of an old barricade
  for (const s of S.structs.slice()) if (s.k === 'barricade' && !s.re && !s.nr && s.age >= 1) { s.max = Math.round(s.max / 2); s.hp = Math.min(s.max, Math.ceil(s.hp / 2)); rot++; if (s.max < 20) { destroyStruct(s); gone++; } }
  if (rot) { S.sv++; say(`The evening damp has rotted ${rot} old barricade${rot > 1 ? 's' : ''} by half` + (gone ? `, and ${gone} fell apart.` : '.') + ' Iron braces stop the rot.'); }
}
function nightPlan(day, n) {                      // who comes down from the graveyard tonight, and over how long
  const total = Math.round(NIGHT_BASE * (1 + NIGHT_PER_PLAYER * (n - 1)) * Math.pow(NIGHT_GROWTH, day - 1));
  const kf = day < 2 ? 0 : day === 2 ? 0.2 : day === 4 ? 0.3 : 0.25, af = day >= 5 ? 0.14 : day === 4 ? 0.08 : 0;   // skeletons from night 2, a few archers from night 4
  const a = Math.round(total * af), k = Math.round(total * kf);
  return { c: [total - a - k, k, a], dur: NIGHT_RISE + NIGHT_RISE_DAY * (day - 1) };
}
// The dead do not come in waves. They rise one after another all night, slowly at first and faster as it goes on:
// the last of them come up a little over twice as fast as the first.
function nightQueue(plan) {
  const kinds = []; plan.c.forEach((n, k) => { for (let i = 0; i < n; i++) kinds.push(k); });
  for (let i = kinds.length - 1; i > 0; i--) { const j = srand() * (i + 1) | 0;[kinds[i], kinds[j]] = [kinds[j], kinds[i]]; }
  const first = Math.min(6, kinds.length);
  for (let i = 0; i < first; i++) if (kinds[i] === 2) { const j = kinds.findIndex((v, n) => n >= first && v !== 2); if (j > 0) { kinds[i] = kinds[j]; kinds[j] = 2; } }   // no archers among the very first
  return kinds.map((kd, i) => { const f = (i + 0.5) / kinds.length, x = (-0.6 + Math.sqrt(0.36 + 1.6 * f)) / 0.8; return { k: kd, t: 4 + plan.dur * x }; });
}
function spawnUndead(k, x, z) {
  const sx = x === undefined ? (srand() * 2 - 1) * SPAWN.w : x;
  const u = { id: S.nid++, k, x: sx, z: z === undefined ? SPAWN.z + (srand() * 2 - 1) * 4.5 : z, r: 0, hp: UN[k].hp, state: 'rise', t: 1.2, cd: srand(), lane: clamp(sx * 0.62 + (srand() * 2 - 1) * 3.5, -20, 20), jit: (srand() * 2 - 1) * 1.7, gap: -1, gt: 0, ac: 0, hc: 0, slow: 0, rt: 5, stun: 0, pin: 0, vuln: 0, fear: 0, taunt: 0, tauntT: 0, tg: 0 };
  if (k === 3) { u.hp = Math.round(UN[3].hp * (1 + 0.5 * (S.players.length - 1))); u.max = u.hp; u.lane = 0; S.boss = u; for (const q of S.peasants) nerveHit(q, 25); }
  S.undead.push(u); return u;
}
function startNight() {
  S.phase = 'night'; S.nf = 1; S.timeLeft = 0; S.graves = []; S.fallen = [];
  const plan = nightPlan(S.day, S.players.length), q = nightQueue(plan);
  S.night = { t: 0, q, total: q.length, c: plan.c, dur: plan.dur, kills: 0, boss: S.day === LAST_DAY };
  S.waves = q.length;
  for (const p of S.players) p.ready = false;
}
function nightStep(dt) {
  const N = S.night; N.t += dt;
  while (N.q.length && N.q[0].t <= N.t && S.undead.length < ALIVE_CAP) spawnUndead(N.q.shift().k);
  if (N.boss && N.q.length <= N.total * 0.6) { N.boss = false; spawnUndead(3, 0, SPAWN.z); say('The Steward has come down to supervise.'); }   // he arrives once the night is well under way
  // with nobody left standing (all dead, or under their beds) the dead make short work of what is in their way, so the night is not dragged out
  N.idle = S.players.some(p => p.state === 'ok' || p.state === 'down' || p.state === 'inn') ? 0 : (N.idle || 0) + dt; S.rage = N.idle > 12 ? Math.min(40, 6 + (N.idle - 12) * 0.4) : 1;
  S.wave = N.q.length; S.left = S.undead.length + N.q.length + (N.boss ? 1 : 0);    // S.wave: how many have still to rise
  if (S.keepHp <= 0) { S.keepHp = 0; S.phase = 'lost'; return; }
  if (S.left === 0) endNight();
}
function growTrees() {                           // dawn in the forest: saplings that are old enough become trees, and yesterday's stumps rot into saplings
  for (const t of trees) {
    if (t.st === 2 && S.day >= t.gd) { t.wood = TREE_WOOD; setTreeState(t, 0, t.par); }
    else if (t.st === 1) { setTreeState(t, 2, t.dx || t.dz ? 1 - t.par : t.par); t.gd = S.day + 1 + (t.i % 2); }
  }
  S.tv++;
}
function endNight() {                            // dawn: count the cost, bring people home, start the next day
  const N = S.night, lines = [`Night ${S.day} is over. ${N.kills} of the dead were put back down.`];
  if (S.fallen.length) lines.push(`Fallen: ${S.fallen.join(', ')}. What is left lies where it fell, and could still be useful.`);
  const share = 6 + (N.kills / 5 | 0); let paid = 0;
  for (const p of S.players) {
    if (p.state === 'inn') leaveInn(p, false);
    if (p.state === 'dead') {
      const was = p.dn, kept = SLOTS.map(k => p[k]).concat(p.inv).filter(id => id > 0 && IT[id].tier === 'relic'); p.deaths++; p.dn = relName(p.name, p.deaths);
      for (const id of kept) dropItem(id, p.x, p.z);
      Object.assign(p, { wood: 0, stone: 0, iron: 0, food: 0, bodies: 0, bbod: 0, wpn: 0, head: -1, body: -1, off: -1, trk: -1, inv: [], hp: PLAYER_HP, state: 'ok', coward: false });
      lines.push(`${was} did not see the dawn. ${p.dn.charAt(0).toUpperCase() + p.dn.slice(1)} has taken up the pitchfork, and the cottage.` + (kept.length ? ` ${kept.map(itCap).join(' and ')} still ${kept.length > 1 ? 'lie' : 'lies'} where ${was} fell.` : ''));
    } else {
      if (p.state === 'down') p.hp = 30;
      const hid = p.coward; p.state = 'ok'; p.hp = Math.min(maxHp(p), p.hp + 25);
      if (hid) lines.push(`${p.dn} spent the night under the bed. The village has noticed, and will remember until dusk.`);
      else { p.coin += share; paid++; }
    }
    const c = cottage(p.slot); p.x = p.tx = c.sx; p.z = p.tz = c.sz; p.tp = S.tpc++; p.gk = 0; p.prog = 0; p.bite = 0;
    Object.assign(p, { bless: 0, bbod: 0, cg: 0, charge: 0, hang: 0, drinkT: 0, parry: 0, guard: 0, upOnce: false, study: false, ord: 0, abCd: 0, useCd: 0, tbCd: 0 });   // blessings and Dutch courage both wear off by morning
  }
  if (paid) lines.push(`The village passed the hat: ${coins(share)} for everyone who stood and fought.`);
  if (S.ale > 0) lines.push(`The innkeeper finished the last ${S.ale} tankard${S.ale > 1 ? 's' : ''} himself.`);
  const row = {};
  for (const q of S.peasants) {                  // the living come home, and line up outside their leader's door
    if (q.state === 'body') continue;
    const own = S.players.find(p => p.id === q.owner);
    q.hp = PEASANT_HP; q.tree = null; q.nv = 100; q.saved = false;
    if (own) { const j = row[own.id] = (row[own.id] || 0) + 1, h = homeSpot(own.slot, j, 7); q.x = h.x; q.z = h.z; q.state = 'follow'; }
    else { q.owner = 0; q.state = 'idle'; q.x = q.hx; q.z = q.hz; }
  }
  for (const p of S.players) if (p.coward) {     // nobody new follows a coward, and one of the posse walks off
    const mine = S.peasants.filter(q => q.owner === p.id && q.state !== 'body');
    while (mine.length > posseMax(p)) { const q = mine.pop(); q.owner = 0; q.state = 'idle'; q.x = q.hx; q.z = q.hz; }
  }
  for (const s of S.structs) s.age = (s.age || 0) + 1;
  S.undead = []; S.boss = null;
  if (S.day >= LAST_DAY) { S.phase = 'won'; S.dawn = { seq: S.dawn.seq + 1, day: S.day, lines }; try { localStorage.removeItem('dtv-save'); } catch (e) { } return; }
  S.day++; growTrees(); rollDay(false); lines.push(siteLine()); startDay(lines);
}

function playerStep(p, dt) {
  p.atkCd = Math.max(0, p.atkCd - dt); p.eatCd = Math.max(0, p.eatCd - dt); p.hurtT += dt; p.workT = Math.max(0, p.workT - dt);
  p.abCd = Math.max(0, p.abCd - dt); p.useCd = Math.max(0, p.useCd - dt); p.tbCd = Math.max(0, p.tbCd - dt); p.parry = Math.max(0, p.parry - dt); p.guard = Math.max(0, p.guard - dt); p.hang = Math.max(0, p.hang - dt);
  if (p.charge > 0) { p.charge -= dt; if (p.charge <= 0) { p.charge = 0; const r = rk(p, 7); p.hang = r >= 4 ? 0 : r >= 3 ? 5 : 10; } }
  if (p.remote) { const k = Math.min(1, dt * 16); p.x = lerp(p.x, p.tx, k); p.z = lerp(p.z, p.tz, k); p.r = angLerp(p.r, p.tr, k); }
  if (p.state === 'down') { p.downT -= dt; if (p.downT <= 0) { p.state = 'dead'; say(`${p.dn} is dead.`); } return; }
  if (p.state === 'dead') return;
  let n = 0; for (const q of S.peasants) if (q.owner === p.id && q.state !== 'body') n++;
  p.posse = n;
  if (p.state === 'inn') {                       // drinking: each tankard takes a few seconds and fills the courage meter
    p.gk = 0; p.prog = 0;
    if (S.phase === 'day') return leaveInn(p, false);
    if (p.drinkT > 0) {
      p.drinkT -= dt;
      if (p.drinkT <= 0) {
        p.drinkT = 0; p.cg = Math.min(100, p.cg + TANKARD + 4 * rk(p, 7)); addXp(p, 7, 1); p.cc++;
        if (rk(p, 7) >= 5) for (const o of S.players) if (o !== p && o.state === 'inn') o.cg = Math.min(100, o.cg + 10);
        if (p.cg >= 100) leaveInn(p, true);
      }
    }
    for (const o of S.players) if (o.state === 'inn' && o.cg >= 100) leaveInn(o, true);
    return;
  }
  if (rk(p, 9) >= 4 && p.hp < maxHp(p)) p.hp = Math.min(maxHp(p), p.hp + dt);
  if (p.study) {                                 // a class in holy studies: stay by the priest until it is over
    const st = STATIONS[6];
    if (p.state !== 'ok' || p.holy >= 2 || dist2(p.x, p.z, st.x, st.z) > (st.r + 1.5) ** 2) p.study = false;
    else { p.holyT += dt; if (p.holyT >= HOLY_TIME) { p.holyT = 0; p.holy++; p.study = false; S.ev.push(['holy', r1(p.x), r1(p.z)]); say(p.holy === 1 ? `${p.dn} has sat through a class in holy studies, and can now bless a weapon or a bucket.` : `${p.dn} has finished holy studies, and can now bless the departed.`); } }
  }
  if (!p.eHold) p.eLock = false;                 // going in or out of the cottage needs a fresh press of E
  const it = p.eHold && !p.eLock ? findInteract(p) : null;
  if (!it || it.key !== p.itKey) { p.itT = 0; p.itKey = it ? it.key : null; p.bite = 0; p.fishT = fishWait(p); }
  p.gk = 0; p.prog = 0;
  if (it && it.ok && it.type === 'gather' && it.kind === 'fish') {             // fishing: wait for the bite
    p.gk = 5;
    if (p.bite > 0) { p.bite -= dt; if (p.bite <= 0) p.fishT = fishWait(p); }
    else { p.fishT -= dt; if (p.fishT <= 0) { p.bite = 1.2; S.ev.push(['bite', p.id]); } }
  } else if (it && it.ok) {
    p.itT += dt; p.prog = Math.min(1, p.itT / it.dur);
    if (it.type === 'gather') {
      p.gk = GK.indexOf(it.kind); p.workT = Math.max(p.workT, rk(p, 0) >= 4 ? 20 : 0.8); p.workK = it.kind; p.workX = it.x; p.workZ = it.z;
      if (!p.remote) p.r = angLerp(p.r, Math.atan2(it.x - p.x, it.z - p.z), Math.min(1, dt * 12));
    } else if (it.type === 'search') p.gk = 6;
    if (p.itT >= it.dur) {
      p.itT = 0;
      if (it.type === 'unhide') { p.state = 'ok'; p.eLock = true; }
      else if (it.type === 'hide') { p.state = 'hide'; p.coward = true; p.gk = 0; p.eLock = true; say(`${p.dn} has gone to hide under the bed.`); }
      else if (it.type === 'revive') { const o = it.target; o.state = 'ok'; o.hp = rk(p, 9) >= 2 ? 70 : 40; o.hurtT = 0; addXp(p, 9, 3); }
      else if (it.type === 'bandage') { const o = it.target, mx = it.isP ? maxHp(o) : PEASANT_HP; o.hp = rk(p, 9) >= 6 ? mx : Math.min(mx, o.hp + 25 + 5 * rk(p, 9)); addXp(p, 9, 1); S.ev.push(['eat', r1(o.x), r1(o.z)]); }
      else if (it.type === 'pick') { const d = it.target, i = S.drops.indexOf(d); if (i >= 0) { S.drops.splice(i, 1); gain(p, d.it); S.ev.push(['coin', r1(p.x), r1(p.z)]); } }
      else if (it.type === 'rally') { it.target.owner = p.id; it.target.state = 'follow'; addXp(p, 6, 2); }
      else if (it.type === 'body') { const q = it.target; S.peasants.splice(S.peasants.indexOf(q), 1); p.bodies++; }
      else if (it.type === 'found') { const s = it.target; pay(p, costOf(p, s.k)); s.built = true; s.max = SHP[s.k]; s.hp = s.max; s.re = false; s.bl = false; S.stats.built++; S.sv++; addXp(p, 2, 1); }
      else if (it.type === 'repair') { const s = it.target; pay(p, repairCost(p, s)); s.hp = s.max; s.hc++; S.sv++; addXp(p, 2, 0.5); S.ev.push(['build', r1(s.x), r1(s.z)]); }
      else if (it.type === 'reinf') { const s = it.target, rf = REINF[s.k]; pay(p, reinfCost(p, s.k)); s.re = true; s.max = Math.round(s.max * rf.mul); s.hp = s.max; s.hc++; S.sv++; addXp(p, 2, 1); S.ev.push(['build', r1(s.x), r1(s.z)]); }
      else if (it.type === 'blessre') { const s = it.target; p.bodies--; p.bbod--; s.bl = true; const add = Math.round(s.max * 0.5); s.max += add; s.hp += add; s.hc++; S.sv++; addXp(p, 2, 1); S.ev.push(['holy', r1(s.x), r1(s.z)]); }
      else if (it.type === 'keep') { pay(p, { wood: 1, stone: 1 }); S.keepHp = Math.min(KEEP_HP, S.keepHp + 40); S.ev.push(['build', r1(it.x), r1(it.z)]); }
      else if (it.type === 'search') { p.cc++; doSearch(p, it.i); }
      else if (it.type === 'gather') { p.cc++; gatherOne(it.kind, it.target, p); }
    } else if (it.type === 'search' && (p.itT % 0.7) < dt) p.cc++;
  }
}

const FOLLOW = [[-1.2, -1.7], [1.2, -1.7], [0, -2.8], [-2.3, -3.1], [2.3, -3.1], [0, -4.1], [-1.2, -4.6], [1.2, -4.6]];
function stepTo(e, x, z, spd, dt, stop) {
  const dx = x - e.x, dz = z - e.z, d = Math.hypot(dx, dz);
  if (d > 0.05) e.r = angLerp(e.r, Math.atan2(dx, dz), Math.min(1, dt * 10));
  if (d <= (stop || 0.15)) return d;
  const s = Math.min(spd * dt, d - (stop || 0));
  e.x += dx / d * s; collideFriend(e, 0.35, 0); e.z += dz / d * s; collideFriend(e, 0.35, 1);   // one axis at a time, so corners do not snag
  return d;
}
function peasantStep(q, dt) {
  q.cd = Math.max(0, q.cd - dt);
  if (q.state === 'body' || q.state === 'idle' || q.state === 'gone' || q.state === 'inn') return;
  if (q.state === 'hide') { if (stepTo(q, KEEP.x + 0.6, -KEEP.h - 0.6, 3.6, dt) < 0.5) q.state = 'gone'; return; }
  const Ld = S.players.find(p => p.id === q.owner);
  if (!Ld || Ld.state === 'dead') { q.owner = 0; q.state = S.phase === 'day' ? 'idle' : 'hide'; return; }
  if (Ld.state === 'hide') { q.state = 'hide'; return; }
  if (Ld.state === 'inn') { q.state = 'inn'; return; }
  const ord = Ld.ord | 0;                        // 0 follow, 1 hold here, 2 charge
  let tgt = null, bd = ord === 2 ? 900 : 81, near = false;
  for (const u of S.undead) {
    if (u.state === 'pile' || u.state === 'rise') continue; const d = dist2(q.x, q.z, u.x, u.z); if (d < 144) near = true;
    if (d < bd && (ord === 2 || (ord === 1 ? dist2(q.px, q.pz, u.x, u.z) < 36 : dist2(Ld.x, Ld.z, u.x, u.z) < 64)) && !wallBetween(q.x, q.z, u.x, u.z)) { bd = d; tgt = u; }
  }
  if (!near && q.nv < 100) q.nv = Math.min(100, q.nv + dt * 3);
  if (tgt) {
    q.state = 'fight'; q.tree = null;
    const reach = (q.armed ? 2.2 : 1.7) + UN[tgt.k].r, d = stepTo(q, tgt.x, tgt.z, ord === 2 ? 6 : 5.2, dt, reach - 0.45);
    if (d < reach && q.cd <= 0) { q.cd = 0.9; q.ac++; hitU(tgt, ((q.armed ? 10 : 6) + (q.armed && rk(Ld, 3) >= 6 ? 3 : 0)) * (rk(Ld, 6) >= 5 ? 1.25 : 1) * (Ld.charge > 0 ? 1.3 : 1), { x: q.x, z: q.z, q }); }
  } else if (ord === 1) {
    q.state = 'follow'; q.tree = null; q.ct = 0; if (Math.hypot(q.px - q.x, q.pz - q.z) > 0.5) stepTo(q, q.px, q.pz, 5.4, dt, 0.3);
  } else if (Ld.workT > 0 && Ld.workK !== 'fish' && Ld[GATHER[Ld.workK].res] < cap(Ld) && dist2(q.x, q.z, Ld.x, Ld.z) < 400) {
    q.state = 'chop'; const wt = PEASANT_WORK_TIME * (rk(Ld, 0) >= 3 ? 0.65 : 1);
    if (Ld.workK === 'tree') {
      if (!q.tree || !q.tree.alive || dist2(q.tree.x, q.tree.z, Ld.x, Ld.z) > 196) {
        q.tree = null; let b = 100;
        for (const t of trees) { if (!t.alive) continue; if (dist2(t.x, t.z, Ld.x, Ld.z) > 100) continue; if (S.peasants.some(o => o !== q && o.tree === t)) continue; const d = dist2(t.x, t.z, q.x, q.z); if (d < b) { b = d; q.tree = t; } }
      }
      if (q.tree) { const d = stepTo(q, q.tree.x, q.tree.z, 5, dt, 1.25 * q.tree.s + 0.3); if (d < 1.25 * q.tree.s + 0.7) { q.ct += dt; if (q.ct >= wt) { q.ct = 0; q.ac++; gatherOne('tree', q.tree, Ld); } } }
    } else {
      q.tree = null; const a = (q.id % 7) * 0.9, wx = Ld.workX + Math.cos(a) * 1.6 + (Ld.x - Ld.workX) * 0.6, wz = Ld.workZ + Math.sin(a) * 1.6 + (Ld.z - Ld.workZ) * 0.6;
      const d = stepTo(q, wx, wz, 5, dt, 0.4);
      if (d < 1.2) { q.r = angLerp(q.r, Math.atan2(Ld.workX - q.x, Ld.workZ - q.z), 0.2); q.ct += dt; if (q.ct >= wt) { q.ct = 0; q.ac++; gatherOne(Ld.workK, null, Ld); } }
    }
  } else {
    q.state = 'follow'; q.tree = null; q.ct = 0;
    let idx = 0; for (const o of S.peasants) { if (o === q) break; if (o.owner === q.owner && o.state !== 'body') idx++; }
    const f = FOLLOW[idx % FOLLOW.length], cs = Math.cos(Ld.r), sn = Math.sin(Ld.r);
    const tx = Ld.x + f[0] * cs + f[1] * sn, tz = Ld.z - f[0] * sn + f[1] * cs, d = Math.hypot(tx - q.x, tz - q.z);
    if (d > 40) { q.x = tx; q.z = tz; } else if (d > 0.45) stepTo(q, tx, tz, d > 4 ? (Ld.charge > 0 ? 10.5 : 8.2) : 5.4, dt, 0.3);
  }
  collideFriend(q, 0.35);
  for (const o of S.peasants) if (o !== q && o.state !== 'body' && o.state !== 'gone' && o.state !== 'inn') { const dx = q.x - o.x, dz = q.z - o.z, d = dx * dx + dz * dz; if (d < 0.5 && d > 1e-6) { const l = Math.sqrt(d), k = (0.71 - l) * 0.5; q.x += dx / l * k; q.z += dz / l * k; } }
}

function undeadGoal(u) {
  if (u.z < VN - 0.3) {                          // outside, to the north: look for a way through the wall
    u.gt -= 1;
    if (u.gt <= 0) {
      u.gt = 30; u.gap = -1; let b = 16;
      for (const s of S.structs) if (s.slot != null && !s.built) { const d = Math.abs(s.x - (u.z > VN - 12 ? u.x : u.lane)); if (d < b) { b = d; u.gap = s.slot; } }
    }
    if (u.gap >= 0) {
      const gx = SLOTX[u.gap] + u.jit;
      if (Math.abs(u.x - gx) > 1.2 && u.z > VN - 5) return [gx, VN - 5.2];
      return Math.abs(u.x - gx) > 1.2 ? [gx, VN - 4.6] : [gx, VN + 2.5];
    }
    return [clamp(u.lane, -20, 20), VN + 2];
  }
  if (!insideVillage(u.x, u.z)) {                // outside to the west, east or south (things from the outer ruins): round to a side gateway
    const sx = u.x < 0 ? -1 : 1;
    if (u.z > VS - 0.5 && Math.abs(u.x) < VW + 2.5) return [sx * (VW + 4.5), VS + 3];    // south of the wall: along it to the corner
    return Math.abs(u.z - GATE_Z) > 1.4 ? [sx * (VW + 4.5), GATE_Z] : [sx * (VW - 3), GATE_Z];
  }
  if (u.z < -18.6 && Math.abs(u.x) > 6.5) return [Math.sign(u.x) * 5.5, -19.9];   // sidle along the inside of the wall to the avenue
  return [clamp(u.lane * 0.3, -KEEP.h + 0.6, KEEP.h - 0.6), -KEEP.h - 0.2];   // somewhere along the keep's north face
}
function hitStruct(u, U, blk) { u.state = 'atk'; if (u.cd <= 0) { u.cd = U.cd; u.ac++; blk.hp -= U.sdmg * (S.rage || 1); blk.hc++; S.sv++; if (blk.bl) hitU(u, 5, { holy: 1.5 }); if (blk.hp <= 0) destroyStruct(blk); } }
function undeadStep(dt) {
  const keepBox = { x: KEEP.x, z: KEEP.z, hw: KEEP.h, hd: KEEP.h, rot: 0 };
  const decoys = S.structs.filter(s => s.k === 'decoy'), censers = S.players.filter(p => p.trk === 27 && p.state === 'ok');
  for (const u of S.undead) {
    const U = UN[u.k]; u.cd = Math.max(0, u.cd - dt); u.t -= dt; u.slow = Math.max(0, u.slow - dt);
    u.stun = Math.max(0, u.stun - dt); u.pin = Math.max(0, u.pin - dt); u.vuln = Math.max(0, u.vuln - dt); u.fear = Math.max(0, u.fear - dt); u.tauntT = Math.max(0, u.tauntT - dt);
    if (u.dead) continue;
    if (u.state === 'rise') { if (u.t <= 0) u.state = 'walk'; continue; }
    if (u.state === 'pile') { if (u.t <= 0) { u.state = 'walk'; u.hp = U.hp; } continue; }
    if (u.stun > 0) { u.state = 'stun'; continue; }
    if (u.state === 'stun') u.state = 'walk';
    for (const p of censers) if (dist2(u.x, u.z, p.x, p.z) < 30) u.slow = Math.max(u.slow, 0.3);
    const sp = U.spd * (u.slow > 0 ? 0.5 : 1);
    if (u.fear > 0) {                            // running from the smell
      const dx = u.x - u.fx, dz = u.z - u.fz, d = Math.hypot(dx, dz) || 1; u.state = 'walk'; u.r = angLerp(u.r, Math.atan2(dx, dz), Math.min(1, dt * 8));
      if (u.pin <= 0) { u.x += dx / d * sp * 1.5 * dt; for (const c of colliders) pushOut(u, U.r, c, 0); u.z += dz / d * sp * 1.5 * dt; for (const c of colliders) pushOut(u, U.r, c, 1); u.z = Math.max(u.z, SPAWN.z - 6); }
      continue;
    }
    const sight = u.k === 2 ? 169 : u.k === 3 ? 30 : 49;
    let tgt = null, tp = false, bd = sight;
    for (const p of S.players) if (p.state === 'ok') { const d = dist2(u.x, u.z, p.x, p.z); if (d < bd) { bd = d; tgt = p; tp = true; } }
    if (u.k !== 3) for (const q of S.peasants) if (q.state === 'follow' || q.state === 'fight' || q.state === 'chop') { const d = dist2(u.x, u.z, q.x, q.z); if (d < bd) { bd = d; tgt = q; tp = false; } }
    if (u.tauntT > 0) { const t = S.players.find(p => p.id === u.taunt && p.state === 'ok'); if (t && dist2(u.x, u.z, t.x, t.z) < 625) { tgt = t; tp = true; bd = dist2(u.x, u.z, t.x, t.z); } }
    u.tg = tgt && tp ? tgt.id : 0;
    let gx, gz, door = false;
    if (u.k === 3) {                             // the Steward: stands back and raises the fallen, until a player gets close
      const N = S.night, alone = !S.graves.length && S.undead.length === 1 && N && !N.q.length;
      if (!tgt) {
        if (alone || u.march) { u.march = true; const g = undeadGoal(u); gx = g[0]; gz = g[1]; }   // nobody left to raise: he sees to the keep himself
        else if (dist2(u.x, u.z, 0, -35) > 2) { gx = 0; gz = -35; }
        else { u.state = 'atk'; u.r = angLerp(u.r, 0, 0.1); u.rt -= dt; if (u.rt <= 0 && S.graves.length) { u.rt = 6; u.ac++; const n = Math.min(S.graves.length, 2 + (S.players.length / 2 | 0)); for (let i = 0; i < n; i++) { const g = S.graves.splice(srand() * S.graves.length | 0, 1)[0]; spawnUndead(g.k, g.x, g.z); S.ev.push(['raise', r1(g.x), r1(g.z)]); } } continue; }
      } else { gx = tgt.x; gz = tgt.z; u.rt = Math.max(u.rt, 2.5); }
    } else if (u.k === 2 && tgt && bd <= U.rng * U.rng) {    // archers stop and shoot
      u.state = 'atk'; u.r = angLerp(u.r, Math.atan2(tgt.x - u.x, tgt.z - u.z), Math.min(1, dt * 8));
      if (u.cd <= 0) { u.cd = U.cd; u.ac++; const hit = srand() < 0.7 && !(tp && (tgt.guard > 0 || (tgt.off >= 0 && srand() < IT[tgt.off].arrow))); S.ev.push(['arrow', r1(u.x), r1(u.z), r1(tgt.x), r1(tgt.z)]); if (hit) hurtFriend(tgt, U.dmg, tp, u, true); }
      continue;
    } else {
      let dc = null, dd = 64; if (u.k < 2 && bd > 12 && u.tauntT <= 0) for (const s of decoys) { const d = dist2(u.x, u.z, s.x, s.z); if (d < dd) { dd = d; dc = s; } }
      if (dc) { gx = dc.x; gz = dc.z; tgt = null; }           // a propped-up body is more interesting than anyone further off
      else if (tgt) { gx = tgt.x; gz = tgt.z; }
      else if (S.innIn && S.innHp > 0 && insideVillage(u.x, u.z) && dist2(u.x, u.z, INN.dx, INN.dz) < 260) { gx = INN.dx - 0.6; gz = INN.dz; door = true; }   // they can hear the singing
      else { const g = undeadGoal(u); gx = g[0]; gz = g[1]; }
    }
    const dx = gx - u.x, dz = gz - u.z, d = Math.hypot(dx, dz) || 1;
    u.r = angLerp(u.r, Math.atan2(dx, dz), Math.min(1, dt * 6));
    if (tgt && d < U.r + 1.05 && !wallBetween(u.x, u.z, tgt.x, tgt.z)) { if (u.state !== 'atk' && u.t < -1) u.cd = Math.max(u.cd, 0.45); u.state = 'atk'; u.t = 0; if (u.cd <= 0) { u.cd = U.cd; u.ac++; hurtFriend(tgt, U.dmg, tp, u, false); } continue; }
    if (door && d < U.r + 1.3) {
      u.state = 'atk'; if (u.cd <= 0) { u.cd = U.cd; u.ac++; S.innHp -= U.sdmg; S.ev.push(['build', r1(INN.dx - 0.8), r1(INN.dz)]); if (S.innHp <= 0) { S.innHp = 0; say('The dead have broken into the Thorny Rose. Drinking-up time.'); for (const p of S.players) leaveInn(p, p.cg >= 100); } }
      continue;
    }
    if (!tgt && !door && (u.k !== 3 || u.march) && inBox(u.x, u.z, U.r + 0.45, keepBox)) { u.state = 'atk'; u.r = angLerp(u.r, Math.atan2(KEEP.x - u.x, KEEP.z - u.z), 0.3); if (u.cd <= 0) { u.cd = U.cd; u.ac++; S.keepHp -= U.kdmg * (S.rage || 1); S.keepHc++; } continue; }
    if (u.pin > 0) { u.state = 'stun'; continue; }
    const nx = u.x + dx / d * sp * dt, nz = u.z + dz / d * sp * dt;
    const blk = blockingStruct(nx, nz, U.r);
    if (blk) { hitStruct(u, U, blk); continue; }
    u.state = 'walk';
    u.x = nx; for (const c of colliders) pushOut(u, U.r, c, 0);
    u.z = nz; for (const c of colliders) pushOut(u, U.r, c, 1);
  }
  const a = S.undead;                            // keep them from standing inside each other
  for (let i = 0; i < a.length; i++) {
    const u = a[i]; if (u.state === 'rise' || u.state === 'pile') continue;
    for (let j = i + 1; j < a.length; j++) {
      const v = a[j]; if (v.state === 'rise' || v.state === 'pile') continue;
      const dx = u.x - v.x, dz = u.z - v.z, d = dx * dx + dz * dz, rr = UN[u.k].r + UN[v.k].r;
      if (d < rr * rr && d > 1e-6) { const l = Math.sqrt(d), k = (rr - l) * 0.5 / l; u.x += dx * k; u.z += dz * k; v.x -= dx * k; v.z -= dz * k; }
    }
  }
}
function spikesStep(dt) {
  for (const s of S.structs.slice()) {
    if (s.k !== 'spikes') continue;
    s.tick = (s.tick || 0) - dt; if (s.tick > 0) continue; s.tick = 0.5;
    for (const u of S.undead) {
      if (u.state === 'rise' || u.state === 'pile' || u.dead || u.k === 3 || !inBox(u.x, u.z, UN[u.k].r * 0.6, s)) continue;
      hitU(u, s.re ? 10 : 5, {}); u.slow = 0.8; s.hp--; s.hc++; S.sv++;
      if (s.hp <= 0) { destroyStruct(s); break; }
    }
  }
}
