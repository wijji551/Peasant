const { chromium } = require('./_playwright');
const URL = process.env.DTV_URL || 'http://127.0.0.1:8765/defend-the-village.html';
const sleep = ms => new Promise(r => setTimeout(r, ms));
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 760 } });
  const page = await ctx.newPage(); const errs = [];
  page.on('pageerror', e => errs.push('PAGEERROR: ' + e.message + '\n' + (e.stack || '').split('\n').slice(0, 6).join('\n')));
  page.on('console', m => { if (m.type() === 'error' && !/ERR_TUNNEL|Failed to load/.test(m.text())) errs.push(m.text()); });
  await page.goto(URL); await sleep(2500);
  await page.screenshot({ path: 'test/shots/b3-home.png' });
  await page.evaluate(() => localStorage.removeItem('dtv-save'));
  await page.fill('#name', 'Matt'); await page.click('#btnSolo'); await sleep(2500);
  await page.evaluate(() => { document.getElementById('dawn').hidden = true; });
  await page.screenshot({ path: 'test/shots/b3-start.png' });
  const r = await page.evaluate(() => { const d = window.__dtv; d.fast(5); return { phase: d.S.phase, posse: d.S.peasants.map(q => [q.x.toFixed(1), q.z.toFixed(1)]), trees: d.trees.length, sites: d.S.sites, spots: d.S.spots }; });
  console.log(JSON.stringify(r));
  const shots = process.argv.slice(2);
  for (const sh of shots) { const [n, x, z] = sh.split(','); await page.evaluate(([x, z]) => { const m = window.__dtv.me(); m.x = +x; m.z = +z; }, [x, z]); await sleep(4000); await page.screenshot({ path: `test/shots/b3-${n}.png` }); }
  console.log(errs.length ? errs.join('\n') : 'no errors');
  await browser.close();
})();
