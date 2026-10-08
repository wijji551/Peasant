// (Ported to Build 3.) Exercises every Build 2 system across a whole week, solo. The bot is moved straight to places (this tests the rules, not walking).
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
    const d = window.__dtv, S = d.S, K = d.keys, T = d.trees, log = [], me = () => d.me();
    const ok = (name, cond, extra) => log.push((cond ? 'PASS ' : 'FAIL ') + name + (extra !== undefined ? '  [' + extra + ']' : ''));
    const at = (x, z) => { const m = me(); m.x = x; m.z = z; };
    const hold = (sec, stop) => { K.KeyE = true; d.fast(sec, () => stop && stop() ? false : undefined); K.KeyE = false; d.fast(0.1); };
    const key = code => { window.dispatchEvent(new KeyboardEvent('keydown', { code })); K[code] = false; };
    const wood = n => { for (let g = 0; g < 40 && me().wood < n; g++) { const t = T.filter(t => t.alive && t.x < -34).sort((a, b) => a.x * a.x + a.z * a.z - b.x * b.x - b.z * b.z)[0]; at(t.x + 1.5, t.z); hold(20, () => me().wood >= n || !t.alive); } };
    const stone = n => { at(d.QUARRY.x - d.QUARRY.hw - 1.2, d.QUARRY.z); hold(60, () => me().stone >= n); }, iron = n => { at(d.MINE.x - d.MINE.dir * 0.8, d.MINE.z); hold(70, () => me().iron >= n); }, food = n => { at(-58, 30); hold(60, () => me().food >= n); };
    const fight = (opts) => {                    // night: chase the nearest undead and hit it; eat when hurt
      opts = opts || {}; let t = 0;
      d.fast(900, () => {
        const m = me(); if (S.phase !== 'night') return false; t += 1 / 30;
        if (opts.each) opts.each(t);
        if (m.state !== 'ok') return;
        if (m.hp < 55 && m.food > 0) key('KeyF');
        K.Space = true;
        let bu = null, bd = 1e9; for (const u of S.undead) { if (u.state === 'rise' || (u.z < -40 && u.k !== 3)) continue; const dd = Math.hypot(u.x, u.z) + Math.hypot(u.x - m.x, u.z - m.z) * 0.3 - (u.k === 3 && opts.boss ? 60 : 0) - (u.k === 2 ? 8 : 0); if (dd < bd) { bd = dd; bu = u; } }
        const tx = bu ? bu.x : 0, tz = bu ? bu.z : -20, dx = tx - m.x, dz = tz - m.z, far = Math.hypot(dx, dz) > 1.7;
        if (bu && opts.teleport && Math.hypot(dx, dz) > 6) { m.x = bu.x + 1.6; m.z = bu.z + 1.6; return; }
        K.KeyD = far && dx > 0.3; K.KeyA = far && dx < -0.3; K.KeyS = far && dz > 0.3; K.KeyW = far && dz < -0.3;
      });
      K.Space = K.KeyD = K.KeyA = K.KeyS = K.KeyW = false; return t;
    };
    const ready = () => { me().ready = true; d.fast(0.2); d.fast(21, () => S.phase !== 'dusk' ? (S.phase === 'day' ? undefined : false) : undefined); };

    // ---------- day 1
    ok('starts on day 1 with a save', S.day === 1 && S.phase === 'day' && !!d.readSave());
    at(13.4, 20.4); d.act('book', 0); ok('took the Almanac from the library', me().books[0] === 1);
    d.act('book', 1); ok('cannot take a second book yet', me().books[1] === 0);
    for (let i = 0; i < 12 && me().posse < 4; i++) { const q = S.peasants.find(q => q.state === 'idle'); if (!q) break; at(q.x + 1, q.z); K.KeyE = true; d.fast(0.4); K.KeyE = false; d.fast(0.1); }
    ok('rallied four neighbours', me().posse === 4, me().posse);
    wood(20); ok('chopped 20 wood (the carry limit)', me().wood === 20, me().wood);
    const xp0 = me().xp[0]; ok('chopping earns Almanac experience', xp0 > 0, Math.floor(xp0));
    for (const s of S.structs.filter(s => s.slot != null)) { wood(20); at(s.x, s.z - 1.8); hold(3, () => s.built); }
    ok('built the whole north side', S.structs.filter(s => s.slot != null).every(s => s.built));
    ok('Almanac reached rank 2 by gathering', me().books[0] >= 2, 'rank ' + me().books[0] + ' xp ' + Math.floor(me().xp[0]));
    at(13.4, 20.4); d.act('book', 2); ok('rank 2 unlocks a second book (Barricades)', me().books[2] === 1);
    wood(30); ok('rank 2 Almanac carries 30', me().wood === 30, me().wood);
    stone(12); ok('quarried stone', me().stone >= 10, me().stone);
    const w0 = S.structs.find(s => s.slot === 2); at(w0.x, w0.z + 1.8); hold(3, () => w0.re);
    ok('faced a wall with stone: three times the strength', w0.re && w0.max === 780 && w0.hp === 780, w0.max);
    iron(20); ok('mined iron', me().iron >= 20, me().iron);
    at(12.4, -4.7); d.act('forge', 2); ok('forged a spear at the smithy', me().wpn === 2 && me().iron === 16, 'iron ' + me().iron);
    d.act('forge', 5); ok('heavy arms need the smithing book', me().wpn === 2);
    d.act('forge', 19); ok('forged an iron cap', me().head === 19);
    d.act('armp'); ok('armed one of the posse', S.peasants.filter(q => q.armed).length === 1);
    const gate = S.structs.find(s => s.k === 'gate'); iron(8); at(gate.x, gate.z + 1.8); hold(3, () => gate.re); ok('banded the gate with iron', gate.re && gate.max === 440);
    food(12); ok('foraged food at the farms', me().food >= 10, me().food);
    at(d.JETTY.x, d.JETTY.z - 0.6); K.KeyE = true; let bites = 0; const f0 = me().food;
    d.fast(40, () => { if (me().bite > 0) { bites++; key('Space'); } if (me().food >= f0 + 6) return false; }); K.KeyE = false;
    ok('fishing: bites come, and Space lands the fish', me().food >= f0 + 3, 'food ' + f0 + ' -> ' + me().food);
    at(-17.6, 17.4); const f1 = me().food; d.act('recruit'); ok('recruited a fifth peasant in the slum for 5 food', me().food === f1 - 5 && S.peasants.filter(q => q.owner === me().id).length === 5);
    d.fast(0.2); d.act('recruit'); ok('posse is then full', S.peasants.filter(q => q.owner === me().id).length === 5);
    wood(10); at(0, 19.7); const c0 = me().coin, wd = me().wood; d.act('sell', 'wood'); ok('market: sold 5 wood for 5d', me().coin === c0 + 5 && me().wood === wd - 5);
    d.act('buy', 'stone'); ok('market: bought stone at 2d each', me().coin === c0 + 5 - 4 && me().stone >= 2, 'coin ' + me().coin);
    at(12.9, 10.6); const wd2 = me().wood; d.act('put', 'wood'); ok('storehouse: put wood in', me().wood === 0 && S.store.wood === wd2); d.act('take', 'wood'); ok('storehouse: took 5 out', me().wood === 5 && S.store.wood === wd2 - 5);
    wood(10); at(3, -32); me().r = Math.PI; d.fast(0.1); key('Digit1'); key('KeyE'); key('Escape');
    ok('placed a barricade at the cheaper Barricades price (4 wood)', S.structs.some(s => s.k === 'barricade') && me().wood === 6, me().wood);
    me().hp = 60; const fd = me().food; key('KeyF'); ok('F eats: +20 health for 1 food', Math.round(me().hp) === 80 && me().food === fd - 1, me().hp);
    // ---------- night 1
    at(0, -19); ready(); ok('ready starts dusk then night', S.phase === 'night', S.phase);
    const plan = S.night.c.join('/');
    let t = fight(); ok('night 1 won, on to day 2', S.phase === 'day' && S.day === 2, `${Math.round(t)}s, waves ${plan}, phase ${S.phase}`);
    ok('dawn notice has lines, hat was passed', S.dawn.lines.length >= 2 && me().coin > c0, S.dawn.lines.join(' | '));
    ok('morning save is day 2', d.readSave().day === 2);
    ok('back at the cottage', Math.abs(me().x + 7.5) < 0.1);
    const fallen1 = S.peasants.filter(q => q.state === 'body').length; log.push('     night 1: ' + fallen1 + ' of the posse fell; player hp ' + Math.round(me().hp));
    // ---------- day 2: repairs, bodies, and hiding at night
    const hurt = S.structs.find(s => s.built && s.hp < s.max);
    if (hurt) { wood(10); at(hurt.x, hurt.z + (hurt.slot != null ? 1.8 : 1.2)); hold(3, () => hurt.hp >= hurt.max); ok('repaired a damaged defence', hurt.hp >= hurt.max); } else log.push('     (nothing was damaged to repair)');
    if (!fallen1) { const q = S.peasants.find(q => q.owner === me().id); q.hp = 0; q.state = 'body'; q.owner = 0; }
    const body = S.peasants.find(q => q.state === 'body'); at(body.x + 0.8, body.z); hold(1.5, () => me().bodies > 0); ok('picked up a body', me().bodies >= 1);
    at(-8, -30); me().r = Math.PI; d.fast(0.1); key('Digit4'); const sel = d.App.buildSel; key('KeyE'); key('Escape'); ok('built a decoy outside the wall', sel === 'decoy' && S.structs.some(s => s.k === 'decoy') && me().bodies === 0);
    me().bodies = 1; at(0, 5.5); me().r = 0; d.fast(0.1); key('Digit4'); key('KeyE'); key('Escape'); ok('a decoy cannot go inside the village', S.structs.filter(s => s.k === 'decoy').length === 1); me().bodies = 0;
    ready(); at(-7.5, 6.7); hold(2, () => me().state === 'hide'); ok('hid in the cottage at night', me().state === 'hide' && me().coward);
    const posseBefore = S.peasants.filter(q => q.owner === me().id).length;
    d.fast(900, () => { if (S.phase !== 'night') return false; for (const u of S.undead) if (u.state !== 'rise' && Math.random() < 0.02) u.hp = 0, u.dead = true, S.night.kills++; });   // the night passes without us
    ok('night 2 passed while hiding', S.day === 3 && S.phase === 'day', S.phase + ' day ' + S.day);
    ok('coward next day: no hat money line, posse one smaller', me().coward && me().state === 'ok' && S.peasants.filter(q => q.owner === me().id).length === Math.min(posseBefore, 4), S.dawn.lines.join(' | '));
    at(-17.6, 17.4); me().food = 20; { const q = S.peasants.find(q => q.owner === me().id); q.owner = 0; q.state = 'idle'; q.x = q.hx; q.z = q.hz; } d.fast(0.1);
    ok('cowards pay double in the slum', d.panelData('slum', me()).o[0].sub.includes('10 food'), d.panelData('slum', me()).o[0].sub);
    // ---------- night 3: die, and come back as a relative
    S.keepHp = 1000; me().wood = 9; me().iron = 3; ready(); ok('cowardice ends at dusk', !me().coward);
    d.fast(40); const u = S.undead.filter(u => u.state !== 'rise' && u.z < -30).pop() || S.undead.find(u => u.state !== 'rise'); at(u.x, u.z - 1.2); for (const q of S.peasants) if (q.owner === me().id) { q.owner = 0; q.state = 'hide'; } me().hp = 1; d.fast(9, () => me().state === 'ok' ? undefined : false); ok('knocked down', me().state === 'down', me().state);
    d.fast(16); ok('dead after 15 seconds with nobody to help', me().state === 'dead');
    d.fast(900, () => { if (S.phase !== 'night') return false; for (const u of S.undead) if (u.state !== 'rise' && Math.random() < 0.03) u.hp = 0, u.dead = true, S.night.kills++; });
    ok('a relative arrives at dawn with the books but not the gear', S.day === 4 && me().dn !== 'Matt' && me().state === 'ok' && me().wpn === 0 && me().head === -1 && me().wood === 0 && me().books[0] >= 2 && me().hp === 100, me().dn + ' | ' + S.dawn.lines.join(' | '));
    // ---------- days 4 to 7: archers and the Steward
    for (const s of S.structs) if (s.slot != null) { s.built = true; s.hp = s.max; }
    let sawArcher = false, sawBoss = false, raised = 0, n0;
    for (let day = 4; day <= 7; day++) {
      me().food = 20; me().hp = 100; me().wpn = 2; me().head = 19; me().body = 22; me().off = 25; S.keepHp = 1000; for (const q of S.peasants) if (q.state === 'idle' && S.peasants.filter(o => o.owner === me().id).length < 5) { q.owner = me().id; q.state = 'follow'; }
      at(0, -19); ready();
      const pl = S.night.c.join('/');
      const tt = fight({ boss: day === 7, teleport: true, each: () => { if (S.undead.some(u => u.k === 2)) sawArcher = true; if (S.boss) { sawBoss = true; } if (me().hp < 30) me().hp = 60; if (S.keepHp < 300) S.keepHp = 600; } });
      log.push(`     night ${day}: ${Math.round(tt)}s, waves ${pl}, kills ${S.stats.kills}, phase ${S.phase}, day ${S.day}, bodies ${S.peasants.filter(q => q.state === 'body').length}`);
      if (S.phase !== 'day' && S.phase !== 'won') break;
    }
    ok('skeleton archers appeared from night 5', sawArcher);
    log.push('     the last dawn: ' + S.dawn.lines.join(' | '));
    ok('the Steward came down on night 7', sawBoss);
    ok('the week is won after night 7', S.phase === 'won', S.phase + ' day ' + S.day);
    ok('the save is cleared after winning', !d.readSave());
    return log;
  });
  console.log(out.join('\n'));
  await sleep(9000);
  console.log('end notice:', await page.evaluate(() => document.getElementById('end').hidden ? 'hidden' : document.getElementById('endTitle').textContent + ' | ' + document.getElementById('endStats').textContent));
  await page.screenshot({ path: __dirname + '/shots/b2-won.png' });
  console.log(errs.length ? errs.join('\n') : 'no errors');
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
