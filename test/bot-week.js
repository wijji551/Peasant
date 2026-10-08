// A time-limited bot plays the whole week solo to see how hard it is. Travel costs walking time; fighting uses real movement.
const { chromium } = require('./_playwright');
const URL = process.env.DTV_URL || 'http://127.0.0.1:8765/defend-the-village.html';
const sleep = ms => new Promise(r => setTimeout(r, ms));
const mode = process.argv[2] || 'steady';
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const page = await (await browser.newContext({ viewport: { width: 700, height: 460 } })).newPage(); const errs = [];
  page.on('pageerror', e => errs.push('PAGEERROR: ' + e.message + '\n' + (e.stack || '').split('\n').slice(0, 6).join('\n')));
  await page.goto(URL); await sleep(1000);
  await page.evaluate(() => localStorage.removeItem('dtv-save'));
  await page.fill('#name', 'Bot'); await page.click('#btnSolo'); await sleep(4000);
  const out = await page.evaluate((mode) => {
    const d = window.__dtv, S = d.S, K = d.keys, T = d.trees, log = [], me = () => d.me();
    const key = code => { window.dispatchEvent(new KeyboardEvent('keydown', { code })); K[code] = false; };
    const day = () => S.phase === 'day' && S.timeLeft > 14;
    const go = (x, z) => { const m = me(), dist = Math.hypot(x - m.x, z - m.z); d.fast(dist / 7 * 1.25); m.x = x; m.z = z; d.fast(0.4); };   // walking time, with a quarter extra for detours
    const hold = (sec, stop) => { K.KeyE = true; d.fast(sec, () => (stop && stop()) || !day() ? false : undefined); K.KeyE = false; d.fast(0.1); };
    const capN = () => me().books[0] >= 2 ? 30 : 20;
    const wood = n => { n = Math.min(n, capN()); for (let g = 0; g < 30 && me().wood < n && day(); g++) { const m = me(), ref = m.x < -30 ? m : { x: -36, z: -6 }; const t = T.filter(t => t.alive && t.x < -33 && t.x > -60).sort((a, b) => Math.hypot(a.x - ref.x, a.z - ref.z) - Math.hypot(b.x - ref.x, b.z - ref.z))[0]; go(t.x + 1.5, t.z); hold(25, () => me().wood >= n || !t.alive); } };
    const get = (res, n) => { n = Math.min(n, capN()); if (me()[res] >= n || !day()) return; if (res === 'wood') return wood(n); const at = res === 'stone' ? [d.QUARRY.x - d.QUARRY.hw - 1.2, d.QUARRY.z] : res === 'iron' ? [d.MINE.x - d.MINE.dir * 0.8, d.MINE.z] : [-56, 30]; go(at[0], at[1]); hold(120, () => me()[res] >= n); };
    const act = (st, a, arg) => { const p = { smithy: [12.4, -4.7], library: [13.4, 20.4], slum: [-17.6, 17.4], market: [0, 19.7] }[st]; go(p[0], p[1]); d.act(a, arg); d.fast(0.2); };
    const fight = () => {
      let t = 0, minHp = 100;
      d.fast(900, () => {
        const m = me(); if (S.phase !== 'night') return false; t += 1 / 30; minHp = Math.min(minHp, m.state === 'ok' ? m.hp : 0);
        if (m.state !== 'ok') return;
        if (m.hp < 55 && m.food > 0) key('KeyF');
        K.Space = true; if (mode !== 'walls' && m.abCd <= 0 && S.undead.some(u => u.state !== 'rise' && Math.hypot(u.x - m.x, u.z - m.z) < 2.4 && !d.wallBetween(m.x, m.z, u.x, u.z))) key('ShiftLeft');
        let bu = null, bd = 1e9; for (const u of S.undead) { if (u.state === 'rise' || (u.z < -34 && u.k !== 3)) continue; const dd = Math.hypot(u.x, u.z) + Math.hypot(u.x - m.x, u.z - m.z) * 0.3 - (u.k === 2 ? 6 : 0) - (u.k === 3 ? 10 : 0); if (dd < bd) { bd = dd; bu = u; } }
        let tx = bu ? bu.x : 0, tz = bu ? bu.z : -19;
        if (bu && d.wallBetween(m.x, m.z, bu.x, bu.z)) { const out = m.z > -22; if (Math.abs(m.x) > 1.6) { tx = 0; tz = out ? -20.4 : -24; } else { tx = 0; tz = out ? -25 : -19; } }   // go round by the gate
        const dx = tx - m.x, dz = tz - m.z, far = Math.hypot(dx, dz) > (bu && tx === bu.x ? 1.7 : 0.5);
        K.KeyD = far && dx > 0.3; K.KeyA = far && dx < -0.3; K.KeyS = far && dz > 0.3; K.KeyW = far && dz < -0.3;
      });
      K.Space = K.KeyD = K.KeyA = K.KeyS = K.KeyW = false; return { t, minHp };
    };
    const posse = () => S.peasants.filter(q => q.owner === me().id && q.state !== 'body').length;
    for (let n = 1; n <= 7 && S.phase === 'day'; n++) {
      const m = me(); let did = [];
      if (n === 1) { act('library', 'book', 0); }
      if (m.books.filter(r => r).length < 3 && m.books[0] >= 2 && !m.books[2]) act('library', 'book', 2);
      if (m.books.filter(r => r).length < 3 && m.books[2] >= 2 && !m.books[3]) act('library', 'book', 3);
      for (let i = 0; i < 12 && posse() < S.pm && day(); i++) { const q = S.peasants.find(q => q.state === 'idle'); if (!q) break; go(q.x + 1, q.z); K.KeyE = true; d.fast(0.45); K.KeyE = false; d.fast(0.1); }
      // 1. the north side: build what is missing, repair what is hurt
      const slots = () => S.structs.filter(s => s.slot != null).sort((a, b) => Math.abs(a.x) - Math.abs(b.x));
      for (const s of slots()) { if (!day()) break; if (!s.built) { wood(s.k === 'gate' ? 20 : 15); if (me().wood >= (me().books[2] ? 12 : 15)) { go(s.x, s.z + 1.8); hold(3, () => s.built); did.push('built'); } } else if (s.hp < s.max - 1) { wood(8); go(s.x, s.z + 1.8); hold(3, () => s.hp >= s.max); did.push('repaired'); } }
      if (mode !== 'walls') {
        // 2. food, and the slum if the posse is short
        if (n >= 2 && day()) { get('food', 10); did.push('food ' + me().food); while (posse() < S.pm && me().food >= 5 && day()) { act('slum', 'recruit'); did.push('recruit'); } if (me().food < 6) get('food', 8); }
        // 3. iron for arms, one step a day
        const want = [null, null, ['forge', 2, { iron: 4, wood: 4 }], ['forge', 19, { iron: 5 }], ['forge', 22, { iron: 10 }], ['forge', 25, { iron: 4, wood: 4 }], ['armp', undefined, { iron: 9, wood: 6 }], ['armp', undefined, { iron: 9, wood: 6 }]][n];
        if (want && day()) { get('iron', want[2].iron); if (want[2].wood) get('wood', want[2].wood); if (day()) { act('smithy', want[0], want[1]); if (want[0] === 'armp') { d.act('armp'); d.act('armp'); } did.push(want[0] + (want[1] === undefined ? '' : want[1])); } }
        // 4. stone facing while time lasts, gate bands on day 4
        for (const s of slots()) { if (n < 3 || !day() || S.timeLeft < 70) break; if (s.built && !s.re && s.k === 'wall') { get('stone', 10); if (me().stone >= 10 && day()) { go(s.x, s.z + 1.8); hold(3, () => s.re); did.push('faced'); } } }
      }
      const tUsed = Math.round(360 - S.timeLeft); me().ready = true; d.fast(0.3); d.fast(21, () => S.phase === 'dusk');
      if (S.phase !== 'night') { log.push('day ' + n + ': did not reach night, phase ' + S.phase); break; }
      const m2 = me(); m2.x = 0; m2.z = -19;
      const plan = S.night.c.join('/') + ' over ' + S.night.dur + 's', p0 = posse(), k0 = S.stats.kills, keep0 = S.keepHp;
      const r = fight();
      log.push(`night ${n}: ${S.phase === 'day' || S.phase === 'won' ? 'held' : S.phase.toUpperCase()} in ${Math.round(r.t)}s | horde ${plan} | day took ${tUsed}s: ${did.join(', ') || '-'} | posse ${p0}->${posse()} | player low ${Math.round(r.minHp)} ${me().state === 'ok' ? '' : '(' + me().state + ')'} food ${me().food} | keep ${Math.round(keep0)}->${Math.round(S.keepHp)} | north ${S.structs.filter(s => s.slot != null).map(s => s.built ? (s.re ? 'S' : 'w') : '_').join('')} | ${me().dn}, wpn ${me().wpn} armour ${[me().head, me().body, me().off].join('/')} books ${me().books.join('')}`);
      if (S.phase !== 'day') break;
    }
    if (S.phase === 'night') { const st = {}; for (const u of S.undead) { const k = u.k + ':' + u.state + '@' + Math.round(u.x) + ',' + Math.round(u.z) + (u.march ? 'M' : '') + ' hp' + Math.round(u.hp); st[k] = (st[k] || 0) + 1; } log.push('STUCK NIGHT: undead ' + S.undead.length + ' q ' + S.night.q.length + ' graves ' + S.graves.length + ' boss ' + !!S.boss + ' :: ' + Object.entries(st).slice(0, 12).map(e => e[0] + ' x' + e[1]).join(' | ') + ' :: structs ' + S.structs.map(s => s.k[0] + (s.built ? Math.round(s.hp) : '_') + '@' + Math.round(s.x) + ',' + Math.round(s.z)).join(' ')); }
    log.push('end: ' + S.phase + ' day ' + S.day + ', kills ' + S.stats.kills + ', peasants lost ' + S.stats.lost);
    return log;
  }, mode);
  console.log(out.join('\n')); console.log(errs.length ? errs.join('\n') : 'no errors');
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
