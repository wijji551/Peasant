const { chromium } = require('./_playwright');
const URL = process.env.DTV_URL || 'http://127.0.0.1:8765/defend-the-village.html';
const sleep = ms => new Promise(r => setTimeout(r, ms));
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const page = await (await browser.newContext({ viewport: { width: 700, height: 460 } })).newPage();
  await page.goto(URL); await sleep(1000);
  await page.fill('#name', 'Bot'); await page.click('#btnSolo'); await sleep(4000);
  console.log(await page.evaluate(() => {
    const d = window.__dtv, S = d.S; d.sim.duskFalls(); d.fast(21); S.night.q = [{ k: 0, t: 1e9 }];
    for (let i = 0; i < 220; i++) d.sim.spawnUndead(i % 4 === 0 ? 1 : 0);
    const t0 = performance.now(); d.fast(20); const ms = performance.now() - t0;
    const snap = JSON.stringify(S.undead.map(u => [u.id, u.k, Math.round(u.x * 10) / 10, Math.round(u.z * 10) / 10, Math.round(u.r * 100) / 100, Math.ceil(u.hp), 1, u.ac, u.hc, 0, 0])).length;
    return `220 undead: ${(ms / 600).toFixed(2)} ms per rules step (600 steps); undead list is ${snap} bytes per send; alive ${S.undead.length}`;
  }));
  await browser.close();
})();
