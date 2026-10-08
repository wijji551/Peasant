// Two browser tabs on one machine: one hosts, one joins (same-computer test mode), then they play together.
const { chromium } = require('./_playwright');
const sleep = ms => new Promise(r => setTimeout(r, ms));
const URL = (process.env.DTV_URL || 'http://127.0.0.1:8765/defend-the-village.html') + '#local';
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const ctx = await browser.newContext({ viewport: { width: 640, height: 420 } });
  const errs = [];
  const open = async tag => { const p = await ctx.newPage(); p.on('pageerror', e => errs.push(tag + ' PAGEERROR: ' + e.message + '\n' + e.stack)); p.on('console', m => { if (m.type() === 'error' && !/ERR_TUNNEL|Failed to load resource/.test(m.text())) errs.push(tag + ': ' + m.text()); }); await p.goto(URL); await sleep(900); return p; };
  const ok = (name, cond, extra) => console.log((cond ? 'PASS ' : 'FAIL ') + name + (extra ? '  [' + extra + ']' : ''));
  const H = await open('host'), C = await open('client');
  const fps = await H.evaluate(() => new Promise(r => { let n = 0; const t0 = performance.now(); (function f() { n++; if (performance.now() - t0 > 2000) r((n / 2).toFixed(1)); else requestAnimationFrame(f); })(); }));
  console.log('headless frame rate (software drawing):', fps, 'fps');
  await H.fill('#name', 'Matt'); await H.click('#btnHost'); await sleep(800);
  const code = await H.textContent('#lobbyCode');
  ok('host gets a five-letter code', /^[A-Z]{5}$/.test(code), code);
  // a wrong code is refused
  await C.fill('#name', 'Friend'); await C.fill('#code', code === 'ZZZZZ' ? 'YYYYY' : 'ZZZZZ'); await C.click('#btnJoin'); await sleep(2600);
  ok('wrong code shows a message', /No village/.test(await C.textContent('#status')), await C.textContent('#status'));
  await C.click('.sw:nth-child(2)'); await C.fill('#code', code.toLowerCase()); await C.click('#btnJoin'); await sleep(1800);
  const hl = await H.textContent('#lobbyList'), cl = await C.textContent('#lobbyList');
  ok('both lobbies list both players', /Matt/.test(hl) && /Friend/.test(hl) && /Matt/.test(cl) && /Friend/.test(cl), cl);
  ok('client cannot start', await C.isHidden('#btnStart'));
  await H.click('#btnStart'); await sleep(2500);
  const st = () => Promise.all([H, C].map(p => p.evaluate(() => { const d = window.__dtv, S = d.S; return { screen: d.App.screen, phase: S.phase, players: S.players.map(p => p.name + '@' + p.x.toFixed(0) + ',' + p.z.toFixed(0) + ' hp' + Math.round(p.hp) + ' w' + p.wood + ' p' + p.posse + ' ' + p.state).join(' | '), peasants: S.peasants.length, undead: S.undead.length, structs: S.structs.filter(s => s.built).length, keep: S.keepHp, dead: d.trees.filter(t => !t.alive).length, tl: Math.round(S.timeLeft), me: d.me() && d.me().name }; })));
  let [h, c] = await st();
  ok('both are in the game on day 1', h.screen === 'game' && c.screen === 'game' && c.phase === 'day', c.players);
  ok('each knows who they are', h.me === 'Matt' && c.me === 'Friend');
  ok('six neighbours waiting (three each)', h.peasants === 6 && c.peasants === 6);
  // client walks west and rallies a neighbour; host must see both
  await C.evaluate(() => { const d = window.__dtv, me = d.me(); const q = d.S.peasants.reduce((a, b) => ((a.x - me.x) ** 2 + (a.z - me.z) ** 2 < (b.x - me.x) ** 2 + (b.z - me.z) ** 2 ? a : b)); me.x = q.x + 1; me.z = q.z; d.keys.KeyE = true; });
  await sleep(5000); await C.evaluate(() => { window.__dtv.keys.KeyE = false; });
  [h, c] = await st();
  ok('client rallied a neighbour, seen on both sides', /Friend[^|]* p[1-3]/.test(h.players) && /Friend[^|]* p[1-3]/.test(c.players), h.players);
  // client chops a tree
  await C.evaluate(() => { const d = window.__dtv, me = d.me(), t = d.trees.filter(t => t.alive && t.x < -32).sort((a, b) => Math.hypot(a.x + 34, a.z) - Math.hypot(b.x + 34, b.z))[0]; me.x = t.x + 1.6; me.z = t.z; d.keys.KeyE = true; });
  await sleep(9000); await C.evaluate(() => { window.__dtv.keys.KeyE = false; });
  [h, c] = await st();
  const cw = +(/Friend[^|]* w(\d+)/.exec(h.players) || [])[1];
  ok('client chopped wood, host agrees', cw > 0 && /Friend[^|]* w[1-9]/.test(c.players), 'wood ' + cw);
  // give wood on the host, client builds a wall on a foundation and places a barricade
  await H.evaluate(() => { for (const p of window.__dtv.S.players) p.wood = 20; });
  await C.evaluate(() => { const d = window.__dtv, me = d.me(); me.x = -6; me.z = -24; d.keys.KeyE = true; });
  await sleep(5000); await C.evaluate(() => { window.__dtv.keys.KeyE = false; });
  await C.evaluate(() => { const d = window.__dtv, me = d.me(); me.x = 3; me.z = -34; me.r = Math.PI; window.dispatchEvent(new KeyboardEvent('keydown', { code: 'Digit1' })); d.keys.Digit1 = false; });
  await sleep(3000); await C.evaluate(() => { window.dispatchEvent(new KeyboardEvent('keydown', { code: 'KeyE' })); window.__dtv.keys.KeyE = false; }); await sleep(2500);
  [h, c] = await st();
  ok('client built a wall and a barricade, seen on both sides', h.structs === 2 && c.structs === 2, 'host ' + h.structs + ' client ' + c.structs);
  if (h.structs !== 2) console.log('   debug host:', await H.evaluate(() => JSON.stringify(window.__dtv.S.structs.filter(s => s.built).map(s => s.k + '@' + s.x + ',' + s.z))), h.players, '| client:', c.players, await C.evaluate(() => JSON.stringify({ sel: window.__dtv.App.buildSel, r: window.__dtv.me().r })));
  await C.screenshot({ path: __dirname + '/shots/coop-client-day.png' });
  // ready up: day must not end until both are ready
  await H.evaluate(() => { window.dispatchEvent(new KeyboardEvent('keydown', { code: 'KeyR' })); window.__dtv.keys.KeyR = false; }); await sleep(1500);
  [h, c] = await st(); ok('one ready is not enough', h.phase === 'day');
  await C.evaluate(() => { window.dispatchEvent(new KeyboardEvent('keydown', { code: 'KeyR' })); window.__dtv.keys.KeyR = false; }); await sleep(2500);
  [h, c] = await st(); ok('both ready starts dusk on both sides', h.phase === 'dusk' && c.phase === 'dusk', h.phase + '/' + c.phase);
  // night: fast-forward the host; the client should see undead and be able to hurt them
  await H.evaluate(() => { window.__dtv.fast(52); }); await sleep(2500);
  [h, c] = await st(); ok('night: client sees the same undead', h.phase === 'night' && h.undead > 0 && Math.abs(c.undead - h.undead) <= 2, 'host ' + h.undead + ' client ' + c.undead);
  await C.evaluate(() => { const d = window.__dtv, me = d.me(), u = d.S.undead.find(u => u.state !== 'rise') || d.S.undead[0]; me.x = u.x; me.z = u.z + 1.8; d.keys.Space = true; });
  await sleep(9000); await C.evaluate(() => { window.__dtv.keys.Space = false; });
  const kills = await H.evaluate(() => window.__dtv.S.stats.kills);
  ok('client attacks count on the host', kills > 0, 'kills ' + kills);
  await H.screenshot({ path: __dirname + '/shots/coop-host-night.png' }); await C.screenshot({ path: __dirname + '/shots/coop-client-night.png' });
  // a late joiner is turned away
  const L = await open('late'); await L.fill('#code', code); await L.click('#btnJoin'); await sleep(2500);
  ok('late joiner is told the day has begun', /already begun/.test(await L.textContent('#status')), await L.textContent('#status'));
  await L.close();
  // finish the night on the host: both should wake on day 2 with the notice
  await H.evaluate(() => { const d = window.__dtv; d.me().x = 0; d.me().z = 12; d.fast(400, () => { for (const u of d.S.undead) if (u.state !== 'rise') { u.dead = true; d.S.night.kills++; } for (const p of d.S.players) if (p.state === 'ok') p.hp = 100; return d.S.phase === 'night'; }); }); await sleep(8000);
  [h, c] = await st();
  const day = await Promise.all([H, C].map(p => p.evaluate(() => window.__dtv.S.day)));
  ok('day 2 on both sides', h.phase === 'day' && c.phase === 'day' && day[0] === 2 && day[1] === 2, h.phase + '/' + c.phase + ' day ' + day.join('/'));
  ok('client sees the dawn notice', !(await C.isHidden('#dawn')) && /Night 1 is over/.test(await C.textContent('#dawnLines')), await C.textContent('#dawnLines'));
  ok('everyone is back at their cottage', /Friend[^|]*@-3,6/.test(c.players) && /Friend[^|]*@-3,6/.test(h.players), c.players);
  // Build 2 actions from the client: a book, the market, eating, hiding
  await H.evaluate(() => { for (const p of window.__dtv.S.players) { p.wood = 12; p.food = 6; p.iron = 12; p.hp = 50; } }); await sleep(1500);
  await C.evaluate(() => { const d = window.__dtv; d.me().x = 13.4; d.me().z = 20.4; }); await sleep(3000);
  await C.evaluate(() => window.__dtv.act('book', 1)); await sleep(2500);
  const cs = () => Promise.all([H, C].map(p => p.evaluate(() => { const f = window.__dtv.S.players.find(p => p.name === 'Friend'); return f ? JSON.stringify({ bk: f.books, wood: f.wood, coin: f.coin, food: f.food, hp: Math.round(f.hp), wpn: f.wpn, st: f.state, cw: !!f.coward, dn: f.dn }) : 'none'; })));
  let [hc, cc] = await cs(); ok('client took a book; both sides agree', /"bk":\[0,1,0,0,/.test(hc) && hc === cc, hc + ' vs ' + cc);
  await C.evaluate(() => { const d = window.__dtv; d.me().x = 0; d.me().z = 19.7; }); await sleep(3000);
  await C.evaluate(() => window.__dtv.act('sell', 'wood')); await sleep(2500);
  [hc, cc] = await cs(); ok('client sold wood at the market', /"wood":7/.test(hc) && /"coin":(?!0)/.test(hc) && hc === cc, hc);
  await C.evaluate(() => { window.dispatchEvent(new KeyboardEvent('keydown', { code: 'KeyF' })); window.__dtv.keys.KeyF = false; }); await sleep(2500);
  [hc, cc] = await cs(); ok('client ate: food down, health up', /"food":5/.test(hc) && /"hp":70/.test(hc), hc);
  await C.evaluate(() => { const d = window.__dtv; d.me().x = 12.4; d.me().z = -4.7; }); await sleep(3000);
  await C.evaluate(() => window.__dtv.act('forge', 1)); await sleep(2500);
  [hc, cc] = await cs(); ok('client forged a sword', /"wpn":1/.test(hc) && hc === cc, hc);
  ok('the client hears the news', /forged a short sword/.test(await C.textContent('#toasts')), await C.textContent('#toasts'));
  // ---- Build 3 over the wire: pack, arms rack, tricks, the bucket, sites, trees, the inn
  await H.evaluate(() => { const f = window.__dtv.S.players.find(p => p.name === 'Friend'); f.inv = [6, 28]; }); await sleep(2000);
  ok('client sees its pack', (await C.evaluate(() => window.__dtv.me().inv.join())) === '6,28');
  await C.evaluate(() => { const d = window.__dtv; d.me().x = 12.9; d.me().z = 10.6; }); await sleep(3000);
  await C.evaluate(() => window.__dtv.act('puti', 0)); await sleep(2500);
  const rack = await Promise.all([H, C].map(p => p.evaluate(() => window.__dtv.S.items.join())));
  ok('client put a club on the shared arms rack; both see it', rack[0] === '6' && rack[1] === '6', rack.join(' / '));
  await H.evaluate(() => { const d = window.__dtv; d.me().x = 12.9; d.me().z = 10.6; d.act('takei', 0); }); await sleep(2500);
  ok('host took it off the rack', (await H.evaluate(() => window.__dtv.me().wpn)) === 6 && (await C.evaluate(() => window.__dtv.S.items.length)) === 0);
  await C.evaluate(() => window.__dtv.act('eq', 0)); await sleep(2500);
  ok('client carries the bucket', (await C.evaluate(() => window.__dtv.me().trk)) === 28);
  await C.evaluate(() => { const d = window.__dtv; d.me().x = 40; d.me().z = 0; d.me().r = 0; }); await sleep(3000);
  await H.evaluate(() => { const d = window.__dtv; for (let i = 0; i < 2; i++) { const u = d.sim.spawnUndead(0, 40 + i * 0.8 - 0.4, 1.6); u.state = 'walk'; u.t = 0; u.cd = 99; } }); await sleep(1500);
  await C.evaluate(() => { window.dispatchEvent(new KeyboardEvent('keydown', { code: 'ShiftLeft' })); window.__dtv.keys.ShiftLeft = false; }); await sleep(2500);
  const ab = await H.evaluate(() => { const d = window.__dtv, f = d.S.players.find(p => p.name === 'Friend'); return { cd: f.abCd, hurt: d.S.undead.filter(u => u.hp < d.UN[0].hp || u.stun > 0).length }; });
  ok('client used the sword’s trick (Shift) and the host ran it', ab.cd > 0, JSON.stringify(ab));
  ok('client sees the wait on its trick', (await C.evaluate(() => window.__dtv.me().abCd)) > 0);
  await C.evaluate(() => { window.dispatchEvent(new KeyboardEvent('keydown', { code: 'KeyG' })); window.__dtv.keys.KeyG = false; }); await sleep(2500);
  const bk = await H.evaluate(() => { const d = window.__dtv, f = d.S.players.find(p => p.name === 'Friend'); return { trk: f.trk, feared: d.S.undead.filter(u => u.fear > 0).length }; });
  ok('client lobbed the bucket (G): the dead run', bk.trk === -1 && bk.feared >= 1, JSON.stringify(bk));
  ok('client sees the dead as frightened', (await C.evaluate(() => window.__dtv.S.undead.filter(u => u.fl & 4).length)) >= 1);
  await H.evaluate(() => { window.__dtv.S.undead.length = 0; });
  await H.evaluate(() => { const d = window.__dtv; d.S.sites = [2, 3, 1]; d.sim.rollDay; const t = d.trees[5]; t.st = 1; t.alive = false; d.S.tv++; d.S.spots[4] = 0; d.S.ale = 7; d.S.seed = d.S.seed; }); await sleep(2500);
  const cv = await C.evaluate(() => { const d = window.__dtv; return { q: d.QUARRY.x, m: d.MINEC.x, j: d.JETTY.x, t: d.trees[5].st, sp: d.S.spots[4], ale: d.S.ale, seed: d.S.seed }; });
  const hv = await H.evaluate(() => { const d = window.__dtv; return { seed: d.S.seed }; });
  ok('client follows the stone, iron and fishing when they move', cv.q === 72 && cv.m === -34 && cv.j === -28, JSON.stringify(cv));
  ok('client sees stumps, searched heaps, the ale and the same ruins', cv.t === 1 && cv.sp === 0 && cv.ale === 7 && cv.seed === hv.seed, JSON.stringify(cv));
  await H.evaluate(() => { const d = window.__dtv; d.S.sites = [0, 0, 0]; d.trees[5].st = 0; d.trees[5].alive = true; d.S.tv++; });
  await H.evaluate(() => { for (const p of window.__dtv.S.players) p.ready = true; }); await sleep(4000);
  await C.evaluate(() => { const d = window.__dtv; d.me().x = -13.1; d.me().z = -4.7; }); await sleep(3000);
  await C.evaluate(() => window.__dtv.act('innin')); await sleep(2500);
  const inn = await Promise.all([H, C].map(p => p.evaluate(() => window.__dtv.S.players.find(p => p.name === 'Friend').state)));
  ok('client went into the Thorny Rose at dusk; both agree', inn[0] === 'inn' && inn[1] === 'inn', inn.join('/'));
  ok('the inn notice is open for the client', /Inside the Thorny Rose/.test(await C.textContent('#panelTitle')));
  await C.evaluate(() => window.__dtv.act('drink')); for (let i = 0; i < 30 && (await C.evaluate(() => window.__dtv.me().cg)) < 25; i++) await sleep(1000); await sleep(1500);
  ok('client drank a tankard', (await C.evaluate(() => window.__dtv.me().cg)) >= 25 && (await H.evaluate(() => window.__dtv.S.ale)) === 6);
  await C.evaluate(() => window.__dtv.act('innout')); await sleep(3000);
  ok('client came out again', (await C.evaluate(() => window.__dtv.me().state)) === 'ok' && Math.abs(await C.evaluate(() => window.__dtv.me().x) + 13.6) < 1.5);
  await C.evaluate(() => { const d = window.__dtv; d.me().x = -2.5; d.me().z = 6.7; d.keys.KeyE = true; }); await sleep(6000); await C.evaluate(() => { window.__dtv.keys.KeyE = false; });
  [hc, cc] = await cs(); ok('client hid in their cottage at dusk; host agrees', /"st":"hide"/.test(hc) && /"cw":true/.test(hc) && hc === cc, hc);
  // the keep falls: both see it, and the host can take the day again
  await H.evaluate(() => { const d = window.__dtv; d.fast(40, () => d.S.phase !== 'night'); d.S.keepHp = 4; d.fast(300, () => d.S.phase === 'night'); }); await sleep(11000);
  [h, c] = await st(); ok('the keep falls on both sides', h.phase === 'lost' && c.phase === 'lost', h.phase + '/' + c.phase);
  ok('end notice: host can retry, client waits', !(await H.isHidden('#btnAgain')) && (await C.isHidden('#btnAgain')) && !(await C.isHidden('#end')), await H.textContent('#btnAgain'));
  await H.click('#btnAgain'); await sleep(6000);
  [h, c] = await st(); [hc, cc] = await cs();
  ok('retrying day 2 restores both players as they were that morning', h.phase === 'day' && c.phase === 'day' && /"bk":\[0,0,0,0,/.test(cc) && /"st":"ok"/.test(cc) && /Friend[^|]*@-3,6/.test(c.players) && c.structs >= 1, cc + ' // ' + c.players + ' structs ' + c.structs);
  // host leaves: the client goes back to the notice board
  await H.click('#btnTitle').catch(() => { }); await H.evaluate(() => { document.getElementById('btnTitle').click(); }); await sleep(1500);
  await sleep(1500);
  ok('host leaving sends the client home with a message', (await C.evaluate(() => window.__dtv.App.screen)) === 'home' && /host has left/.test(await C.textContent('#status')), await C.textContent('#status'));
  console.log(errs.length ? errs.join('\n') : 'no errors');
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
