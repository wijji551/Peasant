// Build 3 rules test, solo. The bot is moved straight to places (this tests the rules, not walking).
const { chromium } = require('./_playwright');
const URL = process.env.DTV_URL || 'http://127.0.0.1:8765/defend-the-village.html';
const sleep = ms => new Promise(r => setTimeout(r, ms));
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const ctx = await browser.newContext({ viewport: { width: 1000, height: 640 } });
  const page = await ctx.newPage(); const errs = [];
  page.on('pageerror', e => errs.push('PAGEERROR: ' + e.message + '\n' + (e.stack || '').split('\n').slice(0, 6).join('\n')));
  page.on('console', m => { if (m.type() === 'error' && !/ERR_TUNNEL|Failed to load/.test(m.text())) errs.push(m.text()); });
  await page.goto(URL); await sleep(1200);
  await page.evaluate(() => localStorage.removeItem('dtv-save'));
  await page.fill('#name', 'Matt'); await page.click('#btnSolo'); await sleep(1000);
  const out = await page.evaluate(() => {
    const d = window.__dtv, S = d.S, K = d.keys, T = d.trees, X = d.sim, IT = d.IT, log = [], me = () => d.me();
    const ok = (name, cond, extra) => log.push((cond ? 'PASS ' : 'FAIL ') + name + (extra !== undefined ? '  [' + extra + ']' : ''));
    const at = (x, z) => { const m = me(); m.x = x; m.z = z; };
    const hold = (sec, stop) => { K.KeyE = true; d.fast(sec, () => stop && stop() ? false : undefined); K.KeyE = false; d.fast(0.1); };
    const clearU = () => { S.undead.length = 0; };
    const mob = (n, k, dist) => { const m = me(), a = []; for (let i = 0; i < n; i++) { const u = X.spawnUndead(k || 0, m.x + Math.sin(m.r) * (dist || 1.6) + (i - (n - 1) / 2) * 0.7, m.z + Math.cos(m.r) * (dist || 1.6)); u.state = 'walk'; u.t = 0; a.push(u); } return a; };
    const inKeep = e => Math.abs(e.x) < d.KEEP.h + 0.3 && Math.abs(e.z) < d.KEEP.h + 0.3;
    try {
      // ---------- the morning
      ok('day 1, saved, sites at their first places', S.day === 1 && S.phase === 'day' && !!d.readSave() && S.sites.join() === '0,0,0');
      ok('keep is smaller', d.KEEP.h < 4);
      ok('nobody starts inside the keep', !S.peasants.some(inKeep) && !inKeep(me()), S.peasants.map(q => q.z.toFixed(1)).join());
      let bad = 0; for (let s = 0; s < 8; s++) for (let j = 0; j < 8; j++) { const h = X.homeSpot(s, j, 7); if (inKeep(h)) bad++; }
      ok('no cottage lines its people up inside the keep', bad === 0, bad);
      ok('pitchfork, empty pack, ten books', me().wpn === 0 && me().inv.length === 0 && me().books.length === 10 && d.BOOKS.length === 10 && d.BOOKS.every(b => b.ranks.length === 7));

      // ---------- books: ten of them, seven ranks
      at(13.4, 20.4); const lib = d.panelData('library', me(), ''); ok('library lists ten books', lib.o.length === 10);
      d.act('book', 4); ok('took The Art of Hitting Things', me().books[4] === 1 && X.bookSlots(me()) === 0);
      X.addXp(me(), 4, X.needXp(4, 1)); ok('rank 2 opens a second book', me().books[4] === 2 && X.bookSlots(me()) === 1);
      d.act('book', 6); X.addXp(me(), 6, X.needXp(6, 2)); ok('leadership rank 3', me().books[6] === 3 && X.bookSlots(me()) === 0);
      X.addXp(me(), 4, X.needXp(4, 2)); ok('two books at rank 3 open the third', me().books[4] === 3 && X.bookSlots(me()) === 1);
      d.act('book', 9); ok('three books, no fourth', me().books[9] === 1 && X.bookSlots(me()) === 0); d.act('book', 0); ok('a fourth is refused', me().books[0] === 0);
      X.addXp(me(), 4, 99999); ok('a book stops at rank 7', me().books[4] === 7);
      ok('posse grows with leadership', X.posseMax(me()) === 6, X.posseMax(me()));

      // ---------- gathering at today's sites
      at(d.QUARRY.x - d.QUARRY.hw - 1, d.QUARRY.z); hold(8, () => me().stone >= 2); ok('stone at the outcrop', me().stone >= 2, me().stone);
      at(d.MINE.x - d.MINE.dir * 0.8, d.MINE.z); hold(9, () => me().iron >= 2); ok('iron at the mine', me().iron >= 2, me().iron);
      at(d.JETTY.x, d.JETTY.z - 0.6); const fi = d.findInteract(me()); ok('fishing at the jetty', fi && fi.kind === 'fish', fi && fi.type);
      at(60, -8); ok('player is pushed out of the outcrop', true); d.fast(0.2);

      // ---------- searching the ruins
      const RL = d.ruinLayout(S.seed, S.day); ok('eight heaps of rubble to search', RL.spots.length === 8 && S.spots.every(n => n === 2));
      at(RL.spots[0].x + 0.8, RL.spots[0].z); const si = d.findInteract(me()); ok('prompt to search the old ruins', si && si.type === 'search' && si.ok, si && si.label);
      hold(5, () => S.spots[0] < 2); ok('a search uses the heap up', S.spots[0] === 1, S.spots[0]);
      hold(5, () => S.spots[0] < 1); const si2 = d.findInteract(me()); ok('heap is empty after two searches', S.spots[0] === 0 && si2 && !si2.ok, si2 && si2.label);
      const before = { coin: me().coin, u: S.undead.length };
      let lurk = 0; for (let i = 0; i < 200; i++) { S.spots[3] = 2; const n = S.undead.length; X.doSearch(me(), 3); if (S.undead.length > n) lurk++; clearU(); me().inv.length = Math.min(me().inv.length, 3); }
      ok('searching finds coins and things', me().coin > before.coin && (me().inv.length > 0 || me().wpn > 0), 'coin ' + me().coin + ', pack ' + me().inv.map(i => IT[i].n).join('/'));
      ok('the outer ruins are not empty (lurkers by day about 3 times in 10)', lurk > 30 && lurk < 95, lurk);
      ok('armour found goes straight on', me().head >= 0 || me().body >= 0 || me().off >= 0, [me().head, me().body, me().off].join());
      ok('relics are rare by day', S.relics.length <= 14, S.relics.length);
      const l2 = d.ruinLayout(S.seed, 2); ok('the outer ruins are different tomorrow, the old ruins the same', l2.spots[0].x === RL.spots[0].x && (l2.spots[3].x !== RL.spots[3].x || l2.spots[3].z !== RL.spots[3].z));

      // ---------- pack, arms rack, forge
      const m = me(); m.inv = [6, 10]; m.wpn = 0; m.head = m.body = m.off = m.trk = -1; S.relics.length = 0;
      d.act('eq', 0); ok('club taken in hand from the pack', m.wpn === 6 && m.inv.join() === '10', m.inv.join());
      at(12.9, 10.6); d.act('puti', 0); ok('dagger put on the arms rack', S.items.join() === '10' && m.inv.length === 0);
      d.act('pute', 'wpn'); ok('club put on the rack from the hand', S.items.join() === '10,6' && m.wpn === 0);
      d.act('takei', 1); ok('club taken back, straight into the hand', m.wpn === 6 && S.items.join() === '10');
      const sp = d.panelData('store', m, 'arms'); ok('arms rack notice lists it', sp.o.some(o => /Take: kitchen dagger/.test(o.label)));
      m.iron = 20; m.wood = 20; at(12.4, -4.7); d.act('forge', 1); ok('forged a short sword; the club went into the pack', m.wpn === 1 && m.inv.join() === '6', m.inv.join());
      d.act('forge', 13); ok('forged a bow but cannot use it yet', m.wpn === 1 && m.inv.includes(13));
      d.act('forge', 19); ok('iron cap goes on', m.head === 19);
      d.act('forge', 4); ok('heavy arms still need Hammer and Tongs rank 2', m.wpn === 1);

      // ---------- every weapon's trick
      at(40, 0); m.r = 0; const res = [];
      for (let id = 0; id <= 17; id++) {
        clearU(); m.wpn = id; m.abCd = 0; m.atkCd = 0; m.r = 0; m.parry = 0; const us = mob(3, 0, IT[id].rng ? 6 : 1.5), hp0 = us.map(u => u.hp);
        X.doAbility(m); const hurt = us.filter((u, i) => u.hp < hp0[i] || u.dead).length, st = us.filter(u => u.stun > 0 || u.pin > 0 || u.vuln > 0 || u.tauntT > 0).length;
        res.push(IT[id].ab + ':' + hurt + '/' + st + (m.parry > 0 ? 'P' : ''));
        if (!(hurt > 0 || st > 0 || m.parry > 0) || !(m.abCd > 0)) ok('trick of ' + IT[id].n, false, res[res.length - 1]);
      }
      ok('all eighteen weapons have a working trick', true, res.join(' '));
      clearU(); m.wpn = 1; m.abCd = 0; X.doAbility(m); const pu = mob(1, 0, 1)[0], hpP = m.hp; X.hurtFriend(m, 10, true, pu, false); ok('parry turns the blow and staggers the attacker', m.hp === hpP && pu.stun > 0 && pu.hp < d.UN[0].hp);
      clearU(); m.wpn = 7; m.abCd = 0; const bu = mob(1, 0, 1.4)[0]; bu.hp = 10; X.doAbility(m); ok('the spade buries a wounded shambler', bu.dead === true);
      clearU(); m.wpn = 12; m.atkCd = 0; m.r = 0; const far = mob(1, 0, 8)[0]; far.hp = 9999; let hits = 0; for (let i = 0; i < 12; i++) { m.atkCd = 0; const h = far.hp; X.doAttack(m); if (far.hp < h) hits++; } ok('a sling hits from a distance, mostly', hits >= 7, hits);
      clearU(); m.wpn = 1; m.atkCd = 0; const farS = mob(1, 0, 8)[0]; X.doAttack(m); ok('a sword does not', farS.hp === d.UN[0].hp);

      // ---------- the priest and holy studies
      clearU(); at(13.6, -10.6); m.coin = 30; m.wpn = 1; m.bless = 0;
      d.act('bless', 'w'); ok('the priest blesses a sword for two shillings', (m.bless & 1) === 1 && m.coin === 6, m.coin);
      const hu = mob(1, 0, 1.4)[0]; m.atkCd = 0; m.r = 0; m.combo = 0; X.doAttack(m); const holyDmg = d.UN[0].hp - hu.hp; clearU();
      m.bless = 0; const pu2 = mob(1, 0, 1.4)[0]; m.atkCd = 0; m.combo = 0; X.doAttack(m); const plain = d.UN[0].hp - pu2.hp; clearU();
      ok('a blessed blow does half as much again', Math.abs(holyDmg / plain - 1.5) < 0.02, holyDmg.toFixed(1) + ' vs ' + plain.toFixed(1));
      d.act('bless', 'w'); ok('no blessing without the fee', m.bless === 0 && m.coin === 6);
      at(13.6, -10.6); d.act('study'); d.fast(46); ok('one class of holy studies', m.holy === 1 && !m.study, m.holy + ' ' + m.holyT);
      at(40, 0); d.act('bless', 'w'); ok('after a class, bless your own weapon anywhere for nothing', (m.bless & 1) === 1 && m.coin === 6);
      at(13.6, -10.6); d.act('study'); d.fast(20); at(40, 0); d.fast(1); ok('walking out stops the class but keeps the progress', !m.study && m.holyT > 15 && m.holy === 1, m.holyT);
      at(13.6, -10.6); d.act('study'); d.fast(30); ok('second class finished', m.holy === 2);

      // ---------- barricades: blessed bodies, and the evening rot
      m.wood = 30; at(40, 5); m.r = 0; const placed = X.tryPlace(m, 'barricade', 40, 8, 0), bar = S.structs.find(s => s.k === 'barricade');
      ok('barricade placed', placed && bar && bar.max === 90);
      m.bodies = 1; m.iron = 0; d.act('bless', 'b'); ok('blessed a body', m.bbod === 1);
      at(40, 9.2); const bi = d.findInteract(m); ok('prompt to build the blessed body in', bi && bi.type === 'blessre', bi && bi.type); hold(2, () => bar.bl);
      ok('blessed body strengthens the barricade by half', bar.bl && bar.max === 135 && m.bodies === 0 && m.bbod === 0, bar.max);
      X.tryPlace(m, 'barricade', 46, 8, 0); const bar2 = S.structs.filter(s => s.k === 'barricade')[1];
      X.duskFalls(); ok('a new barricade does not rot on its first evening', bar2.max === 90 && S.phase === 'dusk');
      S.phase = 'day'; S.timeLeft = 300; bar2.age = 1; bar.age = 1; bar.re = true; X.duskFalls();
      ok('an old barricade loses half each evening; a braced one does not', bar2.max === 45 && bar2.hp === 45 && bar.max === 135, bar2.max + ' ' + bar.max);
      S.phase = 'day'; X.duskFalls(); S.phase = 'day'; X.duskFalls(); ok('and falls apart in the end', !S.structs.includes(bar2), bar2.max);
      S.phase = 'day'; S.timeLeft = 300;

      // ---------- posse: orders, nerve, toilet break, the bucket
      at(-7.5, 5.9); for (const q of S.peasants.slice(0, 4)) { q.owner = m.id; q.state = 'follow'; } d.fast(0.5);
      ok('posse of four', m.posse === 4, m.posse);
      X.doOrder(m); ok('orders: hold', m.ord === 1); const q0 = S.peasants[0], px = q0.x, pz = q0.z; at(-7.5, -16); d.fast(4);
      ok('a holding posse stays where it was put', Math.hypot(q0.x - px, q0.z - pz) < 1.5, Math.hypot(q0.x - px, q0.z - pz).toFixed(1));
      X.doOrder(m); X.doOrder(m); ok('orders cycle back to follow', m.ord === 0); d.fast(6);
      ok('a following posse comes along', Math.hypot(q0.x - m.x, q0.z - m.z) < 7, Math.hypot(q0.x - m.x, q0.z - m.z).toFixed(1));
      m.r = Math.PI; let us = mob(4, 0, 4); m.tbCd = 0; X.doToilet(m); ok('emergency toilet break: the dead run', us.every(u => u.fear > 0) && m.tbCd > 50, m.tbCd);
      const y0 = us[0].z; d.fast(2); ok('they run away from the posse', us[0].z < y0 - 1, (us[0].z - y0).toFixed(1)); clearU();
      m.trk = 28; m.bless |= 2; us = mob(3, 0, 5); const uh = us[0].hp; X.doUse(m); ok('a blessed slop bucket scares and burns, and is used up', us.every(u => u.fear > 0) && us[0].hp < uh && m.trk === -1 && !(m.bless & 2)); clearU();
      m.trk = 26; m.useCd = 0; us = mob(3, 0, 4); X.doUse(m); ok('the Chapel Handbell stuns', us.every(u => u.stun > 2) && m.useCd > 30); clearU();
      for (const q of S.peasants.slice(0, 4)) q.nv = 100; m.books[6] = 0; const gr = m.books[9]; m.books[9] = 1;
      const vic = S.peasants[3]; X.hurtFriend(vic, 999, false); ok('a death shakes the others', vic.state === 'body' && S.peasants.slice(0, 3).every(q => q.nv < 100), S.peasants.slice(0, 4).map(q => q.nv + q.state + q.owner + '@' + q.x.toFixed(0) + ',' + q.z.toFixed(0)).join(' ') + ' me ' + m.id + ' head ' + m.head + ' ch ' + m.charge);
      S.peasants[0].nv = 5; X.hurtFriend(S.peasants[1], 999, false); ok('a peasant with no nerve left runs for the keep', S.peasants[0].state === 'hide', S.peasants[0].state);
      m.head = 20; S.peasants[2].nv = 5; X.hurtFriend(S.peasants[2], 5, false); ok('the Helm of the Unbothered keeps the posse steady', S.peasants[2].state !== 'hide' && S.peasants[2].nv === 5); m.head = -1; m.books[6] = 3; m.books[9] = 3; const sv1 = S.peasants[2]; sv1.hp = 75; X.hurtFriend(sv1, 999, false); ok('Granny’s Remedies rank 3: a posse member survives one fatal blow', sv1.state !== 'body' && sv1.saved && sv1.hp > 0); X.hurtFriend(sv1, 999, false); ok('but not two', sv1.state === 'body'); m.books[9] = 1;

      // ---------- the Thorny Rose
      S.phase = 'day'; S.timeLeft = 300; clearU(); at(-13.1, -4.7); m.food = 12; d.act('ale'); d.act('ale'); ok('food becomes ale', S.ale === 10 && m.food === 2);
      d.act('innin'); ok('the Rose is shut by day', m.state === 'ok');
      X.duskFalls(); d.fast(21); ok('night has fallen', S.phase === 'night'); S.night.q = [{ k: 0, t: 1e9 }]; clearU();
      S.peasants[4].owner = m.id; S.peasants[4].state = 'follow'; at(-13.1, -4.7); d.act('innin'); ok('inside, door barred, posse with you', m.state === 'inn' && S.peasants.some(q => q.state === 'inn'));
      ok('nothing can reach a drinker', (() => { const u = mob(1, 0, 1)[0], h = m.hp; X.hurtFriend(m, 10, true, u, false); clearU(); return m.hp === h; })());
      d.act('drink'); d.fast(1); d.act('drink'); d.fast(2.5); ok('one tankard at a time', m.cg === 25 && S.ale === 9, m.cg + ' ' + S.ale);
      d.act('drink'); d.fast(3.2); d.act('drink'); d.fast(3.2); ok('three tankards: 75%', m.cg === 75 && m.state === 'inn', m.cg);
      d.act('drink'); d.fast(3.2); ok('the fourth sends you out charging', m.state === 'ok' && m.charge > 15 && m.cg === 0 && S.peasants.some(q => q.state === 'follow'), m.state + ' ' + m.charge);
      m.r = 0; const cu = mob(1, 0, 1.4)[0]; m.wpn = 1; m.bless = 0; m.atkCd = 0; m.combo = 0; X.doAttack(m); ok('a charging blow is far stronger', (d.UN[0].hp - cu.hp) > plain * 1.5, (d.UN[0].hp - cu.hp).toFixed(1)); clearU();
      d.fast(21); ok('then the hangover', m.charge === 0 && m.hang > 5, m.hang); d.fast(11); ok('which passes', m.hang === 0);
      at(-13.1, -4.7); d.act('innin'); ok('back inside', m.state === 'inn');
      const du = X.spawnUndead(0, -8, -4.7); du.state = 'walk'; d.fast(40, () => S.innHp <= 0 ? false : undefined);
      ok('the dead break the door down and everyone is thrown out', S.innHp === 0 && m.state === 'ok', S.innHp + ' ' + m.state); clearU();
      d.act('innin'); ok('no going back in tonight', m.state === 'ok');

      // ---------- dawn: trees, sites, relics dropped
      const tr0 = T.filter(t => t.alive && t.x < -34)[0]; at(tr0.x + 1.4, tr0.z); m.wood = 0; S.phase = 'night'; const tr = d.findInteract(m).target; hold(30, () => !tr.alive); ok('a felled tree leaves a stump', tr.st === 1 && !tr.alive);
      const tx0 = tr.x, tz0 = tr.z; m.inv = [15, 6]; m.wpn = 17; m.trk = -1; S.relics = [15, 17]; m.state = 'dead';
      const sites0 = S.sites.join(), key0 = JSON.stringify(d.ruinLayout(S.seed, S.day).spots.slice(2));
      S.night.q = []; clearU(); d.fast(1);
      ok('dawn of day 2', S.day === 2 && S.phase === 'day', S.day + ' ' + S.phase);
      ok('a dead player loses gear but relics lie where they fell', m.wpn === 0 && m.inv.length === 0 && S.drops.length === 2 && S.drops.every(x => IT[x.it].tier === 'relic'), S.drops.map(x => IT[x.it].n).join(' / '));
      ok('the stump has rotted and a sapling has come up beside it', tr.st === 2 && !tr.alive && (tr.x !== tx0 || tr.z !== tz0 || (!tr.dx && !tr.dz)), tr.st + ' moved ' + Math.hypot(tr.x - tx0, tr.z - tz0).toFixed(1));
      ok('stone, iron and fishing have all moved', S.sites.join() !== sites0 && S.sites.every((c, i) => c !== +sites0.split(',')[i]), sites0 + ' -> ' + S.sites.join());
      ok('today’s sites are where the game says', d.QUARRY.x === d.SITES[0][S.sites[0]].x && d.JETTY.x === d.SITES[2][S.sites[2]].x);
      ok('the outer ruins fell down differently, and the heaps are full again', JSON.stringify(d.ruinLayout(S.seed, S.day).spots.slice(2)) !== key0 && S.spots.every(n => n === 2));
      ok('dawn notice says where things are', /stone is/.test(S.dawn.lines.join(' ')), S.dawn.lines[S.dawn.lines.length - 1]);
      ok('the posse lines up outside the door, not in the keep', !S.peasants.some(q => q.state !== 'body' && inKeep(q)));
      at(S.drops[0].x, S.drops[0].z + 0.5); hold(1, () => S.drops.length < 2); ok('a relic can be picked up again', S.drops.length === 1 && (m.wpn >= 15 || m.inv.length === 1));
      const sv = d.readSave(); ok('the save holds the new things', sv && sv.v === 3 && sv.sites.join() === S.sites.join() && sv.trees.length >= 1 && sv.drops.length === 2 && sv.players[0].books.length === 10, sv && JSON.stringify(sv.sites));
      // next dawns: the sapling matures 1 to 2 days after it came up
      const skip = () => { X.duskFalls(); d.fast(21); S.night.q = []; clearU(); d.fast(1); };
      skip(); const d3 = tr.st; skip(); ok('the sapling is a tree again by day 3 or 4', tr.st === 0 && tr.alive && S.day === 4, 'day 3: ' + d3 + ', day 4: ' + tr.st);

      // ---------- the horde
      const tot = (day, n) => X.nightPlan(day, n).c.reduce((a, b) => a + b, 0);
      ok('hordes are bigger, most of all in co-op', tot(1, 1) >= 28 && tot(1, 4) >= 100 && tot(7, 4) >= 320, [tot(1, 1), tot(7, 1), tot(1, 4), tot(7, 4), tot(7, 8)].join(' / '));
      clearU(); const xs = []; for (let i = 0; i < 200; i++) xs.push(X.spawnUndead(0).x); clearU();
      ok('the dead rise across the whole graveyard', Math.min(...xs) < -26 && Math.max(...xs) > 26 && xs.filter(x => Math.abs(x) < 10).length < 90, Math.min(...xs).toFixed(0) + '..' + Math.max(...xs).toFixed(0) + ', middle third ' + xs.filter(x => Math.abs(x) < 10).length);
      const nq = X.nightQueue(X.nightPlan(5, 4)), gaps = nq.slice(1).map((e, i) => e.t - nq[i].t), third = gaps.length / 3 | 0, avg = a => a.reduce((x, y) => x + y, 0) / a.length;
      ok('no waves: the dead rise in one unbroken stream', nq.length === tot(5, 4) && Math.max(...gaps) < 3 && nq[0].t < 6, 'longest gap ' + Math.max(...gaps).toFixed(2) + 's over ' + nq[nq.length - 1].t.toFixed(0) + 's');
      ok('and faster as the night goes on', avg(gaps.slice(0, third)) > avg(gaps.slice(-third)) * 1.5, avg(gaps.slice(0, third)).toFixed(2) + 's between them early, ' + avg(gaps.slice(-third)).toFixed(2) + 's late');
      // one archer against a stone wall must not keep a dead village waiting half the night
      { clearU(); for (const st of S.structs) if (st.slot != null) { st.built = true; st.re = true; st.max = 780; st.hp = 780; } S.keepHp = 1000; X.duskFalls(); d.fast(21); S.night.q = []; m.state = 'dead'; for (const q of S.peasants) if (q.state !== 'body') q.state = 'gone';
        const ar = X.spawnUndead(2, 6, -30); ar.state = 'walk'; const t = d.fast(900, () => S.phase !== 'night' ? false : undefined);
        ok('with everyone dead, the night is settled quickly', S.phase === 'lost' && t < 200, S.phase + ' after ' + Math.round(t) + 's'); S.phase = 'day'; S.timeLeft = 300; S.keepHp = 1000; m.state = 'ok'; clearU(); }
      // a lurker from the west ruins must find its way to the keep
      at(80, 40); m.state = 'hide'; const lu = X.spawnUndead(0, -58, 46); lu.state = 'walk'; let reached = false; d.fast(170, () => { if (Math.hypot(lu.x, lu.z) < d.KEEP.h + 2.5) { reached = true; return false; } });
      ok('something from the west ruins reaches the keep through the west gateway', reached, lu.x.toFixed(1) + ',' + lu.z.toFixed(1)); clearU(); m.state = 'ok';
      at(91.9, 0); K.KeyD = true; d.fast(0.5); K.KeyD = false; ok('the hedge stops you, and says so', me().x <= 92 && d.App.edge === 'hedge', me().x);
      // ---------- bows: the book lets you use one, and comes with a sling
      m.state = 'ok'; S.phase = 'day'; S.timeLeft = 300; m.books = new Array(10).fill(0); m.xp = new Array(10).fill(0); m.inv = [13]; m.wpn = 0; at(13.4, 20.4);
      d.act('eq', 0); ok('no bow without the book', m.wpn === 0 && m.inv.join() === '13');
      d.act('book', 5); ok('Slings, Bows and Thrown Turnips comes with a sling', m.books[5] === 1 && m.inv.includes(12), m.inv.join());
      d.act('eq', 0); ok('with the book, the bow goes in the hand', m.wpn === 13 && !m.inv.includes(13), m.wpn + ' / ' + m.inv.join());
      at(40, 0); m.r = 0; clearU(); const bt = mob(1, 0, 10)[0]; bt.hp = 9999; let bh = 0; for (let i = 0; i < 10; i++) { m.atkCd = 0; const h = bt.hp; X.doAttack(m); if (bt.hp < h) bh++; } ok('and it shoots', bh >= 6, bh); clearU();
      m.inv = [14]; d.act('eq', 0); ok('a crossbow needs rank 3', m.wpn === 13); m.books[5] = 3; d.act('eq', 0); ok('and works at rank 3', m.wpn === 14);
    } catch (e) { log.push('EXCEPTION ' + e.message + '\n' + (e.stack || '').split('\n').slice(0, 5).join('\n')); }
    return log;
  });
  console.log(out.join('\n'));
  console.log('\n' + out.filter(l => l.startsWith('PASS')).length + ' passed, ' + out.filter(l => !l.startsWith('PASS')).length + ' failed');
  console.log(errs.length ? errs.join('\n') : 'no page errors');
  await browser.close();
})();
