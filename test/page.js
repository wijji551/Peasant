// Build 2 through the real page: place notices, number keys, the dawn notice, carrying on from a save, losing and retrying, the Steward.
const { chromium } = require('./_playwright');
const URL = process.env.DTV_URL || 'http://127.0.0.1:8765/defend-the-village.html';
const sleep = ms => new Promise(r => setTimeout(r, ms));
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const ctx = await browser.newContext({ viewport: { width: 1100, height: 680 } });
  const page = await ctx.newPage(); const errs = [];
  page.on('pageerror', e => errs.push('PAGEERROR: ' + e.message + '\n' + (e.stack || '').split('\n').slice(0, 6).join('\n')));
  page.on('console', m => { if (m.type() === 'error' && !/ERR_TUNNEL|Failed to load/.test(m.text())) errs.push(m.text()); });
  const ok = (n, c, x) => console.log((c ? 'PASS ' : 'FAIL ') + n + (x !== undefined ? '  [' + x + ']' : ''));
  const g = (f, a) => page.evaluate(f, a);
  const shot = n => page.screenshot({ path: __dirname + '/shots/' + n + '.png' });
  await page.goto(URL); await sleep(1200);
  await g(() => localStorage.removeItem('dtv-save')); await page.reload(); await sleep(1200);
  ok('no carry-on button without a save', await page.isHidden('#contRow'));
  await page.fill('#name', 'Matt'); await page.click('#btnSolo'); await sleep(2500);
  ok('the day 1 notice is up', !(await page.isHidden('#dawn')), await page.textContent('#dawnTitle'));
  await page.keyboard.press('Escape'); await sleep(600); ok('Esc puts it away', await page.isHidden('#dawn'));
  // library by real keys
  await g(() => { const m = window.__dtv.me(); m.x = 13.2; m.z = 20.4; }); await sleep(3500);
  ok('prompt offers the library', /library/.test(await page.textContent('#promptText')), await page.textContent('#promptText'));
  await page.keyboard.down('KeyE'); await sleep(4000); await page.keyboard.up('KeyE'); await sleep(1500);
  ok('holding E opens the library notice', !(await page.isHidden('#panel')) && /library/i.test(await page.textContent('#panelTitle')));
  await shot('b2-library');
  await page.keyboard.press('Digit4'); await sleep(1200);
  ok('pressing 4 takes Hammer and Tongs', await g(() => window.__dtv.me().books[3]) === 1, await page.textContent('#hudBooks'));
  await g(() => { const m = window.__dtv.me(); m.x = 5; m.z = 20; }); await sleep(4000);
  ok('walking away closes the notice', await page.isHidden('#panel'));
  // smithy by click
  await g(() => { const m = window.__dtv.me(); m.x = 12.4; m.z = -4.7; m.iron = 20; m.wood = 20; m.stone = 7; m.food = 4; m.coin = 30; m.hp = 62; for (const q of window.__dtv.S.peasants.slice(0, 3)) { q.owner = m.id; q.state = 'follow'; } }); await sleep(800);
  await page.keyboard.down('KeyE'); await sleep(4000); await page.keyboard.up('KeyE'); await sleep(1500);
  await shot('b2-smithy');
  const iron0 = await g(() => window.__dtv.me().iron);
  await page.click('#panelOpts button:has-text("Forge a mace")'); await sleep(1200);
  ok('clicking forges a mace at the book price', await g(() => window.__dtv.me().wpn) === 3 && await g(() => window.__dtv.me().iron) === iron0 - 6, 'iron ' + iron0 + ' -> ' + await g(() => window.__dtv.me().iron));
  ok('heavy arms are greyed out below rank 2', await page.isDisabled('#panelOpts button:has-text("warhammer")'));
  await sleep(2000); ok('gear shows in the readout', /mace/.test(await page.textContent('#hudGear')), await page.textContent('#hudGear'));
  // carry on from a save: finish night 1 quickly, reload, carry on
  await g(() => { const d = window.__dtv; d.me().ready = true; d.fast(22); d.fast(600, () => { if (d.S.phase !== 'night') return false; for (const u of d.S.undead) if (u.state !== 'rise') u.dead = true, d.S.night.kills++; }); });
  await sleep(6000); ok('day 2 notice shows', !(await page.isHidden('#dawn')) && /Day 2/.test(await page.textContent('#dawnTitle')), await page.textContent('#dawnLines'));
  await shot('b2-dawn');
  const before = await g(() => { const m = window.__dtv.me(); return JSON.stringify([m.wpn, m.books, m.iron, m.coin, window.__dtv.S.peasants.filter(q => q.owner === m.id).length, window.__dtv.S.day]); });
  await page.reload(); await sleep(1500);
  ok('after reloading, the notice board offers to carry on', !(await page.isHidden('#contRow')) && /day 2/.test(await page.textContent('#btnCont')), await page.textContent('#btnCont') + ' / ' + await page.textContent('#contNote'));
  await page.click('#btnCont'); await sleep(2500);
  const after = await g(() => { const m = window.__dtv.me(); return JSON.stringify([m.wpn, m.books, m.iron, m.coin, window.__dtv.S.peasants.filter(q => q.owner === m.id).length, window.__dtv.S.day]); });
  ok('carrying on restores the morning exactly', before === after, before + ' vs ' + after);
  // lose, then retry the day
  await g(() => { const d = window.__dtv; d.me().wood = 3; d.me().ready = true; d.fast(22); d.S.keepHp = 5; d.fast(200, () => d.S.phase === 'night'); });
  await sleep(11000);
  ok('the keep falling ends the night', await g(() => window.__dtv.S.phase) === 'lost' && !(await page.isHidden('#end')), await page.textContent('#endTitle') + ' / ' + await page.textContent('#btnAgain'));
  await shot('b2-lost');
  await page.click('#btnAgain'); await sleep(2500);
  ok('retrying goes back to that morning', await g(() => { const d = window.__dtv; return d.S.phase === 'day' && d.S.day === 2 && d.S.keepHp === 1000 && d.me().wpn === 3; }));
  // the Steward raises the fallen while nobody is near him, and stops when a player closes in
  const r = await g(() => {
    const d = window.__dtv, S = d.S; S.day = 7; d.me().ready = true; d.fast(22); d.me().x = 0; d.me().z = 10; d.me().arm = 7;
    d.fast(300, () => { if (S.boss) return false; for (const u of S.undead) if (u.state !== 'rise') u.dead = true; });
    const b = S.boss; if (!b) return 'no boss';
    S.night.q.length = 0; for (const u of S.undead) if (u.k !== 3) u.dead = true; d.fast(0.2);
    for (let i = 0; i < 12; i++) S.graves.push({ x: -6 + i, z: -30, k: i % 3 });
    d.fast(40, () => S.keepHp = 1000); const raised = S.undead.length - 1, gl = S.graves.length;
    for (const u of S.undead) if (u.k !== 3) u.dead = true; d.fast(0.2); S.graves.length = 0; for (let i = 0; i < 6; i++) S.graves.push({ x: -3 + i, z: -30, k: 0 });
    d.me().x = b.x + 2; d.me().z = b.z + 2; d.fast(10, () => { d.me().hp = 100; }); const whileNear = S.undead.length - 1;
    return JSON.stringify({ raised, gravesLeft: gl, raisedWhileNear: whileNear, bossHp: b.hp + '/' + b.max });
  });
  ok('the Steward raises the fallen, and stops when someone reaches him', /"raised":(?!0)/.test(r) && /"raisedWhileNear":0/.test(r), r);
  await g(() => { const d = window.__dtv, S = d.S; S.graves.length = 0; for (let i = 0; i < 4; i++) S.graves.push({ x: -3 + i * 2, z: S.boss.z + 5, k: i % 3 }); d.me().x = S.boss.x + 9; d.me().z = S.boss.z + 9; d.fast(8, () => { d.me().hp = 100; }); d.me().x = S.boss.x + 3; d.me().z = S.boss.z + 6; });
  await sleep(5000); await shot('b2-steward');
  ok('boss bar is showing', !(await page.isHidden('#bossBox')), await page.textContent('#bossNum'));
  console.log(errs.length ? errs.join('\n') : 'no errors');
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
