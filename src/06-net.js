// ===== co-op: one player hosts, the rest join by village code =====
const PREFIX = 'dtv3-thornhallow-';
const PEER_URLS = ['https://cdnjs.cloudflare.com/ajax/libs/peerjs/1.5.4/peerjs.min.js', 'https://cdn.jsdelivr.net/npm/peerjs@1.5.4/dist/peerjs.min.js', 'https://unpkg.com/peerjs@1.5.4/dist/peerjs.min.js'];
const Net = { role: 'solo', code: '', tr: null, myId: 1, nextId: 2, conns: new Map(), acc: 0, full: true, sentSv: 0, sentTv: 0, sentDawn: -1, unBuf: [], stBuf: null, trBuf: null, evOut: [] };
const Lobby = { players: [], saved: 0 };
const useLocal = () => location.hash === '#local';      // same-computer test mode: tabs talk to each other directly
function mkCode() { const a = 'ABCDEFGHJKLMNPRSTUVWXYZ'; let s = ''; for (let i = 0; i < 5; i++) s += a[Math.random() * a.length | 0]; return s; }
function loadPeer(cb) {
  if (useLocal() || typeof Peer !== 'undefined') return cb(true);
  let i = 0;
  (function next() {
    if (i >= PEER_URLS.length) return cb(false);
    const s = document.createElement('script'); s.src = PEER_URLS[i++];
    s.onload = () => typeof Peer !== 'undefined' ? cb(true) : next(); s.onerror = next;
    document.head.appendChild(s);
  })();
}

// --- transports. h = handlers
function hostTransport(code, h) {
  if (useLocal()) {
    const ch = new BroadcastChannel(PREFIX + code);
    ch.onmessage = ev => { const d = ev.data; if (d.to !== 'H') return; if (d.sys === 'open') { ch.postMessage({ to: d.from, sys: 'ok' }); h.join(d.from); } else if (d.sys === 'close') h.leave(d.from); else h.data(d.from, d.m); };
    setTimeout(h.open, 0);
    return { send: (cid, m) => ch.postMessage({ to: cid, m }), drop: cid => ch.postMessage({ to: cid, sys: 'bye' }), close() { for (const cid of Net.conns.keys()) ch.postMessage({ to: cid, sys: 'bye' }); ch.close(); } };
  }
  const peer = new Peer(PREFIX + code, { debug: 0 }), cs = new Map();
  peer.on('open', () => h.open());
  peer.on('error', e => h.error(e && e.type || 'error'));
  peer.on('disconnected', () => { try { peer.reconnect(); } catch (e) { } });
  peer.on('connection', c => {
    c.on('open', () => { cs.set(c.peer, c); h.join(c.peer); });
    c.on('data', m => h.data(c.peer, m));
    c.on('close', () => { cs.delete(c.peer); h.leave(c.peer); });
    c.on('error', () => { });
  });
  return { send(cid, m) { const c = cs.get(cid); if (c && c.open) try { c.send(m); } catch (e) { } }, drop(cid) { const c = cs.get(cid); if (c) setTimeout(() => { try { c.close(); } catch (e) { } }, 300); }, close() { try { peer.destroy(); } catch (e) { } } };
}
function clientTransport(code, h) {
  if (useLocal()) {
    const ch = new BroadcastChannel(PREFIX + code), id = 'c' + Math.random().toString(36).slice(2, 8); let ok = false, shut = false;
    ch.onmessage = ev => { const d = ev.data; if (d.to !== id || shut) return; if (d.sys === 'ok') { ok = true; h.open(); } else if (d.sys === 'bye') h.close(); else h.data(d.m); };
    ch.postMessage({ to: 'H', from: id, sys: 'open' });
    setTimeout(() => { if (!ok && !shut) h.error('peer-unavailable'); }, 1500);
    const bye = () => { if (!shut) { shut = true; ch.postMessage({ to: 'H', from: id, sys: 'close' }); ch.close(); } };
    addEventListener('pagehide', bye);
    return { send: m => { if (!shut) ch.postMessage({ to: 'H', from: id, m }); }, close: bye };
  }
  const peer = new Peer(undefined, { debug: 0 }); let c = null, ok = false, shut = false;
  peer.on('open', () => {
    c = peer.connect(PREFIX + code, { reliable: true, serialization: 'json' });
    c.on('open', () => { ok = true; h.open(); });
    c.on('data', m => h.data(m));
    c.on('close', () => { if (!shut) h.close(); });
    c.on('error', () => { if (!shut) h.close(); });
  });
  peer.on('error', e => { if (!ok && !shut) h.error(e && e.type || 'error'); });
  setTimeout(() => { if (!ok && !shut) h.error('timeout'); }, 15000);
  return { send(m) { if (c && c.open) try { c.send(m); } catch (e) { } }, close() { shut = true; try { peer.destroy(); } catch (e) { } } };
}

// --- host side
function freeCol(want) { const used = new Set(Lobby.players.map(p => p.col)); if (want != null && !used.has(want)) return want; for (let i = 0; i < 8; i++) if (!used.has(i)) return i; return 0; }
function broadcast(m) { if (Net.role !== 'host' || !Net.tr) return; for (const cid of Net.conns.keys()) Net.tr.send(cid, m); }
function sendLobby() { broadcast({ t: 'lobby', code: Net.code, pl: Lobby.players.map(p => [p.id, p.name, p.col]) }); uiLobby(); }
function sendRoster() { Net.full = true; Net.sentDawn = -1; broadcast({ t: 'ros', pm: S.pm, sd: S.seed, pl: S.players.map(p => [p.id, p.name, p.col, p.slot]) }); }
function startHost(done) {
  Net.role = 'host'; Net.myId = 1; Net.nextId = 2; Net.conns.clear(); Net.code = mkCode();
  Lobby.players = [{ id: 1, name: App.name, col: App.col }];
  Net.tr = hostTransport(Net.code, {
    open() { done(null); },
    error(type) { if (type === 'unavailable-id') { Net.tr.close(); startHost(done); } else if (App.screen !== 'game') done(type); },
    join(cid) {
      if (App.screen === 'game') { Net.tr.send(cid, { t: 'no', why: 'The day has already begun in that village. Ask the host to start a new game.' }); Net.tr.drop(cid); return; }
      if (Lobby.players.length >= 8) { Net.tr.send(cid, { t: 'no', why: 'That village is full: eight peasants already.' }); Net.tr.drop(cid); return; }
      const id = Net.nextId++; Net.conns.set(cid, id);
      Lobby.players.push({ id, name: 'Peasant', col: freeCol() });
      Net.tr.send(cid, { t: 'you', id }); sendLobby();
    },
    data(cid, m) { hostMsg(cid, m); },
    leave(cid) { dropClient(cid); }
  });
}
function dropClient(cid) {
  const id = Net.conns.get(cid); if (id == null) return; Net.conns.delete(cid);
  Lobby.players = Lobby.players.filter(p => p.id !== id);
  if (App.screen === 'game') {
    const gone = S.players.find(p => p.id === id);   /* a relic must not leave the village with whoever was holding it */
    if (gone) { if (gone.state === 'inn') leaveInn(gone, false); for (const it of SLOTS.map(k => gone[k]).concat(gone.inv)) if (it > 0 && IT[it].tier === 'relic') dropItem(it, gone.x, gone.z); }
    S.players = S.players.filter(p => p.id !== id);
    for (const q of S.peasants) if (q.owner === id) { q.owner = 0; q.state = S.phase === 'day' ? 'idle' : 'hide'; }
    sendRoster();
  } else sendLobby();
}
function hostMsg(cid, m) {
  const id = Net.conns.get(cid); if (id == null || !m) return;
  if (m.t === 'hi') {
    const lp = Lobby.players.find(p => p.id === id); if (!lp) return;
    lp.name = String(m.name || 'Peasant').slice(0, 14); const others = Lobby.players.filter(p => p !== lp).map(p => p.col);
    if (m.col >= 0 && m.col < 8 && !others.includes(m.col)) lp.col = m.col;
    sendLobby(); return;
  }
  const p = S.players.find(q => q.id === id); if (!p) return;
  if (m.t === 'in') { /* positions sent before the client heard it had been moved are ignored */ if (p.state === 'ok' && m.tp === p.tp) { p.tx = clamp(+m.x || 0, BOUNDS.x0, BOUNDS.x1); p.tz = clamp(+m.z || 0, BOUNDS.z0, BOUNDS.z1); p.tr = +m.r || 0; } p.eHold = !!m.e; p.lastIn = performance.now(); }
  else if (m.t === 'atk') { p.r = p.tr = +m.r || 0; doAttack(p); }
  else if (m.t === 'abl') { p.r = p.tr = +m.r || 0; doAbility(p); }
  else if (m.t === 'use') { p.r = p.tr = +m.r || 0; doUse(p); }
  else if (m.t === 'tb') doToilet(p);
  else if (m.t === 'ord') doOrder(p);
  else if (m.t === 'bld') tryPlace(p, m.k, +m.x, +m.z, +m.rot || 0);
  else if (m.t === 'rdy') { if (S.phase === 'day') p.ready = !!m.v; }
  else if (m.t === 'act') doAct(p, String(m.a), m.arg);
  else if (m.t === 'eat') doEat(p);
  else if (m.t === 'fish') doFish(p);
}
const r1 = v => Math.round(v * 10) / 10, r2 = v => Math.round(v * 100) / 100;
const PSTATE = ['ok', 'down', 'dead', 'hide', 'inn'], QSTATE = ['idle', 'follow', 'chop', 'fight', 'hide', 'body', 'gone', 'inn'], USTATE = ['rise', 'walk', 'atk', 'pile', 'stun'];
// one player, as sent to everyone twelve times a second
const pOut = p => ({
  id: p.id, x: r1(p.x), z: r1(p.z), r: r2(p.r), hp: Math.ceil(p.hp), st: PSTATE.indexOf(p.state), rd: p.ready ? 1 : 0, po: p.posse, ac: p.ac, hc: p.hc, cc: p.cc, gk: p.gk, pr: r2(p.prog), tp: p.tp, dt: r1(p.downT),
  w: [p.wood, p.stone, p.iron, p.food, p.coin, p.bodies, p.bbod], g: [p.wpn, p.head, p.body, p.off, p.trk], iv: p.inv, bk: p.books, xp: p.xp.map(Math.floor), dn: p.dn,
  f: (p.coward ? 1 : 0) | (p.bite > 0 ? 2 : 0) | (p.study ? 4 : 0) | (p.gab ? 8 : 0) | (p.parry > 0 ? 16 : 0) | (p.guard > 0 ? 32 : 0), bl: p.bless, ho: [p.holy, Math.floor(p.holyT)],
  cg: Math.round(p.cg), cd: [r1(p.charge), r1(p.hang), r1(p.abCd), Math.ceil(p.useCd), Math.ceil(p.tbCd), r1(p.drinkT)], od: p.ord
});
function pIn(e, a) {
  e.tx = a.x; e.tz = a.z; e.tr = a.r; e.hp = a.hp; e.ready = !!a.rd; e.posse = a.po; e.hc = a.hc; e.cc = a.cc; e.gk = a.gk; e.prog = a.pr; e.downT = a.dt;
  e.wood = a.w[0]; e.stone = a.w[1]; e.iron = a.w[2]; e.food = a.w[3]; e.coin = a.w[4]; e.bodies = a.w[5]; e.bbod = a.w[6];
  e.wpn = a.g[0]; e.head = a.g[1]; e.body = a.g[2]; e.off = a.g[3]; e.trk = a.g[4]; e.inv = a.iv; e.books = a.bk; e.xp = a.xp; e.dn = a.dn;
  e.coward = !!(a.f & 1); e.bite = a.f & 2 ? 1 : 0; e.study = !!(a.f & 4); e.gab = !!(a.f & 8); e.parry = a.f & 16 ? 1 : 0; e.guard = a.f & 32 ? 1 : 0; e.bless = a.bl; e.holy = a.ho[0]; e.holyT = a.ho[1];
  e.cg = a.cg; e.charge = a.cd[0]; e.hang = a.cd[1]; e.abCd = a.cd[2]; e.useCd = a.cd[3]; e.tbCd = a.cd[4]; e.drinkT = a.cd[5]; e.ord = a.od;
}
function sendDawn() { broadcast({ t: 'dawn', d: S.dawn }); }
function hostNet(dt) {
  if (Net.role !== 'host') return;
  const now = performance.now();
  for (const [cid, id] of Net.conns) { const p = S.players.find(q => q.id === id); if (p && App.screen === 'game' && now - p.lastIn > 12000) { Net.tr.drop(cid); dropClient(cid); } }
  Net.acc += dt; if (Net.acc < 1 / 12 || App.screen !== 'game' || !Net.conns.size) return; Net.acc = 0;
  if (Net.sentDawn !== S.dawn.seq) { Net.sentDawn = S.dawn.seq; sendDawn(); }
  const o = {
    t: 's', ph: S.phase, d: S.day, tl: r1(S.timeLeft), nf: r2(S.nf), k: Math.round(S.keepHp), kc: S.keepHc, w: [S.wave, S.waves, S.left], stt: [S.stats.kills, S.stats.wood, S.stats.built, S.stats.lost],
    so: [S.store.wood, S.store.stone, S.store.iron, S.store.food], si: S.sites, sp: S.spots, al: S.ale, ih: Math.ceil(S.innHp), it: S.items, dr: S.drops.map(d => [d.id, d.it, r1(d.x), r1(d.z)]), ev: Net.evOut,
    pl: S.players.map(pOut),
    pe: S.peasants.filter(q => q.state !== 'gone' && q.state !== 'inn').map(q => [q.id, r1(q.x), r1(q.z), r2(q.r), Math.ceil(q.hp), q.owner, QSTATE.indexOf(q.state), q.ac, q.hc, q.ni, q.armed, Math.round(q.nv)]),
    sv: S.sv, tv: S.tv
  };
  Net.evOut = [];
  // long lists travel as their own small messages just ahead of the snapshot, so no single message grows too big for the connection
  const un = S.undead.map(u => [u.id, u.k, r1(u.x), r1(u.z), r2(u.r), Math.ceil(u.hp), USTATE.indexOf(u.state), u.ac, u.hc, u.max | 0, (u.stun > 0 ? 1 : 0) | (u.pin > 0 ? 2 : 0) | (u.fear > 0 ? 4 : 0) | (u.vuln > 0 ? 8 : 0)]), CH = useLocal() ? 5 : 80;
  const uf = un.length <= 120 || (Net.tick = (Net.tick | 0) + 1) % 2 === 0;   // a big horde is sent every other time, to spare the host's connection
  if (uf) for (let i = 0; i < un.length; i += CH) broadcast({ t: 'un', a: un.slice(i, i + CH) });
  o.uf = uf ? 1 : 0;
  if (Net.full || S.sv !== Net.sentSv) { broadcast({ t: 'st', a: S.structs.map(s => [s.id, SKINDS.indexOf(s.k), r1(s.x), r1(s.z), r2(s.rot), s.built ? 1 : 0, Math.ceil(s.hp), s.slot == null ? -1 : s.slot, s.hc, s.re ? 1 : 0, s.max, s.bl ? 1 : 0]) }); Net.sentSv = S.sv; }
  if (Net.full || S.tv !== Net.sentTv) { broadcast({ t: 'tr', a: treeCodes() }); Net.sentTv = S.tv; }
  Net.full = false;
  broadcast(o);
}

// --- client side
function startClient(code, done) {
  Net.role = 'client'; Net.code = code; Net.myId = 0; let told = false;
  Net.tr = clientTransport(code, {
    open() { },
    error(type) { if (!told) { told = true; done(type === 'peer-unavailable' ? 'No village is using that code. Check it with the host.' : 'Could not reach that village. Check your connection and the code.'); } },
    data(m) { clientMsg(m, () => { if (!told) { told = true; done(null); } }); },
    close() { const why = App.kick; App.kick = null; if (App.screen !== 'home') uiHostLeft(why); else if (!told) { told = true; done(why || 'Could not reach that village.'); } }
  });
}
function syncList(list, arr, make, upd, gone) {
  const by = new Map(); for (const e of list) by.set(e.id, e);
  const out = [];
  for (const a of arr) { const id = Array.isArray(a) ? a[0] : a.id; let e = by.get(id), fresh = false; if (!e) { e = make(a); fresh = true; } else by.delete(id); upd(e, a, fresh); out.push(e); }
  if (gone) for (const e of by.values()) gone(e);
  return out;
}
const blankPlayer = id => ({ id, x: 0, z: 0, r: 0, tx: 0, tz: 0, tr: 0, hp: PLAYER_HP, wood: 0, stone: 0, iron: 0, food: 0, coin: 0, bodies: 0, bbod: 0, wpn: 0, head: -1, body: -1, off: -1, trk: -1, inv: [], bless: 0, holy: 0, holyT: 0, books: new Array(10).fill(0), xp: new Array(10).fill(0), cg: 0, charge: 0, hang: 0, abCd: 0, useCd: 0, tbCd: 0, drinkT: 0, ord: 0, state: 'ok', posse: 0, ac: 0, hc: 0, cc: 0, gk: 0, tpSeen: -1 });
function clientMsg(m, joined) {
  if (!m) return;
  if (m.t === 'you') { Net.myId = m.id; Net.tr.send({ t: 'hi', name: App.name, col: App.col }); joined(); }
  else if (m.t === 'no') { App.kick = m.why; }
  else if (m.t === 'lobby') { Lobby.players = m.pl.map(a => ({ id: a[0], name: a[1], col: a[2] })); Net.code = m.code; Lobby.saved = m.sv || 0; uiLobby(); }
  else if (m.t === 'ros') {
    S.pm = m.pm; S.seed = m.sd;
    S.players = syncList(S.players, m.pl, a => blankPlayer(a[0]), (e, a) => { e.name = a[1]; e.col = a[2]; e.slot = a[3]; if (!e.dn) e.dn = e.name; });
  }
  else if (m.t === 'dawn') S.dawn = m.d;
  else if (m.t === 'un') Net.unBuf.push(...m.a);
  else if (m.t === 'st') Net.stBuf = m.a;
  else if (m.t === 'tr') Net.trBuf = m.a;
  else if (m.t === 's') {
    m.un = Net.unBuf; Net.unBuf = []; m.st = Net.stBuf; Net.stBuf = null; m.tr = Net.trBuf; Net.trBuf = null;
    S.phase = m.ph; S.day = m.d; S.timeLeft = m.tl; S.nf = m.nf; S.keepHp = m.k; S.keepHc = m.kc; S.wave = m.w[0]; S.waves = m.w[1]; S.left = m.w[2];
    S.stats.kills = m.stt[0]; S.stats.wood = m.stt[1]; S.stats.built = m.stt[2]; S.stats.lost = m.stt[3];
    RES.forEach((r, i) => { S.store[r] = m.so[i]; });
    if (m.si.join() !== S.sites.join()) { S.sites = m.si; setSites(m.si); }
    S.spots = m.sp; S.ale = m.al; S.innHp = m.ih; S.items = m.it; S.drops = m.dr.map(a => ({ id: a[0], it: a[1], x: a[2], z: a[3] }));
    for (const a of m.pl) {
      const e = S.players.find(p => p.id === a.id); if (!e) continue;
      const mine = e.id === Net.myId, st = PSTATE[a.st];
      pIn(e, a);
      if (!mine) e.ac = a.ac;
      if (e.tpSeen !== a.tp || (mine && st !== 'ok' && e.state === 'ok')) { e.tpSeen = a.tp; e.x = e.tx; e.z = e.tz; e.r = e.tr; }
      e.state = st;
    }
    S.peasants = syncList(S.peasants, m.pe, a => ({ id: a[0], x: a[1], z: a[2], r: a[3] }), (e, a) => { e.tx = a[1]; e.tz = a[2]; e.tr = a[3]; e.hp = a[4]; e.owner = a[5]; e.state = QSTATE[a[6]]; e.ac = a[7]; e.hc = a[8]; e.ni = a[9]; e.armed = a[10]; e.nv = a[11]; });
    if (m.uf) S.undead = syncList(S.undead, m.un, a => ({ id: a[0], x: a[2], z: a[3], r: a[4] }), (e, a) => { e.k = a[1]; e.tx = a[2]; e.tz = a[3]; e.tr = a[4]; e.hp = a[5]; e.state = USTATE[a[6]]; e.ac = a[7]; e.hc = a[8]; e.max = a[9]; e.fl = a[10]; }, e => fxGone('u', e));
    S.boss = S.undead.find(u => u.k === 3) || null;
    if (m.st) S.structs = syncList(S.structs, m.st, a => ({ id: a[0] }), (e, a) => { e.k = SKINDS[a[1]]; e.x = a[2]; e.z = a[3]; e.rot = a[4]; e.built = !!a[5]; e.hp = a[6]; e.slot = a[7] < 0 ? null : a[7]; e.hc = a[8]; e.re = !!a[9]; e.max = a[10]; e.bl = !!a[11]; e.hw = SDIM[e.k].hw; e.hd = SDIM[e.k].hd; }, e => fxGone('s', e));
    if (m.tr) { applyTreeCodes(m.tr); S.tv = m.tv; }
    if (m.ev && m.ev.length) S.ev.push(...m.ev);
    if (App.screen !== 'game' && S.players.length) enterGame();
  }
}
function clientStep(dt) {                        // ease everything toward where the host last said it was
  const k = Math.min(1, dt * 11);
  for (const p of S.players) if (p.id !== Net.myId) { p.x = lerp(p.x, p.tx, k); p.z = lerp(p.z, p.tz, k); p.r = angLerp(p.r, p.tr, k); }
  for (const q of S.peasants) { q.x = lerp(q.x, q.tx, k); q.z = lerp(q.z, q.tz, k); q.r = angLerp(q.r, q.tr, k); }
  for (const u of S.undead) { u.x = lerp(u.x, u.tx, k); u.z = lerp(u.z, u.tz, k); u.r = angLerp(u.r, u.tr, k); }
  Net.acc += dt;
  if (Net.acc >= 1 / 15 && ME && Net.tr) { Net.acc = 0; Net.tr.send({ t: 'in', x: r2(ME.x), z: r2(ME.z), r: r2(ME.r), e: ME.eHold ? 1 : 0, tp: ME.tpSeen }); }
}
function leaveNet() { Net.unBuf = []; Net.stBuf = null; Net.trBuf = null; Net.evOut = []; if (Net.tr) { try { Net.tr.close(); } catch (e) { } } Net.tr = null; Net.role = 'solo'; Net.conns.clear(); Net.myId = 1; }
// what the local player does goes straight to the rules when hosting or alone, and to the host otherwise
function act(a, arg) { if (!ME) return; if (Net.role === 'client') Net.tr.send({ t: 'act', a, arg }); else doAct(ME, a, arg); }
